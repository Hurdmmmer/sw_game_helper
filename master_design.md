# SW Game Helper - 项目总设计文档

## 📋 项目概述

**项目名称**: SW Game Helper (游戏自动化助手)  
**技术栈**: Flutter + Dart (跨平台)  
**支持平台**: Windows (优先) + Android (未来)  
**原项目**: Python版本 (`C:\Users\Onyx\OneDrive\Documents\PythonProject\GameScript`)  
**新项目路径**: `d:\FlutterProject\sw_game_helper`

---

## 🎯 核心目标

1. ✅ **完全绕过游戏反检测机制**
2. ✅ **跨平台支持** (Windows + Android 双平台)
3. ✅ **可视化UI界面** (两套完全不同的UI)
4. ✅ **动态截图模板管理**
5. ✅ **自动化游戏任务** (钓鱼、竞技场、试炼等)

---

## 📊 开发优先级

### **阶段1: Windows端开发** (当前优先)

- 完整的桌面应用
- 基于Scrcpy投屏方案
- 详细的控制界面
- 模板管理系统

### **阶段2: Android端开发** (未来实施)

- 悬浮窗模式
- 底部弹出面板
- 无障碍服务集成

---

## 🎨 UI设计方案

### **Windows端UI** (桌面应用模式 - Windows 11 Fluent)

> [!NOTE]
> 设计遵循 **UI UX Pro Max** 规范，统一采用 **Windows 11 Fluent Design (Mica + Acrylic + Rounded)**。右侧控制区升级为“会话配置 + 任务中心 + 队列控制”三段式结构，支撑后续钓鱼/日常等辅助任务扩展。

#### 主界面布局 (Custom TitleBar + Left Stage + Right Control Hub)

```
┌─── Window Title Bar (系统标题栏 + 导航) ───────────────────────────────────────┐
│ [Logo] SW Game Helper        首页   设置   关于                      [ - □ × ] │
└──────────────────────────────────────────────────────────────────────────────┘
┌───────────────────────────────────────────────────────┬────────────────────────┐
│                                                       │                        │
│  ┌─ Device Stage (Flex: 5) ────────────────────────┐ │ ┌─ Control Hub (Flex:2)┐
│  │  状态: 未连接  FPS: --  分辨率: --               │ │ │ 1) 会话配置           │
│  │ ┌──────────────────────────────────────────────┐ │ │ │ [USB|WiFi]           │
│  │ │              Scrcpy 实时画面                │ │ │ │ [设备下拉] [刷新]     │
│  │ └──────────────────────────────────────────────┘ │ │ │ [渲染链路] [解码模式] │
│  └──────────────────────────────────────────────────┘ │ │ [熄屏开关]             │
│  ┌─ Log Console (Flex:1) ──────────────────────────┐ │ │ [连接设备] [断开设备]  │
│  │ [10:23:45][INFO] session idle                   │ │ ├────────────────────────┤
│  │ [10:23:50][WARN] 未选择任务                     │ │ │ 2) 任务中心            │
│  └──────────────────────────────────────────────────┘ │ │ [日常][钓鱼][副本][自定义]│
│                                                       │ │ [任务卡片列表]          │
│                                                       │ ├────────────────────────┤
│                                                       │ │ 3) 任务队列            │
│                                                       │ │ 1. 自动钓鱼  等待中    │
│                                                       │ │ 2. 每日收菜  等待中    │
│                                                       │ │ [开始] [暂停] [停止]   │
│                                                       │ └────────────────────────┘
└───────────────────────────────────────────────────────┴────────────────────────┘
```

#### 右侧控制中台详细设计 (Control Hub Details)

> [!IMPORTANT]
> 右侧区域不再使用占位 `TASK AREA`。统一替换为可执行的“任务中心 + 队列控制”。

##### A. 会话配置区 (Session Section)

```yaml
Session Section:
  Goal: 管理设备连接和渲染参数
  Layout: 固定在最上方，始终可见
  Controls:
    - Connection Mode Toggle (USB/WiFi)
    - Device Dropdown + Refresh Button
    - Render Pipeline Dropdown
    - Decoder Mode Dropdown
    - Turn Screen Off Switch
    - Connect / Disconnect Buttons
  Interaction Rule:
    - 连接成功后锁定关键参数(模式/设备/链路)
    - 断开后恢复参数编辑
```

##### B. 任务中心区 (Task Catalog Section)

```yaml
Task Catalog Section:
  Goal: 选择与配置自动化任务
  Tabs: ["日常", "钓鱼", "副本", "自定义"]
  Task Card Fields:
    - 任务名称
    - 前置条件 (例如: 已连接设备)
    - 预计时长
    - 风险等级
  Actions:
    - 加入队列
    - 立即开始
  Empty State:
    - "暂无任务，点击自定义创建"
```

##### C. 队列控制区 (Task Queue Section)

```yaml
Task Queue Section:
  Goal: 编排并执行任务序列
  List Item:
    - 序号
    - 任务名
    - 状态 (等待中 / 运行中 / 暂停 / 失败 / 完成)
  Global Actions:
    - 开始队列
    - 暂停队列
    - 停止队列
  Recovery:
    - 失败任务可单独重试
```

#### 设备连接区域规范 (Device Connection Area)

