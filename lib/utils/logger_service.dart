import 'dart:async';
import 'dart:collection';

import 'package:logger/logger.dart';

class Log {
  // 单例
  static final Log _instance = Log._internal();
  factory Log() => _instance;
  Log._internal();

  static late final Logger logger;

  /// 对外暴露日志流，供 UI 日志面板实时订阅。
  static Stream<List<LogEntry>> get stream => _LogBuffer.instance.stream;

  /// 对外暴露增量日志流（追加/清空/淘汰），用于高频日志场景优化。
  static Stream<LogStreamEvent> get eventStream => _LogBuffer.instance.eventStream;

  /// 当前日志缓冲上限。
  static int get maxEntries => _LogBuffer.maxEntries;

  /// 提供当前日志快照，避免首帧空白。
  static List<LogEntry> get entries => _LogBuffer.instance.entries;

  /// 清空内存日志（不影响控制台输出）。
  static void clear() => _LogBuffer.instance.clear();

  /// 导出当前内存日志文本（用于一键复制）。
  static String dumpPlainText() => _LogBuffer.instance.dumpPlainText();

  /// 初始化（main() 中调用一次）
  static void init({
    Level level = Level.debug,
    String tag = 'App',
  }) {
    logger = Logger(
      level: level,
      printer: _JavaLikePrinter(tag),
      filter: ProductionFilter(),
      output: _CompositeOutput(
        outputs: <LogOutput>[
          ConsoleOutput(),
          _MemoryLogOutput(),
        ],
      ),
    );
  }

  static void v(dynamic message) => logger.t(message);
  static void d(dynamic message) => logger.d(message);
  static void i(dynamic message) => logger.i(message);
  static void w(dynamic message) => logger.w(message);

  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      logger.e(
        message,
        error: error,
        stackTrace: stackTrace,
      );
}

/// ================= Java 风格 Printer =================

/// UI 日志项。
class LogEntry {
  final String text;
  final Level level;

  const LogEntry({
    required this.text,
    required this.level,
  });

  /// 日志区显示文本（避免超长日志占满视觉空间）。
  String get displayText {
    const int maxLen = 220;
    if (text.length <= maxLen) {
      return text;
    }
    return '${text.substring(0, maxLen)}...';
  }
}

/// 日志增量事件。
class LogStreamEvent {
  final bool cleared;
  final int droppedCount;
  final List<LogEntry> appended;

  const LogStreamEvent({
    required this.cleared,
    required this.droppedCount,
    required this.appended,
  });
}

class _JavaLikePrinter extends LogPrinter {
  final String tag;

  _JavaLikePrinter(this.tag);

  @override
  List<String> log(LogEvent event) {
    final time = _formatTime(DateTime.now());
    final level = _levelToString(event.level);
    var message = event.message.toString();
    var resolvedTag = tag;

    // 统一 Rust 日志标签：
    // - 如果正文以 [Rust] 开头，则前缀标签改为 [Rust]；
    // - 同时去掉正文重复的 [Rust][LEVEL] 前缀，减少视觉噪声。
    if (message.startsWith('[Rust]')) {
      resolvedTag = 'Rust';
      message = message.replaceFirst(
        RegExp(r'^\[Rust\](\[[A-Z]+\])?\s*'),
        '',
      );
    }

    return [
      '$time  $level  [$resolvedTag] - $message'
    ];
  }

  String _levelToString(Level level) {
    switch (level) {
      case Level.trace:
        return 'TRACE';
      case Level.debug:
        return 'DEBUG';
      case Level.info:
        return 'INFO ';
      case Level.warning:
        return 'WARN ';
      case Level.error:
        return 'ERROR';
      case Level.fatal:
        return 'FATAL';
      default:
        return 'INFO ';
    }
  }

  /// yyyy-MM-dd HH:mm:ss.SSS
  String _formatTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    String three(int n) => n.toString().padLeft(3, '0');

    return '${t.year}-'
        '${two(t.month)}-'
        '${two(t.day)} '
        '${two(t.hour)}:'
        '${two(t.minute)}:'
        '${two(t.second)}.'
        '${three(t.millisecond)}';
  }
}

/// 组合输出：同一条日志可同时写入多个目标。
class _CompositeOutput extends LogOutput {
  final List<LogOutput> outputs;

  _CompositeOutput({required this.outputs});

  @override
  void output(OutputEvent event) {
    for (final output in outputs) {
      output.output(event);
    }
  }
}

/// 内存日志输出：用于 Flutter 界面实时展示。
class _MemoryLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      _LogBuffer.instance.add(
        LogEntry(
          text: line,
          level: event.level,
        ),
      );
    }
  }
}

/// 日志缓冲区：保存最近 N 条日志，避免内存无限增长。
class _LogBuffer {
  _LogBuffer._();

  static final _LogBuffer instance = _LogBuffer._();

  static const int maxEntries = 600;
  /// 刷新间隔：尽量贴近控制台实时滚动，同时控制重建频率。
  static const Duration _flushInterval = Duration(milliseconds: 24);

  final ListQueue<LogEntry> _entries = ListQueue<LogEntry>();
  final StreamController<List<LogEntry>> _controller =
      StreamController<List<LogEntry>>.broadcast();
  final StreamController<LogStreamEvent> _eventController =
      StreamController<LogStreamEvent>.broadcast();
  Timer? _flushTimer;
  final List<LogEntry> _pendingAppended = <LogEntry>[];
  int _pendingDroppedCount = 0;

  Stream<List<LogEntry>> get stream => _controller.stream;
  Stream<LogStreamEvent> get eventStream => _eventController.stream;

  List<LogEntry> get entries => List<LogEntry>.unmodifiable(_entries);

  void add(LogEntry entry) {
    if (_entries.length >= maxEntries) {
      _entries.removeFirst();
      _pendingDroppedCount += 1;
    }
    _entries.addLast(entry);
    _pendingAppended.add(entry);
    _scheduleFlush();
  }

  void clear() {
    _entries.clear();
    _pendingAppended.clear();
    _pendingDroppedCount = 0;
    _flushTimer?.cancel();
    _flushTimer = null;
    _controller.add(entries);
    _eventController.add(
      const LogStreamEvent(
        cleared: true,
        droppedCount: 0,
        appended: <LogEntry>[],
      ),
    );
  }

  /// 导出日志纯文本，便于复制到外部分析。
  String dumpPlainText() {
    return _entries.map((e) => e.text).join('\n');
  }

  /// 合并高频日志刷新，降低 UI 重建频率。
  void _scheduleFlush() {
    if (_flushTimer != null) {
      return;
    }
    _flushTimer = Timer(_flushInterval, () {
      _flushTimer = null;
      final event = LogStreamEvent(
        cleared: false,
        droppedCount: _pendingDroppedCount,
        appended: List<LogEntry>.unmodifiable(_pendingAppended),
      );
      _pendingDroppedCount = 0;
      _pendingAppended.clear();
      _controller.add(entries);
      _eventController.add(event);
    });
  }
}
