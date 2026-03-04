import 'package:flutter/material.dart';
import 'package:sw_game_helper/platforms/windows/ui/widgets/loading_text.dart';
import 'package:sw_game_helper/style/app_tokens.dart';

class DropdownItem<T> {
  /// 下拉列表项的值
  final T value;

  /// 下拉列表项的标签
  final String label;

  /// 下拉列表项的前导图标
  final IconData? leadingIcon;

  /// 构造函数
  DropdownItem({required this.value, required this.label, this.leadingIcon});
}

/// 符合设计系统的下拉选择器
///
/// 使用 Overlay 实现自定义下拉菜单，完全遵循 AppTokens 设计规范。
///
/// 使用示例:
/// ```dart
/// StyledDropdown<String>(
///   value: selectedDeviceId,
///   hint: '请选择设备',
///   items: devices.map((d) => DropdownItem(
///     value: d.id,
///     label: d.name,
///     leadingIcon: Icons.phone_android,
///   )).toList(),
///   onChanged: (id) => setState(() => selectedDeviceId = id),
/// )
/// ```
class StyledDropdown<T> extends StatefulWidget {
  /// 当前选中的值
  final T? value;

  /// 选项列表
  final List<DropdownItem<T>> items;

  /// 是否正在加载中
  final bool isLoading;

  /// 值改变回调
  final ValueChanged<T>? onChanged;

  /// 占位提示文字
  final String? hint;

  /// 是否撑满父容器宽度
  final bool isExpanded;

  /// 构造函数
  ///
  /// [value] 当前选中的值
  /// [items] 选项列表
  /// [onChanged] 值改变回调
  /// [hint] 占位提示文字
  /// [isExpanded] 是否撑满父容器宽度
  const StyledDropdown({
    super.key,
    this.value,
    required this.items,
    this.onChanged,
    this.hint,
    this.isExpanded = true,
    required this.isLoading,
  });
  @override
  State<StyledDropdown<T>> createState() => _StyledDropdownState<T>();
}

class _StyledDropdownState<T> extends State<StyledDropdown<T>> {
  // ========== 核心状态 ==========
  /// Overlay 入口（菜单层）
  OverlayEntry? _overlayEntry;

  /// 用于定位菜单相对于按钮的位置
  final LayerLink _layerLink = LayerLink();

  /// 触发按钮的 GlobalKey，用于获取位置和尺寸
  final GlobalKey _triggerKey = GlobalKey();

  /// 菜单是否展开
  bool get _isOpen => _overlayEntry != null;
  // ========== 生命周期 ==========
  @override
  void dispose() {
    // dispose 时只清理 overlay，不调用 setState
    _cleanupOverlay();
    super.dispose();
  }

  // ========== 核心方法 ==========
  /// 切换菜单显示/隐藏
  void _toggleMenu() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  /// 显示下拉菜单
  void _showOverlay() {
    // 获取触发按钮的尺寸
    final RenderBox? renderBox =
        _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;
    // 创建 Overlay 入口
    _overlayEntry = OverlayEntry(
      builder: (context) => _DropdownOverlay<T>(
        link: _layerLink,
        triggerWidth: size.width,
        items: widget.items,
        selectedValue: widget.value,
        onSelected: (value) {
          widget.onChanged?.call(value);
          _removeOverlay();
        },
        onDismiss: _removeOverlay,
      ),
    );
    // 插入到 Overlay
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {}); // 更新 UI 以显示展开状态的箭头
  }

  /// 仅清理 overlay，不刷新 UI（用于 dispose）
  void _cleanupOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// 移除下拉菜单并刷新 UI（用于用户交互）
  void _removeOverlay() {
    _cleanupOverlay();
    // 只有在 widget 存活时才刷新 UI
    if (mounted) {
      setState(() {});
    }
  }

  // ========== 构建 UI ==========
  @override
  Widget build(BuildContext context) {
    // 查找当前选中项的标签
    final selectedItem = widget.items.cast<DropdownItem<T>?>().firstWhere(
      (item) => item?.value == widget.value,
      orElse: () => null,
    );
    // CompositedTransformTarget 用于将菜单与触发按钮关联起来
    // 常见使用下拉框时就需要使用 CompositedTransformTarget 来关联菜单与触发按钮
    return CompositedTransformTarget(
      // 绑定 LayerLink，让菜单知道跟随谁
      link: _layerLink,
      // GestureDetector 用于监听点击，滑动，长按事件对象
      child: GestureDetector(
        key: _triggerKey,
        onTap: widget.onChanged != null && !widget.isLoading
            ? _toggleMenu
            : null,
        child: _TriggerButton(
          label: selectedItem?.label ?? widget.hint ?? '',
          isHint: selectedItem == null,
          isOpen: _isOpen,
          isExpanded: widget.isExpanded,
          isEnabled: widget.onChanged != null && !widget.isLoading,
          isLoading: widget.isLoading,
        ),
      ),
    );
  }
}

