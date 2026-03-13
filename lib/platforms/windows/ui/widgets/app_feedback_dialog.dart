import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sw_game_helper/platforms/windows/ui/widgets/panel_primitives.dart';
import 'package:sw_game_helper/style/app_tokens.dart';

/// 全局反馈弹窗语义类型。
enum AppFeedbackType {
  /// 成功反馈。
  success,

  /// 警告反馈。
  warning,

  /// 错误反馈。
  error,

  /// 信息反馈。
  info,
}

/// 全局反馈弹窗。
///
/// 用于替代分散的 SnackBar，统一桌面端提示层的视觉与交互。
class AppFeedbackDialog extends StatelessWidget {
  /// 构造函数。
  const AppFeedbackDialog({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.confirmText = '知道了',
  });

  /// 反馈语义类型。
  final AppFeedbackType type;

  /// 标题。
  final String title;

  /// 说明文案。
  final String message;

  /// 确认按钮文案。
  final String confirmText;

  /// 显示反馈弹窗。
  static Future<void> show(
    BuildContext context, {
    required AppFeedbackType type,
    required String title,
    required String message,
    String confirmText = '知道了',
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AppFeedbackDialog(
          type: type,
          title: title,
          message: message,
          confirmText: confirmText,
        );
      },
    );
  }

  /// 显示错误反馈。
  static Future<void> showError(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = '知道了',
  }) {
    return show(
      context,
      type: AppFeedbackType.error,
      title: title,
      message: message,
      confirmText: confirmText,
    );
  }

  /// 显示成功反馈。
  static Future<void> showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = '知道了',
  }) {
    return show(
      context,
      type: AppFeedbackType.success,
      title: title,
      message: message,
      confirmText: confirmText,
    );
  }

  /// 根据语义类型返回对应颜色。
  Color _semanticColor(BuildContext context) {
    return switch (type) {
      AppFeedbackType.success => AppTokens.success(context),
      AppFeedbackType.warning => AppTokens.warning(context),
      AppFeedbackType.error => AppTokens.error(context),
      AppFeedbackType.info => AppTokens.info(context),
    };
  }

  /// 根据语义类型返回对应图标。
  IconData _semanticIcon() {
    return switch (type) {
      AppFeedbackType.success => LucideIcons.badgeCheck,
      AppFeedbackType.warning => LucideIcons.alertTriangle,
      AppFeedbackType.error => LucideIcons.wifiOff,
      AppFeedbackType.info => LucideIcons.info,
    };
  }

  /// 构建语义图标容器。
  Widget _buildSemanticBadge(BuildContext context) {
    final semanticColor = _semanticColor(context);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: semanticColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: semanticColor.withValues(alpha: 0.18)),
      ),
      child: Icon(_semanticIcon(), size: 20, color: semanticColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSemanticBadge(context),
              SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.textPrimary(context),
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppTokens.textSecondary(context),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    style: PanelPrimitives.compactPrimaryButtonStyle(context),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.check, size: 14),
                    label: Text(confirmText),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
