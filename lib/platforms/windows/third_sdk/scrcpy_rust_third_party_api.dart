import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart'
    show Clipboard, ClipboardData, MethodCall, MethodChannel, PlatformException;
import 'package:sw_game_helper/platforms/windows/bridge_generated/gh_api/flutter_api.dart'
    as flutter_api;
import 'package:sw_game_helper/platforms/windows/bridge_generated/gh_common/model.dart';
import 'package:sw_game_helper/utils/logger_service.dart';

/// Windows 下第三方依赖路径解析。
class ThirdPartyPaths {
  static String getPath(String filename) {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    return '$exeDir${Platform.pathSeparator}$filename';
  }

  static String get adb => getPath('adb.exe');

  static String get scrcpyServer => getPath('scrcpy-server-v3.3.4');
}

/// Rust bridge 的业务封装。
class ScrcpyRustThirdPartyApi {
  ScrcpyRustThirdPartyApi._();

  static final ScrcpyRustThirdPartyApi _instance = ScrcpyRustThirdPartyApi._();

  static ScrcpyRustThirdPartyApi get instance => _instance;
  bool _rustLogBound = false;
  static const MethodChannel _clipboardBridgeChannel = MethodChannel(
    'clipboard_bridge',
  );
  bool _clipboardHandlerBound = false;

  /// 初始化 Rust DLL 日志级别（仅首次调用生效，后续调用会被 Rust 侧忽略）。
  Future<void> initLogger({LogLevel maxLevel = LogLevel.info}) async {
    await flutter_api.setupLogger(maxLevel: maxLevel);
    _ensureRustLogBridgeBound();
  }

  /// 绑定 Rust 日志流到 App 日志面板（FRB，无 MethodChannel）。
  void _ensureRustLogBridgeBound() {
    if (_rustLogBound) {
      return;
    }
    _rustLogBound = true;
    flutter_api.subscribeLogs().listen(
      (event) {
        final level = event.level.toLowerCase();
        final text = '[Rust][${event.target}] ${event.message}';
        switch (level) {
          case 'trace':
          case 'debug':
            Log.d(text);
            break;
          case 'warn':
          case 'warning':
            Log.w(text);
            break;
          case 'error':
            Log.e(text);
            break;
          default:
            Log.i(text);
        }
      },
      onError: (Object e, StackTrace st) {
        Log.e('Rust 日志流订阅失败: $e', e, st);
      },
    );
  }

  /// 先列设备，再逐个补全详情（型号/版本）。
  Future<List<DeviceInfo>> listDevices() async {
    final devices = await flutter_api.listDevices(adbPath: ThirdPartyPaths.adb);
    if (devices.isEmpty) {
      return const <DeviceInfo>[];
    }

    final detailFutures = devices.map((device) async {
      try {
        return await flutter_api.getDeviceInfo(
          adbPath: ThirdPartyPaths.adb,
          deviceId: device.deviceId,
        );
      } catch (e, st) {
        Log.w('读取设备详情失败(${device.deviceId})，回退基础信息: $e');
        Log.e('读取设备详情异常堆栈', e, st);
        return device;
      }
    }).toList();

    return Future.wait(detailFutures);
  }

  /// 渲染链路选择（V2）。
  Future<String> connectV2({
    required String deviceId,
    required RenderPipelineMode renderPipelineMode,
    required DecoderMode decoderMode,
    required int bitRate,
    required int maxSize,
    required int maxFps,
    bool turnScreenOff = false,
  }) async {
    final base = SessionConfig(
      adbPath: ThirdPartyPaths.adb,
      serverPath: ThirdPartyPaths.scrcpyServer,
      deviceId: deviceId,
      maxSize: maxSize,
      bitRate: bitRate,
      maxFps: maxFps,
      videoPort: 27183,
      controlPort: 27184,
      videoEncoder: null,
      turnScreenOff: turnScreenOff,
      stayAwake: false,
      scrcpyVerbosity: 'info',
      intraRefreshPeriod: 1,
    );

    final config = SessionConfigV2(
      base: base,
      renderPipelineMode: renderPipelineMode,
      decoderMode: decoderMode,
    );

    final sessionId = await flutter_api.createSessionV2(config: config);
    await flutter_api.startSession(sessionId: sessionId);
    return sessionId;
  }

  /// 断开与设备的连接。
  Future<void> disconnect(String sessionId) async {
    final sw = Stopwatch()..start();
    Log.i('disconnect start: session=$sessionId');
    try {
      await flutter_api.stopSession(sessionId: sessionId);
      Log.i(
        'disconnect stop done: session=$sessionId cost=${sw.elapsedMilliseconds}ms',
      );
    } catch (_) {
      Log.w('disconnect stop failed (ignored): session=$sessionId');
    }
    await flutter_api.disposeSession(sessionId: sessionId);
    Log.i(
      'disconnect dispose done: session=$sessionId cost=${sw.elapsedMilliseconds}ms',
    );
  }

  /// 发送触控事件到 Rust 当前会话。
  Future<void> sendTouch(String sessionId, TouchEvent event) async {
    await flutter_api.sendTouch(sessionId: sessionId, event: event);
  }

  Future<void> sendKey(String sessionId, KeyEvent event) async {
    await flutter_api.sendKey(sessionId: sessionId, event: event);
  }

  /// 发送文本输入到当前会话。
  Future<void> sendText(String sessionId, String text) async {
    if (text.isEmpty) {
      return;
    }
    await flutter_api.sendText(sessionId: sessionId, text: text);
  }

