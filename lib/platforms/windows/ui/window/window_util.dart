import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Windows 桌面窗口工具类（生产版）。
///
/// 设计目标：
/// 1) 集中管理窗口初始化与常用窗口能力，避免散落在 UI 组件中；
/// 2) 仅使用 window_manager，不依赖自定义 MethodChannel；
/// 3) 保持 Win11 系统语义（最小化/最大化/Snap/阴影）尽可能稳定。
class WindowUtil {
  WindowUtil._();

  static bool get isWindows => Platform.isWindows;
  static bool _initialized = false;
  static bool? _lastResizable;

  /// 初始化 Windows 主窗口。
  ///
  /// 注意：
  /// - 只在 Windows 执行；
  /// - 使用 `TitleBarStyle.hidden` 实现融合标题栏；
  /// - 不调用 `setAsFrameless()`，避免破坏系统动画与窗口语义。
  static Future<void> initializeMainWindow({
    required String title,
    Size size = const Size(1280, 720),
    Size minimumSize = const Size(1024, 640),
  }) async {
    if (!isWindows) {
      return;
    }

    if (_initialized) {
      return;
    }

    await windowManager.ensureInitialized();

    final windowOptions = WindowOptions(
      size: size,
      minimumSize: minimumSize,
      center: true,
      skipTaskbar: false,
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.hidden,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setTitle(title);
      await windowManager.show();
      await windowManager.focus();
    });

    _initialized = true;
  }

  /// 设置窗口是否可调整大小（幂等）。
  ///
  /// 说明：
  /// - 登录页可调用 `setResizable(false)`；
  /// - 主页可调用 `setResizable(true)`；
  /// - 内部做了状态去重，避免重复调用导致不必要抖动。
  static Future<void> setResizable(bool enabled) async {
    if (!isWindows) return;
    if (_lastResizable == enabled) return;
    await windowManager.setResizable(enabled);
    _lastResizable = enabled;
  }

  /// 最小化窗口。
  static Future<void> minimize() async {
    if (!isWindows) return;
    try {
      await windowManager.minimize();
    } catch (_) {
      // 保持 UI 路径稳定：窗口指令失败时不抛到业务层。
    }
  }

  /// 切换最大化/还原。
  static Future<void> toggleMaximize() async {
    if (!isWindows) return;
    try {
      final isMaximized = await windowManager.isMaximized();
      if (isMaximized) {
        await windowManager.unmaximize();
        return;
      }
      await windowManager.maximize();
    } catch (_) {
      // 同上：窗口状态调用失败不影响主流程。
    }
  }

  /// 关闭窗口。
  static Future<void> close() async {
    if (!isWindows) return;
    try {
      await windowManager.close();
    } catch (_) {
      // 同上：窗口关闭失败时由系统默认行为兜底。
    }
  }
}