// ========== 触发按钮子组件 ==========
class _TriggerButton extends StatefulWidget {
  final String label;
  final bool isHint;
  final bool isOpen;
  final bool isExpanded;
  final bool isEnabled;
  final bool isLoading;

  /// 触发按钮子组件
  ///
  /// [label] 按钮文字
  /// [isHint] 是否为占位提示
  /// [isOpen] 是否展开
  /// [isExpanded] 是否撑满父容器宽度
  /// [isEnabled] 是否可交互
  const _TriggerButton({
    required this.label,
    required this.isHint,
    required this.isOpen,
    required this.isExpanded,
    required this.isEnabled,
    required this.isLoading,
  });
  @override
  State<_TriggerButton> createState() => _TriggerButtonState();
}

class _TriggerButtonState extends State<_TriggerButton> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    // MouseRegion 用于监听鼠标事件，更新 hover 状态
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.isEnabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, // 12px
          vertical: AppSpacing.sm + 2, // 10px
        ),
        decoration: BoxDecoration(
          // 背景色：hover 时使用 highlight，否则 secondary
          color: _isHovered && widget.isEnabled
              ? AppTokens.cardHighlight(context)
              : AppTokens.cardSecondary(context),
          // 8px 圆角
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          // 边框
          border: Border.all(
            color: widget.isOpen
                ? AppTokens.primary(context) // 展开时高亮边框
                : AppTokens.divider(context),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            // 文字
            Expanded(
              // 文字内容切换动画（加载时显示加载动画，否则显示文字）
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: widget.isLoading
                    ? LoadingBounceDots(
                        key: const ValueKey('loading'),
                        style: TextStyle(
                          color: widget.isHint
                              ? AppTokens.textTertiary(context)
                              : AppTokens.textPrimary(context),
                          fontSize: 14,
                        ),
                      )
                    : Text(
                        widget.label,
                        key: ValueKey(widget.label),
                        style: TextStyle(
                          color: widget.isHint
                              ? AppTokens.textTertiary(context)
                              : AppTokens.textPrimary(context),
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // 箭头图标（展开时旋转）
            AnimatedRotation(
              turns: widget.isOpen ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: AppTokens.iconSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== 下拉菜单 Overlay ==========
class _DropdownOverlay<T> extends StatelessWidget {
  final LayerLink link;
  final double triggerWidth;
  final List<DropdownItem<T>> items;
  final T? selectedValue;
  final ValueChanged<T> onSelected;
  final VoidCallback onDismiss;
  const _DropdownOverlay({
    required this.link,
    required this.triggerWidth,
    required this.items,
    required this.selectedValue,
    required this.onSelected,
    required this.onDismiss,
  });
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1️⃣ 透明遮罩层：点击关闭菜单
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),
        // 2️⃣ 下拉菜单
        CompositedTransformFollower(
          link: link,
          // 显示在触发按钮下方，间隔 4px
          offset: const Offset(0, 4),
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: triggerWidth,
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: AppTokens.surface(context),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: AppTokens.divider(context), width: 1),
                boxShadow: AppShadows.card,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: items.map((item) {
                      final isSelected = item.value == selectedValue;
                      return _DropdownMenuItem(
                        item: item,
                        isSelected: isSelected,
                        onTap: () => onSelected(item.value),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ========== 菜单项子组件 ==========
class _DropdownMenuItem<T> extends StatefulWidget {
  final DropdownItem<T> item;
  final bool isSelected;
  final VoidCallback onTap;
  const _DropdownMenuItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });
  @override
  State<_DropdownMenuItem<T>> createState() => _DropdownMenuItemState<T>();
}

class _DropdownMenuItemState<T> extends State<_DropdownMenuItem<T>> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          color: _isHovered
              ? AppTokens.primary(context).withValues(alpha: 0.08)
              : Colors.transparent,
          child: Row(
            children: [
              // 可选的前置图标
              if (widget.item.leadingIcon != null) ...[
                Icon(
                  widget.item.leadingIcon,
                  size: 18,
                  color: AppTokens.iconSecondary(context),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              // 标签文字
              Expanded(
                child: Text(
                  widget.item.label,
                  style: TextStyle(
                    color: AppTokens.textPrimary(context),
                    fontSize: 14,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              // 选中标记
              if (widget.isSelected)
                Icon(Icons.check, size: 18, color: AppTokens.success(context)),
            ],
          ),
        ),
      ),
    );
  }
}