```yaml
Connection Mode Toggle:
  Widget: SegmentedButton / 自定义 PillToggle
  Options: ["USB", "WiFi"]
  Default: USB
  Width: 100%

USB Device Dropdown:
  Widget: StyledDropdown<AppDeviceInfo>
  Placeholder: "请选择设备"
  Data Source: adb devices 解析结果
  First Load: 自动刷新

Refresh Button:
  Widget: StyledIconButton
  Icon: LucideIcons.refreshCw (16~18px)
  Tooltip: "刷新设备列表"
  Loading: 图标旋转

WiFi Inputs:
  IP Field:
    Hint: "192.168.1.100"
    Validation: IPv4 格式
  Port Field:
    Default: "5555"
    Validation: 1-65535

Primary Action:
  Button: Filled Button
  Text: "连接设备"
  Icon: LucideIcons.link
  State: idle/loading/disabled

Secondary Action:
  Button: Outlined Button
  Text: "断开设备"
  Icon: LucideIcons.unlink
  Visibility: 仅已连接时启用
```

#### 日志区域优化 (Log Area Optimization)

> [!TIP]
> 日志为“运行反馈中枢”，建议保留在左下角，采用等宽字体 + 语义色高亮。

```yaml
Log Styling:
  Font: JetBrains Mono
  Font Size: 12~13px
  Line Height: 1.4
  Auto Scroll: true
  Max Lines: 1000

Log Levels:
  Timestamp: #64748B
  INFO: #94A3B8
  SUCCESS: #22C55E
  WARNING: #F59E0B
  ERROR: #EF4444
```

#### 交互流程设计 (User Flow)

1. **连接设备 (Session Start)**:
    - 在会话配置区选择连接方式和设备，点击“连接设备”建立会话。
2. **选择任务 (Task Selection)**:
    - 在任务中心区选择“日常/钓鱼”等任务，加入任务队列。
3. **执行与监控 (Execution + Monitoring)**:
    - 队列开始后，左侧画面显示实时执行过程，日志区持续输出状态。
4. **恢复与中断 (Recovery)**:
    - 支持暂停/停止；失败任务可单独重试，不影响其余队列。

#### 交互细节规范 (Interaction Details)

```yaml
Hover:
  Background Delta: +6% 亮度
  Cursor: pointer
  Transition: 120~180ms ease-out

Focus:
  Outline: 2px solid Primary
  Outline Offset: 2px
  Keyboard: Tab 顺序与视觉顺序一致

Motion:
  Toggle/Dropdown: 150~200ms
  Panel Expand: 180~220ms
  Rule: 优先 opacity/transform，避免 layout 抖动
```

#### 响应式设计 (Responsive Layout)

```yaml
Breakpoints:
  Compact: 1024px ~ 1279px
    Layout: Left:Right = 3:2
    Right Hub: 任务卡片折叠摘要
  Default: 1280px ~ 1919px
    Layout: Left:Right = 5:2
  Wide: 1920px+
    Layout: Left:Right = 6:2

Minimum Size:
  Width: 1024px
  Height: 768px
```

#### 设计风格 (Windows 11 Fluent)

- **Material**: 使用 `Mica` 作为窗口级背景，`Acrylic` 用于右侧控制面板。
- **Shape**: 全局圆角统一，容器 16px，控件 12px，按钮 10~12px。
- **Depth**: 少边框，轻阴影，层级依靠明度和透明度区分。
- **Color Strategy**: 单主色强调，仅用于选中状态和主按钮。
- **Typography**: 优先 Segoe UI / Inter，标题与正文拉开字重层级。

---

### **Design System (设计系统规范)**

> [!IMPORTANT]
> 基于 **UI UX Pro Max** 规范,定义完整的设计系统以确保 Windows 和 Android 端的视觉一致性和可维护性。

#### **1. 颜色系统 (Color Palette)**

```yaml
# 核心设计理念 (Windows 11 Fluent)
Design Philosophy:
  - Rounded Corners: 8px (Small), 12px (Medium)
  - Elevation: 阴影而非边框
  - Material: Mica (云母) / Acrylic (亚克力) 效果
  - Theme: System Sync (跟随系统设置)

# 1. Light Theme (Day Mode) - 极简、清爽
Light Mode:
  Background: "#F8FAFC"   # Slate 50 (接近纯白的灰)
  Surface: "#FFFFFF"      # White (纯白卡片)
  Primary: "#0891B2"      # Cyan 600 (保持品牌色)
  Text:
    Primary: "#0F172A"    # Slate 900 (深黑文本)
    Secondary: "#64748B"  # Slate 500
  Border: "#E2E8F0"       # Slate 200

# 2. Dark Theme (Night Mode) - 沉浸、护眼
Dark Mode:
  Background: "#0F172A"   # Slate 900 (深邃蓝黑)
  Surface: "#1E293B"      # Slate 800 (深色卡片)
  Primary: "#06B6D4"      # Cyan 500 (稍亮的主色)
  Text:
    Primary: "#F1F5F9"    # Slate 100 (亮白文本)
    Secondary: "#94A3B8"  # Slate 400
  Border: "#334155"       # Slate 700

# 功能色 (Semantic Colors) - 通用
Semantic:
  Success: "#10B981"      # Green 500
  Warning: "#F59E0B"      # Amber 500
  Error: "#EF4444"        # Red 500
  Info: "#3B82F6"         # Blue 500
```

