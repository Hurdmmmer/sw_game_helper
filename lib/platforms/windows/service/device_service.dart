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

    // 当设备断开连接时，清空当前设备引用
    if (status == ConnectionStatus.disconnected) {
      _currentDevice = null;
    }
  }

  /// 扫描全部设备列表（USB + Wi-Fi）。
  Future<List<AppDeviceInfo>> scanDevices();

  /// 连接设备并启动会话。
  Future<bool> connectDevice(AppDeviceInfo device);

  /// 断开当前设备会话并清理资源。
  Future<void> disconnectDevice(AppDeviceInfo? device);

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
  Stream<ConnectionStatus> get currentConnectStatus => _statusController.stream;

  /// 当前连接的设备信息。
  AppDeviceInfo? get connectedDevice => _currentDevice;

  /// 当前会话 ID。
  String? get currentSessionId;

  /// 订阅会话事件流。
  Stream<SessionEvent> streamSessionEvents();

  /// 获取当前会话统计。
  Future<SessionStats?> getCurrentSessionStats();

  /// 配置 YOLO 模型与推理参数（模型路径由 Flutter 传入）。
  ///
  /// 参数说明：
  /// - [modelPath]：ONNX 模型绝对路径；
  /// - [inputWidth]/[inputHeight]：网络输入尺寸；
  /// - [confidenceThreshold]：置信度阈值；
  /// - [iouThreshold]：NMS IoU 阈值；
  /// - [maxDetections]：单帧最多检测框；
  /// - [provider]：推理后端；
  /// - [deviceIndex]：可选设备索引；
  /// - [maxInferFps]：推理限频；
  /// - [enableAfterConfig]：配置后是否立即启用。
  Future<void> configureYoloModel({
    required String modelPath,
    int inputWidth = 640,
    int inputHeight = 640,
    double confidenceThreshold = 0.50,
    double iouThreshold = 0.45,
    int maxDetections = 100,
    YoloExecutionProvider provider = YoloExecutionProvider.directMl,
    int? deviceIndex,
    int maxInferFps = 15,
    bool enableAfterConfig = true,
  });

  /// 设置当前会话 YOLO 开关。
  Future<void> setYoloEnabled(bool enabled);

  /// 订阅 YOLO 推理结果流。
  Stream<YoloFrameResult> streamYoloResults();

  /// 当前缓存的 YOLO 配置（用于设置页回显）。
  YoloConfig? get currentYoloConfig;

  /// 当前 YOLO 启用状态。
  bool get yoloEnabled;

  set currentDevice(AppDeviceInfo? device) {
    _currentDevice = device;
  }

  /// 释放服务资源。
  void dispose() {
    _statusController.close();
  }
}
