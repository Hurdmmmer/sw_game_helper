import 'dart:async';

import 'package:sw_game_helper/enums/connection_mode.dart';
import 'package:sw_game_helper/enums/connection_status.dart';
import 'package:sw_game_helper/models/device_info.dart';
import 'package:sw_game_helper/platforms/windows/bridge_generated/gh_common/model.dart';

import 'package:sw_game_helper/platforms/windows/service/device_service.dart';
import 'package:sw_game_helper/platforms/windows/third_sdk/scrcpy_rust_third_party_api.dart';
import 'package:sw_game_helper/utils/logger_service.dart';

class DeviceServiceImpl extends DeviceService {
  /// 设备 ID -> 会话 ID 映射（当前实现按设备最多一个活动会话）。
  final Map<String, String> _connectedSessions = {};

  /// 自动重连最大重试次数。
  static const int _maxAutoReconnectAttempts = 3;

  /// 自动重连基础退避时长（线性递增）。
  static const Duration _autoReconnectBaseDelay = Duration(milliseconds: 180);

  /// 会话事件广播流（运行态、错误、分辨率变化等）。
  final StreamController<SessionEvent> _sessionEventController =
      StreamController<SessionEvent>.broadcast();

  /// 会话事件订阅（统一由该订阅驱动上层状态）。
  StreamSubscription<SessionEvent>? _eventSub;

  /// 手动断开标志：避免断开期间触发自动重连。
  bool _manualDisconnecting = false;

  /// 自动重连互斥标志：防止并发重连流程重入。
  bool _autoReconnecting = false;

  /// Service 生命周期终止标志。
  bool _disposed = false;

  /// 全局会话 epoch 递增值（每次新建会话递增）。
  int _sessionEpoch = 0;

  /// 当前活动会话 epoch（用于丢弃旧会话回调）。
  int _activeSessionEpoch = 0;

  /// 最近一次连接设备（自动重连时复用）。
  AppDeviceInfo? _lastConnectDevice;

  /// 最近一次渲染管线模式（自动重连时复用）。
  RenderPipelineMode _lastRenderPipelineMode = RenderPipelineMode.original;

  /// 最近一次解码模式（自动重连时复用）。
  DeviceDecoderMode _lastDecoderMode = DeviceDecoderMode.forceSoftware;

  /// 最近一次“连接后是否熄屏”配置（自动重连时复用）。
  bool _lastTurnScreenOff = false;

  /// 解绑所有会话流订阅。
  ///
  /// 注意：纹理轮询流已被移除，这里仅保留事件流解绑。
  Future<void> _unbindSessionStreams() async {
    await _eventSub?.cancel();
    _eventSub = null;
  }


  /// 防止旧会话异步回调（尤其是重连后）污染当前 UI 状态。
  bool _isSessionActive(String sessionId, int epoch) {
    if (_disposed) {
      return false;
    }
    if (epoch != _activeSessionEpoch) {
      return false;
    }
    final current = connectedDevice;
    if (current == null) {
      return false;
    }
    return _connectedSessions[current.deviceId] == sessionId;
  }

  Future<void> _bindSessionStreams(String sessionId, int epoch) async {
    await _unbindSessionStreams();
    // 统一帧驱动架构：V1/V2 都由 Rust->Runner 回调触发渲染，
    // DeviceService 不再订阅 Dart 侧纹理轮询流。

    _eventSub = ScrcpyRustThirdPartyApi.instance
        .streamSessionEvents(sessionId)
        .listen(
          (event) {
            if (!_isSessionActive(sessionId, epoch)) {
              Log.d(
                '[SessionRouter] ignore stale event: session=$sessionId epoch=$epoch active=$_activeSessionEpoch',
              );
              return;
            }
            _routeSessionEvent(
              sessionId: sessionId,
              epoch: epoch,
              event: event,
            );
          },
          onError: (Object e, StackTrace st) {
            _handleSessionStreamError(
              sessionId: sessionId,
              epoch: epoch,
              error: e,
              stackTrace: st,
            );
          },
        );
  }

