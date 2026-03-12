import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:sw_game_helper/platforms/windows/bridge_generated/gh_common/model.dart';
import 'package:sw_game_helper/platforms/windows/providers/settings_provider.dart';
import 'package:sw_game_helper/platforms/windows/ui/widgets/settings_control_panel.dart';
import 'package:sw_game_helper/platforms/windows/ui/widgets/session_control_panel.dart';
import 'package:sw_game_helper/platforms/windows/ui/widgets/glass_card.dart';
import 'package:sw_game_helper/platforms/windows/ui/widgets/task_catalog_card.dart';
import 'package:sw_game_helper/platforms/windows/ui/widgets/top_nav_bar.dart';
import 'package:sw_game_helper/platforms/windows/ui/widgets/video_view.dart';
import 'package:sw_game_helper/style/app_tokens.dart';
import 'package:sw_game_helper/utils/logger_service.dart';

class HomePage extends ConsumerStatefulWidget {
  /// 回调函数
  final VoidCallback onThemeToggle;

  const HomePage({super.key, required this.onThemeToggle});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  /// 顶部导航当前页面标识。
  /// 约定：
  /// - home: 展示原控制面板（设备 + 任务）
  /// - settings: 展示设置面板（仅替换右侧控制区）
  /// - about: 展示关于内容（仍在右侧控制区）
  String _currentPage = 'home';

  /// 右侧面板切换动画控制器。
  late final AnimationController _panelSwitchController;

  /// 右侧面板淡入动画。
  late final Animation<double> _panelFadeAnimation;

  /// 右侧面板轻微位移动画。
  late final Animation<Offset> _panelSlideAnimation;

  @override
  void initState() {
    super.initState();
    _panelSwitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _panelFadeAnimation = CurvedAnimation(
      parent: _panelSwitchController,
      curve: Curves.easeOut,
    );
    _panelSlideAnimation = Tween<Offset>(
      begin: const Offset(0.02, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _panelSwitchController, curve: Curves.easeOut),
    );
    _panelSwitchController.value = 1;
  }

  @override
  void dispose() {
    _panelSwitchController.dispose();
    super.dispose();
  }

  /// 将页面标识映射到右侧面板索引，避免频繁销毁/重建语义节点。
  int _panelIndexByPage(String page) {
    return switch (page) {
      'settings' => 1,
      'about' => 2,
      _ => 0,
    };
  }

  /// 处理顶部导航切换。
  /// 先更新页面，再触发一次轻量过渡动画。
  void _handleNavChanged(String value) {
    if (_currentPage == value) {
      return;
    }
    setState(() => _currentPage = value);
    _panelSwitchController.forward(from: 0);
  }

