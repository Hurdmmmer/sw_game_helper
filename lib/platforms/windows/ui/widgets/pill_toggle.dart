import 'package:flutter/material.dart';
import 'package:sw_game_helper/style/app_tokens.dart';

class PillOption {
  /// 选项值
  final String value;

  /// 选项标签
  final String label;

  const PillOption(this.value, this.label);
}

/// 圆角切换选择器
///
/// 使用 [AppTokens.cardSecondary] 作为背景色，
/// [AppTokens.primary] 作为滑块高亮色。
class PillToggle extends StatelessWidget {
  /// 当前选中值
  final String selectedValue;

  /// 选项列表
  final List<PillOption> options;

  /// 值改变回调
  final ValueChanged<String> onChanged;

  /// 是否启用切换
  final bool isEnable;

  const PillToggle({
    super.key,
    required this.selectedValue,
    required this.options,
    required this.onChanged,
    required this.isEnable,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedIndex = options.indexWhere(
      (opt) => opt.value == selectedValue,
    );
    final safeIndex = selectedIndex < 0 ? 0 : selectedIndex;

    final alignmentX = options.length <= 1
        ? 0.0
        : -1.0 + (safeIndex * 2.0 / (options.length - 1));

    return SizedBox(
      // 固定高度，避免在不稳定约束下出现 RenderBox not laid out。
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTokens.cardSecondary(context),
          borderRadius: BorderRadius.circular(64),
          border: Border.all(color: AppTokens.divider(context), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment(alignmentX, 0),
                child: FractionallySizedBox(
                  widthFactor: 1 / options.length,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTokens.primary(context),
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(
                        color: AppTokens.divider(context),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTokens.shadow(context),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: options.map((option) {
                  final isSelected = option.value == selectedValue;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: isEnable ? () => onChanged(option.value) : null,
                      child: Center(
                        child: Text(
                          option.label,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTokens.textTertiary(context),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