  /// 会话事件统一路由：同一入口负责分发、状态更新和重连触发。
  void _routeSessionEvent({
    required String sessionId,
    required int epoch,
    required SessionEvent event,
  }) {
    _sessionEventController.add(event);
    event.when(
      starting: () => refreshDeviceStatus(ConnectionStatus.connecting),
      running: () => refreshDeviceStatus(ConnectionStatus.connected),
      reconnecting: () {
        Log.w(
          '[SessionRouter] reconnecting event: session=$sessionId epoch=$epoch',
        );
        refreshDeviceStatus(ConnectionStatus.connecting);
        unawaited(
          _tryAutoReconnect(
            sessionId: sessionId,
            epoch: epoch,
            reason: 'runtime_reconnecting_event',
          ),
        );
      },
      stopped: () => refreshDeviceStatus(ConnectionStatus.disconnected),
      error: (code, message) {
        Log.w('Session error: code=$code message=$message');
        refreshDeviceStatus(ConnectionStatus.disconnected);
      },
      orientationChanged: (mode, source) {
        Log.i('Orientation changed: mode=$mode source=$source');
      },
      resolutionChanged: (width, height, newHandle, generation) {
        Log.d(
          'Resolution changed: ${width}x$height handle=${newHandle.toInt()} gen=$generation',
        );
      },
    );
  }

  /// 会话事件流异常统一处理。
  void _handleSessionStreamError({
    required String sessionId,
    required int epoch,
    required Object error,
    required StackTrace stackTrace,
  }) {
    Log.e('Session event stream error: $error', error, stackTrace);
    unawaited(
      _tryAutoReconnect(
        sessionId: sessionId,
        epoch: epoch,
        reason: 'session_event_stream_error',
      ),
    );
  }

  Future<bool> _connectSession(
    AppDeviceInfo device, {
    required RenderPipelineMode renderPipelineMode,
    required DeviceDecoderMode decoderMode,
    required bool turnScreenOff,
    required bool replaceExisting,
  }) async {
    final existingSessionId = _connectedSessions[device.deviceId];
    if (!replaceExisting &&
        existingSessionId != null &&
        existingSessionId.isNotEmpty) {
      currentDevice = device;
      _lastConnectDevice = device;
      _lastRenderPipelineMode = renderPipelineMode;
      _lastDecoderMode = decoderMode;
      _lastTurnScreenOff = turnScreenOff;
      return true;
    }

    if (replaceExisting && existingSessionId != null && existingSessionId.isNotEmpty) {
      try {
        await ScrcpyRustThirdPartyApi.instance.disconnect(existingSessionId);
      } catch (e, st) {
        Log.w(
          'Force disconnect previous session failed($existingSessionId): $e',
        );
        Log.e('Force disconnect previous session stack', e, st);
      } finally {
        _connectedSessions.remove(device.deviceId);
      }
    }

    final sessionId = await ScrcpyRustThirdPartyApi.instance.connectV2(
      deviceId: device.deviceId,
      renderPipelineMode: _toBridgeRenderPipelineMode(renderPipelineMode),
      decoderMode: _toBridgeDecoderMode(decoderMode),
      // 关键透传：把 UI 的熄屏开关传到 Rust，会话建链后再执行设备熄屏请求。
      turnScreenOff: turnScreenOff,
    );

    _sessionEpoch += 1;
    _activeSessionEpoch = _sessionEpoch;
    await _bindSessionStreams(sessionId, _activeSessionEpoch);
    _connectedSessions[device.deviceId] = sessionId;
    currentDevice = device;
    _lastConnectDevice = device;
    _lastRenderPipelineMode = renderPipelineMode;
    _lastDecoderMode = decoderMode;
    _lastTurnScreenOff = turnScreenOff;
    return true;
  }

