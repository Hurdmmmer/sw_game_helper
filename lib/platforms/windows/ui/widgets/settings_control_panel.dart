import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sw_game_helper/platforms/windows/bridge_generated/gh_common/model.dart';
import 'package:sw_game_helper/platforms/windows/providers/settings_provider.dart';
import 'package:sw_game_helper/platforms/windows/service/device_service.dart';
import 'package:sw_game_helper/platforms/windows/ui/widgets/panel_primitives.dart';
import 'package:sw_game_helper/platforms/windows/ui/widgets/styled_dropdown.dart';
import 'package:sw_game_helper/style/app_tokens.dart';

/// 右侧控制面板中的“设置”视图。
class SettingsControlPanel extends ConsumerWidget {
  /// 设置面板构造函数。
  const SettingsControlPanel({super.key});

  /// 将渲染链路枚举转换为可读文本。
  String _renderPipelineLabel(RenderPipelineMode mode) {
    return switch (mode) {
      RenderPipelineMode.original => 'Original',
      RenderPipelineMode.cpuPixelBufferV2 => 'CPU PixelBuffer V2',
    };
  }

  /// 将解码模式枚举转换为可读文本。
  String _decoderModeLabel(DeviceDecoderMode mode) {
    return switch (mode) {
      DeviceDecoderMode.preferHardware => 'Prefer HW',
      DeviceDecoderMode.forceHardware => 'Force HW',
      DeviceDecoderMode.forceSoftware => 'Force SW',
    };
  }

  /// 将 scrcpy `--max-size` 档位转换为可读文本。
  String _maxSizeLabel(ScrcpyMaxSizeOption option) {
    return switch (option) {
      ScrcpyMaxSizeOption.max1024 => 'max-size 1024',
      ScrcpyMaxSizeOption.max1280 => 'max-size 1280',
      ScrcpyMaxSizeOption.max1600 => 'max-size 1600',
      ScrcpyMaxSizeOption.max1920 => 'max-size 1920',
      ScrcpyMaxSizeOption.max2560 => 'max-size 2560',
    };
  }