**设计理由**:

- **Cyan + Indigo** 冷色调搭配,科技感强,适合游戏工具类应用
- **语义化颜色** 让任务状态一目了然 (绿色=成功, 橙色=警告, 红色=错误)
- **深色背景** 护眼,适合长时间挂机使用

---

#### **2. Typography (字体系统)**

```yaml
# 标题字体 - Google Font "Outfit"
Heading:
  Font: "Outfit"  # 现代感强,几何无衬线
  H1: 32px / 700 (Bold)        # 页面主标题
  H2: 24px / 600 (SemiBold)    # 模块标题
  H3: 18px / 600 (SemiBold)    # 卡片标题

# 正文字体 - Google Font "Inter"
Body:
  Font: "Inter"  # 高可读性,适合长文本
  Large: 16px / 400 (Regular)   # 主要正文
  Medium: 14px / 400 (Regular)  # 次要文本
  Small: 12px / 400 (Regular)   # 辅助信息

# 等宽字体 - 用于日志、代码
Monospace:
  Font: "JetBrains Mono"
  Size: 13px / 400 (Regular)     # 日志输出
```

**Flutter 实现示例**:

```dart
import 'package:google_fonts/google_fonts.dart';

// 在 ThemeData 中定义
textTheme: TextTheme(
  displayLarge: GoogleFonts.outfit(
    fontSize: 32, 
    fontWeight: FontWeight.w700,
    color: Color(0xFFF1F5F9),  // Text.primary
  ),
  headlineMedium: GoogleFonts.outfit(
    fontSize: 24, 
    fontWeight: FontWeight.w600,
  ),
  bodyLarge: GoogleFonts.inter(
    fontSize: 16, 
    fontWeight: FontWeight.w400,
  ),
  labelSmall: GoogleFonts.jetBrainsMono(
    fontSize: 13,  // 日志区域
  ),
),
```

**为什么选择这些字体**:

- **Outfit + Inter**: 现代 SaaS 应用经典搭配,视觉层级清晰
- **JetBrains Mono**: 专为代码设计,日志区域更清晰易读

---

#### **3. Spacing System (间距系统)**

```yaml
# 基础间距 (8px Grid System)
Spacing:
  xs: 4px     # 图标与文字间距
  sm: 8px     # 元素内边距
  md: 16px    # 卡片/按钮内边距
  lg: 24px    # 模块间距
  xl: 32px    # 大区块间距
  xxl: 48px   # 页面边距

# 边框圆角
Radius:
  sm: 4px       # 小按钮
  md: 8px       # 卡片、输入框
  lg: 12px      # 大卡片
  xl: 20px      # Android 底部抽屉
  full: 9999px  # 圆形按钮 (FAB)
```

**规范说明**:

- **8px 网格系统**: 确保视觉一致性,避免出现奇怪间距 (如 7px, 13px)
- **圆角统一**: 玻璃拟态风格保持圆角一致性

---

#### **4. 动画规范 (Animation Standards)**

```yaml
# 动画时长 (Duration) - 符合 Material Motion
Duration:
  micro: 100ms    # 按钮 hover
  short: 200ms    # 卡片展开、颜色过渡
  medium: 300ms   # 页面切换、底部抽屉
  long: 500ms     # 大型布局变化

# 缓动函数 (Easing)
Easing:
  standard: cubic-bezier(0.4, 0.0, 0.2, 1)      # 通用
  deceleration: cubic-bezier(0.0, 0.0, 0.2, 1)  # 元素进入
  acceleration: cubic-bezier(0.4, 0.0, 1, 1)    # 元素离开
```

**Flutter 实现**:

```dart
// Hover 状态过渡
AnimatedContainer(
  duration: Duration(milliseconds: 200),  // short
  curve: Curves.easeInOut,  // standard
  color: isHovered ? Color(0xFF06B6D4) : Color(0xFF0891B2),
)
```

---

#### **5. 图标规范 (Icon Standards)**

> [!WARNING]
> **禁止使用 Emoji 作为 UI 图标** (🏠 ⚙️ 📄 等),必须使用专业的 SVG 图标库。

**推荐图标库**:

- **Lucide Icons** (`lucide_icons` package) - 现代、一致性强,推荐使用
- **Heroicons** - Tailwind CSS 官方图标
- **Material Icons** - Flutter 内置

**使用规范**:

```yaml
Icon Size:
  Small: 16px   # 按钮内图标
  Medium: 24px  # 导航栏、列表项
  Large: 32px   # FAB、大按钮

Icon Color:
  Default: Text.secondary (#94A3B8)
  Active: Primary.main (#0891B2)
  Disabled: Text.disabled (#64748B)
```

**Flutter 实现**:

```dart
import 'package:lucide_icons/lucide_icons.dart';

// ✅ 正确:使用 SVG 图标
NavigationItem(
  icon: Icon(
    LucideIcons.home,  
    size: 24,
    color: Color(0xFF0891B2),
  ),
  label: '首页',
)

// ❌ 错误:使用 Emoji
Text('🏠 首页'),  // 不专业,不同系统显示不一致
```

---

#### **6. 组件规范 (Component Standards)**

##### **玻璃拟态卡片 (Glass Card)**