  Future<void> _tryAutoReconnect({
    required String sessionId,
    required int epoch,
    required String reason,
  }) async {
    if (_disposed || _manualDisconnecting || _autoReconnecting) {
      return;
    }
    final device = _lastConnectDevice;
    if (device == null) {
      return;
    }
    if (!_isSessionActive(sessionId, epoch)) {
      return;
    }
    if (_lastDecoderMode == DeviceDecoderMode.forceSoftware) {
      // 仅硬解模式启用自动重连，软解路径维持现状，避免引入不必要扰动。
      return;
    }

    _autoReconnecting = true;
    try {
      Log.w(
        '[重连] 开始: device=${device.deviceId} reason=$reason session=$sessionId epoch=$epoch',
      );
      for (var attempt = 1; attempt <= _maxAutoReconnectAttempts; attempt++) {
        if (_disposed || _manualDisconnecting) {
          return;
        }
        final delayMs = _autoReconnectBaseDelay.inMilliseconds * attempt;
        await Future<void>.delayed(Duration(milliseconds: delayMs));
        if (_disposed || _manualDisconnecting) {
          return;
        }
        if (!_isSessionActive(sessionId, epoch)) {
          return;
        }
        // 第一优先级：同 session 快速重启，避免全量重建。
        try {
          await ScrcpyRustThirdPartyApi.instance.restartSession(sessionId);
          refreshDeviceStatus(ConnectionStatus.connected);
          Log.i(
            '[重连] 快速重启成功: device=${device.deviceId} attempt=$attempt session=$sessionId',
          );
          return;
        } catch (e, st) {
          Log.w(
            '[重连] 快速重启失败，转全量重连: device=${device.deviceId} attempt=$attempt/$_maxAutoReconnectAttempts reason=$reason error=$e',
          );
          Log.e('[重连] 快速重启异常堆栈', e, st);
        }
        // 第二优先级：全量重连（create/start + 重绑事件流）。
        try {
          await _connectSession(
            device,
            renderPipelineMode: _lastRenderPipelineMode,
            decoderMode: _lastDecoderMode,
            turnScreenOff: _lastTurnScreenOff,
            replaceExisting: true,
          );
          refreshDeviceStatus(ConnectionStatus.connected);
          Log.i(
            '[重连] 全量重连成功: device=${device.deviceId} attempt=$attempt new_session=${_connectedSessions[device.deviceId]} old_session=$sessionId',
          );
          return;
        } catch (fullErr, fullSt) {
          Log.w(
            '[重连] 全量重连失败: device=${device.deviceId} attempt=$attempt/$_maxAutoReconnectAttempts error=$fullErr',
          );
          Log.e('[重连] 全量重连异常堆栈', fullErr, fullSt);
        }
      }
      Log.e(
        '[重连] 失败并放弃: device=${device.deviceId} max_attempts=$_maxAutoReconnectAttempts reason=$reason',
      );
      refreshDeviceStatus(ConnectionStatus.disconnected);
    } finally {
      _autoReconnecting = false;
    }
  }

  static bool _isUnknown(String value) {
    final text = value.trim();
    return text.isEmpty || text.toLowerCase() == 'unknown';
  }

  static String _displayName(DeviceInfo info) {
    if (!_isUnknown(info.model)) {
      return _capitalize(info.model);
    }
    return info.deviceId;
  }

  static String _capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  /// 判断是不是 USB 或者 WIFI 连接
  static ConnectionMode _modeOf(DeviceInfo info) {
    final ip = info.ip?.trim() ?? '';
    return ip.isEmpty ? ConnectionMode.usb : ConnectionMode.wifi;
  }

  static RenderPipelineMode _toBridgeRenderPipelineMode(RenderPipelineMode mode,) {
    return switch (mode) {
      RenderPipelineMode.original => RenderPipelineMode.original,
      RenderPipelineMode.cpuPixelBufferV2 => RenderPipelineMode.cpuPixelBufferV2,
    };
  }

  /// 将 [DeviceDecoderMode] 转换为 Rust 侧的 [DecoderMode]。
  /// 注意： 
  /// - Rust 侧解码器模式与 Flutter 侧枚举值不同，需转换。
  static DecoderMode _toBridgeDecoderMode(DeviceDecoderMode mode) {
    return switch (mode) {
      DeviceDecoderMode.preferHardware => DecoderMode.preferHardware,
      DeviceDecoderMode.forceHardware => DecoderMode.forceHardware,
      DeviceDecoderMode.forceSoftware => DecoderMode.forceSoftware,
    };
  }

