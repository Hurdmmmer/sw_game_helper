# Flutter 学习日志

## 📅 2026-01-23 (Day 1 继续 - Widget 布局学习)

### ✅ 已完成

1. **Widget 核心概念理解**
   - ✅ Widget 是"界面的描述"，不是界面本身
   - ✅ Widget 组合模式（Widget 套 Widget）
   - ✅ Scaffold 页面框架的使用

2. **布局系统学习**
   - ✅ Column（竖向布局）和 Row（横向布局）
   - ✅ Expanded 的作用：占满父容器剩余空间
   - ✅ flex 参数：控制空间分配比例
   - ✅ Container 容器的基本使用

3. **实践：主界面框架搭建**
   - ✅ 实现了游戏区域和日志区域的垂直布局（3:2 比例）
   - ✅ 实现了游戏画面和控制面板的横向布局（2:1 比例）
   - ✅ 理解了布局的嵌套关系

4. **UI 设计决策**
   - ✅ 选择使用原生 Windows 标题栏（符合桌面应用设计规范）
   - ✅ 理解了 Material AppBar 不适合 Windows 桌面应用

### 🎯 当前任务

- [x] 理解 Widget 组合模式
- [x] 学习 Scaffold、Column、Row、Expanded
- [x] 搭建主界面基础框架
- [x] 运行程序查看效果
- [x] 学习 StatelessWidget vs StatefulWidget
- [x] 实战：添加计数器按钮（理解 setState）

### 💡 今日学到的核心知识点

#### 1. Widget 的本质

```dart
// Widget 是"界面的描述"
Widget build(BuildContext context) {
  return Container(  // 返回一个 Widget
    child: Text("Hello"),  // 包含另一个 Widget
  );
}
```

#### 2. Expanded 的作用

| 父容器 | Expanded 的行为 |
|--------|----------------|
| Column（竖向） | 占满剩余**高度** |
| Row（横向） | 占满剩余**宽度** |

```dart
Column(
  children: [
    Expanded(flex: 3, child: ...),  // 占 3/5 高度
    Expanded(flex: 2, child: ...),  // 占 2/5 高度
  ],
);
```

#### 3. 布局嵌套

```dart
Column(              // 竖向：上下排列
  children: [
    Expanded(
      child: Row(    // 横向：左右排列
        children: [
          Expanded(child: 游戏区域),   // 左
          Expanded(child: 控制面板),   // 右
        ],
      ),
    ),
    Expanded(child: 日志区域),  // 底部
  ],
);
```

### 📚 重要概念理解

#### Container

- Flutter 的"万能容器"
- 可以设置：颜色、大小、边距、圆角等
- 类似 HTML 的 `<div>`

#### Scaffold

- Flutter 的"页面框架"
- 提供：appBar（标题栏）、body（主体）、bottomNavigationBar（底部导航）等
- 类似网页的整体布局结构

### 🎓 设计原则学习

#### Windows 桌面应用 UI 设计

- ✅ 使用原生标题栏（符合 Windows 设计语言）
- ✅ 功能按钮集成在内容区域
- 🔮 未来可升级为自定义标题栏（支持拖拽、悬停菜单）

### ❓ 遇到的问题

- 无

### 📝 反思和总结

- 理解了 Flutter 的核心思想：**用 Widget 组合 Widget**
- 掌握了基本布局工具：Column、Row、Expanded
- 学会了思考 UI 设计的合理性（AppBar vs 原生标题栏）
- **边讲边练**的学习方式很有效，理论+实践结合

---

## 📋 下一步计划

### 今天剩余任务

1. 运行程序，查看布局效果
2. 学习 StatelessWidget vs StatefulWidget 的区别
3. 完成 Day 1-2 的全部内容

### 明天/下次学习（Day 3-4）

1. 学习更多布局组件（Padding, Margin, Alignment）
2. 优化主界面样式（颜色、间距、圆角）
3. 开始实现控制面板的具体内容

---

**今日学习时长**: 约 6 小时  
**累计学习时长**: 8 小时  
**学习进度**: Day 1-2 完成 / 126天（约 2%）  
**最后更新**: 2026-01-23 15:30

---

## 📋 下一步计划

### 明天/下次学习（Day 1-2 继续）

1. 完成"修改应用标题"练习
2. 学习 Widget 核心概念
3. 理解 StatelessWidget vs StatefulWidget
4. 完成 Day 1-2 的全部内容

### 本周目标（Week 1）

- 完成 Flutter 基础学习
- 搭建截图工具的基本 UI 框架

---

## 🎯 长期目标追踪

### 第1阶段目标（3周）

完成 Windows 截图工具，掌握 Flutter 基础和 Win32 API

### 第2阶段目标（3周）

重构 UI，实现配置系统和常量管理

### 第3阶段目标（4周）

实现自动化功能，掌握数据库和任务调度

### 第4阶段目标（4周）

完成图像识别，掌握高级 UI 组件

### 第5阶段目标（5周）

开发 Android 端，掌握跨平台开发

### 第6阶段目标（4周）

完整应用发布，具备独立开发能力 ✅

---

**今日学习时长**: 约2小时（主要是规划和文档）  
**累计学习时长**: 2小时  
**学习进度**: Day 1 / 126天（约1%）  
**最后更新**: 2026-01-19 20:48
