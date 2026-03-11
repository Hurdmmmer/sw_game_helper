import 'package:sw_game_helper/enums/connection_mode.dart';
import 'package:sw_game_helper/enums/connection_status.dart';

class AppDeviceInfo {
  /// 设备名称（通常是型号）
  final String name;

  /// 设备品牌（如 Samsung、Xiaomi），用于列表展示。
  final String? brand;

  /// 设备ID
  final String deviceId;

  /// 设备类型
  final ConnectionMode connectionMode;

  /// 设备连接状态
  ConnectionStatus connectionStatus;

  /// 设备IP地址
  final String? ipAddress;

  /// 设备端口号
  final String? port;

  /// 安卓版本
  final String? androidVersion;

  /// 屏幕宽度
  final int? screenWidth;

  /// 屏幕高度
  final int? screenHeight;

  /// 设备信息构造函数
  AppDeviceInfo({
    required this.name,
    this.brand,
    required this.deviceId,
    required this.connectionMode,
    required this.connectionStatus,
    this.ipAddress,
    this.port,
    this.androidVersion,
    this.screenWidth,
    this.screenHeight,
  });
}
