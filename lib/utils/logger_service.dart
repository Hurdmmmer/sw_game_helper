import 'package:logger/logger.dart';

class Log {
  // 单例
  static final Log _instance = Log._internal();
  factory Log() => _instance;
  Log._internal();

  static late final Logger logger;

  /// 初始化（main() 中调用一次）
  static void init({
    Level level = Level.debug,
    String tag = 'App',
  }) {
    logger = Logger(
      level: level,
      printer: _JavaLikePrinter(tag),
      filter: ProductionFilter(),
      output: ConsoleOutput(),
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

class _JavaLikePrinter extends LogPrinter {
  final String tag;

  _JavaLikePrinter(this.tag);

  @override
  List<String> log(LogEvent event) {
    final time = _formatTime(DateTime.now());
    final level = _levelToString(event.level);
    final message = event.message;

    return [
      '$time  $level  [$tag] - $message'
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
      case Level.wtf:
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
