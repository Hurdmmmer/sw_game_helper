import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sw_game_helper/platforms/windows/bridge_generated/gh_common/model.dart' as control;
import 'package:sw_game_helper/platforms/windows/providers/device_provider.dart';
import 'package:sw_game_helper/utils/logger_service.dart';

/// 单个 pointer 的手势快照。
///
/// 用于在 `up` 阶段判断这次输入更像“点击”还是“滑动”，
/// 并决定是否执行“补 move / 插值 / 最小时长保护”。
class TouchGestureState {
  TouchGestureState({
    required this.downAt,
    required this.downLocalPosition,
    required this.lastLocalPosition,
    required this.lastPressure,
    required this.lastButtons,
  });

  final DateTime downAt;
  final Offset downLocalPosition;
  Offset lastLocalPosition;
  double lastPressure;
  int lastButtons;
  int moveCount = 0;
}

/// 快速滑动补偿策略参数。
///
/// 说明：
/// - `swipeMinDistancePx`：超过该距离才视为滑动；
/// - `swipeMinDuration`：滑动最小时长，防止过快 down/up 被系统判为 tap；
/// - `swipeInterpolationPoints`：move 很少时补点数量。
class TouchSwipeAssistConfig {
  const TouchSwipeAssistConfig({
    this.swipeMinDistancePx = 8.0,
    this.swipeMinDuration = const Duration(milliseconds: 28),
    this.swipeInterpolationPoints = 2,
  });

  final double swipeMinDistancePx;
  final Duration swipeMinDuration;
  final int swipeInterpolationPoints;
}

/// 统一触控发送函数签名。
///
/// 由具体 View 提供实现，内部完成：
/// - 本地坐标 -> 设备坐标映射；
/// - pressure/buttons/action 组包；
/// - 调用 DeviceService 发送到 Rust。
typedef SendTouchAction = Future<void> Function({
  required Offset localPosition,
  required double eventPressure,
  required int buttons,
  required control.AndroidMotionEventAction action,
  required double localWidth,
  required double localHeight,
  required int pointerId,
});

/// 触控“抬手补偿”工具。
///
/// 目标：降低“快速滑动被识别为点击”的概率。
/// 核心流程：
/// 1) 若判定为滑动，先补一帧最新 move；
/// 2) 若 move 事件过少，插值补若干 move；
/// 3) 若 down->up 过快，补足最小时长；
/// 4) 最后发送 up。
class TouchSwipeAssist {
  /// 在发送 `up` 前执行一次滑动补偿。
  ///
  /// 不负责 pointerId 生命周期管理，只处理“这一次 up”的补偿策略。
  static Future<void> sendPointerUpWithSwipeAssist({
    required PointerEvent event,
    required int stablePointerId,
    required double localWidth,
    required double localHeight,
    required TouchGestureState? gesture,
    required Offset? pendingLocalPosition,
    required double? pendingPressure,
    required int? pendingButtons,
    required double? pendingLocalWidth,
    required double? pendingLocalHeight,
    required SendTouchAction sendTouch,
    TouchSwipeAssistConfig config = const TouchSwipeAssistConfig(),
  }) async {
    final state = gesture;
    if (state != null) {
      final endPos = event.localPosition;
      final dx = endPos.dx - state.downLocalPosition.dx;
      final dy = endPos.dy - state.downLocalPosition.dy;
      final distance = math.sqrt(dx * dx + dy * dy);
      final isSwipe = distance >= config.swipeMinDistancePx;
      if (isSwipe) {
        // 先发“当前最新 move”，保证服务端看到明确的滑动轨迹。
        final latestPos = pendingLocalPosition ?? state.lastLocalPosition;
        await sendTouch(
          localPosition: latestPos,
          eventPressure: pendingPressure ?? state.lastPressure,
          buttons: pendingButtons ?? state.lastButtons,
          action: control.AndroidMotionEventAction.move,
          localWidth: pendingLocalWidth ?? localWidth,
          localHeight: pendingLocalHeight ?? localHeight,
          pointerId: stablePointerId,
        );

        if (state.moveCount <= 1) {
          // move 太少时，补插值点，提升短滑手势命中率。
          for (var i = 1; i <= config.swipeInterpolationPoints; i++) {
            final t = i / (config.swipeInterpolationPoints + 1);
            final p = Offset(
              state.downLocalPosition.dx +
                  (endPos.dx - state.downLocalPosition.dx) * t,
              state.downLocalPosition.dy +
                  (endPos.dy - state.downLocalPosition.dy) * t,
            );
            await sendTouch(
              localPosition: p,
              eventPressure: event.pressure,
              buttons: event.buttons,
              action: control.AndroidMotionEventAction.move,
              localWidth: localWidth,
              localHeight: localHeight,
              pointerId: stablePointerId,
            );
          }
        }

        // 保证最小滑动时长，避免被目标应用归类为点击。
        final elapsed = DateTime.now().difference(state.downAt);
        if (elapsed < config.swipeMinDuration) {
          await Future<void>.delayed(config.swipeMinDuration - elapsed);
        }
      }
    }

    // 最终发送 up，完成一次触控生命周期。
    await sendTouch(
      localPosition: event.localPosition,
      eventPressure: event.pressure,
      buttons: event.buttons,
      action: control.AndroidMotionEventAction.up,
      localWidth: localWidth,
      localHeight: localHeight,
      pointerId: stablePointerId,
    );
  }
}

