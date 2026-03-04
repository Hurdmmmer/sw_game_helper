import 'package:flutter/material.dart';
import 'package:sw_game_helper/enums/game_task.dart';
import 'package:sw_game_helper/platforms/windows/ui/widgets/glass_card.dart';
import 'package:sw_game_helper/platforms/windows/ui/widgets/pill_toggle.dart';
import 'package:sw_game_helper/style/app_tokens.dart';

/// 任务分类卡片
/// 包含任务分类名称的卡片
class TaskCatalogCard extends StatefulWidget {
  const TaskCatalogCard({super.key});

  /// 任务分类选项
  List<PillOption> get options =>
      GameTaskType.values.map((e) => PillOption(e.code, e.label)).toList();

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

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '任务分类',
          style: TextStyle(
            color: AppTokens.textPrimary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSpacing.md),
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
        SizedBox(height: AppSpacing.md),
        Expanded(
          child: PageView.builder(
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
              return SizedBox.expand(
                child: _InteTaskCard(
                  taskRunning: _dailyTaskRunning,
                  taskType: type,
                  onTap: () {
                    setState(() {
                      _dailyTaskRunning = !_dailyTaskRunning;
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 状态点小部件
/// [active] 是否激活
/// [size] 点的大小
class _StatusDot extends StatelessWidget {
  final bool active;
  final double size;

  const _StatusDot({super.key, required this.active, this.size = 8.0});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150), // 状态切换时有平滑过渡
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: active ? Colors.green : Colors.red,
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

  /// 点击回调
  final VoidCallback? onTap;

  /// 内部任务卡片
  /// [taskType] 任务类型
  /// [taskRunning] 任务是否正在运行
  const _InteTaskCard({
    super.key,
    required this.taskRunning,
    required this.taskType,
    this.onTap,
  });

  @override
  State<_InteTaskCard> createState() => _InteTaskCardState();
}

class _InteTaskCardState extends State<_InteTaskCard> {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.taskType.label,
                    style: TextStyle(
                      color: AppTokens.textPrimary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _StatusDot(active: widget.taskRunning),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        widget.taskRunning ? '运行中' : '未运行',
                        style: TextStyle(
                          color: AppTokens.textPrimary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.taskType.desc,
                    maxLines: 2,
                    style: TextStyle(
                      color: AppTokens.textPrimary(context),
                      fontWeight: FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: widget.onTap,
                      child: Text(
                        widget.taskRunning ? '暂停任务' : '开始任务',
                        key: ValueKey(
                          Theme.of(context).brightness,
                        ), // 关键：根据亮度切换 Key
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