  /// 设置设备剪贴板文本，并按需触发设备端粘贴动作。
  Future<void> setClipboard({
    required String sessionId,
    required String text,
    required bool paste,
  }) async {
    if (text.isEmpty) {
      return;
    }
    await flutter_api.setClipboard(
      sessionId: sessionId,
      text: text,
      paste: paste,
    );
  }

  Future<void> sendScroll(String sessionId, ScrollEvent event) async {
    await flutter_api.sendScroll(sessionId: sessionId, event: event);
  }

  /// 同步设备剪贴板到 Windows。
  ///
  /// 策略：
  /// - 首次写入失败时，仅在“剪贴板被占用”场景重试一次；
  /// - 第二次仍失败则记录并放弃，不向外抛异常，避免污染会话事件流。
  Future<void> _syncDeviceClipboardToWindows(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      Log.i('剪贴板同步：设备内容已写入 Windows');
      return;
    } on PlatformException catch (e) {
      if (!_isClipboardBusyError(e)) {
        Log.w('剪贴板同步失败(非占用错误): $e');
        return;
      }
      // 仅重试一次，避免复杂重试策略引入额外维护成本。
      await Future<void>.delayed(const Duration(milliseconds: 40));
      try {
        await Clipboard.setData(ClipboardData(text: text));
        Log.i('剪贴板同步：重试一次后成功');
      } on PlatformException catch (e2) {
        Log.w('剪贴板同步失败(重试后放弃): $e2');
      } catch (e2) {
        Log.w('剪贴板同步失败(重试后放弃): $e2');
      }
    } catch (e) {
      Log.w('剪贴板同步失败: $e');
    }
  }

  /// 判断是否为“Windows 剪贴板暂时被占用”错误。
  bool _isClipboardBusyError(PlatformException e) {
    final message = (e.message ?? '').toLowerCase();
    final details = '${e.details}'.toLowerCase();
    return message.contains('unable to open clipboard') ||
        details == '5' ||
        details.contains('error, 5');
  }

  /// 订阅会话事件流（FRB 直连 Rust，无 MethodChannel 中转）。
  Stream<SessionEvent> streamSessionEvents(String sessionId) {
    return flutter_api.subscribeSessionEvents(sessionId: sessionId);
  }

  /// 初始化 YOLO 推理配置（仅硬件后端）。
  ///
  /// 参数：
  /// - [config]：初始推理配置（模型路径、阈值、输入尺寸、后端）。
  Future<void> initYolo(YoloConfig config) async {
    await flutter_api.initYolo(config: config);
    Log.i('YOLO 初始化完成: provider=${config.provider.name}');
  }

  /// 运行中更新 YOLO 推理配置（实时生效）。
  ///
  /// 参数：
  /// - [config]：新的推理配置（可由 Flutter 设置页动态下发）。
  Future<void> updateYoloConfig(YoloConfig config) async {
    await flutter_api.updateYoloConfig(config: config);
    Log.i('YOLO 配置已更新: provider=${config.provider.name}');
  }

  /// 设置会话级 YOLO 开关。
  ///
  /// 参数：
  /// - [sessionId]：会话 ID；
  /// - [enabled]：是否启用 YOLO 推理。
  Future<void> setYoloEnabled({
    required String sessionId,
    required bool enabled,
  }) async {
    await flutter_api.setYoloEnabled(sessionId: sessionId, enabled: enabled);
    Log.i('YOLO 会话开关更新: session=$sessionId enabled=$enabled');
  }

  /// 订阅会话级 YOLO 推理结果流。
  ///
  /// 参数：
  /// - [sessionId]：会话 ID。
  Stream<YoloFrameResult> streamYoloResults(String sessionId) {
    return flutter_api.subscribeYoloResults(sessionId: sessionId);
  }

  /// 绑定“设备剪贴板 -> Windows”独立同步通道（Rust 独立 API）。
  Future<void> bindClipboardSync(String sessionId) async {
    if (!_clipboardHandlerBound) {
      _clipboardHandlerBound = true;
      _clipboardBridgeChannel.setMethodCallHandler((MethodCall call) async {
        if (call.method != 'onClipboard') {
          return;
        }
        final text = call.arguments is String ? call.arguments as String : '';
        if (text.isEmpty) {
          return;
        }
        // 回调旁路执行，不阻塞会话状态链路。
        unawaited(_syncDeviceClipboardToWindows(text));
      });
    }
    await _clipboardBridgeChannel.invokeMethod<bool>('bindClipboardCallback', {
      'sessionId': sessionId,
    });
  }

  /// 解绑独立剪贴板同步通道。
  Future<void> unbindClipboardSync(String sessionId) async {
    await _clipboardBridgeChannel.invokeMethod<bool>(
      'unbindClipboardCallback',
      {'sessionId': sessionId},
    );
  }

  Future<SessionStats> getSessionStats(String sessionId) {
    return flutter_api.getSessionStats(sessionId: sessionId);
  }

  Future<void> setOrientationMode({
    required String sessionId,
    required OrientationMode mode,
  }) async {
    await flutter_api.setOrientationMode(sessionId: sessionId, mode: mode);
  }

  Future<void> requestIdr(String sessionId) async {
    await flutter_api.requestIdr(sessionId: sessionId);
  }

  /// 在同一个 sessionId 上重启运行时（不销毁会话对象）。
  Future<void> restartSession(String sessionId) async {
    await flutter_api.startSession(sessionId: sessionId);
  }
}
