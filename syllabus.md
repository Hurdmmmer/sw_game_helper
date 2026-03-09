# Flutter 实战学习大纲 - SW Game Helper 项目

> **📌 Gemini 使用说明**（重要！）
>
> 这是教学大纲概览文件。在开始教学前，请：
>
> 1. **查看当前进度**：见下方"当前教学进度"部分
> 2. **阅读详细教程**：
>    - `C:\Users\Onyx\.gemini\antigravity\brain\a12877c0-b240-48db-ac7f-3772d5d8c156\detailed_teaching_syllabus.md` （详细教学内容）
>    - `C:\Users\Onyx\.gemini\antigravity\brain\a12877c0-b240-48db-ac7f-3772d5d8c156\ui_design_spec.md` （UI设计规范）
> 3. **遵守教学原则**：❌ 禁止直接写代码，✅ 只能引导用户自己动手
> 4. **标准教学流程**：讲解概念（为什么用）→ 对比方案 → 给出步骤 → 用户实践 → Review → 解答疑问

---

## 🎯 当前教学进度

**当前阶段**：第1阶段 - Flutter 基础 + UI 框架  
**当前周次**：Week 1  
**当前任务**：Day 4-5 - 设计规范系统（颜色、间距、透明度常量）  
**开始时间**：2026-01-27  
**最后更新**：2026-01-29

### 进度追踪

- [/] Week 1: Flutter 基础 + 布局框架 + 设计规范
  - [x] Day 1-2: Scaffold + Column + Row + 玻璃拟态基础
  - [x] Day 3-4: 自定义 TopNavBar + 组件化思维
  - [/] Day 4-5: 设计规范系统（AppColors + AppSpacing + AppOpacity）
  - [ ] Day 6-7: ControlPanel（使用设计规范）

---

> **📊 大纲优化说明**：
>
> - ✅ 调整知识点顺序：UI → Scrcpy → 任务系统 → 数据持久化 (2026-01-27)
> - ✅ 新增 Scrcpy 集成专题（第2阶段）(2026-01-27)
> - ✅ 提前 UI 设计阶段（第1阶段 Week 1-3）(2026-01-27)
> - ✅ 每周任务细化，便于 Gemini 教学执行 (2026-01-27)
> - ✅ **设计规范系统提前到 Day 4-5**，避免后期重构 (2026-01-29)

## 🎯 最终目标

**完成一个完整的跨平台游戏助手**，并具备独立开发 Flutter 应用的能力

### **项目交付物**

- ✅ Windows 端游戏助手（完整版）
- ✅ Android 端游戏助手（悬浮窗版）
- ✅ 精美的 UI 设计
- ✅ 完整的数据持久化
- ✅ 灵活的配置系统

### **能力验证标准**

- ✅ 能独立设计和实现完整应用
- ✅ 掌握跨平台开发（Windows + Android）
- ✅ 掌握数据库和配置管理
- ✅ 具备良好的 UI/UX 设计能力

---

## 📚 学习方式：项目驱动 + 能力递进

```
跟着做 → 部分自主 → 完全独立
  ↓          ↓           ↓
第1-2阶   第3-4阶段   第5-6阶段
```

---

## 🏗️ 第1阶段：Flutter 基础 + UI 框架（3周）

### **学习模式**: 🎓 跟着做（60% 指导）

### **阶段目标**

- 掌握 Flutter Widget 体系
- 实现精美的 Windows 端 UI
- 理解响应式布局
- 掌握主题系统和中文字体

---

#### Week 1: Flutter 基础 + 布局框架 + 设计规范

- [x] **Day 1-2**: Widget 概念 + Scaffold + Column + Row + 玻璃拟态基础
  - 为什么用 Scaffold？（vs Container）
  - Column + Row vs Stack 对比
  - Expanded 的必要性
  - 实现三区布局
  - BackdropFilter 实现玻璃拟态
  - ClipRRect 的作用
  - 对比度与视觉效果

- [x] **Day 3-4**: 自定义 TopNavBar + 组件化思维
  - 为什么不用 AppBar？
  - StatelessWidget vs StatefulWidget
  - 创建可复用组件
  - 实现导航栏玻璃拟态
  - 组件文件结构

- [/] **Day 4-5**: 设计规范系统 ⭐ 新增
  - 为什么需要常量管理？（vs 硬编码）
  - 创建 AppColors（颜色常量）
  - 创建 AppSpacing（间距常量，8px Grid）
  - 创建 AppOpacity（透明度常量）
  - 重构现有代码使用常量
  - 建立设计规范意识

- [ ] **Day 6-7**: ControlPanel 实现
  - TextField vs TextFormField
  - DropdownButton 设备选择
  - ChoiceChip 任务选择
  - 使用设计规范常量

#### Week 2: 主题系统 + 控制面板

