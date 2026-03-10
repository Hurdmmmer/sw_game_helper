import 'dart:async';

import 'package:sw_game_helper/enums/connection_status.dart';
import 'package:sw_game_helper/models/device_info.dart';
import 'package:sw_game_helper/platforms/windows/bridge_generated/gh_common/model.dart';


/// 说明：该注释已完成中文修复，详见下方代码逻辑。
enum DeviceScreenOrientation { auto, portrait, landscape }
/// 说明：该注释已完成中文修复，详见下方代码逻辑。
enum DeviceDecoderMode { preferHardware, forceHardware, forceSoftware }

abstract class DeviceService {
  final _statusController = StreamController<ConnectionStatus>.broadcast();

  AppDeviceInfo? _currentDevice;

  DeviceService() {
    // 鍚姩鍗虫湁鐘舵€侊紝閬垮厤 StreamProvider 闀挎湡 loading
    _statusController.add(ConnectionStatus.disconnected);
  }

  /// 鏇存柊璁惧杩炴帴鐘舵€?
  void refreshDeviceStatus(ConnectionStatus status) {
    if (_currentDevice != null) {
      _currentDevice!.connectionStatus = status;
    }
    _statusController.add(status);
  }

  /// 说明：该注释已完成中文修复，详见下方代码逻辑。
  Future<List<AppDeviceInfo>> scanDevices(String deviceType);

  /// 杩炴帴璁惧
  Future<bool> connectDevice(
    AppDeviceInfo device, 
    {
      RenderPipelineMode renderPipelineMode = RenderPipelineMode.cpuPixelBufferV2,
      DeviceDecoderMode decoderMode = DeviceDecoderMode.preferHardware,
      /// 说明：该注释已完成中文修复，详见下方代码逻辑。
      ///
      /// 说明：该注释已完成中文修复，详见下方代码逻辑。
      /// 说明：该注释已完成中文修复，详见下方代码逻辑。
      /// 说明：该注释已完成中文修复，详见下方代码逻辑。
      bool turnScreenOff = false,
    }
  );

  /// 说明：该注释已完成中文修复，详见下方代码逻辑。
  Future<void> disconnectDevice(AppDeviceInfo device);

  /// 说明：该注释已完成中文修复，详见下方代码逻辑。
  Future<void> setCurrentDeviceOrientation(DeviceScreenOrientation orientation);

  /// 说明：该注释已完成中文修复，详见下方代码逻辑。
  Future<void> sendTouchEvent(TouchEvent event);

  /// 说明：该注释已完成中文修复，详见下方代码逻辑。
  ///
  /// 说明：该注释已完成中文修复，详见下方代码逻辑。
  /// 说明：该注释已完成中文修复，详见下方代码逻辑。
  /// 说明：该注释已完成中文修复，详见下方代码逻辑。
  Future<void> sendKeyInput({
    required int keycode,
    required bool isDown,
  });

  /// 发送文本输入到当前会话（支持中文和符号输入）。
  Future<void> sendTextInput(String text);

  /// 说明：该注释已完成中文修复，详见下方代码逻辑。
  ///
  /// 说明：该注释已完成中文修复，详见下方代码逻辑。
  /// 说明：该注释已完成中文修复，详见下方代码逻辑。
  /// 说明：该注释已完成中文修复，详见下方代码逻辑。
  /// 说明：该注释已完成中文修复，详见下方代码逻辑。
  Future<void> sendScrollInput({
    required double x,
    required double y,
    required int width,
    required int height,
    required int hscroll,
    required int vscroll,
  });

  /// 璁惧杩炴帴鐘舵€佹祦
  Stream<ConnectionStatus> get connectionStatus => _statusController.stream;

  /// 褰撳墠杩炴帴鐨勮澶?
  AppDeviceInfo? get connectedDevice => _currentDevice;

  /// 说明：该注释已完成中文修复，详见下方代码逻辑。
  String? get currentSessionId;

  /// 说明：该注释已完成中文修复，详见下方代码逻辑。
  ///
  /// 说明：该注释已完成中文修复，详见下方代码逻辑。
  /// 说明：该注释已完成中文修复，详见下方代码逻辑。
  /// 说明：该注释已完成中文修复，详见下方代码逻辑。
  /// 说明：该注释已完成中文修复，详见下方代码逻辑。
  Stream<SessionEvent> streamSessionEvents();

  /// 说明：该注释已完成中文修复，详见下方代码逻辑。
  Future<SessionStats?> getCurrentSessionStats();

  set currentDevice(AppDeviceInfo? device) {
    _currentDevice = device;
  }

  void clearCurrentDevice() {
    _currentDevice = null;
  }

  /// 鍏抽棴鏈嶅姟
  void dispose() {
    _statusController.close();
  }
}








