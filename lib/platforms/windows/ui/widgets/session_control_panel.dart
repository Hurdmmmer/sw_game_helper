import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sw_game_helper/enums/connection_mode.dart';
import 'package:sw_game_helper/models/device_info.dart';
import 'package:sw_game_helper/platforms/windows/bridge_generated/gh_common/model.dart';
import 'package:sw_game_helper/platforms/windows/providers/device_provider.dart';
import 'package:sw_game_helper/platforms/windows/service/device_service.dart';
import 'package:sw_game_helper/platforms/windows/ui/widgets/pill_toggle.dart';

import 'package:sw_game_helper/platforms/windows/ui/widgets/styled_dropdown.dart';
import 'package:sw_game_helper/platforms/windows/ui/widgets/styled_icon_button.dart';
import 'package:sw_game_helper/platforms/windows/ui/widgets/video_view.dart';
import 'package:sw_game_helper/style/app_tokens.dart';
import 'package:sw_game_helper/utils/logger_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// 会话控制面板
/// 包含 USB 和 WiFi 连接模式的控制面板
class SessionControlPanel extends ConsumerStatefulWidget {
  /// 面板中修改解码方式回调
  final ValueChanged<VideoRenderBackend>? onRenderBackendChanged;

  /// 构造函数
  /// [onRenderBackendChanged] 修改解码方式回调
  const SessionControlPanel({super.key, this.onRenderBackendChanged});

  @override
  ConsumerState<SessionControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends ConsumerState<SessionControlPanel> {
  /// 当前选中选项
  late String currentSelectOption = 'usb';

  /// 连接按钮被点击
  late bool disablePillBtn = false;

  @override
  Widget build(BuildContext context) {
    /// 选项列表
    List<PillOption> options = ConnectionMode.values
        .map((e) => PillOption(e.code, e.label))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PillToggle(
          selectedValue: currentSelectOption,
          options: options,
          // 值改变回调，更新当前选中选项
          onChanged: (value) => setState(() => currentSelectOption = value),
          isEnable: !disablePillBtn,
        ),
        SizedBox(height: AppSpacing.md),
        // 用 Expanded 包裹子面板，让高度约束传递下去
        if (currentSelectOption == 'usb')
          Expanded(
            child: UsbSettingsPanel(
              onRenderBackendChanged: widget.onRenderBackendChanged,
              onConnectBtnClick: () {
                setState(() {
                  disablePillBtn = !disablePillBtn;
                });
              },
            ),
          ),
        if (currentSelectOption == 'wifi') Expanded(child: WifiSettingsPanel()),
      ],
    );
  }
}

class UsbSettingsPanel extends ConsumerStatefulWidget {
  /// USB 面板中修改解码方式回调
  final ValueChanged<VideoRenderBackend>? onRenderBackendChanged;

  final VoidCallback? onConnectBtnClick;

  /// 构造函数
  /// [onRenderBackendChanged] 修改解码方式回调
  /// [onConnectBtnClick] 连接按钮点击回调
  const UsbSettingsPanel({
    super.key,
    this.onRenderBackendChanged,
    this.onConnectBtnClick,
  });

  @override
  ConsumerState<UsbSettingsPanel> createState() => _UsbSettingsPanelState();
}

class _UsbSettingsPanelState extends ConsumerState<UsbSettingsPanel> {
  /// 当前选中的设备 ID
  String? selectedDeviceId;

  /// 当前视频解码路径为CPU解码
  RenderPipelineMode _renderPipelineMode = RenderPipelineMode.cpuPixelBufferV2;

  DeviceDecoderMode _decoderMode = DeviceDecoderMode.preferHardware;

