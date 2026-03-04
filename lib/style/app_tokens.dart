import 'package:flutter/material.dart';

/// SW Game Helper Design Token 系统
///
/// 设计理念：基于 Design Tokens，通过语义化命名统一管理所有设计资源。
/// 所有 UI 组件都应该使用 Token 而非直接使用颜色值。
/// **所有颜色统一从 ColorScheme 读取，确保主题切换动画流畅。**
///
/// Token 分类：
/// 1. Surface（背景色）- 页面、卡片、弹窗等背景
/// 2. Text（文字颜色）- 标题、正文、提示、禁用等
/// 3. Icon（图标颜色）- 主要、次要、提示图标
/// 4. Border（边框/分割线）- 卡片边框、列表分割线
/// 5. Semantic（语义色）- 成功、警告、错误、信息
/// 6. Glass（玻璃拟态）- 玻璃效果专用
///
/// 使用示例：
/// ```dart
/// Container(
///   color: AppTokens.surface(context),
///   child: Text(
///     'Hello',
///     style: TextStyle(color: AppTokens.textPrimary(context)),
///   ),
/// )
/// ```
class AppTokens {
  // ========== 辅助方法 ==========

  /// 获取当前 ColorScheme
  static ColorScheme _colorScheme(BuildContext context) =>
      Theme.of(context).colorScheme;

  /// 判断当前是否为暗黑模式
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // ========== 背景色 Token (Surface) ==========

