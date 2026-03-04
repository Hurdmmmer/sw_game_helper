import 'package:flutter/material.dart';

class LayoutLearningPage extends StatelessWidget {
  const LayoutLearningPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. MediaQuery: 获取屏幕总宽
    // 就像站在高处看全景
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text("布局实验室")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("实验 1: Expanded (霸道总裁)"),
              const Text("强制占满所有剩余空间。"),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.arrow_back),
                  // Expanded 强制拉伸中间区域
                  Expanded(
                    child: Container(
                      color: Colors.blue[100],
                      padding: const EdgeInsets.all(8),
                      child: const Text(
                        "我被 Expanded 强制拉伸了，不管字少不少，我都得占满。",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward),
                ],
              ),

              const SizedBox(height: 32),

              _buildSectionTitle("实验 2: Flexible (温和派)"),
              const Text("只占自己需要的大小，但不超过剩余空间。"),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.arrow_back),
                  // Flexible 允许孩子比剩余空间小 (fit: FlexFit.loose)
                  Flexible(
                    child: Container(
                      color: Colors.green[100],
                      padding: const EdgeInsets.all(8),
                      child: const Text(
                        "我很短哈哈哈哈哈哈拉萨的交流发电机了房间", // 试着把这里改成很长的字看看效果
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward),
                  const SizedBox(width: 8),
                  const Text("<-- 看到空白了吗？"),
                ],
              ),

              const SizedBox(height: 32),

              _buildSectionTitle("实验 3: MediaQuery (上帝视角)"),
              Text("当前屏幕总宽度: ${screenWidth.toStringAsFixed(1)}"),
              Container(
                width: double.infinity,
                height: 50,
                margin: const EdgeInsets.only(top: 8),
                // 根据屏幕宽度改变颜色
                color: screenWidth > 800
                    ? Colors.purple[100]
                    : Colors.orange[100],
                alignment: Alignment.center,
                child: Text(
                  screenWidth > 800
                      ? "屏幕很宽 (>800) -> 紫色"
                      : "屏幕较窄 (<=800) -> 橙色",
                ),
              ),

              const SizedBox(height: 32),

              _buildSectionTitle("实验 4: LayoutBuilder (局部视角)"),
              const Text("不管屏幕多大，我只关心父容器给我多少位置。"),
              const SizedBox(height: 8),
              Container(
                width: 300, // 父容器强制限制为 300
                height: 100,
                color: Colors.grey[300],
                padding: const EdgeInsets.all(8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Center(
                      child: Text(
                        "LayoutBuilder 说:\n虽然屏幕宽 $screenWidth\n但我最大只能宽 ${constraints.maxWidth}",
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
