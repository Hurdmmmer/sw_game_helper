import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sw_game_helper/platforms/windows/bridge_generated/rust_scrcpy_api.dart'
    as bridge;
import 'package:sw_game_helper/platforms/windows/bridge_generated/scrcpy/control.dart'
    as control;
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
    bridge.LogLevel maxLevel = bridge.LogLevel.info,
  }) async {
    await bridge.setupLogger(maxLevel: maxLevel);
  }

  /// 先列设备，再逐个补全详情（型号/版本）。
  Future<List<bridge.DeviceInfo>> listDevices() async {
    final devices = await bridge.listDevices(adbPath: ThirdPartyPaths.adb);
    if (devices.isEmpty) {
      return const <bridge.DeviceInfo>[];
    }

    final detailFutures = devices.map((device) async {
      try {
        return await bridge.getDeviceInfo(
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
    required bridge.RenderPipelineMode renderPipelineMode,
    required bridge.DecoderMode decoderMode,
    bool turnScreenOff = false,
  }) async {
    final base = bridge.SessionConfig(
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

    final config = bridge.SessionConfigV2(
      base: base,
      renderPipelineMode: renderPipelineMode,
      decoderMode: decoderMode,
    );

    final sessionId = await bridge.createSessionV2(config: config);
    await bridge.startSession(sessionId: sessionId);
    return sessionId;
  }

  /// 断开与设备的连接
  Future<void> disconnect(String sessionId) async {
    final sw = Stopwatch()..start();
    Log.i('disconnect start: session=$sessionId');
    try {
      await bridge.stopSession(sessionId: sessionId);
      Log.i('disconnect stop done: session=$sessionId cost=${sw.elapsedMilliseconds}ms');
    } catch (_) {
      Log.w('disconnect stop failed (ignored): session=$sessionId');
    }
    await bridge.disposeSession(sessionId: sessionId);
    Log.i('disconnect dispose done: session=$sessionId cost=${sw.elapsedMilliseconds}ms');
  }

  /// 发送触控事件到 Rust 当前会话。
  Future<void> sendTouch(
    String sessionId,
    control.TouchEvent event,
  ) async {
    await bridge.sendTouch(sessionId: sessionId, event: event);
  }

  /// 会话事件流（回调驱动，无轮询）。
  ///
  /// 数据路径：
  /// 1. Rust runtime 触发 `rs_register_session_event_callback` 回调；
  /// 2. Windows Runner 把事件转发到 `dxgi_texture_bridge.onSessionEvent`；
  /// 3. 这里解析 JSON，再按 sessionId 分发给订阅者。
  Stream<bridge.SessionEvent> streamSessionEvents(String sessionId) {
    _ensureSessionEventBridgeBound();
    return _sessionEventController.stream
        .where((item) => item.sessionId == sessionId)
        .map((item) => item.event);
  }

  Future<bridge.SessionStats> getSessionStats(String sessionId) {
    return bridge.getSessionStats(sessionId: sessionId);
  }

  Future<void> setOrientationMode({
    required String sessionId,
    required bridge.OrientationMode mode,
  }) async {
    await bridge.setOrientationMode(sessionId: sessionId, mode: mode);
  }

  Future<void> requestIdr(String sessionId) async {
    await bridge.requestIdr(sessionId: sessionId);
  }

  /// 在同一个 sessionId 上重启运行时（不销毁会话对象）。
  ///
  /// 适用于“运行时异常后的快速恢复”，可避免 create/dispose 带来的额外开销。
  Future<void> restartSession(String sessionId) async {
    await bridge.startSession(sessionId: sessionId);
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
  bridge.SessionEvent? _parseSessionEvent(String jsonText) {
    final decoded = jsonDecode(jsonText);
    if (decoded is String) {
      if (decoded == 'Starting') return const bridge.SessionEvent.starting();
      if (decoded == 'Running') return const bridge.SessionEvent.running();
      if (decoded == 'Reconnecting') {
        return const bridge.SessionEvent.reconnecting();
      }
      if (decoded == 'Stopped') return const bridge.SessionEvent.stopped();
      return null;
    }
    if (decoded is! Map) {
      return null;
    }
    if (decoded.containsKey('Error')) {
      final payload = decoded['Error'];
      if (payload is! Map) return null;
      return bridge.SessionEvent.error(
        code: _parseErrorCode(payload['code']?.toString()),
        message: payload['message']?.toString() ?? '',
      );
    }
    if (decoded.containsKey('OrientationChanged')) {
      final payload = decoded['OrientationChanged'];
      if (payload is! Map) return null;
      return bridge.SessionEvent.orientationChanged(
        mode: _parseOrientationMode(payload['mode']?.toString()),
        source: _parseOrientationSource(payload['source']?.toString()),
      );
    }
    if (decoded.containsKey('ResolutionChanged')) {
      final payload = decoded['ResolutionChanged'];
      if (payload is! Map) return null;
      return bridge.SessionEvent.resolutionChanged(
        width: _toInt(payload['width']),
        height: _toInt(payload['height']),
        newHandle: _toInt(payload['new_handle']),
        generation: BigInt.from(_toInt(payload['generation'])),
      );
    }
    return null;
  }

  bridge.ErrorCode _parseErrorCode(String? text) {
    return switch (text) {
      'InvalidSession' => bridge.ErrorCode.invalidSession,
      'AlreadyRunning' => bridge.ErrorCode.alreadyRunning,
      'NotRunning' => bridge.ErrorCode.notRunning,
      'DeviceDisconnected' => bridge.ErrorCode.deviceDisconnected,
      'DecodeFailed' => bridge.ErrorCode.decodeFailed,
      'TextureFailed' => bridge.ErrorCode.textureFailed,
      'ControlFailed' => bridge.ErrorCode.controlFailed,
      _ => bridge.ErrorCode.internal,
    };
  }

  bridge.OrientationMode _parseOrientationMode(String? text) {
    return switch (text) {
      'Portrait' => bridge.OrientationMode.portrait,
      'Landscape' => bridge.OrientationMode.landscape,
      _ => bridge.OrientationMode.auto,
    };
  }

  bridge.OrientationChangeSource _parseOrientationSource(String? text) {
    return switch (text) {
      'ManualApi' => bridge.OrientationChangeSource.manualApi,
      _ => bridge.OrientationChangeSource.autoSensor,
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
  final bridge.SessionEvent event;

  const _SessionEventEnvelope({required this.sessionId, required this.event});
}