- [ ] **Day 8-10**: ThemeData + Google Fonts + 中文字体
  - Material 3 主题配置
  - Noto Sans SC（中文）+ Plus Jakarta Sans（英文）混合使用
  - 明暗主题切换
  - 整合设计规范常量到 ThemeData

- [ ] **Day 11-13**: ControlPanel 完整实现
  - TextField vs TextFormField（为什么用 TextField）
  - DropdownButton 设备选择
  - ChoiceChip vs TabBar vs SegmentedButton 对比
  - TextEditingController 管理
  - dispose() 资源释放

- [ ] **Day 14**: Material 3 组件深入
  - ElevatedButton vs OutlinedButton
  - SnackBar 错误提示
  - CircularProgressIndicator 加载状态

#### Week 3: 日志区域 + 阶段验收

- [ ] **Day 15-17**: ListView.builder 实现日志
  - ListView.builder vs Column（性能对比）
  - 为什么不用 SingleChildScrollView？
  - ScrollController 自动滚动
  - JetBrains Mono 等宽字体
  - 日志语法高亮（INFO/SUCCESS/ERROR）

- [ ] **Day 18-19**: 动画优化
  - AnimatedContainer 平滑过渡
  - Hero 动画
  - 微动画提升体验

- [ ] **Day 20-21**: 阶段1验收
  - [ ] 完整的三区布局（导航栏+游戏区+控制面板+日志）
  - [ ] Glassmorphism 效果正常
  - [ ] 设备选择、WiFi连接、任务选择正常
  - [ ] 中文字体显示正常
  - [ ] 日志区域可滚动
  - [ ] 代码结构清晰（组件化）
  - [ ] 无编译错误和警告

---

## � 第2阶段：Scrcpy 集成（4周）⭐ 核心难点

### **学习模式**: 🎓 跟着做（50% 指导）

### **阶段目标**

- 掌握 Dart Process 调用外部程序
- 学习 FFI 调用 Win32 API
- 实现 Scrcpy 窗口嵌入
- 掌握窗口控制和输入模拟

---

#### Week 4: Process + ADB 基础

- [ ] **Day 22-24**: Dart Process 调用 ADB
  - Process.run vs Process.start 对比
  - 为什么用 Process.run？（简单同步）
  - 解析 `adb devices` 输出
  - 实现设备检测服务（ADBService）
  - Timer 自动刷新设备列表

- [ ] **Day 25-27**: 启动 Scrcpy 进程
  - Process.start 异步启动
  - stdout/stderr 输出捕获
  - 进程生命周期管理
  - 错误处理（Scrcpy 未安装、启动失败）

- [ ] **Day 28**: 测试和优化
  - USB 设备检测测试
  - WiFi 连接测试
  - 日志输出到 UI

#### Week 5-6: Win32 API + 窗口嵌入

- [ ] **Day 29-32**: FFI + FindWindow
  - 为什么需要 FFI？（调用 C API）
  - Dart FFI 基础
  - 调用 Win32 API：FindWindow
  - 获取 Scrcpy 窗口句柄（HWND）

- [ ] **Day 33-36**: SetParent 嵌入窗口
  - SetParent API 原理
  - 将 Scrcpy 窗口嵌入到 Flutter
  - 窗口父子关系管理

- [ ] **Day 37-40**: MoveWindow 调整位置
  - MoveWindow API
  - 响应式调整窗口大小
  - 窗口缩放时自动适配

#### Week 7: PostMessage 窗口控制

- [ ] **Day 43-45**: 模拟点击事件
  - PostMessage vs SendMessage
  - WM_LBUTTONDOWN/UP 消息
  - 坐标转换（Flutter → Scrcpy）

- [ ] **Day 46-49**: 完善和测试
  - 点击测试
  - 长按、滑动模拟
  - 性能优化

#### 阶段2验收标准

- [ ] Scrcpy 成功启动
- [ ] Scrcpy 窗口嵌入到 Flutter
- [ ] 窗口大小自适应
- [ ] 能够点击游戏画面
- [ ] 设备切换时重新启动 Scrcpy

---

## 🖼️ 第3阶段：图像识别 + 钓鱼任务（5周）

### **学习模式**: 🛠️ 部分自主（40% 指导）

### **阶段目标**

- 掌握 opencv_dart 使用
- 实现模板匹配
- 学习状态机设计模式
- 完成第一个完整任务

---

#### Week 8-9: OpenCV 基础

- [ ] **Day 50-54**: opencv_dart 入门
  - 安装和配置
  - 截图（win32 API）
  - 图像加载和保存
  - 图像格式转换（BGR ↔ RGB）

- [ ] **Day 55-59**: 模板匹配
  - matchTemplate 原理
  - 阈值设置
  - 多个结果处理
  - 性能优化（缩小搜索区域）

