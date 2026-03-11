import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sw_game_helper/platforms/windows/service/device_service.dart';
import 'package:sw_game_helper/platforms/windows/service/device_service_impl.dart';
import 'package:sw_game_helper/enums/connection_status.dart';
import 'package:sw_game_helper/models/device_info.dart';

// 设备服务提供器，类似于 Spring 的 Bean 管理
final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceServiceImpl();
});

/// 设备列表提供器，用于获取已连接设备列表，
/// 该提供器会在设备服务初始化后自动调用 [scanDevices] 方法，
/// 并将结果缓存起来，后续调用直接返回缓存结果。
final usbDevicesProvider = FutureProvider<List<AppDeviceInfo>>((ref) async {
  final deviceService = ref.watch(deviceServiceProvider);
  return await deviceService.scanDevices('usb');
});

final wifiDevicesProvider = FutureProvider<List<AppDeviceInfo>>((ref) async {
  final deviceService = ref.watch(deviceServiceProvider);
  return await deviceService.scanDevices('wifi');
});

/// 合并设备列表（USB + WiFi）。
/// 说明：
/// - USB 设备优先展示；
/// - 同设备 ID 去重，避免重复项。
final allDevicesProvider = FutureProvider<List<AppDeviceInfo>>((ref) async {
  final deviceService = ref.watch(deviceServiceProvider);
  final usb = await deviceService.scanDevices('usb');
  final wifi = await deviceService.scanDevices('wifi');

  final map = <String, AppDeviceInfo>{};
  for (final d in [...usb, ...wifi]) {
    map[d.deviceId] = d;
  }

  final result = map.values.toList();
  result.sort((a, b) {
    if (a.connectionMode == b.connectionMode) {
      return a.name.compareTo(b.name);
    }
    return a.connectionMode.code == 'usb' ? -1 : 1;
  });
  return result;
});

// 设备连接状态监听
final deviceConnectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  final deviceService = ref.watch(deviceServiceProvider);
  return deviceService.connectionStatus;
});