```yaml
Glass Card:
  Background: rgba(30, 41, 59, 0.7)  # 半透明
  Backdrop Filter: blur(10px)        # 背景模糊
  Border: 1px solid rgba(255, 255, 255, 0.1)  # 轻微边框
  Border Radius: 12px
  Box Shadow: 0 4px 6px rgba(0, 0, 0, 0.3)  # 阴影提升层级
```

**Flutter 实现**:

```dart
Container(
  decoration: BoxDecoration(
    color: Color(0xFF1E293B).withOpacity(0.7),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: Colors.white.withOpacity(0.1),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: child,
      ),
    ),
  ),
)
```

##### **按钮状态 (Button States)**

```yaml
Primary Button:
  Default:
    Background: Primary.main (#0891B2)
    Text: White (#FFFFFF)
    Cursor: pointer
  Hover:
    Background: Primary.light (#06B6D4)
    Transform: scale(1.02)  # 轻微放大
    Transition: 200ms
  Pressed:
    Background: Primary.dark (#0E7490)
  Disabled:
    Background: Slate 700 (#334155)
    Text: Slate 500 (#64748B)
    Cursor: not-allowed
```

**Flutter 实现**:

```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFF0891B2),  // Primary.main
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ).copyWith(
    backgroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.hovered)) {
        return Color(0xFF06B6D4);  // Primary.light
      }
      if (states.contains(MaterialState.pressed)) {
        return Color(0xFF0E7490);  // Primary.dark
      }
      if (states.contains(MaterialState.disabled)) {
        return Color(0xFF334155);  // Slate 700
      }
      return Color(0xFF0891B2);
    }),
  ),
  onPressed: onPressed,
  child: Text('开始挂机'),
)
```

---

### **Android端UI** (悬浮窗模式)

#### 交互流程

```
状态1: 收起状态
┌─────────────────────────┐
│                         │
│    [游戏全屏画面]        │
│                         │
│                         │
│               ●  ← FAB 悬浮按钮 (56x56dp, SVG 图标)
│                         │
│                         │
└─────────────────────────┘

          ↓  点击 FAB

状态2: 展开状态
┌─────────────────────────┐
│                         │
│    [游戏全屏画面]        │
│         (半透明遮罩)      │
│                         │
├─────────────────────────┤
│ SW Game Helper           │ ← 从底部弹出
│                         │
│ [任务选择按钮组]         │
│                         │
│ [▶️ 开始任务]           │
└─────────────────────────┘

          ↓  下滑/点击遮罩

状态3: 收起（回到状态1）
```

#### 设计规范 (Design Specifications)

##### **悬浮按钮 (FAB - Floating Action Button)**

```yaml
FAB Design:
  Size: 56x56 dp  # Material Design 标准
  Icon: SVG 图标 (LucideIcons.gamepad2),禁用 Emoji
  Background: Primary.main (#0891B2)
  Elevation: 6dp (阴影)
  Ripple Effect: 点击时水波纹动画
  Drag Handle: 长按 300ms 后可拖动,防止误触
  Positioning: 默认右下角,距离边缘 16dp
```

**Flutter 实现**:

```dart
FloatingActionButton(
  heroTag: 'game_helper_fab',
  backgroundColor: Color(0xFF0891B2),  // Primary.main
  elevation: 6,
  child: Icon(
    LucideIcons.gamepad2,  // ✅ SVG 图标
    size: 24,
    color: Colors.white,
  ),
  onPressed: () => _showControlPanel(),
)
```

##### **底部抽屉动画 (Bottom Sheet Animation)**

```yaml
Bottom Sheet:
  Animation Duration: 300ms  # Medium
  Curve: easeOutCubic
  Backdrop: rgba(0, 0, 0, 0.5)  # 半透明遮罩
  Background: rgba(30, 41, 59, 0.95)  # 几乎不透明
  Border Radius: 20px (顶部圆角)
  Max Height: 70% of screen height
  Dismiss Gestures:
    - 下滑手势关闭
    - 点击遮罩关闭
    - 返回键关闭
```

**Flutter 实现**:

```dart
showModalBottomSheet(
  context: context,
  backgroundColor: Colors.transparent,
  barrierColor: Colors.black.withOpacity(0.5),
  isScrollControlled: true,  // 支持自定义高度
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
  builder: (context) => Container(
    height: MediaQuery.of(context).size.height * 0.7,
    decoration: BoxDecoration(
      color: Color(0xFF1E293B).withOpacity(0.95),
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: Column(
      children: [
        // 顶部拖拽指示器
        Container(
          margin: EdgeInsets.symmetric(vertical: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(child: ControlPanelWidget()),
      ],
    ),
  ),
)
```

##### **无障碍性规范 (Accessibility)**

```yaml
# 触摸区域最小尺寸
Touch Targets:
  Minimum: 48x48 dp  # Material Design 标准
  Recommended: 56x56 dp  # 避免误触

# 文字对比度
Text Contrast:
  Title: #F1F5F9 on #1E293B (19.5:1, WCAG AAA)
  Body: #94A3B8 on #0F172A (7.2:1, WCAG AA)

# 屏幕阅读器支持
Semantics:
  - 所有按钮添加语义标签 (Semantics widget)
  - FAB 标签: "打开游戏助手控制面板"
  - 任务状态变化时通知屏幕阅读器
```

**Flutter 实现**:

