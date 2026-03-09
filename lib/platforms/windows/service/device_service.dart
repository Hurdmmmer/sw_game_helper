import 'dart:async';

import 'package:sw_game_helper/enums/connection_status.dart';
import 'package:sw_game_helper/models/device_info.dart';
import 'package:sw_game_helper/platforms/windows/bridge_generated/gh_common/model.dart';


/// 屏幕方向枚举
enum DeviceScreenOrientation { auto, portrait, landscape }
/// 解码方式枚举
enum DeviceDecoderMode { preferHardware, forceHardware, forceSoftware }

abstract class DeviceService {
  final _statusController = StreamController<ConnectionStatus>.broadcast();

  AppDeviceInfo? _currentDevice;

  DeviceService() {
    // 启动即有状态，避免 StreamProvider 长期 loading
    _statusController.add(ConnectionStatus.disconnected);
  }

  /// 更新设备连接状态
  void refreshDeviceStatus(ConnectionStatus status) {
    if (_currentDevice != null) {
      _currentDevice!.connectionStatus = status;
    }
    _statusController.add(status);
  }

  /// 扫描设备
  Future<List<AppDeviceInfo>> scanDevices(String deviceType);

  /// 连接设备
  Future<bool> connectDevice(
    AppDeviceInfo device, 
    {
      RenderPipelineMode renderPipelineMode = RenderPipelineMode.cpuPixelBufferV2,
      DeviceDecoderMode decoderMode = DeviceDecoderMode.preferHardware,
      /// 是否在会话建链成功后请求设备熄屏。
      ///
      /// 语义约定：
      /// - `true`：请求熄屏（适合后台投屏/挂机）；
      /// - `false`：保持默认亮屏行为。
      bool turnScreenOff = false,
    }
  );

  /// 断开设备连接
  Future<void> disconnectDevice(AppDeviceInfo device);

  /// 切换当前会话设备的屏幕方向
  Future<void> setCurrentDeviceOrientation(DeviceScreenOrientation orientation);

  /// 发送触控事件到当前会话。
  Future<void> sendTouchEvent(TouchEvent event);

  /// 设备连接状态流
  Stream<ConnectionStatus> get connectionStatus => _statusController.stream;

  /// 当前连接的设备
  AppDeviceInfo? get connectedDevice => _currentDevice;

  /// 当前设备对应的 Rust 会话 ID
  String? get currentSessionId;

  /// 当前会话的状态事件流（运行/停止/错误/分辨率变化）。
  ///
  /// 说明（当前架构）：
  /// 1. 视频帧刷新由 Rust->Runner 回调驱动；
  /// 2. 会话事件同样由 Rust 回调推送到 Dart，不再轮询；
  /// 3. 该流仍保留为 UI 统一订阅入口。
  Stream<SessionEvent> streamSessionEvents();

  /// 拉取当前会话统计（未连接时返回 null）。
  Future<SessionStats?> getCurrentSessionStats();

  set currentDevice(AppDeviceInfo? device) {
    _currentDevice = device;
  }

  void clearCurrentDevice() {
    _currentDevice = null;
  }

  /// 关闭服务
  void dispose() {
    _statusController.close();
  }
}






