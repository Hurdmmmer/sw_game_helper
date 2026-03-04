import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sw_game_helper/style/app_tokens.dart';

/// 公共抽象类，用于实现玻璃卡片效果
class GlassCard extends StatelessWidget {
  /// 玻璃卡片子组件
  final Widget child;

  /// 玻璃卡片模糊半径
  final double blurSigma;

  /// 圆角半径
  final double borderRadius;

  /// 自定义背景色（不设置则使用主题默认）
  final Color? backgroundColor;

  /// 自定义透明度（不设置则根据主题自动选择）
  final double? opacity;

  /// 是否显示边框
  final bool showBorder;

  /// 是否显示阴影
  final bool showShadow;

  /// 玻璃卡片构造函数
  /// [child] 玻璃卡片子组件
  /// [blurSigma] 玻璃卡片模糊半径
  /// [borderRadius] 圆角半径
  /// [backgroundColor] 自定义背景色（不设置则使用主题默认）
  /// [opacity] 自定义透明度（不设置则根据主题自动选择）
  /// [showBorder] 是否显示边框
  /// [showShadow] 是否显示阴影
  const GlassCard({
    super.key,
    required this.child,
    this.blurSigma = 10.0,
    this.borderRadius = AppSpacing.radiusLg,
    this.backgroundColor,
    this.opacity,
    this.showBorder = true,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    // 计算背景色 - 统一从 AppTokens 获取
    final bgColor = backgroundColor ?? AppTokens.surface(context);
    final bgOpacity = opacity ?? (AppTokens.isDark(context) ? 0.7 : 0.85);

    return Container(
      // 外层装饰，用于添加圆角和阴影
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppTokens.shadow(context),
                  offset: const Offset(0, 4),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      // 内层装饰，用于添加模糊效果和背景颜色
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: bgOpacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: showBorder
                  ? Border.all(color: AppTokens.divider(context), width: 1)
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