```dart
Semantics(
  label: '开始钓鱼任务',  // 屏幕阅读器会读出
  button: true,
  child: ElevatedButton(
    onPressed: () => _startFishing(),
    child: Text('开始挂机'),
  ),
)
```

##### **权限要求 (Required Permissions)**

```yaml
Android Permissions:
  - SYSTEM_ALERT_WINDOW: 悬浮窗显示
  - BIND_ACCESSIBILITY_SERVICE: 无障碍服务(模拟触摸)
  - WRITE_EXTERNAL_STORAGE: 模板存储
  - FOREGROUND_SERVICE: 后台运行
```

---

## 🛠️ 技术架构设计

### **整体架构**

```
┌────────────────────────────────────────────────────────┐
│                    Flutter Application                 │
│                                                        │
│  ┌──────────────────────────────────────────────────┐ │
│  │              UI Layer (Platform Specific)         │ │
│  │  ┌─────────────────┐   ┌─────────────────┐      │ │
│  │  │  Windows UI     │   │  Android UI     │      │ │
│  │  │  (Desktop)      │   │  (Floating)     │      │ │
│  │  └─────────────────┘   └─────────────────┘      │ │
│  │  └──────────────────────────────────────────────────┘ │
│                                                        │
│  ┌──────────────────────────────────────────────────┐ │
│  │         Core Logic Layer (Platform Agnostic)     │ │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐        │ │
│  │  │  Vision  │ │  Tasks   │ │  Config  │        │ │
│  │  │  Module  │ │  System  │ │  Manager │        │ │
│  │  └──────────┘ └──────────┘ └──────────┘        │ │
│  │  └──────────────────────────────────────────────────┘ │
│                                                        │
│  ┌──────────────────────────────────────────────────┐ │
│  │      Platform Services (Platform Specific)       │ │
│  │  ┌─────────────────┐   ┌─────────────────┐      │ │
│  │  │ Win32 API       │   │ Accessibility   │      │ │
│  │  │ Scrcpy Service  │   │ Overlay Service │      │ │
│  │  └─────────────────┘   └─────────────────┘      │ │
│  │  └──────────────────────────────────────────────────┘ │
│  └────────────────────────────────────────────────────────┘
```

---

## 🎯 反检测核心方案

### **Windows端: Scrcpy投屏方案**

#### 原理

```
Flutter App → ADB命令 → Scrcpy投屏 → 控制scrcpy窗口 
    → PostMessage/SendMessage → 转为触摸事件 → 安卓游戏
```

#### 为什么不会被检测

- ✅ 游戏运行在**真实的Android系统**
- ✅ 接收的是**真实的触摸事件**（通过scrcpy注入）
- ✅ PC端只是控制投屏窗口，游戏**无法检测**
- ✅ 原理类似远程桌面，不会被封禁

#### 关键优势

- 0检测风险
- 使用简单的Win32 API (PostMessage/SendMessage)
- 不需要复杂的输入模拟
- 已在Python版本验证可行

---

### **Android端: 无障碍服务方案**

#### 原理

```
Flutter App (悬浮窗) → AccessibilityService 
    → 真实触摸事件 → 游戏进程
```

#### 为什么不会被检测

- ✅ 使用系统提供的**无障碍服务**
- ✅ 模拟的是**系统级触摸事件**
- ✅ 游戏无法区分用户手动操作和辅助服务操作
- ✅ 无需Root权限

---

## 📁 项目目录结构

