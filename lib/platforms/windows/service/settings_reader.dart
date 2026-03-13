import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sw_game_helper/platforms/windows/providers/settings_provider.dart';

/// 设置读取接口。
///
/// 作用：
/// 1. 为业务服务提供“读取当前最新设置”的统一入口；
/// 2. 将设备服务与 Riverpod 直接解耦，便于后续替换实现和测试。
abstract class SettingsReader {
  /// 获取当前最新设置快照。
  AppSettings getCurrentSettings();
}

/// 基于 Riverpod 的设置读取实现。
class RiverpodSettingsReader implements SettingsReader {
  /// 构造函数。
  const RiverpodSettingsReader(this._ref);

  final Ref _ref;

  @override
  AppSettings getCurrentSettings() => _ref.read(settingsProvider);
}
