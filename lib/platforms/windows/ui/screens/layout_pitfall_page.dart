import 'package:flutter/material.dart';

class LayoutPitfallPage extends StatefulWidget {
  const LayoutPitfallPage({super.key});

  @override
  State<LayoutPitfallPage> createState() => _LayoutPitfallPageState();
}

class _LayoutPitfallPageState extends State<LayoutPitfallPage> {
  int _selectedIndex = 0;
  final int _itemCount = 3;

  @override
  Widget build(BuildContext context) {
    // 假设设计稿要求：3个选项平分宽度
    // 坑点模拟：开发者试图手动计算宽度
    final screenWidth = MediaQuery.of(context).size.width;

    // ❌ 错误示范：手动计算每一个的高宽和位置
    // 这会导致浮点数误差，或者在不同DPI屏幕上出现1像素的裂缝/溢出
    final double manualItemWidth = (screenWidth - 32) / 3;

    return Scaffold(
      appBar: AppBar(title: const Text("布局深坑：手动计算 vs 响应式")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "❌ 错误示范 (手动计算):",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const Text(
              "使用 Stack + Positioned 手动算坐标。\n如果屏幕宽度是除不尽的 (比如 100 / 3)，就会出现缝隙或错位。",
            ),
            const SizedBox(height: 10),
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  // 选中指示器 (手动计算位置)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    left: _selectedIndex * manualItemWidth,
                    width: manualItemWidth,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                    ),
                  ),
                  // 按钮本体 (Row 排列)
                  Row(
                    children: List.generate(_itemCount, (index) {
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIndex = index),
                        child: Container(
                          width: manualItemWidth, // 强制指定宽度
                          alignment: Alignment.center,
                          child: Text("选项 $index"),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            const Text(
              "✅ 正确示范 (响应式):",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "使用 Flex/Expanded 自动分配。\n不需要任何数学计算，Flutter 引擎自动处理子像素渲染。",
            ),
            const SizedBox(height: 10),
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  // 选中指示器 (使用 LayoutBuilder + Align 配合)
                  // 这里用了一个小技巧：Row + Expanded 占位
                  Row(
                    children: [
                      // 动态占位：如果选中第 1 个，前面就是 1 份空，后面是 1 份空
                      // 这里的逻辑稍微复杂，为了演示 Expanded 的威力：
                      // 我们构造一个和前景一模一样的 Row，只有选中的那个 Expanded 是有颜色的
                      if (_selectedIndex > 0)
                        Expanded(flex: _selectedIndex, child: const SizedBox()),

                      Expanded(
                        flex: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green),
                          ),
                        ),
                      ),

                      if (_selectedIndex < _itemCount - 1)
                        Expanded(
                          flex: _itemCount - 1 - _selectedIndex,
                          child: const SizedBox(),
                        ),
                    ],
                  ),

                  // 内容层
                  Row(
                    children: List.generate(_itemCount, (index) {
                      return Expanded(
                        // ✅ 让每个孩子平分空间
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent, // 确保点击空白也能触发
                          onTap: () => setState(() => _selectedIndex = index),
                          child: Container(
                            alignment: Alignment.center,
                            child: Text("选项 $index"),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