```
sw_game_helper/
├── lib/
│   ├── main.dart                          # 应用入口
│   │
│   ├── core/                              # ✅ 核心逻辑（平台无关）
│   │   ├── vision/                       # 图像识别模块
│   │   │   ├── game_vision.dart          # 图像识别主类
│   │   │   ├── template_matcher.dart     # 模板匹配
│   │   │   └── image_utils.dart          # 图像工具
│   │   │
│   │   ├── tasks/                        # 任务系统
│   │   │   ├── base_task.dart            # 任务基类
│   │   │   ├── fishing_task.dart         # 钓鱼任务
│   │   │   ├── arena_task.dart           # 竞技场任务
│   │   │   ├── trial_task.dart           # 试炼任务
│   │   │   └── task_scheduler.dart       # 任务调度器
│   │   │
│   │   ├── models/                       # 数据模型
│   │   │   ├── template.dart             # 模板模型
│   │   │   ├── task.dart                 # 任务模型
│   │   │   ├── config.dart               # 配置模型
│   │   │   └── game_state.dart           # 游戏状态
│   │   │
│   │   └── config/                       # 配置管理
│   │       ├── config_manager.dart       # 配置管理器
│   │       └── app_config.dart           # 应用配置
│   │
│   ├── platforms/
│   │   ├── windows/                      # 🖥️ Windows平台
│   │   │   ├── ui/                       # Windows UI
│   │   │   │   ├── pages/
│   │   │   │   │   ├── home_page.dart           # 主页面
│   │   │   │   │   ├── template_manager_page.dart
│   │   │   │   │   └── settings_page.dart
│   │   │   │   │
│   │   │   │   └── widgets/
│   │   │   │       ├── game_preview_widget.dart  # 游戏画面
│   │   │   │       ├── control_panel_widget.dart # 控制面板
│   │   │   │       ├── task_selector_widget.dart # 任务选择器
│   │   │   │       ├── log_viewer_widget.dart    # 日志查看器
│   │   │   │       └── screenshot_overlay_widget.dart
│   │   │   │
│   │   │   └── services/                # Windows服务层
│   │   │       ├── win32_controller.dart        # Win32 API封装
│   │   │       ├── scrcpy_service.dart          # Scrcpy管理
│   │   │       ├── window_capture_service.dart  # 窗口截图
│   │   │       └── adb_service.dart             # ADB操作
│   │   │
│   │   └── android/                      # 📱 Android平台（未来）
│   │       ├── ui/
│   │       │   ├── floating_button.dart         # 悬浮按钮
│   │       │   ├── bottom_sheet_panel.dart      # 底部面板
│   │       │   └── quick_actions_widget.dart    # 快捷操作
│   │       │
│   │       └── services/
│   │           ├── overlay_window_service.dart   # 悬浮窗服务
│   │           ├── accessibility_service.dart    # 无障碍服务
│   │           └── gesture_service.dart          # 手势模拟
│   │
│   ├── shared/                           # 🔄 共享组件
│   │   └── widgets/
│   │       ├── task_card.dart            # 任务卡片
│   │       ├── status_indicator.dart     # 状态指示器
│   │       └── custom_button.dart        # 自定义按钮
│   │
│   └── utils/                            # 工具类
│       ├── logger.dart                   # 日志工具
│       ├── platform_utils.dart           # 平台工具
│       └── style.dart                # 常量定义
│
├── windows/                              # Windows平台特定代码
│   └── runner/
│       └── win32_helper.cpp              # C++ Win32封装
│
├── android/                              # Android平台特定代码
│   └── app/src/main/
│       ├── AndroidManifest.xml           # 权限配置
│       └── kotlin/
│           └── AccessibilityService.kt   # 无障碍服务实现
│
├── assets/                               # 资源文件
│   ├── templates/                        # 模板图片
│   │   ├── fishing/                      # 钓鱼模板
│   │   ├── arena/                        # 竞技场模板
│   │   └── trial/                        # 试炼模板
│   │
│   └── icons/                            # 应用图标
│
├── config/                               # 配置文件
│   └── app_config.json                   # 应用配置
│
└── pubspec.yaml                          # 依赖配置
```

---

## 🔧 核心技术栈

### **Flutter依赖**

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Windows平台特定
  win32: ^5.0.0              # Windows API调用
  ffi: ^2.1.0                # C语言FFI接口
  
  # 图像处理
  image: ^4.0.0              # 图片处理库
  opencv_dart: ^1.0.4        # OpenCV绑定（模板匹配）
  
  # 状态管理
  provider: ^6.0.0           # 状态管理
  riverpod: ^2.4.0           # 替代方案（可选）
  
  # UI组件
  flutter_hooks: ^0.20.0     # Hooks支持
  
  # 工具
  path_provider: ^2.0.0      # 路径管理
  shared_preferences: ^2.0.0 # 配置存储
  logger: ^2.0.0             # 日志框架
  
  # Android平台特定（未来）
  flutter_overlay_window: ^0.4.0  # 悬浮窗
  system_alert_window: ^1.0.0     # 系统弹窗
```

---

## 💻 核心功能设计

### **1. Scrcpy控制器 (Windows)**

#### ScrcpyController类

```dart
class ScrcpyController {
  int? windowHandle;
  
  /// 查找scrcpy窗口
  Future<void> findWindow(String title) async {
    // Windows: 使用FFI调用FindWindowW
    // 返回窗口句柄
  }
  
  /// 点击操作
  Future<void> click(int x, int y) async {
    // 1. 添加随机偏移 (±3像素)
    // 2. PostMessage到scrcpy窗口
    // 3. 添加随机延迟
    await _addRandomDelay();
    await _addPositionOffset(x, y);
  }
  
  /// 滑动操作
  Future<void> swipe(int x1, y1, x2, y2, Duration duration) async {
    // 1. 生成贝塞尔曲线路径
    // 2. 逐步发送消息模拟轨迹
    // 3. 添加随机抖动
  }
  
  /// 窗口截图
  Future<Uint8List> capture() async {
    // Windows: BitBlt截取窗口客户区
    // 返回BGRA格式图像数据
  }
}
```

---

### **2. 图像识别模块**

#### GameVision类

```dart
class GameVision {
  final opencv.OpenCV cv;
  
  /// 模板匹配
  Future<Point?> findTemplate({
    required Uint8List screenshot,
    required String templatePath,
    double threshold = 0.99,
  }) async {
    // 1. 加载模板图片
    final template = await loadTemplate(templatePath);
    
    // 2. 使用opencv_dart进行TM_CCORR_NORMED匹配
    final result = cv.matchTemplate(
      screenshot, 
      template,
      method: cv.TM_CCORR_NORMED,
      mask: alpha,
    );
    
    // 3. 检查匹配度
    if (result.maxVal >= threshold) {
      // 返回中心点 + 随机偏移
      return _getRandomPointInRect(result.maxLoc, templateSize);
    }
    
    return null;
  }
  
  /// 多目标匹配
  Future<List<Point>> findAll({...}) async {
    // 返回所有匹配位置（阈值以上的）
  }
}
```

---

### **3. 任务系统**

#### 抽象任务基类

```dart
abstract class GameTask {
  String get name;
  TaskStatus status = TaskStatus.idle;
  