  @override
  Future<List<AppDeviceInfo>> scanDevices(String deviceType) async {
    try {
      final rustDevices = await ScrcpyRustThirdPartyApi.instance.listDevices();
      final targetMode = ConnectionMode.fromCode(deviceType);

      return rustDevices.where((d) => _modeOf(d) == targetMode).map((d) {
        final ip = d.ip?.trim();
        return AppDeviceInfo(
          name: _displayName(d),
          deviceId: d.deviceId,
          connectionMode: _modeOf(d),
          connectionStatus: ConnectionStatus.disconnected,
          ipAddress: (ip == null || ip.isEmpty) ? null : ip,
          androidVersion: _isUnknown(d.androidVersion)
              ? null
              : d.androidVersion,
          screenWidth: d.width > 0 ? d.width : null,
          screenHeight: d.height > 0 ? d.height : null,
        );
      }).toList();
    } catch (e, st) {
      Log.e('Scan devices failed: $e', e, st);
      return const <AppDeviceInfo>[];
    }
  }

  @override
  Future<bool> connectDevice(
    AppDeviceInfo device, {
    RenderPipelineMode renderPipelineMode = RenderPipelineMode.cpuPixelBufferV2,
    DeviceDecoderMode decoderMode = DeviceDecoderMode.forceSoftware,
    bool turnScreenOff = false,
  }) async {
    try {
      Log.i(
        'Connect request: device=${device.deviceId}, render=$renderPipelineMode, decoder=$decoderMode, turnScreenOff=$turnScreenOff',
      );
      refreshDeviceStatus(ConnectionStatus.connecting);
      final ok = await _connectSession(
        device,
        renderPipelineMode: renderPipelineMode,
        decoderMode: decoderMode,
        turnScreenOff: turnScreenOff,
        replaceExisting: false,
      );
      if (ok) {
        refreshDeviceStatus(ConnectionStatus.connected);
      }
      return ok;
    } catch (e, st) {
      Log.e('Connect device failed(${device.deviceId}): $e', e, st);
      refreshDeviceStatus(ConnectionStatus.disconnected);
      return false;
    }
  }

  @override
  Future<void> disconnectDevice(AppDeviceInfo device) async {
    _manualDisconnecting = true;
    final sw = Stopwatch()..start();
    final connected = connectedDevice;
    final fallbackDeviceId = connected?.deviceId;
    String? sessionId = _connectedSessions.remove(device.deviceId);
    sessionId ??= currentSessionId;
    if (sessionId == null || sessionId.isEmpty) {
      Log.w(
        'Disconnect skipped: no active session for device=${device.deviceId}, '
        'connected=${fallbackDeviceId ?? "none"}',
      );
      await _unbindSessionStreams();
      Log.i(
        'Disconnect unbind done(no session): cost=${sw.elapsedMilliseconds}ms',
      );
      clearCurrentDevice();
      refreshDeviceStatus(ConnectionStatus.disconnected);
      _manualDisconnecting = false;
      return;
    }

    Log.i('Disconnect start: device=${device.deviceId}, session=$sessionId');
    // 先切断 UI 连接态，确保 VideoView 立即显示“未连接设备”并清理纹理。
    refreshDeviceStatus(ConnectionStatus.disconnected);
    clearCurrentDevice();
    await _unbindSessionStreams();
    Log.i(
      'Disconnect unbind done: session=$sessionId cost=${sw.elapsedMilliseconds}ms',
    );

    try {
      await ScrcpyRustThirdPartyApi.instance.disconnect(sessionId);
      Log.i(
        'Disconnect dispose done: session=$sessionId cost=${sw.elapsedMilliseconds}ms',
      );
    } catch (e, st) {
      Log.e('Disconnect device failed(${device.deviceId}): $e', e, st);
    } finally {
      if (fallbackDeviceId != null) {
        _connectedSessions.remove(fallbackDeviceId);
      }
      _activeSessionEpoch = -1;
      refreshDeviceStatus(ConnectionStatus.disconnected);
      _manualDisconnecting = false;
    }
  }

