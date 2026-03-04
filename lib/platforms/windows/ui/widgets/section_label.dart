import 'package:flutter/material.dart';
import 'package:sw_game_helper/style/app_tokens.dart';

/// 小节标签组件
///
/// 用于面板内的小节标题，提供统一的样式规范。
///
/// 使用示例:
/// ```dart
/// SectionLabel(
///   text: '设备列表',
///   trailing: StyledIconButton(icon: Icons.refresh, onPressed: _refresh),
/// )
/// ```
class SectionLabel extends StatefulWidget {
  /// 标签文本
  final String text;

  ///  trailing 组件，通常用于添加操作按钮
  final Widget? trailing;

  const SectionLabel({super.key, required this.text, this.trailing});

  @override
  State<SectionLabel> createState() => _SectionLabelState();
}

class _SectionLabelState extends State<SectionLabel> {
  @override
  Widget build(BuildContext context) {
    return Row(
      // 设置 Row 内组件的对齐方式为两端对齐
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          widget.text,
          style: TextStyle(
            color: AppTokens.textSecondary(context),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            // 字母间距 0.5 个像素
            letterSpacing: 0.5,
          ),
        ),
        // 如果 trailing 为空，则添加一个占位符，否则显示 trailing 组件
        widget.trailing ?? const SizedBox.shrink(),
      ],
    );
  }
}
