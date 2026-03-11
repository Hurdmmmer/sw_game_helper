import 'dart:async';

import 'package:sw_game_helper/enums/connection_status.dart';
import 'package:sw_game_helper/models/device_info.dart';
import 'package:sw_game_helper/platforms/windows/bridge_generated/gh_common/model.dart';

/// 设备方向模式。
enum DeviceScreenOrientation { auto, portrait, landscape }

/// 解码模式选择。
enum DeviceDecoderMode { preferHardware, forceHardware, forceSoftware }

/// 设备服务抽象接口。
///
/// 负责统一封装“设备连接、输入转发、会话事件、会话统计”等能力。
abstract class DeviceService {
  final _statusController = StreamController<ConnectionStatus>.broadcast();

  AppDeviceInfo? _currentDevice;

  DeviceService() {
    // 初始化时默认处于未连接状态，避免上层一直处于 loading。
    _statusController.add(ConnectionStatus.disconnected);
  }

  /// 更新当前设备连接状态。
  void refreshDeviceStatus(ConnectionStatus status) {
    if (_currentDevice != null) {
      _currentDevice!.connectionStatus = status;
    }
    _statusController.add(status);
  }

  /// 扫描设备列表。
  Future<List<AppDeviceInfo>> scanDevices(String deviceType);

  /// 连接设备并启动会话。
  ///
  /// 参数说明：
  /// - [renderPipelineMode]：渲染管线模式；
  /// - [decoderMode]：解码器偏好；
  /// - [turnScreenOff]：连接后是否请求设备熄屏（投屏继续）。
  /// - [bitRate]：视频码率（单位 bps）；
  /// - [maxSize]：视频最大边界（scrcpy `--max-size`）；
  /// - [maxFps]：视频最大帧率（单位 FPS）。
  Future<bool> connectDevice(
    AppDeviceInfo device, {
    RenderPipelineMode renderPipelineMode = RenderPipelineMode.cpuPixelBufferV2,
    DeviceDecoderMode decoderMode = DeviceDecoderMode.preferHardware,
    bool turnScreenOff = false,
    int bitRate = 16000000,
    int maxSize = 0,
    int maxFps = 0,
  });

  /// 断开当前设备会话并清理资源。
  Future<void> disconnectDevice(AppDeviceInfo device);

  /// 设置当前设备方向模式。
  Future<void> setCurrentDeviceOrientation(DeviceScreenOrientation orientation);

  /// 发送触摸事件到设备。
  Future<void> sendTouchEvent(TouchEvent event);

  /// 发送按键事件到设备。
  ///
  /// 参数说明：
  /// - [keycode]：Android keycode；
  /// - [isDown]：true 为按下，false 为抬起。
  Future<void> sendKeyInput({required int keycode, required bool isDown});

  /// 发送文本输入到设备（适合中文、符号、输入法提交文本）。
  Future<void> sendTextInput(String text);

  /// 发送剪贴板文本到设备端。
  ///
  /// 参数说明：
  /// - [text]：要写入设备剪贴板的文本；
  /// - [paste]：是否在写入后立即触发设备端粘贴动作。
  Future<void> sendClipboardToDevice({
    required String text,
    required bool paste,
  });

  /// 发送滚动输入到设备。
  Future<void> sendScrollInput({
    required double x,
    required double y,
    required int width,
    required int height,
    required int hscroll,
    required int vscroll,
  });

  /// 设备连接状态流。
  Stream<ConnectionStatus> get connectionStatus => _statusController.stream;

  /// 当前连接的设备信息。
  AppDeviceInfo? get connectedDevice => _currentDevice;

  /// 当前会话 ID。
  String? get currentSessionId;

  /// 订阅会话事件流。
  Stream<SessionEvent> streamSessionEvents();

  /// 获取当前会话统计。
  Future<SessionStats?> getCurrentSessionStats();

  set currentDevice(AppDeviceInfo? device) {
    _currentDevice = device;
  }

  void clearCurrentDevice() {
    _currentDevice = null;
  }

  /// 释放服务资源。
  void dispose() {
    _statusController.close();
  }
}
