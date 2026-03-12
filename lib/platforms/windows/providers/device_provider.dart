import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sw_game_helper/platforms/windows/service/device_service.dart';
import 'package:sw_game_helper/platforms/windows/service/device_service_impl.dart';
import 'package:sw_game_helper/enums/connection_status.dart';
import 'package:sw_game_helper/models/device_info.dart';

// 设备服务提供器，类似于 Spring 的 Bean 管理
final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceServiceImpl();
});

/// 合并设备列表（USB + WiFi）。
/// 说明：
/// - USB 设备优先展示；
/// - 同设备 ID 去重，避免重复项。
final allDevicesProvider = FutureProvider<List<AppDeviceInfo>>((ref) async {
  final deviceService = ref.watch(deviceServiceProvider);
  final all = await deviceService.scanDevices();

  final map = <String, AppDeviceInfo>{};
  for (final d in all) {
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
final currentDeviceConnectStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  final deviceService = ref.watch(deviceServiceProvider);
  return deviceService.currentConnectStatus;
});
