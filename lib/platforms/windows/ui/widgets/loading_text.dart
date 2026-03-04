import 'dart:math' as math;
import 'package:flutter/material.dart';

class LoadingBounceDots extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const LoadingBounceDots({super.key, this.text = '加载中', this.style});

  @override
  State<LoadingBounceDots> createState() => _LoadingBounceDotsState();
}

class _LoadingBounceDotsState extends State<LoadingBounceDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? const TextStyle(fontSize: 14);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.text, style: style),
        const SizedBox(width: 8),
        ...List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final phase = (_controller.value * 2 * math.pi) + index * 0.6;
              final dx = 4 * math.sin(phase); // 左右位移 4px

              return Transform.translate(offset: Offset(dx, 0), child: child);
            },
            child: Text('.', style: style),
          );
        }),
      ],
    );
  }
}
