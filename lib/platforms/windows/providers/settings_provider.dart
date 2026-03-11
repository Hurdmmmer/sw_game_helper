import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
enum ScrcpyMaxSizeOption {
  unlimited,
  max1920,
}

/// scrcpy 尺寸档位与传输参数转换工具。
extension ScrcpySettingsValueX on ScrcpyMaxSizeOption {
  /// 转换为 scrcpy `--max-size` 对应数值。
  int toMaxSizeValue() {
    return switch (this) {
      ScrcpyMaxSizeOption.unlimited => 0,
      ScrcpyMaxSizeOption.max1920 => 1920,
    };
  }
}

/// 码率单位转换工具。
extension BitrateUnitX on int {
  /// 将 UI 侧 Kbps 转换为 scrcpy 所需 bps。
  int toBpsFromKbps() => this * 1000;
}

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
    bitrateKbps: 160000,
    maxSizeOption: ScrcpyMaxSizeOption.unlimited,
    frameRate: 0,
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

  /// 将配置序列化为 JSON 对象。
  Map<String, dynamic> toJson() {
    return {
      'renderPipelineMode': renderPipelineMode.name,
      'decoderMode': decoderMode.name,
      'turnScreenOffOnConnect': turnScreenOffOnConnect,
      'bitrateKbps': bitrateKbps,
      'maxSizeOption': maxSizeOption.name,
      'frameRate': frameRate,
      'showInferenceBox': showInferenceBox,
      'confidenceThreshold': confidenceThreshold,
    };
  }

  /// 从 JSON 对象反序列化配置。
  ///
  /// 设计要点：
  /// 1. 任意字段缺失时自动回退默认值；
  /// 2. 数值字段统一做范围约束，避免异常值导致会话参数不可用；
  /// 3. 枚举字段解析失败时回退默认枚举。
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final defaults = AppSettings.defaults();
    final bitrate =
        (json['bitrateKbps'] as num?)?.toInt() ?? defaults.bitrateKbps;
    final frameRate =
        (json['frameRate'] as num?)?.toInt() ?? defaults.frameRate;
    final confidence =
        (json['confidenceThreshold'] as num?)?.toDouble() ??
        defaults.confidenceThreshold;

    return AppSettings(
      renderPipelineMode: _parseRenderPipelineMode(
        json['renderPipelineMode'],
        defaults.renderPipelineMode,
      ),
      decoderMode: _parseDecoderMode(json['decoderMode'], defaults.decoderMode),
      turnScreenOffOnConnect:
          json['turnScreenOffOnConnect'] as bool? ??
          defaults.turnScreenOffOnConnect,
      bitrateKbps: bitrate.clamp(2000, 20000),
      maxSizeOption: _parseMaxSizeOption(
        json['maxSizeOption'],
        defaults.maxSizeOption,
      ),
      // 帧率允许 0（不限）以及 30/60/120 档位。
      frameRate: frameRate.clamp(0, 120),
      showInferenceBox:
          json['showInferenceBox'] as bool? ?? defaults.showInferenceBox,
      confidenceThreshold: confidence.clamp(0.10, 0.95),
    );
  }

  /// 解析渲染链路枚举。
  static RenderPipelineMode _parseRenderPipelineMode(
    Object? raw,
    RenderPipelineMode fallback,
  ) {
    for (final mode in RenderPipelineMode.values) {
      if (mode.name == raw) {
        return mode;
      }
    }
    return fallback;
  }

  /// 解析解码模式枚举。
  static DeviceDecoderMode _parseDecoderMode(
    Object? raw,
    DeviceDecoderMode fallback,
  ) {
    for (final mode in DeviceDecoderMode.values) {
      if (mode.name == raw) {
        return mode;
      }
    }
    return fallback;
  }

  /// 解析 max-size 枚举。
  static ScrcpyMaxSizeOption _parseMaxSizeOption(
    Object? raw,
    ScrcpyMaxSizeOption fallback,
  ) {
    for (final option in ScrcpyMaxSizeOption.values) {
      if (option.name == raw) {
        return option;
      }
    }
    return fallback;
  }
}

