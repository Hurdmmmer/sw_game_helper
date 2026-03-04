import 'package:flutter/material.dart';
import 'package:sw_game_helper/style/app_tokens.dart';

/// 带样式的图标按钮组件
///
/// 用于在界面上添加图标按钮，提供统一的样式规范。
///
/// 使用示例:
/// ```dart
/// StyledIconButton(
///   icon: Icons.add,
///   onPressed: () {},
///   isLoading: false,
///   tooltip: '刷新设备列表',
/// )
/// ```

class StyledIconButton extends StatefulWidget {
  /// 图标
  final IconData iconData;

  /// 点击回调
  final VoidCallback? onPressed;

  /// 提示文本
  final String? tooltip;

  /// 是否显示加载状态
  final bool isLoading;

  /// 图标大小默认值 20.0
  final double iconSize;

  const StyledIconButton({
    super.key,
    required this.iconData,
    this.onPressed,
    this.tooltip,
    required this.isLoading,
    this.iconSize = 20.0,
  });

  @override
  State<StyledIconButton> createState() => _StyledIconButtonState();
}

/// 使用 SingleTickerProviderStateMixin
/// 为 AnimationController 提供 vsync（动画时钟）
/// 用于创建旋转动画
class _StyledIconButtonState extends State<StyledIconButton>
    with SingleTickerProviderStateMixin {
  /// 鼠标悬停状态
  bool _isHovered = false;

  /// 旋转动画控制器
  late final AnimationController _rotationController;

  // 第一次构建组件时调用该方法，只会执行一次
  @override
  void initState() {
    super.initState();
    // 初始化旋转动画，1秒完成一次旋转
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    if (widget.isLoading) {
      // 加载状态下，开始旋转动画
      _rotationController.repeat();
    }
  }

  /// 当组件状态更新时调用该方法
  /// 用于处理加载状态的变化
  @override
  void didUpdateWidget(StyledIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 监听 isLoading 属性变化
    if (widget.isLoading && !oldWidget.isLoading) {
      // 从非加载状态切换到加载状态，开始旋转动画
      _rotationController.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      // 从加载状态切换到非加载状态，停止旋转动画并重置
      _rotationController.stop();
      _rotationController.reset();
    }
  }

  /// 组件销毁时调用该方法，用于释放资源
  @override
  void dispose() {
    // 释放旋转动画控制器资源
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonSize = widget.iconSize + AppSpacing.lg;
    // MouseRegion 用于检测鼠标进入/离开按钮区域
    Widget button = MouseRegion(
      // 检测鼠标进入/离开
      onEnter: (_) => setState(() {
        _isHovered = true;
      }),
      onExit: (_) => setState(() {
        _isHovered = false;
      }),
      // 设置鼠标光标样式
      cursor: widget.onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        // 不再加载状态下，点击回调
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: _isHovered && widget.onPressed != null
                ? AppTokens.cardSecondary(context)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(buttonSize / 2),
          ),
          child: Center(
            child: RotationTransition(
              // 绑定旋转动画控制器
              turns: _rotationController,
              child: Icon(
                widget.iconData,
                size: widget.iconSize,
                weight: 100,
                color: _isHovered
                    ? AppTokens.iconPrimary(context)
                    : AppTokens.iconSecondary(context),
              ),
            ),
          ),
        ),
      ),
    );

    // 添加提示文本
    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}