  /// 页面背景色（Scaffold 背景）
  /// 使用 ThemeData.scaffoldBackgroundColor
  static Color scaffoldBackground(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  /// 卡片背景色（贴在页面上的卡片）
  /// 从 ColorScheme.surface 读取
  static Color surface(BuildContext context) => _colorScheme(context).surface;

  /// 次级背景色（嵌套卡片、输入框背景）
  /// 从 ColorScheme.surfaceContainerHighest 读取
  static Color surfaceSecondary(BuildContext context) =>
      _colorScheme(context).surfaceContainerHighest;

  /// 悬浮卡片背景色（Dialog、BottomSheet 等）
  /// 从 ColorScheme.surfaceContainerLow 读取
  static Color surfaceElevated(BuildContext context) =>
      _colorScheme(context).surfaceContainerLow;

  /// 输入框背景色
  /// 从 ColorScheme.surfaceContainerHighest 读取
  static Color surfaceInput(BuildContext context) =>
      _colorScheme(context).surfaceContainerHighest;

  /// 禁用背景色
  /// 从 ColorScheme.surfaceContainerLowest 读取
  static Color surfaceDisabled(BuildContext context) =>
      _colorScheme(context).surfaceContainerLowest;

  // ========== 文字颜色 Token (Text) ==========

  /// 主要文字颜色（标题、正文）
  /// 从 ColorScheme.onSurface 读取
  static Color textPrimary(BuildContext context) =>
      _colorScheme(context).onSurface;

  /// 次要文字颜色（副标题、说明文字）
  /// 从 ColorScheme.onSurfaceVariant 读取
  static Color textSecondary(BuildContext context) =>
      _colorScheme(context).onSurfaceVariant;

  /// 提示文字颜色（placeholder、hint）
  /// 从 ColorScheme.onSurfaceVariant 读取
  static Color textTertiary(BuildContext context) =>
      _colorScheme(context).onSurfaceVariant;

  /// 禁用文字颜色
  /// 从 ColorScheme.outline 读取（较淡）
  static Color textDisabled(BuildContext context) =>
      _colorScheme(context).outline;

  /// 反色文字（用于深色背景上的白色文字）
  /// 从 ColorScheme.onPrimary 读取
  static Color textOnPrimary(BuildContext context) =>
      _colorScheme(context).onPrimary;

  // ========== 图标颜色 Token (Icon) ==========

  /// 主要图标颜色
  /// 从 ColorScheme.onSurface 读取
  static Color iconPrimary(BuildContext context) =>
      _colorScheme(context).onSurface;

  /// 次要图标颜色
  /// 从 ColorScheme.onSurfaceVariant 读取
  static Color iconSecondary(BuildContext context) =>
      _colorScheme(context).onSurfaceVariant;

  /// 提示图标颜色
  /// 从 ColorScheme.outline 读取
  static Color iconTertiary(BuildContext context) =>
      _colorScheme(context).outline;

  // ========== 边框/分割线 Token (Border) ==========

  /// 分割线颜色
  /// 从 ColorScheme.outline 读取
  static Color divider(BuildContext context) => _colorScheme(context).outline;

  /// 边框颜色
  /// 从 ColorScheme.outline 读取
  static Color border(BuildContext context) => _colorScheme(context).outline;

  /// 阴影颜色
  /// 从 ColorScheme.shadow 读取
  static Color shadow(BuildContext context) => _colorScheme(context).shadow;

  /// 主色悬停背景（用于 InkWell 等）
  /// 从 ColorScheme.primary 派生
  static Color hoverPrimary(BuildContext context) => _colorScheme(
    context,
  ).primary.withValues(alpha: isDark(context) ? 0.3 : 0.06);

  /// 主色点击波纹（用于 InkWell 等）
  /// 从 ColorScheme.primary 派生
  static Color splashPrimary(BuildContext context) => _colorScheme(
    context,
  ).primary.withValues(alpha: isDark(context) ? 0.4 : 0.10);

  // ========== 主题色 Token (Theme) ==========

  /// 主色
  /// 从 ColorScheme.primary 读取
  static Color primary(BuildContext context) => _colorScheme(context).primary;

  /// 主色的亮色变体（用于 hover 状态）
  /// 从 ColorScheme.primaryContainer 读取
  static Color primaryLight(BuildContext context) =>
      _colorScheme(context).primaryContainer;

  /// 主色的深色变体（用于 pressed 状态）
  /// 从 ColorScheme.onPrimaryContainer 读取
  static Color primaryDark(BuildContext context) =>
      _colorScheme(context).onPrimaryContainer;

  /// 次要色
  /// 从 ColorScheme.secondary 读取
  static Color secondary(BuildContext context) =>
      _colorScheme(context).secondary;

  /// 强调色/CTA 色（行动号召按钮）
  /// 从 ColorScheme.tertiary 读取
  static Color accent(BuildContext context) => _colorScheme(context).tertiary;

  // ========== 语义色 Token (Semantic) ==========

  /// 成功状态颜色
  /// 从 ColorScheme.tertiary 读取（绿色）
  static Color success(BuildContext context) => _colorScheme(context).tertiary;

  /// 警告状态颜色
  /// 使用固定琥珀色，避免与 success/error 语义冲突
  static Color warning(BuildContext context) =>
      isDark(context) ? const Color(0xFFFBBF24) : const Color(0xFFD97706);

  /// 错误状态颜色
  /// 从 ColorScheme.error 读取
  static Color error(BuildContext context) => _colorScheme(context).error;

  /// 信息提示颜色
  /// 从 ColorScheme.primary 读取
  static Color info(BuildContext context) => _colorScheme(context).primary;

  // ========== 卡片层级 Token (Card Layers) ==========

  /// 一级卡片背景（ControlPanel, Sidebar 等主容器）
  /// 从 ColorScheme.surface 读取
  static Color cardPrimary(BuildContext context) =>
      _colorScheme(context).surface;

  /// 二级卡片背景（嵌套在一级卡片内的组件）
  /// 从 ColorScheme.surfaceContainerHighest 读取
  static Color cardSecondary(BuildContext context) =>
      _colorScheme(context).surfaceContainerHighest;

  /// 三级高亮（滑块、选中状态、高亮元素）
  /// 从 ColorScheme.surfaceContainerHigh 读取
  static Color cardHighlight(BuildContext context) =>
      _colorScheme(context).surfaceContainerHigh;

  /// 反色主色（用于深色背景上的白色文字）
  /// 从 ColorScheme.onPrimary 读取
  static Color inversePrimary(BuildContext context) =>
      _colorScheme(context).inversePrimary;

  // ========== 玻璃拟态 Token (Glass) ==========

  /// 玻璃背景色（始终用白色）
  static const Color glassBg = Color(0xFFFFFFFF);

  /// 玻璃边框色（始终用白色）
  static const Color glassBorder = Color(0xFFFFFFFF);

  /// 玻璃背景透明度
  static double glassBgOpacity(BuildContext context) =>
      isDark(context) ? 0.1 : 0.7;

  /// 玻璃边框透明度
  static const double glassBorderOpacity = 0.2;

  /// 根据语义获取颜色
  static Color semantic(BuildContext context, String type) {
    switch (type) {
      case 'success':
        return success(context);
      case 'warning':
        return warning(context);
      case 'error':
        return error(context);
      case 'info':
        return info(context);
      default:
        return textPrimary(context);
    }
  }
}

// ========== 间距令牌 (Spacing Tokens) ==========

/// 间距、圆角等尺寸令牌
/// 基于 8px Grid 系统
class AppSpacing {
  AppSpacing._();

  // 间距（8px 的倍数）
  static const double xs = 4.0; // 0.5x
  static const double sm = 8.0; // 1x
  static const double md = 12.0; // 1.5x
  static const double lg = 16.0; // 2x
  static const double xl = 24.0; // 3x
  static const double xxl = 32.0; // 4x

  // 圆角
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
}

// ========== 阴影令牌 (Shadow Tokens) ==========

/// 阴影配置
class AppShadows {
  AppShadows._();

  /// 卡片阴影
  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  /// 轻量阴影
  static List<BoxShadow> light = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
}