/// 设置状态管理
class SettingsNotifier extends Notifier<AppSettings> {
  /// 本地 JSON 配置存储。
  final _storage = _SettingsJsonStorage();

  /// 防止 build 多次触发重复加载。
  bool _hasStartedLoad = false;

  /// 初始化设置状态。
  @override
  AppSettings build() {
    if (!_hasStartedLoad) {
      _hasStartedLoad = true;
      // 延迟异步读取本地配置，避免阻塞首帧。
      unawaited(_loadFromDisk());
    }
    return AppSettings.defaults();
  }

  /// 从本地 JSON 文件加载配置。
  Future<void> _loadFromDisk() async {
    try {
      final loaded = await _storage.load();
      if (loaded == null) {
        Log.i('未发现本地设置文件，使用默认配置');
        return;
      }
      state = loaded;
      Log.i('已从本地 JSON 加载设置');
    } catch (e, st) {
      Log.e('加载本地设置失败，将继续使用内存默认配置: $e', e, st);
    }
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

  /// 应用设置并写入本地 JSON 文件。
  Future<void> applySettings() async {
    Log.i(
      '应用设置: pipeline=${state.renderPipelineMode.name}, '
      'decoder=${state.decoderMode.name}, turnOff=${state.turnScreenOffOnConnect}, '
      'bitrate=${state.bitrateKbps}, maxSize=${state.maxSizeOption.name}, '
      'fps=${state.frameRate}, showBox=${state.showInferenceBox}, '
      'confidence=${state.confidenceThreshold.toStringAsFixed(2)}',
    );

    try {
      await _storage.save(state);
      Log.i('设置已写入本地 JSON 文件');
    } catch (e, st) {
      Log.e('设置写入本地 JSON 失败: $e', e, st);
      rethrow;
    }
  }
}

/// 全局设置 Provider。
final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

/// 设置 JSON 存储实现。
///
/// 存储路径：
/// - Windows: `%APPDATA%\\SW Game Helper\\settings.json`
/// - 兜底: `${Directory.current.path}\\SW Game Helper\\settings.json`
class _SettingsJsonStorage {
  static const int _schemaVersion = 1;
  static const String _directoryName = 'SW Game Helper';
  static const String _fileName = 'settings.json';

  /// 读取本地配置文件。
  Future<AppSettings?> load() async {
    final file = await _resolveSettingsFile();
    if (!await file.exists()) {
      return null;
    }

    final raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      Log.w('本地设置 JSON 顶层结构异常，已忽略该文件');
      return null;
    }

    final migrated = _migrateSchema(decoded);
    return AppSettings.fromJson(migrated);
  }

  /// 保存配置到本地文件（原子写入：tmp -> rename）。
  Future<void> save(AppSettings settings) async {
    final file = await _resolveSettingsFile();
    final payload = <String, dynamic>{
      'schemaVersion': _schemaVersion,
      'updatedAt': DateTime.now().toIso8601String(),
      ...settings.toJson(),
    };
    final text = const JsonEncoder.withIndent('  ').convert(payload);
    final tempFile = File('${file.path}.tmp');

    await tempFile.writeAsString(text, flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await tempFile.rename(file.path);
  }

  /// 迁移旧版本 JSON 结构。
  ///
  /// 当前版本为 v1，后续可在此补充分支迁移逻辑。
  Map<String, dynamic> _migrateSchema(Map<String, dynamic> source) {
    final schemaVersion = (source['schemaVersion'] as num?)?.toInt() ?? 0;
    final migrated = Map<String, dynamic>.from(source);
    if (schemaVersion < 1) {
      migrated['schemaVersion'] = 1;
    }
    return migrated;
  }

  /// 解析 settings.json 文件路径。
  Future<File> _resolveSettingsFile() async {
    final appData = Platform.environment['APPDATA'];
    final basePath = (appData != null && appData.isNotEmpty)
        ? appData
        : Directory.current.path;
    final directory = Directory('$basePath\\$_directoryName');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return File('${directory.path}\\$_fileName');
  }
}