  @override
  Future<void> sendTouchEvent(TouchEvent event) async {
    final sessionId = currentSessionId;
    if (sessionId == null || sessionId.isEmpty) {
      return;
    }
    await ScrcpyRustThirdPartyApi.instance.sendTouch(sessionId, event);
  }

  @override
  Future<void> sendKeyInput({
    required int keycode,
    required bool isDown,
  }) async {
    final sessionId = currentSessionId;
    if (sessionId == null || sessionId.isEmpty) {
      return;
    }

    // 按键事件
    final event = KeyEvent(
      action: isDown ? AndroidKeyEventAction.down : AndroidKeyEventAction.up,
      keycode: keycode,
      repeat: 0,
      metastate: 0,
    );
    await ScrcpyRustThirdPartyApi.instance.sendKey(sessionId, event);
  }

  @override
  Future<void> sendTextInput(String text) async {
    final sessionId = currentSessionId;
    if (sessionId == null || sessionId.isEmpty) {
      return;
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    // 文本输入通道：用于中文输入法提交文本和符号输入。
    await ScrcpyRustThirdPartyApi.instance.sendText(sessionId, trimmed);
  }

  @override
  Future<void> sendClipboardToDevice({
    required String text,
    required bool paste,
  }) async {
    final sessionId = currentSessionId;
    if (sessionId == null || sessionId.isEmpty) {
      return;
    }
    if (text.isEmpty) {
      return;
    }

    // 调用 scrcpy SetClipboard 控制协议，把 Windows 剪贴板写入设备。
    await ScrcpyRustThirdPartyApi.instance.setClipboard(
      sessionId: sessionId,
      text: text,
      paste: paste,
    );
  }

  @override
  Future<void> sendScrollInput({
    required double x,
    required double y,
    required int width,
    required int height,
    required int hscroll,
    required int vscroll,
  }) async {
    final sessionId = currentSessionId;
    if (sessionId == null || sessionId.isEmpty) {
      return;
    }

    // 滚动事件
    final event = ScrollEvent(
      x: x,
      y: y,
      width: width,
      height: height,
      hscroll: hscroll,
      vscroll: vscroll,
    );
    await ScrcpyRustThirdPartyApi.instance.sendScroll(sessionId, event);
  }

  @override
  String? get currentSessionId {
    final device = connectedDevice;
    if (device == null) {
      return null;
    }
    return _connectedSessions[device.deviceId];
  }

  @override
  Future<void> setCurrentDeviceOrientation(
    DeviceScreenOrientation orientation,
  ) async {
    final sessionId = currentSessionId;
    if (sessionId == null || sessionId.isEmpty) {
      return;
    }

    final mode = switch (orientation) {
      DeviceScreenOrientation.auto => OrientationMode.auto,
      DeviceScreenOrientation.portrait => OrientationMode.portrait,
      DeviceScreenOrientation.landscape => OrientationMode.landscape,
    };

    await ScrcpyRustThirdPartyApi.instance.setOrientationMode(
      sessionId: sessionId,
      mode: mode,
    );
  }

  @override
  /// 会话事件统一出口（提供给 VideoView/VideoViewV2 订阅）。
  ///
  /// 注意：
  /// - 该流与“帧刷新”无关，仅承载状态与分辨率变更；
  /// - 帧刷新由 Rust->Runner 回调直接触发。
  Stream<SessionEvent> streamSessionEvents() =>
      _sessionEventController.stream;

  @override
  Future<SessionStats?> getCurrentSessionStats() async {
    final sessionId = currentSessionId;
    if (sessionId == null || sessionId.isEmpty) {
      return null;
    }
    return ScrcpyRustThirdPartyApi.instance.getSessionStats(sessionId);
  }

  @override
  void dispose() {
    _disposed = true;
    _unbindSessionStreams();
    _sessionEventController.close();
    super.dispose();
  }
}

