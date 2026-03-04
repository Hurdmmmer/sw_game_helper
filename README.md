# SW Game Helper - Flutter 学习项目

## 📚 项目简介

这是一个**跨平台游戏自动化助手**项目，同时也是我的 **Flutter 实战学习项目**。

- **注入项目中全局规则和项目规则**
- **平台**: Windows (优先) + Android
- **技术栈**: Flutter + Dart
- **学习目标**: 通过完整项目开发，掌握 Flutter 并具备独立开发能力
- **学习时长**: 预计 5-6 个月

---

## 🎯 项目最终目标

### **Windows 端**
- ✅ Scrcpy 窗口控制
- ✅ 图像识别（OpenCV模板匹配）
- ✅ 自动化任务系统（钓鱼、竞技场、试炼）
- ✅ 模板管理系统
- ✅ SQLite 数据库统计
- ✅ 精美的 UI 界面
- ✅ 完整的配置系统

### **Android 端**
- ✅ 悬浮窗 UI（小圆点 + 底部抽屉）
- ✅ 无障碍服务自动化
- ✅ 移动端 UI 适配
- ✅ 跨平台代码复用

---

## 📖 学习文档导航

### 🎓 学习相关
- **[学习大纲](./syllabus.md)** - 完整的6阶段学习路线（126天）
- **[任务清单](./task.md)** - 详细的每日任务和进度追踪
- **[学习日志](./learning_log.md)** - 每天的学习记录和总结
- **[教学原则](./teaching_principles.md)** - 我的学习方式和原则

### 🏗️ 项目设计
- **[总设计文档](./master_design.md)** - 完整的技术方案和架构
- **[项目结构说明](./project_structure.md)** - Flutter 项目结构详解（对比 Java）

---

## 🚀 快速开始

### 环境要求
- Flutter 3.38.5+
- Windows 11
- VS Code（推荐）

### 运行项目
```bash
# 开发模式（支持热重载）
flutter run -d windows

# 或使用 VS Code
按 F5 启动调试
```

### 编译发布版本
```bash
flutter build windows
# 输出：build/windows/x64/runner/Release/
```

---

## 📅 学习进度

### 当前状态
- **阶段**: 第1阶段 - Flutter 基础 + Windows 工具
- **进度**: Week 1 Day 1
- **完成度**: 5% (1/126天)
- **当前任务**: 修改应用标题练习

### 学习路线图
```
第1阶段 (3周)   → Windows 截图工具 + Flutter 基础
第2阶段 (3周)   → UI 设计 + 配置系统 ✨
第3阶段 (4周)   → 自动化 + 数据库 💾
第4阶段 (4周)   → 图像识别 + 高级 UI ✨
第5阶段 (5周)   → Android 端开发 📱
第6阶段 (4周)   → 完整应用 + 发布 🏆

总计：5-6 个月
```

详细计划请查看 **[学习大纲](./syllabus.md)**

---

## 🎯 核心技能树

### Flutter 核心
- [ ] Widget 系统和布局
- [ ] 状态管理（setState, Provider, Riverpod）
- [ ] 异步编程（Future, Stream）
- [ ] 导航和路由
- [ ] 动画系统

### 平台特性
- [ ] Windows: FFI, Win32 API
- [ ] Android: 无障碍服务, 悬浮窗
- [ ] Platform Channel 通信

### UI/UX ✨
- [ ] Material Design
- [ ] 主题系统
- [ ] 自定义绘制
- [ ] 响应式布局

### 数据管理 💾
- [ ] SQLite 数据库
- [ ] SharedPreferences
- [ ] JSON 序列化
- [ ] 文件操作

### 配置系统 ⚙️
- [ ] 常量管理
- [ ] 配置文件设计
- [ ] 多环境配置

### 图像处理
- [ ] OpenCV 基础
- [ ] 模板匹配
- [ ] 图像采集

---

## 📝 开发规范

### 代码风格
- 遵循 Dart 官方规范
- 使用有意义的变量名
- **所有字符串使用常量管理**（不硬编码）
- 所有代码必须有注释

### Git 提交规范
```
feat: 添加新功能
fix: 修复问题
docs: 更新文档
refactor: 重构代码
test: 添加测试
```

---

## 📊 能力验证点

每个阶段都有独立任务来验证能力：

| 阶段 | 验证任务 | 目标 |
|------|---------|------|
| 第1阶段 | 截图框选功能 | 独立完成基础功能 |
| 第2阶段 | 设置页面 | 独立设计UI和配置 |
| 第3阶段 | 任务统计页面 | 数据库查询和展示 |
| 第4阶段 | 竞技场任务 | 完整的自动化逻辑 |
| 第5阶段 | Android钓鱼任务 | 跨平台开发能力 |
| 第6阶段 | 完整应用 | 独立开发能力 ✅ |

---

## 🔗 参考资料

- [Flutter 中文网](https://flutter.cn)
- [Dart 语言教程](https://dart.cn)
- [Win32 包文档](https://pub.dev/packages/win32)
- [OpenCV Dart](https://pub.dev/packages/opencv_dart)
- [Sqflite 文档](https://pub.dev/packages/sqflite)

---

## 📞 项目信息

**项目路径**: `d:\FlutterProject\sw_game_helper`  
**开始时间**: 2026-01-19  
**预计完成**: 2026年6-7月  
**当前状态**: 🚀 学习中

---

**最后更新**: 2026-01-19 20:48
