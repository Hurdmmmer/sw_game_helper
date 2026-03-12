import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sw_game_helper/models/device_info.dart';
import 'package:sw_game_helper/platforms/windows/providers/device_provider.dart';
import 'package:sw_game_helper/platforms/windows/providers/settings_provider.dart';
import 'package:sw_game_helper/platforms/windows/ui/widgets/panel_primitives.dart';
import 'package:sw_game_helper/style/app_tokens.dart';
import 'package:sw_game_helper/utils/logger_service.dart';

/// 会话控制面板（统一设备列表版）。
class SessionControlPanel extends ConsumerStatefulWidget {
  /// 构造函数。
  const SessionControlPanel({super.key});

  /// 创建状态对象。
  @override
  ConsumerState<SessionControlPanel> createState() =>
      _SessionControlPanelState();
}

/// 会话控制面板状态。
class _SessionControlPanelState extends ConsumerState<SessionControlPanel>
    with SingleTickerProviderStateMixin {
  /// 当前选中的设备 ID。
  String? _selectedDeviceId;

  /// 当前是否处于已连接状态。
  bool _isConnected = false;

  /// 刷新图标旋转控制器（加载中持续旋转）。
  late final AnimationController _refreshRotationController;

  /// 当前是否正在播放刷新旋转动画。
  bool _isRefreshAnimating = false;

  @override
  void initState() {
    super.initState();
    // 初始化刷新图标旋转控制器。
    _refreshRotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    // 释放动画控制器资源，避免内存泄漏。
    _refreshRotationController.dispose();
    super.dispose();
  }

  /// 同步刷新图标旋转状态：
  /// - 加载中：循环旋转；
  /// - 非加载：停止并重置到初始角度。
  void _syncRefreshRotation(bool isLoading) {
    if (isLoading && !_isRefreshAnimating) {
      _refreshRotationController.repeat();
      _isRefreshAnimating = true;
      return;
    }
    if (!isLoading && _isRefreshAnimating) {
      _refreshRotationController.stop();
      _refreshRotationController.reset();
      _isRefreshAnimating = false;
    }
  }

  /// 执行连接逻辑。
  Future<void> _connectSelectedDevice(
    AppDeviceInfo selectedDevice,
    AppSettings appSettings,
  ) async {
    setState(() => _isConnected = true);
    try {
      final deviceService = ref.read(deviceServiceProvider);
      final success = await deviceService.connectDevice(
        selectedDevice,
        renderPipelineMode: appSettings.renderPipelineMode,
        decoderMode: appSettings.decoderMode,
        turnScreenOff: appSettings.turnScreenOffOnConnect,
        // 设置页参数透传到 scrcpy 连接配置。
        bitRate: appSettings.bitrateKbps.toBpsFromKbps(),
        maxSize: appSettings.maxSizeOption.toMaxSizeValue(),
        maxFps: appSettings.frameRate,
      );
      if (!success) {
        setState(() => _isConnected = false);
        if (mounted) {
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

  /// 执行断开逻辑。
  Future<void> _disconnectDevice() async {
    setState(() => _isConnected = false);
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

  /// 处理顶部按钮点击（连接/断开合并）。
  Future<void> _onActionButtonClick(
    List<AppDeviceInfo> devices,
    AppSettings appSettings,
  ) async {
    if (_isConnected) {
      await _disconnectDevice();
      return;
    }
    final selected = devices.cast<AppDeviceInfo?>().firstWhere(
      (d) => d?.deviceId == _selectedDeviceId,
      orElse: () => null,
    );
    if (selected == null) {
      return;
    }
    await _connectSelectedDevice(selected, appSettings);
  }

  /// 构建标题行（含连接按钮与刷新按钮）。
  Widget _buildHeaderRow(
    BuildContext context, {
    required bool isLoading,
    required bool canConnect,
    required List<AppDeviceInfo> devices,
    required AppSettings appSettings,
  }) {
    final actionLabel = _isConnected ? '断开设备' : '连接设备';
    final actionIcon = _isConnected ? LucideIcons.unlink2 : LucideIcons.link2;
    // 连接状态使用主按钮；已连接后切换为危险按钮，语义更明确。
    final actionStyle = _isConnected
        ? PanelPrimitives.compactDangerButtonStyle(context)
        : PanelPrimitives.compactPrimaryButtonStyle(context);

    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Icon(
            LucideIcons.smartphone,
            size: 16,
            color: AppTokens.iconSecondary(context),
          ),
          SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              '选择设备',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTokens.textPrimary(context),
              ),
            ),
          ),
          SizedBox(
            height: 34,
            child: ElevatedButton.icon(
              style: actionStyle,
              onPressed: canConnect 
                  ? () => _onActionButtonClick(devices, appSettings)
                  : null,
              icon: Icon(actionIcon, size: 14),
              label: Text(actionLabel),
            ),
          ),
          SizedBox(width: AppSpacing.xs),
          // 刷新按钮改为与连接按钮同体系的紧凑次按钮，避免风格割裂。
          SizedBox(
            width: 34,
            height: 34,
            child: ElevatedButton(
              style: PanelPrimitives.compactSecondaryButtonStyle(context)
                  .copyWith(
                    minimumSize: const WidgetStatePropertyAll(Size(34, 34)),
                    padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                  ),
              onPressed: isLoading
                  ? null
                  : () {
                      // setState(() {
                      //   _selectedDeviceId = null;
                      //   _isConnected = false;
                      // });
                      ref.invalidate(allDevicesProvider);
                    },
              child: RotationTransition(
                turns: _refreshRotationController,
                child: const Icon(LucideIcons.refreshCw, size: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建面板主体。
  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(allDevicesProvider);
    // 根据加载状态同步刷新图标旋转动画。
    _syncRefreshRotation(devicesAsync.isLoading);
    final appSettings = ref.watch(settingsProvider);
    final devices = devicesAsync.value ?? const <AppDeviceInfo>[];
    final canConnect = _isConnected || _selectedDeviceId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PanelSectionTitle(title: '设备连接'),
        SizedBox(height: AppSpacing.xs),
        const PanelHintText(text: '列表展示 USB/WiFi 设备，选择后可直接连接。'),
        SizedBox(height: AppSpacing.sm),
        _buildHeaderRow(
          context,
          isLoading: devicesAsync.isLoading,
          canConnect: canConnect,
          devices: devices,
          appSettings: appSettings,
        ),
        SizedBox(height: AppSpacing.sm),
        Expanded(
          child: PanelSectionCard(
            child: _DeviceListSection(
              devices: devices,
              isLoading: devicesAsync.isLoading,
              hasError: devicesAsync.hasError,
              selectedDeviceId: _selectedDeviceId,
              onSelectDevice: (deviceId) =>
                  setState(() => _selectedDeviceId = deviceId),
            ),
          ),
        ),
      ],
    );
  }
}

/// 设备列表区域。
class _DeviceListSection extends StatelessWidget {
  final List<AppDeviceInfo> devices;
  final bool isLoading;
  final bool hasError;
  final String? selectedDeviceId;
  final ValueChanged<String?> onSelectDevice;

  /// 构造函数。
  const _DeviceListSection({
    required this.devices,
    required this.isLoading,
    required this.hasError,
    required this.selectedDeviceId,
    required this.onSelectDevice,
  });

  /// 构建单个设备连接类型标签。
  Widget _buildModeBadge(BuildContext context, AppDeviceInfo device) {
    final isUsb = device.connectionMode.code == 'usb';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isUsb
            ? AppTokens.primary(context).withValues(alpha: 0.12)
            : AppTokens.success(context).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isUsb ? 'USB' : 'WiFi',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isUsb
              ? AppTokens.primary(context)
              : AppTokens.success(context),
        ),
      ),
    );
  }

  /// 构建设备行。
  Widget _buildDeviceTile(BuildContext context, AppDeviceInfo device) {
    final isSelected = selectedDeviceId == device.deviceId;
    // 设备主标题：直接拼接“品牌 + 型号”，不再展示“品牌:”第二行文案。
    final brand = device.brand;
    final displayName =
        (brand != null && brand.trim().isNotEmpty && brand != 'Unknown')
        ? '$brand ${device.name}'
        : device.name;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        // 再次点击已选中设备时取消选中，便于用户快速回退选择。
        onTap: () => onSelectDevice(isSelected ? null : device.deviceId),
        child: Container(
          // 设备列表项关闭内部动画，主题切换时仅跟随全局主题过渡，避免二次闪变。
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 7),
          decoration: BoxDecoration(
            // 与设置面板输入控件统一为第三级容器色：
            // 选中态仅通过边框和文字权重体现，避免底色跳变。
            color: AppTokens.cardHighlight(context),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: isSelected
                  ? AppTokens.primary(context)
                  : AppTokens.divider(context),
            ),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.smartphone,
                size: 16,
                color: isSelected
                    ? AppTokens.primary(context)
                    : AppTokens.iconSecondary(context),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Row(
                  children: [
                    _buildModeBadge(context, device),
                    SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: AppTokens.textPrimary(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: AppTokens.primary(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建设备列表。
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (hasError) {
      return Center(
        child: Text(
          '设备加载失败，请刷新',
          style: TextStyle(color: AppTokens.error(context)),
        ),
      );
    }
    if (devices.isEmpty) {
      return Center(
        child: Text(
          '未检测到设备',
          style: TextStyle(color: AppTokens.textSecondary(context)),
        ),
      );
    }

    return ListView.separated(
      itemCount: devices.length,
      separatorBuilder: (_, _) => SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) =>
          _buildDeviceTile(context, devices[index]),
    );
  }
}
