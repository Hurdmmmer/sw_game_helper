import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sw_game_helper/platforms/windows/bridge_generated/gh_common/model.dart';
import 'package:sw_game_helper/platforms/windows/service/device_service.dart';
import 'package:sw_game_helper/utils/logger_service.dart';

/// scrcpy 视频尺寸档位（`--max-size`）。
///
/// 注意：
/// - 这不是固定输出分辨率；
/// - 最终宽高会按设备原始比例等比缩放；
/// - 数值代表“宽或高的最大边界”。
enum ScrcpyMaxSizeOption { max1024, max1280, max1600, max1920, max2560 }

/// 应用配置模型
///
/// 关键逻辑：
/// 1. 将设置页中的可配置项统一集中在一个模型里；
/// 2. 通过不可变 copyWith 更新，避免状态污染。
class AppSettings {
  /// 渲染链路：决定视频帧从原生到 Flutter 的传输/渲染路径。
  final RenderPipelineMode renderPipelineMode;

  /// 设备解码策略：优先硬解、强制硬解或强制软解。
  final DeviceDecoderMode decoderMode;

  /// 连接后是否请求设备熄屏。
  final bool turnScreenOffOnConnect;

  /// 视频码率（单位 Kbps）。
  final int bitrateKbps;

  /// scrcpy `--max-size` 档位。
  final ScrcpyMaxSizeOption maxSizeOption;

  /// 视频帧率（单位 FPS）。
  final int frameRate;

  /// 是否显示推理框叠加层。
  final bool showInferenceBox;

  /// 推理置信度阈值（0~1）。
  final double confidenceThreshold;

  /// 构造设置模型。
  const AppSettings({
    required this.renderPipelineMode,
    required this.decoderMode,
    required this.turnScreenOffOnConnect,
    required this.bitrateKbps,
    required this.maxSizeOption,
    required this.frameRate,
    required this.showInferenceBox,
    required this.confidenceThreshold,
  });

  /// 默认设置
  factory AppSettings.defaults() => const AppSettings(
    renderPipelineMode: RenderPipelineMode.cpuPixelBufferV2,
    decoderMode: DeviceDecoderMode.preferHardware,
    turnScreenOffOnConnect: false,
    bitrateKbps: 8000,
    maxSizeOption: ScrcpyMaxSizeOption.max1920,
    frameRate: 60,
    showInferenceBox: true,
    confidenceThreshold: 0.50,
  );

  /// 复制并更新设置项（不可变更新）。
  AppSettings copyWith({
    RenderPipelineMode? renderPipelineMode,
    DeviceDecoderMode? decoderMode,
    bool? turnScreenOffOnConnect,
    int? bitrateKbps,
    ScrcpyMaxSizeOption? maxSizeOption,
    int? frameRate,
    bool? showInferenceBox,
    double? confidenceThreshold,
  }) {
    return AppSettings(
      renderPipelineMode: renderPipelineMode ?? this.renderPipelineMode,
      decoderMode: decoderMode ?? this.decoderMode,
      turnScreenOffOnConnect:
          turnScreenOffOnConnect ?? this.turnScreenOffOnConnect,
      bitrateKbps: bitrateKbps ?? this.bitrateKbps,
      maxSizeOption: maxSizeOption ?? this.maxSizeOption,
      frameRate: frameRate ?? this.frameRate,
      showInferenceBox: showInferenceBox ?? this.showInferenceBox,
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
    );
  }
}

/// 设置状态管理
class SettingsNotifier extends Notifier<AppSettings> {
  /// 初始化设置状态。
  @override
  AppSettings build() {
    return AppSettings.defaults();
  }

  /// 设置视频码率（Kbps）。
  void setBitrateKbps(int value) {
    state = state.copyWith(bitrateKbps: value);
  }

  /// 设置渲染链路。
  void setRenderPipelineMode(RenderPipelineMode value) {
    state = state.copyWith(renderPipelineMode: value);
  }

  /// 设置解码策略。
  void setDecoderMode(DeviceDecoderMode value) {
    state = state.copyWith(decoderMode: value);
  }

  /// 设置连接后熄屏策略。
  void setTurnScreenOffOnConnect(bool value) {
    state = state.copyWith(turnScreenOffOnConnect: value);
  }

  /// 设置 scrcpy `--max-size` 档位。
  void setMaxSizeOption(ScrcpyMaxSizeOption value) {
    state = state.copyWith(maxSizeOption: value);
  }

  /// 设置帧率（FPS）。
  void setFrameRate(int value) {
    state = state.copyWith(frameRate: value);
  }

  /// 设置是否显示推理框。
  void setShowInferenceBox(bool value) {
    state = state.copyWith(showInferenceBox: value);
  }

  /// 设置推理置信度阈值。
  void setConfidenceThreshold(double value) {
    state = state.copyWith(confidenceThreshold: value);
  }

  /// 恢复默认设置。
  void resetToDefault() {
    state = AppSettings.defaults();
    Log.i('设置已恢复默认值');
  }

  /// 应用设置（当前先记录日志，后续可接入 Rust 参数下发与持久化）
  Future<void> applySettings() async {
    Log.i(
      '应用设置: pipeline=${state.renderPipelineMode.name}, '
      'decoder=${state.decoderMode.name}, turnOff=${state.turnScreenOffOnConnect}, '
      'bitrate=${state.bitrateKbps}, maxSize=${state.maxSizeOption.name}, '
      'fps=${state.frameRate}, showBox=${state.showInferenceBox}, '
      'confidence=${state.confidenceThreshold.toStringAsFixed(2)}',
    );
  }
}

/// 全局设置 Provider。
final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