  /// 连接后是否请求设备熄屏。
  ///
  /// 语义：
  /// - true: Rust 会在会话建链成功后请求设备熄屏；
  /// - false: 不主动修改设备屏幕电源状态（默认亮屏）。
  bool _turnScreenOffOnConnect = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    widget.onRenderBackendChanged?.call(VideoRenderBackend.cpuPixelBuffer);
  }

  /// 解码链路选择器
  String _renderPipelineLabel(RenderPipelineMode mode) {
    return switch (mode) {
      RenderPipelineMode.original => 'Original',
      RenderPipelineMode.cpuPixelBufferV2 => 'CPU PixelBuffer V2',
    };
  }

  /// 解码选择器
  String _decoderModeLabel(DeviceDecoderMode mode) {
    return switch (mode) {
      DeviceDecoderMode.preferHardware => 'Prefer HW',
      DeviceDecoderMode.forceHardware => 'Force HW',
      DeviceDecoderMode.forceSoftware => 'Force SW',
    };
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(usbDevicesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ===== 标题行 =====
        Row(
          children: [
            // 图标
            Icon(
              LucideIcons.plug,
              size: 18,
              color: AppTokens.iconSecondary(context),
            ),
            SizedBox(width: AppSpacing.sm),
            // 标题
            Expanded(
              child: Text(
                '选择 USB 设备',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTokens.textPrimary(context),
                ),
              ),
            ),
            // 刷新按钮
            StyledIconButton(
              iconData: LucideIcons.refreshCw,
              iconSize: 16,
              isLoading: devices.isLoading,
              onPressed: () {
                setState(() => selectedDeviceId = null);
                ref.invalidate(usbDevicesProvider);
              },
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        // ===== 下拉框 (全宽) =====
        StyledDropdown<AppDeviceInfo>(
          isLoading: devices.isLoading,
          value: selectedDeviceId != null && devices.hasValue
              ? devices.value!.cast<AppDeviceInfo?>().firstWhere(
                  (e) => e?.deviceId == selectedDeviceId,
                  orElse: () => null,
                )
              : null,
          hint: devices.hasError ? '加载失败，请刷新' : '请选择设备',
          items: (devices.value ?? [])
              .map(
                (d) => DropdownItem(
                  value: d,
                  label: d.name,
                  leadingIcon: LucideIcons.smartphone,
                ),
              )
              .toList(),
          onChanged: (selectedDevice) =>
              setState(() => selectedDeviceId = selectedDevice.deviceId),
        ),
        SizedBox(height: AppSpacing.sm),
        StyledDropdown<RenderPipelineMode>(
          isLoading: false,
          value: _renderPipelineMode,
          hint: '渲染链路',
          items: RenderPipelineMode.values
              .map(
                (mode) => DropdownItem(
                  value: mode,
                  label: _renderPipelineLabel(mode),
                  leadingIcon: LucideIcons.smartphone,
                ),
              )
              .toList(),
          onChanged: (mode) {
            setState(() => _renderPipelineMode = mode);

            widget.onRenderBackendChanged?.call(
              mode == RenderPipelineMode.original
                  ? VideoRenderBackend.dxgi
                  : VideoRenderBackend.cpuPixelBuffer,
            );
          },
        ),
        SizedBox(height: AppSpacing.sm),
        // 一行布局：左侧解码模式下拉框，右侧熄屏开关。
        // 关键点：给下拉框和右侧开关区都加 Expanded/Flexible 约束，避免 Row 溢出。
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppTokens.cardSecondary(context),
            borderRadius: BorderRadius.circular(AppSpacing.md),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 6,
                child: StyledDropdown<DeviceDecoderMode>(
                  isLoading: false,
                  value: _decoderMode,
                  hint: '解码模式',
                  items: DeviceDecoderMode.values
                      .map(
                        (mode) => DropdownItem(
                          value: mode,
                          label: _decoderModeLabel(mode),
                          leadingIcon: LucideIcons.smartphone,
                        ),
                      )
                      .toList(),
                  onChanged: (mode) => setState(() => _decoderMode = mode),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.moon,
                      size: 16,
                      color: AppTokens.iconSecondary(context),
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        '手机熄屏',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTokens.textPrimary(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _turnScreenOffOnConnect,
                onChanged: _isConnected
                    ? null
                    : (value) =>
                          setState(() => _turnScreenOffOnConnect = value),
              ),
            ],
          ),
        ),
        Spacer(),
        // ===== 连接按钮 (CTA) =====
        Row(
          children: [
            Expanded(
              flex: 1,
              child: ElevatedButton.icon(
                // 已连接状态下禁用按钮
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xl - 4,
                  ),
                ),
                onPressed: selectedDeviceId != null && !_isConnected
                    ? () async {
                        setState(() => _isConnected = true);
                        // 调用外部连接按钮点击回调,锁定药丸按钮点击事件
                        widget.onConnectBtnClick?.call();

                        try {
                          final deviceService = ref.read(deviceServiceProvider);
                          final devices =
                              ref.read(usbDevicesProvider).value ?? [];
                          final device = devices.firstWhere(
                            (e) => e.deviceId == selectedDeviceId,
                          );

                          final success = await deviceService.connectDevice(
                            device,
                            renderPipelineMode: _renderPipelineMode,
                            decoderMode: _decoderMode,
                            // 关键透传：true=连接后熄屏，false=默认亮屏。
                            turnScreenOff: _turnScreenOffOnConnect,
                          );
                          if (!success) {
                            setState(() => _isConnected = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text('连接失败')));
                            }
                          }
                        } catch (e) {
                          setState(() => _isConnected = false);
                          Log.e('Connection error: $e');
                        }
                      }
                    : null,
                icon: Icon(LucideIcons.link2, size: 16),
                label: Text('连接设备'),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 1,
              child: ElevatedButton.icon(
                // 已连接状态下禁用按钮
                style: ElevatedButton.styleFrom(
                  // 使用 Theme ColorScheme，确保明暗主题切换时颜色过渡一致、避免闪烁。
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  disabledBackgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onErrorContainer,
                  disabledForegroundColor: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xl - 4,
                  ),
                ),
                onPressed: selectedDeviceId != null && _isConnected
                    ? () async {
                        setState(() => _isConnected = false);
                        // 调用外部连接按钮点击回调,解锁药丸按钮点击事件
                        widget.onConnectBtnClick?.call();
                        try {
                          final deviceService = ref.read(deviceServiceProvider);
                          final device = deviceService.connectedDevice;
                          if (device == null) {
                            Log.w('Disconnection skipped: no connected device');
                            return;
                          }
                          await deviceService.disconnectDevice(device);
                        } catch (e) {
                          Log.e('Disconnection error: $e');
                        }
                      }
                    : null,
                icon: Icon(LucideIcons.unlink2, size: 16),
                label: Text(
                  '断开设备',
                  style: TextStyle(fontWeight: FontWeight.w400),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class WifiSettingsPanel extends ConsumerStatefulWidget {
  /// 构造函数
  const WifiSettingsPanel({super.key});

  @override
  ConsumerState<WifiSettingsPanel> createState() => _WifiSettingsPanelState();
}

class _WifiSettingsPanelState extends ConsumerState<WifiSettingsPanel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Text(
          'Wi-Fi 连接设置',
          style: TextStyle(
            color: AppTokens.textPrimary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}