  /// 执行任务
  Future<void> execute();
  
  /// 停止任务
  Future<void> stop();
  
  /// 暂停任务
  Future<void> pause();
}

/// 任务状态枚举
enum TaskStatus { idle, running, paused, stopped, completed, error }
```

#### 钓鱼任务实现

```dart
class FishingTask extends GameTask {
  @override
  String get name => '自动钓鱼';
  
  final ScrcpyController controller;
  final GameVision vision;
  
  @override
  Future<void> execute() async {
    status = TaskStatus.running;
    
    while (status == TaskStatus.running) {
      try {
        // 1. 截图
        final screenshot = await controller.capture();
        
        // 2. 识别"抛竿"按钮
        final paogan = await vision.findTemplate(
          screenshot: screenshot,
          templatePath: 'assets/templates/fishing/paogan.png',
          threshold: 0.99,
        );
        
        if (paogan != null) {
          // 3. 点击抛竿
          await controller.click(paogan.x, paogan.y);
          logger.info('点击抛竿按钮');
          
          // 4. 等待随机时间后确认
          await Future.delayed(Duration(milliseconds: Random().nextInt(500) + 200));
          await controller.click(paogan.x, paogan.y);
          
          // 5. 等待收竿
          await _waitForShougan();
        }
        
        // 6. 间隔等待
        await Future.delayed(Duration(seconds: 2));
        
      } catch (e) {
        logger.error('钓鱼任务异常: $e');
        status = TaskStatus.error;
      }
    }
  }
  
