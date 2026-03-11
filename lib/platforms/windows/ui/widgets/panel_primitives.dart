import 'package:flutter/material.dart';
import 'package:sw_game_helper/style/app_tokens.dart';

/// 右侧面板通用样式工具。
///
/// 作用：
/// 1. 统一按钮规格；
/// 2. 统一分组卡片外观；
/// 3. 避免控制页、设置页、任务页各自定义导致视觉不一致。
class PanelPrimitives {
  PanelPrimitives._();

  /// 按钮内部状态动画时长：设为 0，避免与主题动画叠加导致闪变。
  static const Duration _buttonMotionDuration = Duration.zero;

  /// 按钮基础样式：统一高度、圆角、字号。
  static ButtonStyle _buttonBaseStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(40),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ).copyWith(
      animationDuration: _buttonMotionDuration,
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    );
  }

  /// 主按钮样式（用于“应用并保存”“开始任务”等主操作）。
  static ButtonStyle primaryButtonStyle(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _buttonBaseStyle(context).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.surfaceContainerHighest;
        }
        return scheme.primary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurfaceVariant;
        }
        return scheme.onPrimary;
      }),
    );
  }

  /// 次按钮样式（用于“恢复默认”等次级操作）。
  static ButtonStyle secondaryButtonStyle(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _buttonBaseStyle(context).copyWith(
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.surfaceContainerHighest.withValues(alpha: 0.72);
        }
        return scheme.surfaceContainerHigh;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurfaceVariant;
        }
        return scheme.onSurface;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        final color = states.contains(WidgetState.disabled)
            ? scheme.outlineVariant
            : scheme.outline;
        return BorderSide(color: color, width: 1);
      }),
    );
  }

  /// 危险按钮样式（用于“断开设备”等破坏性操作）。
  static ButtonStyle dangerButtonStyle(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _buttonBaseStyle(context).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.surfaceContainerHighest;
        }
        return scheme.errorContainer;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurfaceVariant;
        }
        return scheme.onErrorContainer;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        final color = states.contains(WidgetState.disabled)
            ? scheme.outlineVariant
            : scheme.error.withValues(alpha: 0.35);
        return BorderSide(color: color, width: 1);
      }),
    );
  }

  /// 紧凑主按钮样式：用于列表头等空间紧张位置。
  static ButtonStyle compactPrimaryButtonStyle(BuildContext context) {
    return primaryButtonStyle(context).copyWith(
      minimumSize: const WidgetStatePropertyAll(Size(108, 34)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// 紧凑次按钮样式：用于列表头等空间紧张位置。
  static ButtonStyle compactSecondaryButtonStyle(BuildContext context) {
    return secondaryButtonStyle(context).copyWith(
      minimumSize: const WidgetStatePropertyAll(Size(108, 34)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// 紧凑危险按钮样式：用于列表头等空间紧张位置。
  static ButtonStyle compactDangerButtonStyle(BuildContext context) {
    return dangerButtonStyle(context).copyWith(
      minimumSize: const WidgetStatePropertyAll(Size(108, 34)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// 兼容旧调用：默认等同主按钮样式。
  static ButtonStyle actionButtonStyle(BuildContext context) =>
      primaryButtonStyle(context);

  /// 统一分组容器装饰。
  static BoxDecoration sectionDecoration(BuildContext context) {
    return BoxDecoration(
      color: AppTokens.cardSecondary(context),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      border: Border.all(color: AppTokens.divider(context)),
    );
  }
}

/// 面板分组标题。
class PanelSectionTitle extends StatelessWidget {
  final String title;

  /// 构造函数。
  const PanelSectionTitle({super.key, required this.title});

  /// 构建分组标题。
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTokens.textPrimary(context),
      ),
    );
  }
}

/// 面板分组容器。
class PanelSectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// 构造函数。
  const PanelSectionCard({super.key, required this.child, this.padding});

  /// 构建分组容器。
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.sm),
      decoration: PanelPrimitives.sectionDecoration(context),
      child: child,
    );
  }
}

/// 面板说明文字。
class PanelHintText extends StatelessWidget {
  final String text;

  /// 构造函数。
  const PanelHintText({super.key, required this.text});

  /// 构建说明文字。
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 12, color: AppTokens.textSecondary(context)),
    );
  }
}
