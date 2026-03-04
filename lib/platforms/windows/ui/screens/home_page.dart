import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _HomePageState extends ConsumerState<HomePage> {
  VideoRenderBackend _renderBackend = VideoRenderBackend.cpuPixelBuffer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {

          return Column(
            children: [
              // Top Bar（自定义融合标题栏 + 主题切换）
              TopNavBar(onThemeToggle: widget.onThemeToggle),
              // 中间区域
              Expanded(
                child: Row(
                  children: [
                    // 左侧区域
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
                                child: VideoView(backend: _renderBackend),
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
                    // 右侧区域
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
                          child: Column(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Padding(
                                  padding: EdgeInsets.all(AppSpacing.sm),
                                  // 让 ControlPanel 填充整个 GlassCard，这样就有了高度传递
                                  child: SizedBox.expand(
                                    child: SessionControlPanel(
                                      onRenderBackendChanged: (renderBackend) {
                                        if (_renderBackend == renderBackend) {
                                          return;
                                        }
                                        setState(
                                          () => _renderBackend = renderBackend,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: EdgeInsets.all(AppSpacing.sm),
                                  child: TaskCatalogCard(),
                                ),
                              ),
                            ],
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
}
