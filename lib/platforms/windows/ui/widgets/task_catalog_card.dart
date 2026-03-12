import 'package:flutter/material.dart';
import 'package:sw_game_helper/enums/game_task.dart';
import 'package:sw_game_helper/platforms/windows/ui/widgets/glass_card.dart';
import 'package:sw_game_helper/platforms/windows/ui/widgets/panel_primitives.dart';
import 'package:sw_game_helper/platforms/windows/ui/widgets/pill_toggle.dart';
import 'package:sw_game_helper/style/app_tokens.dart';

/// 任务分类卡片
/// 包含任务分类名称的卡片
class TaskCatalogCard extends StatefulWidget {
  /// 构造函数。
  const TaskCatalogCard({super.key});

  /// 任务分类选项
  List<PillOption> get options =>
      GameTaskType.values.map((e) => PillOption(e.code, e.label)).toList();

  /// 创建状态对象。
  @override
  State<TaskCatalogCard> createState() => _TaskCatalogCardState();
}

class _TaskCatalogCardState extends State<TaskCatalogCard> {
  /// 当前选中选项
  String _currentSelectOption = 'daily';

  late final PageController _pageController;

  /// 日常任务是否正在运行
  bool _dailyTaskRunning = false;

  /// 钓鱼任务是否正在运行
  bool _fishingTaskRunning = false;

  ///  dungeons 任务是否正在运行
  bool _dungeonsTaskRunning = false;

  /// 获取当前分类是否运行中。
  bool _isCurrentTaskRunning() {
    return switch (_currentSelectOption) {
      'daily' => _dailyTaskRunning,
      'fishing' => _fishingTaskRunning,
      'dungeons' => _dungeonsTaskRunning,
      _ => false,
    };
  }

  /// 切换当前分类任务运行状态。
  void _toggleCurrentTaskRunning() {
    setState(() {
      switch (_currentSelectOption) {
        case 'daily':
          _dailyTaskRunning = !_dailyTaskRunning;
          break;
        case 'fishing':
          _fishingTaskRunning = !_fishingTaskRunning;
          break;
        case 'dungeons':
          _dungeonsTaskRunning = !_dungeonsTaskRunning;
          break;
      }
    });
  }

  @override
  /// 初始化分页控制器。
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1);
  }

  @override
  /// 释放分页控制器。
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  /// 构建任务分类面板。
  Widget build(BuildContext context) {
    final currentRunning = _isCurrentTaskRunning();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 36,
          child: Row(
            children: [
              const PanelSectionTitle(title: '任务分类'),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '选择分类后开始任务',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTokens.textSecondary(context),
                  ),
                ),
              ),
              SizedBox(
                height: 34,
                child: ElevatedButton(
                  // 任务执行按钮按语义区分颜色：
                  // 未运行=开始任务（主色），运行中=停止任务（危险色）。
                  style:
                      (currentRunning
                              ? PanelPrimitives.compactDangerButtonStyle(
                                  context,
                                )
                              : PanelPrimitives.compactPrimaryButtonStyle(
                                  context,
                                ))
                          .copyWith(
                            minimumSize: const WidgetStatePropertyAll(
                              Size(104, 34),
                            ),
                          ),
                  onPressed: _toggleCurrentTaskRunning,
                  child: Text(currentRunning ? '停止任务' : '开始任务'),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        PillToggle(
          selectedValue: _currentSelectOption,
          options: widget.options,
          onChanged: (value) {
            final index = widget.options.indexWhere((e) => e.value == value);
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
            );
          },
          isEnable: true,
        ),
        SizedBox(height: AppSpacing.sm),
        Expanded(child: _buildTaskPager()),
      ],
    );
  }

  /// 构建任务分页组件。
  Widget _buildTaskPager() {
    return PageView.builder(
      padEnds: true,
      clipBehavior: Clip.hardEdge,
      controller: _pageController,
      itemCount: widget.options.length,
      onPageChanged: (index) {
        setState(() {
          _currentSelectOption = widget.options[index].value;
        });
      },
      itemBuilder: (context, index) {
        final type = GameTaskType.values[index];
        final running = switch (type.code) {
          'daily' => _dailyTaskRunning,
          'fishing' => _fishingTaskRunning,
          'dungeons' => _dungeonsTaskRunning,
          _ => false,
        };
        return SizedBox.expand(
          child: _InteTaskCard(taskRunning: running, taskType: type),
        );
      },
    );
  }
}

/// 状态点小部件
/// [active] 是否激活
/// [size] 点的大小
class _StatusDot extends StatelessWidget {
  final bool active;
  final double size;

  /// 构造函数。
  const _StatusDot({required this.active, this.size = 8.0});

  @override
  /// 构建状态点。
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150), // 状态切换时有平滑过渡
      width: size,
      height: size,
      decoration: BoxDecoration(
        // 使用语义色，避免明暗主题切换时状态点与整体配色割裂。
        color: active ? AppTokens.success(context) : AppTokens.error(context),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// 内部任务卡片
/// [task] 任务模型
class _InteTaskCard extends StatefulWidget {
  final bool taskRunning;
  final GameTaskType taskType;

  /// 内部任务卡片
  /// [taskType] 任务类型
  /// [taskRunning] 任务是否正在运行
  const _InteTaskCard({required this.taskRunning, required this.taskType});

  /// 创建状态对象。
  @override
  State<_InteTaskCard> createState() => _InteTaskCardState();
}

class _InteTaskCardState extends State<_InteTaskCard> {
  @override
  /// 构建任务详情卡片。
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据可用高度切换紧凑布局，避免在极小高度下发生 RenderFlex overflow。
        final isVeryCompact = constraints.maxHeight < 72;
        final isCompact = constraints.maxHeight < 108;
        final contentPadding = isVeryCompact
            ? const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6)
            : isCompact
            ? const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8)
            : EdgeInsets.all(AppSpacing.md);
        final titleFontSize = isVeryCompact ? 13.0 : 14.0;
        final statusFontSize = isVeryCompact ? 12.0 : 13.0;
        final descFontSize = isCompact ? 11.0 : 12.0;
        final descMaxLines = isCompact ? 2 : 3;

        return ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: GlassCard(
            child: Padding(
              padding: contentPadding,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.taskType.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTokens.textPrimary(context),
                            fontWeight: FontWeight.w600,
                            fontSize: titleFontSize,
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _StatusDot(
                            active: widget.taskRunning,
                            size: isVeryCompact ? 7 : 8,
                          ),
                          SizedBox(width: AppSpacing.xs),
                          Text(
                            widget.taskRunning ? '运行中' : '未运行',
                            style: TextStyle(
                              color: AppTokens.textPrimary(context),
                              fontWeight: FontWeight.w600,
                              fontSize: statusFontSize,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // 高度过小仅展示标题与状态，确保不溢出。
                  if (!isVeryCompact) ...[
                    SizedBox(height: AppSpacing.xs),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          widget.taskType.desc,
                          maxLines: descMaxLines,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTokens.textPrimary(context),
                            fontWeight: FontWeight.normal,
                            fontSize: descFontSize,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