- [ ] **Day 60-63**: 调试工具
  - 可视化调试（显示匹配区域）
  - 保存调试图片
  - 实时预览

#### Week 10-11: 钓鱼任务实现

- [ ] **Day 64-68**: 状态机设计
  - 为什么用状态机？
  - 状态定义（空闲、抛竿、等待、收竿）
  - 状态转换逻辑
  - 异步状态机（async/await）

- [ ] **Day 69-73**: 钓鱼任务完整实现
  - 识别"抛竿"按钮
  - 识别"收竿"提示
  - 点击模拟
  - 异常处理（识别失败、超时）

- [ ] **Day 74-77**: 测试和优化
  - 准确率测试
  - 性能优化
  - 稳定性测试

#### 阶段3验收标准

- [ ] 能够准确识别游戏元素
- [ ] 钓鱼任务全自动运行
- [ ] 日志记录完整（识别、点击、结果）
- [ ] 异常自动恢复

---

## 💾 第4阶段：数据持久化（3周）

### **学习模式**: 🛠️ 部分自主（30% 指导）

### **阶段目标**

- 掌握 SharedPreferences
- 掌握 SQLite 数据库
- 实现配置管理
- 记录任务历史

---

#### Week 13: SharedPreferences 配置

- [ ] **Day 78-82**: 配置管理
  - SharedPreferences vs 文件 vs 数据库
  - 为什么用 SharedPreferences？（简单配置）
  - 保存用户设置（主题、语言）
  - JSON 序列化任务配置

- [ ] **Day 83-84**: 配置 UI
  - 设置页面实现
  - 表单验证

#### Week 14-15: SQLite 数据库

- [ ] **Day 85-91**: sqflite 使用
  - 数据库设计（任务记录表、统计表）
  - CRUD 操作
  - 数据迁移

- [ ] **Day 92-98**: 任务历史记录
  - 记录每次任务（开始时间、结束时间、结果）
  - 统计页面（今日/本周/总计）
  - 图表展示（可选，使用 fl_chart）

#### 阶段4验收标准

- [ ] 配置正确保存和读取
- [ ] 任务记录写入数据库
- [ ] 统计数据准确

---

## ✅ 第5阶段：完整任务实现（5周）

### **学习模式**: 🚀 完全独立（20% 指导）

### **阶段目标**

- 独立实现竞技场任务
- 独立实现试炼任务
- 完善错误处理和日志

---

#### Week 16-18: 竞技场任务

- [ ] **Day 99-119**: 竞技场自动化
  - 任务分析（流程拆解）
  - 状态机设计
  - 模板准备
  - 实现和测试

#### Week 19-20: 试炼任务

- [ ] **Day 120-140**: 试炼自动化
  - 任务分析
  - 实现
  - 稳定性测试

#### 阶段5验收标准

- [ ] 三个任务都能稳定运行
- [ ] 错误处理完善
- [ ] 性能优化（CPU、内存）

---

## 📱 第6阶段：Android 端开发（5周）

### **学习模式**: 🚀 完全独立（10% 指导）

### **阶段目标**

- 移植到 Android 平台
- 实现悬浮窗
- 掌握无障碍服务

---

#### Week 21-22: Android 基础

- [ ] **Day 141-154**: Android 适配
  - 权限申请（悬浮窗、无障碍）
  - 平台差异处理
  - UI 适配（手机屏幕）

#### Week 23-24: 悬浮窗 + 无障碍服务

- [ ] **Day 155-168**: 核心功能实现
  - 悬浮窗实现
  - 无障碍服务（自动点击）
  - 性能优化（电量优化）

#### Week 25: 打包发布

- [ ] **Day 169-175**: 发布准备
  - 图标、启动页
  - 签名和打包
  - 测试和发布

#### 阶段6验收标准

- [ ] Android 版正常运行
- [ ] 悬浮窗稳定
- [ ] 电量消耗可接受

---

## 📊 学习进度追踪

**当前进度**：第1阶段 Week 1 Day 1  
**完成天数**：0 / 175 天  
**完成百分比**：0%  

---

## 🎓 教学质量要求

每次教学都必须包含：

1. **为什么用这个组件**（设计决策）
2. **有哪些替代方案**（至少2个）
3. **对比表格**（优缺点、推荐度）
4. **完整代码示例**（带注释）
5. **验证标准**（如何判断成功）
6. **常见问题**（Q&A）

---

## 📝 重要备注

- **中文字体**：必须使用 Noto Sans SC，不能用 Plus Jakarta Sans
- **UI 风格**：Glassmorphism + Material 3
- **主题色**：紫色 #7C3AED
- **窗口尺寸**：最小 1024x768，推荐 1280x800
- **教学原则**：教育优先，禁止直接写代码
