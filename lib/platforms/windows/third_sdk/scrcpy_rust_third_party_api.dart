import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show MethodCall, MethodChannel;
import 'package:sw_game_helper/platforms/windows/bridge_generated/gh_common/model.dart';
import 'package:sw_game_helper/platforms/windows/bridge_generated/gh_api/flutter_api.dart' as flutter_api;

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
  static const MethodChannel _dxgiBridgeChannel =
      MethodChannel('dxgi_texture_bridge');

  /// 会话事件总线（Rust 回调 -> Runner -> MethodChannel -> Dart）。
  final StreamController<_SessionEventEnvelope> _sessionEventController =
      StreamController<_SessionEventEnvelope>.broadcast();
  bool _sessionEventBridgeBound = false;

  /// 初始化 Rust DLL 日志级别（仅首次调用生效，后续调用会被 Rust 侧忽略）。
  ///
  /// 使用方式：
  /// `await ScrcpyRustThirdPartyApi.instance.initLogger(maxLevel: bridge.LogLevel.info);`
  Future<void> initLogger({
    LogLevel maxLevel = LogLevel.info,
  }) async {
    await flutter_api.setupLogger(maxLevel: maxLevel);
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
  ///
  /// - `original`: 原共享句柄链路。
  /// - `turnScreenOff`:
  ///   - `true`：会话启动后请求设备熄屏（适合挂机/后台投屏场景）；
  ///   - `false`：保持默认亮屏行为，不主动修改设备电源状态。
  ///
  /// 说明：
  /// - 该参数会透传到 Rust `SessionConfig.turnScreenOff`；
  /// - Rust 侧会在建链完成后执行“最佳努力”熄屏，不会因为熄屏失败而中断会话。
  Future<String> connectV2({
    required String deviceId,
    required RenderPipelineMode renderPipelineMode,
    required DecoderMode decoderMode,
    bool turnScreenOff = false,
  }) async {
    final base = SessionConfig(
      adbPath: ThirdPartyPaths.adb,
      serverPath: ThirdPartyPaths.scrcpyServer,
      deviceId: deviceId,
      maxSize: 0,
      bitRate: 16000000,
      maxFps: 0,
      videoPort: 27183,
      controlPort: 27184,
      videoEncoder: null,
      // 关键透传：由调用方决定是否在建链完成后请求熄屏。
      turnScreenOff: turnScreenOff,
      stayAwake: false,
      scrcpyVerbosity: 'info',
      // 默认先走 1 秒关键帧周期，兼顾恢复速度。
      // 如果某些机型不兼容，可在后续策略中回退到 0。
      intraRefreshPeriod: 1
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

  /// 断开与设备的连接
  Future<void> disconnect(String sessionId) async {
    final sw = Stopwatch()..start();
    Log.i('disconnect start: session=$sessionId');
    try {
      await flutter_api.stopSession(sessionId: sessionId);
      Log.i('disconnect stop done: session=$sessionId cost=${sw.elapsedMilliseconds}ms');
    } catch (_) {
      Log.w('disconnect stop failed (ignored): session=$sessionId');
    }
    await flutter_api.disposeSession(sessionId: sessionId);
    Log.i('disconnect dispose done: session=$sessionId cost=${sw.elapsedMilliseconds}ms');
  }

  /// 发送触控事件到 Rust 当前会话。
  Future<void> sendTouch(
    String sessionId,
    TouchEvent event,
  ) async {
    await flutter_api.sendTouch(sessionId: sessionId, event: event);
  }


  Future<void> sendKey(
    String sessionId,
    KeyEvent event,
  ) async {
    await flutter_api.sendKey(sessionId: sessionId, event: event);
  }

  /// 发送文本输入到当前会话。
  /// 该接口用于中文输入法和符号输入，优先于 keycode 模式。
  Future<void> sendText(
    String sessionId,
    String text,
  ) async {
    if (text.isEmpty) {
      return;
    }
    await flutter_api.sendText(sessionId: sessionId, text: text);
  }


  Future<void> sendScroll(
    String sessionId,
    ScrollEvent event,
  ) async {
    await flutter_api.sendScroll(sessionId: sessionId, event: event);
  }

 
  Stream<SessionEvent> streamSessionEvents(String sessionId) {
    _ensureSessionEventBridgeBound();
    return _sessionEventController.stream
        .where((item) => item.sessionId == sessionId)
        .map((item) => item.event);
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
  ///
  /// 适用于“运行时异常后的快速恢复”，可避免 create/dispose 带来的额外开销。
  Future<void> restartSession(String sessionId) async {
    await flutter_api.startSession(sessionId: sessionId);
  }

  /// 只初始化一次：注册 MethodChannel 回调 + 通知 Runner 绑定 Rust 回调。
  void _ensureSessionEventBridgeBound() {
    if (_sessionEventBridgeBound) {
      return;
    }
    _sessionEventBridgeBound = true;
    _dxgiBridgeChannel.setMethodCallHandler(_handleBridgeCallback);
    unawaited(
      _dxgiBridgeChannel.invokeMethod<bool>('bindSessionEvents').catchError((
        Object e,
        StackTrace st,
      ) {
        Log.w('绑定 SessionEvent 回调失败: $e');
        Log.e('绑定 SessionEvent 回调异常堆栈', e, st);
        return false;
      }),
    );
  }

  /// 处理 Runner -> Dart 的回调消息。
  Future<dynamic> _handleBridgeCallback(MethodCall call) async {
    if (call.method != 'onSessionEvent') {
      return null;
    }
    final args = call.arguments;
    if (args is! Map) {
      return null;
    }

    final sessionId = args['sessionId']?.toString();
    final eventJson = args['eventJson']?.toString();
    if (sessionId == null || sessionId.isEmpty || eventJson == null) {
      return null;
    }

    try {
      final event = _parseSessionEvent(eventJson);
      if (event != null && !_sessionEventController.isClosed) {
        _sessionEventController.add(
          _SessionEventEnvelope(sessionId: sessionId, event: event),
        );
      }
    } catch (e, st) {
      Log.w('解析 SessionEvent 回调失败: $e');
      Log.e('解析 SessionEvent 回调异常堆栈', e, st);
    }
    return null;
  }

  /// 将 Rust 侧 JSON 事件解码为 FRB 生成的 `SessionEvent`。
  SessionEvent? _parseSessionEvent(String jsonText) {
    final decoded = jsonDecode(jsonText);
    if (decoded is String) {
      if (decoded == 'Starting') return const SessionEvent.starting();
      if (decoded == 'Running') return const SessionEvent.running();
      if (decoded == 'Reconnecting') {
        return const SessionEvent.reconnecting();
      }
      if (decoded == 'Stopped') return const SessionEvent.stopped();
      return null;
    }
    if (decoded is! Map) {
      return null;
    }
    if (decoded.containsKey('Error')) {
      final payload = decoded['Error'];
      if (payload is! Map) return null;
      return SessionEvent.error(
        code: _parseErrorCode(payload['code']?.toString()),
        message: payload['message']?.toString() ?? '',
      );
    }
    if (decoded.containsKey('OrientationChanged')) {
      final payload = decoded['OrientationChanged'];
      if (payload is! Map) return null;
      return SessionEvent.orientationChanged(
        mode: _parseOrientationMode(payload['mode']?.toString()),
        source: _parseOrientationSource(payload['source']?.toString()),
      );
    }
    if (decoded.containsKey('ResolutionChanged')) {
      final payload = decoded['ResolutionChanged'];
      if (payload is! Map) return null;
      return SessionEvent.resolutionChanged(
        width: _toInt(payload['width']),
        height: _toInt(payload['height']),
        newHandle: _toInt(payload['new_handle']),
        generation: BigInt.from(_toInt(payload['generation'])),
      );
    }
    return null;
  }

  ErrorCode _parseErrorCode(String? text) {
    return switch (text) {
      'InvalidSession' => ErrorCode.invalidSession,
      'AlreadyRunning' => ErrorCode.alreadyRunning,
      'NotRunning' => ErrorCode.notRunning,
      'DeviceDisconnected' => ErrorCode.deviceDisconnected,
      'DecodeFailed' => ErrorCode.decodeFailed,
      'TextureFailed' => ErrorCode.textureFailed,
      'ControlFailed' => ErrorCode.controlFailed,
      _ => ErrorCode.internal,
    };
  }

  OrientationMode _parseOrientationMode(String? text) {
    return switch (text) {
      'Portrait' => OrientationMode.portrait,
      'Landscape' => OrientationMode.landscape,
      _ => OrientationMode.auto,
    };
  }

  OrientationChangeSource _parseOrientationSource(String? text) {
    return switch (text) {
      'ManualApi' => OrientationChangeSource.manualApi,
      _ => OrientationChangeSource.autoSensor,
    };
  }

  int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

/// 事件分发内部结构：保留 sessionId 方便做单会话过滤。
class _SessionEventEnvelope {
  final String sessionId;
  final SessionEvent event;

  const _SessionEventEnvelope({required this.sessionId, required this.event});
}