/// move 节流缓冲结构（同一 pointer 的最新 move 快照）。
class PendingMoveState {
  PendingMoveState({
    required this.stablePointerId,
    required this.localPosition,
    required this.pressure,
    required this.buttons,
    required this.localWidth,
    required this.localHeight,
  });

  final int stablePointerId;
  final Offset localPosition;
  final double pressure;
  final int buttons;
  final double localWidth;
  final double localHeight;
}

/// 视频触控逻辑复用 Mixin。
///
/// 具体 View 只需要提供尺寸/日志前缀，Mixin 负责：
/// - pointer 生命周期与稳定 ID 管理
/// - move 首帧直发 + 节流合并
/// - 触控坐标映射与发送
mixin VideoTouchMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// 当前真实纹理宽度（设备像素）。
  int get activeWidth;
  /// 当前真实纹理高度（设备像素）。
  int get activeHeight;
  /// 最近分辨率提示宽度。
  int get hintWidth;
  /// 最近分辨率提示高度。
  int get hintHeight;
  /// Flutter 渲染区域宽度。
  double get lastRenderWidth;
  /// Flutter 渲染区域高度。
  double get lastRenderHeight;
  /// 更新渲染区域宽度。
  set lastRenderWidth(double value);
  /// 更新渲染区域高度。
  set lastRenderHeight(double value);
  /// 日志前缀（由 View 定义）。
  String get touchDebugLabel;

  /// 稳定 pointerId 最大数量。
  static const int _maxStablePointerIds = 16;

  /// 活动 pointer 集合。
  final Set<int> _activePointers = <int>{};
  /// Flutter pointer -> 稳定 pointerId 映射。
  final Map<int, int> _pointerIdMap = <int, int>{};
  /// 稳定 pointerId 回收池。
  final List<int> _freePointerIds = <int>[];
  /// 每个 pointer 最近本地坐标缓存。
  final Map<int, Offset> _pointerLocalPositions = <int, Offset>{};
  /// move 缓冲：每个 pointer 只保留最新一帧。
  final Map<int, PendingMoveState> _pendingMovesByPointer =
      <int, PendingMoveState>{};
  /// 手势状态（用于抬手补偿）。
  final Map<int, TouchGestureState> _gestureByPointer =
      <int, TouchGestureState>{};
  /// 稳定 ID 游标。
  int _nextPointerId = 0;
  /// 触控丢弃日志节流时间戳。
  int _lastTouchDropLogMs = 0;
  /// move 节流定时器。
  Timer? _moveTicker;
  /// 触控串行队列，保证事件顺序。
  Future<void> _touchChain = Future<void>.value();

  /// 对外暴露最大 pointer 数。
  int get maxStablePointerIds => _maxStablePointerIds;

  /// 窗口尺寸变化时，清理触控状态。
  void handleTouchMetricsChanged() {
    _moveTicker?.cancel();
    _moveTicker = null;
    _pendingMovesByPointer.clear();
    unawaited(cancelAllActiveTouches());
  }

  /// 将本地坐标映射到设备坐标并发送。
  Future<void> sendTouch({
    required Offset localPosition,
    required double eventPressure,
    required int buttons,
    required control.AndroidMotionEventAction action,
    required double localWidth,
    required double localHeight,
    required int pointerId,
  }) async {
    final effectiveWidth = activeWidth > 0 ? activeWidth : hintWidth;
    final effectiveHeight = activeHeight > 0 ? activeHeight : hintHeight;
    if (effectiveWidth <= 0 || effectiveHeight <= 0) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastTouchDropLogMs > 1000) {
        _lastTouchDropLogMs = now;
        logDropTouch(activeWidth, activeHeight, hintWidth, hintHeight);
      }
      return;
    }

    final service = ref.read(deviceServiceProvider);
    final sessionId = service.currentSessionId;
    if (sessionId == null || sessionId.isEmpty) {
      return;
    }

    final dx = localWidth > 0 ? localPosition.dx / localWidth : 0;
    final dy = localHeight > 0 ? localPosition.dy / localHeight : 0;
    final normalizedX = dx.clamp(0.0, 1.0).toDouble();
    final normalizedY = dy.clamp(0.0, 1.0).toDouble();
    final mappedX = normalizedX * effectiveWidth;
    final mappedY = normalizedY * effectiveHeight;

    final minPressure =
        action == control.AndroidMotionEventAction.up ||
                action == control.AndroidMotionEventAction.cancel
            ? 0.0
            : 1.0;
    final pressure = math.max(minPressure, eventPressure);

    final touch = control.TouchEvent(
      action: action,
      pointerId: pointerId,
      x: mappedX,
      y: mappedY,
      pressure: pressure,
      width: effectiveWidth,
      height: effectiveHeight,
      buttons: buttons,
    );

    try {
      await service.sendTouchEvent(touch);
    } catch (e, st) {
      logSendTouchError(e, st);
    }
  }

  /// 基于 PointerEvent 的快捷发送。
  Future<void> sendTouchFromPointer(
    PointerEvent event,
    control.AndroidMotionEventAction action,
    double localWidth,
    double localHeight,
    int pointerId,
  ) async {
    await sendTouch(
      localPosition: event.localPosition,
      eventPressure: event.pressure,
      buttons: event.buttons,
      action: action,
      localWidth: localWidth,
      localHeight: localHeight,
      pointerId: pointerId,
    );
  }

  /// 串行执行触控发送任务。
  void enqueueTouchTask(Future<void> Function() task) {
    _touchChain = _touchChain.then((_) => task());
  }

  /// 启动 move 节流：8ms tick 合并发送。
  void scheduleMoveTicker() {
    if (_moveTicker != null) {
      return;
    }
    _moveTicker = Timer.periodic(const Duration(milliseconds: 8), (_) {
      if (_pendingMovesByPointer.isEmpty) {
        _moveTicker?.cancel();
        _moveTicker = null;
        return;
      }
      final snapshot = _pendingMovesByPointer.values.toList(growable: false);
      for (final move in snapshot) {
        enqueueTouchTask(
          () => sendTouch(
            localPosition: move.localPosition,
            eventPressure: move.pressure,
            buttons: move.buttons,
            action: control.AndroidMotionEventAction.move,
            localWidth: move.localWidth,
            localHeight: move.localHeight,
            pointerId: move.stablePointerId,
          ),
        );
      }
    });
  }

  /// 取消所有活动触点，避免设备端残留按下。
  Future<void> cancelAllActiveTouches() async {
    _moveTicker?.cancel();
    _moveTicker = null;
    final active = _activePointers.toList(growable: false);
    if (active.isEmpty) {
      _pendingMovesByPointer.clear();
      return;
    }
    final localW = lastRenderWidth > 0 ? lastRenderWidth : 1.0;
    final localH = lastRenderHeight > 0 ? lastRenderHeight : 1.0;
    final cancels = <({Offset pos, int pointerId})>[];
    for (final flutterPointer in active) {
      final stablePointerId = _peekStablePointerId(flutterPointer);
      if (stablePointerId == null) {
        continue;
      }
      final pos =
          _pointerLocalPositions[flutterPointer] ?? Offset(localW / 2, localH / 2);
      cancels.add((pos: pos, pointerId: stablePointerId));
    }
    _pendingMovesByPointer.clear();
    _gestureByPointer.clear();
    _activePointers.clear();
    _pointerLocalPositions.clear();
    _pointerIdMap.clear();
    _freePointerIds.clear();
    _nextPointerId = 0;
    if (cancels.isEmpty) {
      return;
    }
    _touchChain = _touchChain.then((_) async {
      for (final item in cancels) {
        await sendTouch(
          localPosition: item.pos,
          eventPressure: 0.0,
          buttons: 0,
          action: control.AndroidMotionEventAction.cancel,
          localWidth: localW,
          localHeight: localH,
          pointerId: item.pointerId,
        );
      }
    });
    await _touchChain;
  }

  /// 分配稳定 pointerId（优先复用）。
  int? _acquireStablePointerId(int flutterPointer) {
    final cached = _pointerIdMap[flutterPointer];
    if (cached != null) {
      return cached;
    }
    int? stableId;
    if (_freePointerIds.isNotEmpty) {
      stableId = _freePointerIds.removeLast();
    } else {
      for (var i = 0; i < _maxStablePointerIds; i++) {
        final candidate = (_nextPointerId + i) % _maxStablePointerIds;
        if (!_pointerIdMap.containsValue(candidate)) {
          stableId = candidate;
          _nextPointerId = (candidate + 1) % _maxStablePointerIds;
          break;
        }
      }
    }
    if (stableId == null) {
      return null;
    }
    _pointerIdMap[flutterPointer] = stableId;
    return stableId;
  }

  /// 查询稳定 pointerId（不创建）。
  int? _peekStablePointerId(int flutterPointer) => _pointerIdMap[flutterPointer];

  /// 释放稳定 pointerId。
  void _releaseStablePointerId(int flutterPointer) {
    final stableId = _pointerIdMap.remove(flutterPointer);
    if (stableId != null) {
      _freePointerIds.add(stableId);
    }
  }

  /// 清理所有触控状态（纹理切换/销毁）。
  void resetTouchState() {
    _moveTicker?.cancel();
    _moveTicker = null;
    _pendingMovesByPointer.clear();
    _gestureByPointer.clear();
    _pointerLocalPositions.clear();
    _activePointers.clear();
    _pointerIdMap.clear();
    _freePointerIds.clear();
    _nextPointerId = 0;
    lastRenderWidth = 0;
    lastRenderHeight = 0;
  }

  /// 构建触控 Listener（含首帧直发 + 节流）。
  Widget buildTouchListener({
    required Widget child,
    required double localW,
    required double localH,
  }) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        if (_activePointers.length >= _maxStablePointerIds) {
          _pendingMovesByPointer.clear();
          unawaited(cancelAllActiveTouches());
        }
        _activePointers.add(event.pointer);
        _pointerLocalPositions[event.pointer] = event.localPosition;
        _gestureByPointer[event.pointer] = TouchGestureState(
          downAt: DateTime.now(),
          downLocalPosition: event.localPosition,
          lastLocalPosition: event.localPosition,
          lastPressure: event.pressure,
          lastButtons: event.buttons,
        );
        final stablePointerId = _acquireStablePointerId(event.pointer);
        if (stablePointerId == null) {
          _activePointers.remove(event.pointer);
          _pointerLocalPositions.remove(event.pointer);
          return;
        }
        enqueueTouchTask(
          () => sendTouchFromPointer(
            event,
            control.AndroidMotionEventAction.down,
            localW,
            localH,
            stablePointerId,
          ),
        );
      },
      onPointerMove: (event) {
        if (!_activePointers.contains(event.pointer)) {
          return;
        }
        _pointerLocalPositions[event.pointer] = event.localPosition;
        final gesture = _gestureByPointer[event.pointer];
        final isFirstMove = gesture?.moveCount == 0;
        if (gesture != null) {
          gesture.lastLocalPosition = event.localPosition;
          gesture.lastPressure = event.pressure;
          gesture.lastButtons = event.buttons;
          gesture.moveCount += 1;
        }
        final stablePointerId = _peekStablePointerId(event.pointer);
        if (stablePointerId == null) {
          return;
        }
        if (isFirstMove == true) {
          enqueueTouchTask(
            () => sendTouch(
              localPosition: event.localPosition,
              eventPressure: event.pressure,
              buttons: event.buttons,
              action: control.AndroidMotionEventAction.move,
              localWidth: localW,
              localHeight: localH,
              pointerId: stablePointerId,
            ),
          );
          return;
        }
        _pendingMovesByPointer[event.pointer] = PendingMoveState(
          stablePointerId: stablePointerId,
          localPosition: event.localPosition,
          pressure: event.pressure,
          buttons: event.buttons,
          localWidth: localW,
          localHeight: localH,
        );
        scheduleMoveTicker();
      },
      onPointerUp: (event) {
        final pending = _pendingMovesByPointer.remove(event.pointer);
        _activePointers.remove(event.pointer);
        _pointerLocalPositions.remove(event.pointer);
        final gesture = _gestureByPointer.remove(event.pointer);
        final stablePointerId = _peekStablePointerId(event.pointer);
        _releaseStablePointerId(event.pointer);
        if (stablePointerId == null) {
          return;
        }
        enqueueTouchTask(
          () => TouchSwipeAssist.sendPointerUpWithSwipeAssist(
            event: event,
            stablePointerId: stablePointerId,
            localWidth: localW,
            localHeight: localH,
            gesture: gesture,
            pendingLocalPosition: pending?.localPosition,
            pendingPressure: pending?.pressure,
            pendingButtons: pending?.buttons,
            pendingLocalWidth: pending?.localWidth,
            pendingLocalHeight: pending?.localHeight,
            sendTouch: sendTouch,
          ),
        );
      },
      onPointerCancel: (event) {
        _pendingMovesByPointer.remove(event.pointer);
        _activePointers.remove(event.pointer);
        _pointerLocalPositions.remove(event.pointer);
        _gestureByPointer.remove(event.pointer);
        final stablePointerId = _peekStablePointerId(event.pointer);
        _releaseStablePointerId(event.pointer);
        if (stablePointerId == null) {
          return;
        }
        enqueueTouchTask(
          () => sendTouchFromPointer(
            event,
            control.AndroidMotionEventAction.cancel,
            localW,
            localH,
            stablePointerId,
          ),
        );
      },
      child: child,
    );
  }

  /// 触控丢弃日志。
  void logDropTouch(
    int activeWidth,
    int activeHeight,
    int hintWidth,
    int hintHeight,
  ) {
    Log.w(
      '$touchDebugLabel drop touch: video size not ready '
      'active=${activeWidth}x$activeHeight hint=${hintWidth}x$hintHeight',
    );
  }

  /// 触控发送失败日志。
  void logSendTouchError(Object e, StackTrace st) {
    Log.e('$touchDebugLabel send touch failed: $e', e, st);
  }
}


