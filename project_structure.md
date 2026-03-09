# 📂 Flutter 项目结构详解

## 1. 核心目录与文件

### 📄 `pubspec.yaml`
- **作用**: 项目的配置文件，管理依赖、资源（图片/字体）、版本号等。
- **类比**:
  - **Java**: 等同于 `pom.xml` (Maven) 或 `build.gradle` (Gradle)
  - **Python**: 等同于 `requirements.txt` + `setup.py`

### 📂 `lib/`
- **作用**: **最重要**的目录，99% 的代码都在这里写。
- **包含**:
  - `main.dart`: 应用的入口文件（类似 Java 的 Main 类）。
  - 所有 Dart 代码（页面、组件、逻辑）。
- **类比**:
  - **Java**: 等同于 `src/main/java`

### 📂 `windows/`, `android/`
- **作用**: 包含各个平台的原生宿主工程代码。
- **说明**: 
  - `windows/` 其实就是一个完整的 C++ Win32 工程。
  - `android/` 就是一个完整的 Android (Java/Kotlin/Gradle) 工程。

### 📄 `analysis_options.yaml`
- **作用**: 代码静态分析规则配置。
- **类比**:
  - **Java**: 等同于 `checkstyle.xml` 或 `lint` 配置

### 📂 `test/`
- **作用**: 单元测试和组件测试代码。
- **类比**:
  - **Java**: 等同于 `src/test/java`

### 📂 `build/`
- **作用**: 编译输出目录。
- **类比**:
  - **Java**: 等同于 `target/` (Maven) 或 `build/` (Gradle)

---

## 2. 深入 `lib/main.dart` (入口文件)

这是 Flutter 应用的起点，语法和 Java 非常像：

```dart
import 'package:flutter/material.dart'; // import 包

// main 函数是程序的唯一入口，就像 Java 的 public static void main
void main() {
  runApp(const MyApp()); // 启动应用
}

// 一切都是类 (Class)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // @override 注解，重写父类方法
  @override
  Widget build(BuildContext context) {
    // 这里的嵌套结构类似构建 UI 组件树
    return MaterialApp(
      title: 'SW Game Helper',
      theme: ThemeData(...),
      home: const MyHomePage(...),
    );
  }
}
```

---

## 3. Flutter vs Java 结构对比表

| Flutter | Java (Maven/Gradle) | 说明 |
| :--- | :--- | :--- |
| `pubspec.yaml` | `pom.xml` / `build.gradle` | 依赖管理 |
| `lib/` | `src/main/java` | 源码目录 |
| `lib/main.dart` | `Main.java` | 程序入口 |
| `Widget` | `JPanel` / `Component` (Swing) | UI 组件 |
| `build/` | `target/` / `build/` | 编译产物 |
| `analysis_options.yaml`| `checkstyle.xml` | 代码规范 |