  /// 构建设置面板主体。
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PanelSectionTitle(title: '设置'),
        SizedBox(height: AppSpacing.xs),
        const PanelHintText(text: '统一管理解码、画面参数与推理显示参数。'),
        SizedBox(height: AppSpacing.sm),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PanelSectionTitle(title: '连接与解码'),
                SizedBox(height: AppSpacing.xs),
                PanelSectionCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _FieldBlock(
                              title: '渲染链路',
                              child: StyledDropdown<RenderPipelineMode>(
                                isLoading: false,
                                value: settings.renderPipelineMode,
                                hint: '渲染链路',
                                items: RenderPipelineMode.values
                                    .map(
                                      (mode) => DropdownItem(
                                        value: mode,
                                        label: _renderPipelineLabel(mode),
                                        leadingIcon: LucideIcons.layers,
                                      ),
                                    )
                                    .toList(),
                                onChanged: notifier.setRenderPipelineMode,
                              ),
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _FieldBlock(
                              title: '解码模式',
                              child: StyledDropdown<DeviceDecoderMode>(
                                isLoading: false,
                                value: settings.decoderMode,
                                hint: '解码模式',
                                items: DeviceDecoderMode.values
                                    .map(
                                      (mode) => DropdownItem(
                                        value: mode,
                                        label: _decoderModeLabel(mode),
                                        leadingIcon: LucideIcons.cpu,
                                      ),
                                    )
                                    .toList(),
                                onChanged: notifier.setDecoderMode,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.sm),
                      _InlineSwitchTile(
                        title: '连接后手机熄屏',
                        icon: LucideIcons.moon,
                        value: settings.turnScreenOffOnConnect,
                        onChanged: notifier.setTurnScreenOffOnConnect,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                const PanelSectionTitle(title: '视频配置'),
                SizedBox(height: AppSpacing.xs),
                PanelSectionCard(
                  child: Column(
                    children: [
                      _InlineMetricSlider(
                        title: '码率',
                        unit: 'Kbps',
                        valueText: '${settings.bitrateKbps}',
                        min: 2000,
                        max: 20000,
                        divisions: 18,
                        value: settings.bitrateKbps.toDouble(),
                        onChanged: (value) =>
                            notifier.setBitrateKbps(value.round()),
                      ),
                      _InlineMetricSlider(
                        title: '帧率',
                        unit: 'FPS',
                        valueText: '${settings.frameRate}',
                        min: 15,
                        max: 120,
                        divisions: 9,
                        value: settings.frameRate.toDouble(),
                        onChanged: (value) =>
                            notifier.setFrameRate(value.round()),
                      ),
                      _FieldBlock(
                        title: '最大尺寸（scrcpy --max-size）',
                        child: StyledDropdown<ScrcpyMaxSizeOption>(
                          isLoading: false,
                          value: settings.maxSizeOption,
                          hint: '最大尺寸',
                          items: ScrcpyMaxSizeOption.values
                              .map(
                                (item) => DropdownItem(
                                  value: item,
                                  label: _maxSizeLabel(item),
                                ),
                              )
                              .toList(),
                          onChanged: notifier.setMaxSizeOption,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                const PanelSectionTitle(title: '推理显示'),
                SizedBox(height: AppSpacing.xs),
                PanelSectionCard(
                  child: Column(
                    children: [
                      _InlineSwitchTile(
                        title: '显示推理框',
                        icon: LucideIcons.scan,
                        value: settings.showInferenceBox,
                        onChanged: notifier.setShowInferenceBox,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      _InlineMetricSlider(
                        title: '置信度阈值',
                        unit: '',
                        valueText: settings.confidenceThreshold.toStringAsFixed(
                          2,
                        ),
                        min: 0.10,
                        max: 0.95,
                        divisions: 17,
                        value: settings.confidenceThreshold,
                        onChanged: notifier.setConfidenceThreshold,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                // 次操作按钮：与控制面板保持一致的次级语义。
                style: PanelPrimitives.secondaryButtonStyle(context),
                onPressed: () {
                  notifier.resetToDefault();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('已恢复默认设置')));
                },
                icon: Icon(LucideIcons.rotateCcw, size: 15),
                label: Text('恢复默认'),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton.icon(
                // 主操作按钮：与控制面板“连接设备/开始任务”保持一致的主语义。
                style: PanelPrimitives.primaryButtonStyle(context),
                onPressed: () async {
                  await notifier.applySettings();
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('设置已应用')));
                  }
                },
                icon: Icon(LucideIcons.save, size: 15),
                label: Text('应用并保存'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 带标题的字段块。
class _FieldBlock extends StatelessWidget {
  final String title;
  final Widget child;

  /// 构造函数。
  const _FieldBlock({required this.title, required this.child});

  /// 构建字段块。
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTokens.textSecondary(context),
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        child,
      ],
    );
  }
}

/// 行内开关项。
class _InlineSwitchTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// 构造函数。
  const _InlineSwitchTile({
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  /// 构建行内开关项。
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppTokens.iconSecondary(context)),
        SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTokens.textPrimary(context),
            ),
          ),
        ),
        Transform.scale(
          scale: 0.92,
          child: Switch(value: value, onChanged: onChanged),
        ),
      ],
    );
  }
}

/// 行内指标滑块。
class _InlineMetricSlider extends StatelessWidget {
  final String title;
  final String unit;
  final String valueText;
  final double min;
  final double max;
  final int divisions;
  final double value;
  final ValueChanged<double> onChanged;

  /// 构造函数。
  const _InlineMetricSlider({
    required this.title,
    required this.unit,
    required this.valueText,
    required this.min,
    required this.max,
    required this.divisions,
    required this.value,
    required this.onChanged,
  });

  /// 构建行内滑块。
  @override
  Widget build(BuildContext context) {
    final titleText = unit.isEmpty ? title : '$title ($unit)';
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            titleText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTokens.textPrimary(context),
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            valueText,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTokens.primary(context),
            ),
          ),
        ),
      ],
    );
  }
}
