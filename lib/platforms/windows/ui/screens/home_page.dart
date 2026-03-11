import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sw_game_helper/platforms/windows/bridge_generated/gh_common/model.dart';
import 'package:sw_game_helper/platforms/windows/providers/settings_provider.dart';
import 'package:sw_game_helper/platforms/windows/ui/widgets/settings_control_panel.dart';
import 'package:sw_game_helper/platforms/windows/ui/widgets/session_control_panel.dart';
import 'package:sw_game_helper/platforms/windows/ui/widgets/glass_card.dart';
import 'package:sw_game_helper/platforms/windows/ui/widgets/task_catalog_card.dart';
import 'package:sw_game_helper/platforms/windows/ui/widgets/top_nav_bar.dart';
import 'package:sw_game_helper/platforms/windows/ui/widgets/video_view.dart';
import 'package:sw_game_helper/style/app_tokens.dart';

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
                                child: Center(child: Text('Log Console')),
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
}