  /// 将设置中的渲染链路映射为视频组件后端。
  VideoRenderBackend _resolveRenderBackend(RenderPipelineMode mode) {
    return mode == RenderPipelineMode.original
        ? VideoRenderBackend.dxgi
        : VideoRenderBackend.cpuPixelBuffer;
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = ref.watch(settingsProvider);
    final renderBackend = _resolveRenderBackend(appSettings.renderPipelineMode);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // Top Bar（自定义融合标题栏 + 主题切换）
              TopNavBar(
                onThemeToggle: widget.onThemeToggle,
                onNavChanged: _handleNavChanged,
              ),
              // 中间区域
              Expanded(
                child: Row(
                  children: [
                    // 左侧区域：视频画面 + 日志区，始终保持不变。
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.sm),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusLg,
                                  ),
                                ),
                                child: VideoView(backend: renderBackend),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                AppSpacing.sm,
                                0,
                                AppSpacing.sm,
                                AppSpacing.sm,
                              ),
                              child: GlassCard(
                                child: _buildLogConsole(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 右侧区域：根据顶部导航切换控制面板内容。
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          0,
                          AppSpacing.sm,
                          AppSpacing.sm,
                          AppSpacing.sm,
                        ),
                        child: GlassCard(
                          // 说明：
                          // 使用 IndexedStack 保持子树常驻，避免切换时销毁语义节点，
                          // 可规避 Windows 无障碍桥接在动画切换场景下的 AXTree pending 报错。
                          child: FadeTransition(
                            opacity: _panelFadeAnimation,
                            child: SlideTransition(
                              position: _panelSlideAnimation,
                              child: IndexedStack(
                                index: _panelIndexByPage(_currentPage),
                                children: [
                                  _buildRightPanelContentByKey('home'),
                                  _buildRightPanelContentByKey('settings'),
                                  _buildRightPanelContentByKey('about'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 根据页面 key 构建右侧面板内容（供 IndexedStack 固定子树使用）。
  Widget _buildRightPanelContentByKey(String pageKey) {
    if (pageKey == 'settings') {
      return Padding(
        padding: EdgeInsets.all(AppSpacing.sm),
        child: const SettingsControlPanel(),
      );
    }
    if (pageKey == 'about') {
      return Center(
        child: Text(
          'SW Game Helper\n版本: 1.0.0',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTokens.textPrimary(context),
          ),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          // 上半控制区提高占比，优先保证设备列表可展示更多设备。
          flex: 4,
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.sm),
            child: const SizedBox.expand(child: SessionControlPanel()),
          ),
        ),
        Expanded(
          // 下半任务区降低占比，避免任务区占用过多内容空间。
          flex: 2,
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.sm),
            child: TaskCatalogCard(),
          ),
        ),
      ],
    );
  }

  /// 构建底部日志控制台（实时流 + 颜色分级）。
  Widget _buildLogConsole() {
    return const _LogConsolePanel();
  }
}

/// 日志面板：单独维护状态，避免主页面因高频日志频繁重建。
class _LogConsolePanel extends StatefulWidget {
  const _LogConsolePanel();

  @override
  State<_LogConsolePanel> createState() => _LogConsolePanelState();
}

class _LogConsolePanelState extends State<_LogConsolePanel> {
  final ScrollController _logScrollController = ScrollController();
  final List<LogEntry> _entries = <LogEntry>[];
  final ListQueue<LogEntry> _pendingEntries = ListQueue<LogEntry>();
  StreamSubscription<LogStreamEvent>? _logEventSub;
  Timer? _drainTimer;
  bool _autoFollowLogs = true;
  static const Duration _drainInterval = Duration(milliseconds: 16);
  static const int _drainBatchSize = 8;

  @override
  void initState() {
    super.initState();
    _entries.addAll(Log.entries);
    _logScrollController.addListener(_onLogScrollChanged);
    _logEventSub = Log.eventStream.listen(_onLogEvent);
  }

  @override
  void dispose() {
    _logEventSub?.cancel();
    _drainTimer?.cancel();
    _logScrollController.removeListener(_onLogScrollChanged);
    _logScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scheduleScrollToBottom();
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.26),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Stack(
              children: [
                SelectionArea(
                  child: _entries.isEmpty
                      ? Center(
                          child: Text(
                            'No logs yet',
                            style: TextStyle(
                              color: AppTokens.textSecondary(context),
                              fontSize: 12,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _logScrollController,
                          // 预留顶部空间，避免被悬浮按钮遮挡。
                          padding: const EdgeInsets.only(top: 32),
                          itemCount: _entries.length,
                          itemBuilder: (context, index) {
                            final entry = _entries[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                entry.text,
                                softWrap: true,
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.25,
                                  fontFamily: 'Consolas',
                                  color: _levelColor(context, entry.level),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Positioned(
                  top: -10,
                  right: -10,
                  child: TextButton(
                    onPressed: Log.clear,
                    style: TextButton.styleFrom(
                      overlayColor: Colors.transparent,
                    ),
                    child: const Text('Clear'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 应用日志增量事件（清空/丢弃/追加），避免全量重建列表。
  void _onLogEvent(LogStreamEvent event) {
    if (!mounted) {
      return;
    }
    if (event.cleared) {
      _pendingEntries.clear();
      setState(() => _entries.clear());
      return;
    }

    if (event.droppedCount > 0) {
      _dropOldEntries(event.droppedCount);
    }

    if (event.appended.isNotEmpty) {
      _pendingEntries.addAll(event.appended);
      // 先立即刷一小批，减少“延迟感”。
      _drainPendingLogs();
      _ensureDrainTimer();
    }
  }

  /// 处理缓冲区淘汰：优先从已渲染列表移除，其次从待渲染队列移除。
  void _dropOldEntries(int droppedCount) {
    var remain = droppedCount;
    if (_entries.isNotEmpty) {
      final fromRendered = remain > _entries.length ? _entries.length : remain;
      setState(() {
        _entries.removeRange(0, fromRendered);
      });
      remain -= fromRendered;
    }
    while (remain > 0 && _pendingEntries.isNotEmpty) {
      _pendingEntries.removeFirst();
      remain -= 1;
    }
  }

  /// 以小批量方式持续刷出日志，视觉上更接近控制台滚动。
  void _drainPendingLogs() {
    if (!mounted || _pendingEntries.isEmpty) {
      return;
    }
    final batch = <LogEntry>[];
    while (batch.length < _drainBatchSize && _pendingEntries.isNotEmpty) {
      batch.add(_pendingEntries.removeFirst());
    }
    if (batch.isEmpty) {
      return;
    }
    setState(() {
      _entries.addAll(batch);
      if (_entries.length > Log.maxEntries) {
        final overflow = _entries.length - Log.maxEntries;
        _entries.removeRange(0, overflow);
      }
    });
  }

  /// 启动持续刷出定时器，直到待渲染队列为空。
  void _ensureDrainTimer() {
    if (_drainTimer != null) {
      return;
    }
    _drainTimer = Timer.periodic(_drainInterval, (_) {
      if (!mounted || _pendingEntries.isEmpty) {
        _drainTimer?.cancel();
        _drainTimer = null;
        return;
      }
      _drainPendingLogs();
    });
  }

  /// 日志滚动时动态决定是否自动跟随到底部。
  void _onLogScrollChanged() {
    if (!_logScrollController.hasClients) {
      return;
    }
    final position = _logScrollController.position;
    _autoFollowLogs = (position.maxScrollExtent - position.pixels).abs() < 48;
  }

  /// 日志刷新后自动滚动到底部，便于观察最新事件。
  void _scheduleScrollToBottom() {
    if (!_autoFollowLogs) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_logScrollController.hasClients) {
        return;
      }
      _logScrollController.jumpTo(_logScrollController.position.maxScrollExtent);
    });
  }

  /// 按日志级别着色，便于快速识别 debug/info/warn/error。
  Color _levelColor(BuildContext context, Level level) {
    return switch (level) {
      Level.trace => AppTokens.textSecondary(context),
      Level.debug => const Color(0xFF42A5F5),
      Level.info => AppTokens.textPrimary(context),
      Level.warning => const Color(0xFFFFB74D),
      Level.error => const Color(0xFFEF5350),
      Level.fatal => const Color(0xFFE53935),
      _ => AppTokens.textPrimary(context),
    };
  }
}
