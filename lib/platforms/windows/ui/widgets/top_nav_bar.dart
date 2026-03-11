import 'package:flutter/material.dart';
import 'package:sw_game_helper/style/app_tokens.dart';
import 'package:window_manager/window_manager.dart';

class OptionItem<T> {
  final String label;
  final T value;
  final VoidCallback? onTap;

  OptionItem(this.label, this.value, this.onTap);
}

/// 顶部导航栏（生产版融合标题栏）：
/// - 保留你的导航与主题切换；
/// - 使用 `DragToMoveArea` 支持拖拽窗口；
/// - 使用 `WindowCaption` 承载系统窗口按钮，保持 Win11 行为一致性。
class TopNavBar extends StatefulWidget {
  final VoidCallback? onThemeToggle;
  final ValueChanged<String>? onNavChanged;

  const TopNavBar({super.key, this.onThemeToggle, this.onNavChanged});

  @override
  State<TopNavBar> createState() => _TopNavBarState();
}

class _TopNavBarState extends State<TopNavBar> {
  String _currentValue = 'home';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(color: AppTokens.surface(context)),
        child: Row(
          children: [
            SizedBox(width: AppSpacing.md),
            Text(
              'SW Game Helper',
              style: TextStyle(
                color: AppTokens.textPrimary(context),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 背景整块可拖拽，模拟系统标题栏拖拽区域。
                  const DragToMoveArea(child: SizedBox.expand()),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildNavItem(
                        optionItem: OptionItem(
                          '首 页',
                          'home',
                          () {
                            setState(() => _currentValue = 'home');
                            widget.onNavChanged?.call('home');
                          },
                        ),
                      ),
                      const SizedBox(width: 28),
                      _buildNavItem(
                        optionItem: OptionItem(
                          '设 置',
                          'settings',
                          () {
                            setState(() => _currentValue = 'settings');
                            widget.onNavChanged?.call('settings');
                          },
                        ),
                      ),
                      const SizedBox(width: 28),
                      _buildNavItem(
                        optionItem: OptionItem(
                          '关 于',
                          'about',
                          () {
                            setState(() => _currentValue = 'about');
                            widget.onNavChanged?.call('about');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                AppTokens.isDark(context)
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
              onPressed: () {
                widget.onThemeToggle?.call();
              },
            ),
            // 使用插件提供的系统控制按钮，避免手写窗口消息造成行为不一致。
            ConstrainedBox(
              // 使用范围约束代替写死宽度，兼容不同缩放比例和系统字体设定。
              constraints: const BoxConstraints(minWidth: 120, maxWidth: 156),
              child: WindowCaption(
                backgroundColor: Colors.transparent,
                brightness: AppTokens.isDark(context)
                    ? Brightness.dark
                    : Brightness.light,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({required OptionItem optionItem}) {
    final isSelected = _currentValue == optionItem.value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: optionItem.onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        hoverColor: AppTokens.hoverPrimary(context),
        splashColor: AppTokens.splashPrimary(context),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                optionItem.label,
                style: TextStyle(
                  color: isSelected
                      ? AppTokens.primary(context)
                      : AppTokens.textSecondary(context),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              SizedBox(height: 3),
              AnimatedContainer(
                duration: Duration(milliseconds: 180),
                height: 2,
                width: isSelected ? 30 : 0,
                decoration: BoxDecoration(
                  color: AppTokens.primary(context),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