  Future<void> _waitForShougan() async {
    // 循环检测"收竿"按钮
    while (status == TaskStatus.running) {
      final screenshot = await controller.capture();
      final shougan = await vision.findTemplate(
        screenshot: screenshot,
        templatePath: 'assets/templates/fishing/shougan.png',
      );
      
      if (shougan != null) {
        await controller.click(shougan.x, shougan.y);
        logger.info('点击收竿');
        break;
      }
      
      await Future.delayed(Duration(seconds: 1));
    }
  }
}
```

---

## 📊 数据存储设计

### **配置文件 (JSON)**

```json
{
  "scrcpy": {
    "window_title": "幻唐志",
    "max_size": 1024,
    "max_fps": 30,
    "bitrate": "8M"
  },
  "control": {
    "min_delay_ms": 100,
    "max_delay_ms": 300,
    "position_offset_px": 3,
    "click_duration_ms": 50
  },
  "templates": {
    "default_threshold": 0.99,
    "base_path": "assets/templates"
  },
  "tasks": {
    "fishing": {
      "enabled": true,
      "sell_count": 2,
      "auto_buy_rod": true
    },
    "arena": {
      "enabled": false,
      "challenge_count": 10
    }
  },
  "logging": {
    "level": "info",
    "max_lines": 1000
  }
}
```

### **模板数据 (SharedPreferences)**

```dart
{
  "templates": {
    "paogan_btn": {
      "path": "assets/templates/fishing/paogan.png",
      "threshold": 0.99,
      "region": [400, 600, 100, 50]  // x, y, w, h
    },
    "shougan_btn": {
      "path": "assets/templates/fishing/shougan.png",
      "threshold": 0.99,
      "region": null  // 全屏匹配
    }
  }
}
```

---

## 🚀 开发实施计划 (Windows端)

### **阶段1: 基础框架 (2-3天)**

- [x] 创建Flutter项目
- [ ] 配置Windows平台依赖
- [ ] 设计目录结构
- [ ] 实现基础UI框架
- [ ] 配置日志系统

**交付物**: 可运行的空白Desktop应用

---

### **阶段2: Win32集成 (2天)**

- [ ] 实现Win32 API FFI绑定
  - FindWindow (查找窗口)
  - GetClientRect (获取窗口大小)
  - PostMessage (发送消息)
  - BitBlt (窗口截图)
- [ ] 实现ScrcpyController基础功能
  - 窗口查找
  - 窗口截图
  - 点击操作
- [ ] 编写单元测试

**交付物**: 可控制scrcpy窗口并截图

---

### **阶段3: 图像识别 (2天)**

- [ ] 集成opencv_dart
- [ ] 实现GameVision类
  - 模板匹配算法
  - 多目标匹配
  - Alpha通道支持
- [ ] 实现模板管理功能
  - 截图工具
  - 模板保存/加载
  - 模板预览
- [ ] 性能优化

**交付物**: 可识别游戏画面中的按钮

---

### **阶段4: 任务系统 (3天)**

- [ ] 实现任务基类和调度器
- [ ] 实现钓鱼任务
  - 抛竿逻辑
  - 收竿检测
  - 卖鱼逻辑
- [ ] 实现竞技场任务
  - OCR文字识别（可选）
  - 战斗判断
  - 刷新逻辑
- [ ] 实现试炼任务

**交付物**: 完整的自动化任务系统

---

### **阶段5: UI完善 (2天)**

- [ ] 完善主界面
  - 游戏画面实时显示
  - 控制面板
  - 日志查看器
- [ ] 模板管理页面
  - 模板列表
  - 添加/编辑/删除
  - 截图工具集成
- [ ] 设置页面
  - 参数配置
  - Scrcpy路径设置

**交付物**: 完整的GUI应用

---

### **阶段6: 测试和优化 (2天)**

- [ ] 功能测试
  - 各任务完整流程测试
  - 异常处理测试
- [ ] 性能测试
  - 图像识别性能
  - 内存占用
- [ ] 稳定性测试
  - 长时间运行测试
  - 错误恢复测试
- [ ] Bug修复和优化

**交付物**: 稳定可用的Windows版本

---

## 📅 预计总时间

**Windows端开发**: 13-15天

---

## 🔮 未来Android端规划

### **技术要点**

1. **悬浮窗实现**
   - 使用 `flutter_overlay_window` 插件
   - 或通过Platform Channel调用原生代码

2. **无障碍服务**
   - 实现AccessibilityService
   - 获取屏幕内容
   - 模拟点击、滑动

3. **权限管理**
   - SYSTEM_ALERT_WINDOW (悬浮窗)
   - BIND_ACCESSIBILITY_SERVICE (无障碍)
   - READ_EXTERNAL_STORAGE (模板存储)

4. **性能优化**
   - 图像识别降低分辨率
   - 后台运行省电模式
   - 唤醒锁管理

### **预计时间**: 7-10天

---

## ✅ 技术风险评估

| 风险项 | 风险等级 | 缓解措施 |
|--------|---------|---------|
| **Win32 API调用失败** | 中 | 参考Python版本已验证可行，使用成熟的win32包 |
| **OpenCV Dart性能** | 中 | 可降低图像分辨率，或使用原生插件 |
| **Scrcpy连接不稳定** | 低 | 添加重连机制，错误恢复逻辑 |
| **图像识别准确率** | 低 | 已有Python版本模板，直接复用 |
| **Android权限限制** | 高 | 需用户手动授权，提供详细引导 |

---

## 📝 开发规范

### **代码规范**

- 遵循Dart官方代码风格
- 使用有意义的变量名
- 每个类/方法添加注释
- 复杂逻辑添加详细说明

### **Git提交规范**

```
feat: 添加钓鱼任务实现
fix: 修复窗口截图内存泄漏
docs: 更新设计文档
refactor: 重构图像识别模块
test: 添加任务调度器单元测试
```

### **分支策略**

- `main`: 稳定版本
- `develop`: 开发分支
- `feature/xxx`: 功能分支
- `hotfix/xxx`: 紧急修复

---

## 🎯 成功标准

### **Windows端交付标准**

✅ **功能完整性**

- [ ] 可正常连接scrcpy窗口
- [ ] 图像识别准确率 > 98%
- [ ] 至少实现2个完整任务（钓鱼 + 竞技场）
- [ ] UI界面完整可用

✅ **稳定性**

- [ ] 连续运行2小时无崩溃
- [ ] 异常情况可自动恢复
- [ ] 内存占用 < 500MB

✅ **用户体验**

- [ ] 界面响应流畅 (FPS > 30)
- [ ] 日志清晰易读
- [ ] 操作简单直观

---

## 📞 联系信息

**项目路径**:

- 原项目: `C:\Users\Onyx\OneDrive\Documents\PythonProject\GameScript`
- 新项目: `d:\FlutterProject\sw_game_helper`
- 设计文档: 当前文件

**开发时间**: 2026年1月 - 2026年2月

---

## 📚 参考资料

- [Flutter Desktop官方文档](https://docs.flutter.dev/desktop)
- [Win32包文档](https://pub.dev/packages/win32)
- [OpenCV Dart文档](https://pub.dev/packages/opencv_dart)
- [Scrcpy项目](https://github.com/Genymobile/scrcpy)
- [原Python项目源码](file:///C:/Users/Onyx/OneDrive/Documents/PythonProject/GameScript)

---

**文档版本**: 1.0  
**最后更新**: 2026-01-16  
**状态**: ✅ 设计完成，待开发

---

## 附录: 核心API参考

### Windows API映射

```dart
// 查找窗口
final hwnd = FindWindowW(nullptr, windowTitle.toNativeUtf16());

// 获取窗口大小
final rect = calloc<RECT>();
GetClientRect(hwnd, rect);

// 窗口截图
final hdc = GetDC(hwnd);
final memDC = CreateCompatibleDC(hdc);
final bitmap = CreateCompatibleBitmap(hdc, width, height);
SelectObject(memDC, bitmap);
BitBlt(memDC, 0, 0, width, height, hdc, 0, 0, SRCCOPY);
GetBitmapBits(bitmap, totalBytes, buffer);

// 发送点击消息
PostMessage(hwnd, WM_LBUTTONDOWN, MK_LBUTTON, MAKELPARAM(x, y));
PostMessage(hwnd, WM_LBUTTONUP, 0, MAKELPARAM(x, y));
```

### OpenCV模板匹配

```dart
// 模板匹配
final result = Cv.matchTemplate(
  screenshot,
  template,
  Cv.TM_CCORR_NORMED,
  mask: alpha,
  );

// 获取最大值位置
final minMaxLoc = Cv.minMaxLoc(result);
final maxVal = minMaxLoc.$2;
final maxLoc = minMaxLoc.$4;

if (maxVal >= threshold) {
  return Point(
    maxLoc.x + template.width ~/ 2,
    maxLoc.y + template.height ~/ 2,
  );
}
```

---

**🎉 设计文档完成！可以开始开发了！**
