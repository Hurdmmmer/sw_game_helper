import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sw_game_helper/enums/connection_status.dart';
import 'package:sw_game_helper/platforms/windows/bridge_generated/gh_common/model.dart';
import 'package:sw_game_helper/platforms/windows/providers/device_provider.dart';
import 'package:sw_game_helper/platforms/windows/service/texture_bridge_client.dart';
import 'package:sw_game_helper/platforms/windows/ui/widgets/touch_input_controller.dart';
import 'package:sw_game_helper/utils/logger_service.dart';

/// 单组件双后端：DXGI（V1）与 CPU PixelBuffer（V2）。
enum VideoRenderBackend { dxgi, cpuPixelBuffer }

/// 视频显示组件（真实纹理渲染）。
///
/// 规则：
/// 1. 只显示当前会话 `sessionId` 的帧；
/// 2. 只接受当前及更新代际 `generation`；
/// 3. 使用“单 textureId + 句柄更新”策略，减少状态复杂度；
/// 4. 断开或会话切换时必须释放旧纹理，防止串流；
/// 5. 触控坐标按当前纹理尺寸映射到设备像素坐标。
class VideoView extends ConsumerStatefulWidget {
  const VideoView({super.key, this.backend = VideoRenderBackend.dxgi});

  final VideoRenderBackend backend;

  @override
  ConsumerState<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends ConsumerState<VideoView>
    with WidgetsBindingObserver, VideoTouchMixin<VideoView> {
  /// 统一纹理桥接客户端。
  final _textureBridge = TextureBridgeClient.instance;

  /// 连接状态订阅。
  /// 仅用于“运行时门控”（connected -> start，其他状态 -> stop）。
  StreamSubscription<ConnectionStatus>? _statusSub;

  /// 会话事件订阅。
  StreamSubscription<SessionEvent>? _eventSub;

  /// FPS 定时器。
  Timer? _fpsTimer;

  /// 串行化渲染状态处理链。
  ///
  /// 约束：
  /// - 任何纹理生命周期动作（create/bind/dispose）都必须进入该链；
  /// - 避免事件并发导致的状态回滚和资源双重释放。
  Future<void> _frameChain = Future<void>.value();

  /// 标记当前 Widget 已进入销毁流程。
  /// 用于阻止后续异步链继续访问 `ref` / `setState`。
  bool _isDisposing = false;

  /// 当前 Flutter 纹理 ID。
  int? _textureId;

  /// 当前绑定的共享句柄。
  // ignore: unused_field
  int _activeHandle = 0;

  /// 当前纹理宽度。
  int _activeWidth = 0;

  /// 当前纹理高度。
  int _activeHeight = 0;

  /// 当前代际号（防止旧帧回滚）。
  int _activeGeneration = -1;

  /// 当前会话 ID。
  String? _activeSessionId;

  /// FPS 数值。
  double _fps = 0;

  /// 记录上一次 build 看到的连接状态，避免重复刷屏日志。
  ConnectionStatus? _lastBuildStatus;

  /// 记录 runtime 是否已启动，确保 start/stop 幂等。
  bool _runtimeStarted = false;

  /// 分辨率提示尺寸（来自 session event，用于触控映射兜底）。
  int _hintWidth = 0;
  int _hintHeight = 0;

  /// 最近一次渲染区域尺寸（Flutter 侧实际 Texture 显示尺寸）。
  double _lastRenderWidth = 0;
  double _lastRenderHeight = 0;

  // 指定连接模式时CPU模式，还是GPU模式
  bool get _useCpuPixel => widget.backend == VideoRenderBackend.cpuPixelBuffer;

  TextureBridgeBackend get _bridgeBackend => _useCpuPixel
      ? TextureBridgeBackend.cpuPixelBuffer
      : TextureBridgeBackend.dxgi;

  @override
  void initState() {
    super.initState();
    Log.i('VideoView initState: backend=${widget.backend.name}');
    // 监听窗口尺寸变化，用于触控状态清理。
    WidgetsBinding.instance.addObserver(this);
    // 只绑定“连接状态门控”。
    // 真正的会话事件流/FPS 轮询由 connected 状态触发启动。
    _bindRuntimeGate();
  }

  @override
  void didUpdateWidget(covariant VideoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.backend != widget.backend) {
      Log.i(
        'VideoView didUpdateWidget: backend changed '
        '${oldWidget.backend.name} -> ${widget.backend.name}',
      );
    }
  }

  @override
  void didChangeMetrics() {
    // 窗口移动/缩放/跨屏切换后，Flutter 可能丢失当前 pointer 的 up/cancel。
    // 主动清理触点，避免设备端残留“按住”状态导致后续触控失效。
    handleTouchMetricsChanged();
    super.didChangeMetrics();
  }

  /// 绑定“连接状态门控”。
  ///
  /// 策略：
  /// - `connected`：启动 runtime；
  /// - 其余状态：停止 runtime 并释放纹理资源。
  void _bindRuntimeGate() {
    final service = ref.read(deviceServiceProvider);

    _statusSub = service.connectionStatus.listen((status) {
      if (_isDisposing) {
        return;
      }
      Log.d(
        'VideoView runtime gate status: $status',
      );
      final shouldRun = status == ConnectionStatus.connected;
      if (shouldRun) {
        _startRuntimeIfNeeded();
      } else {
        unawaited(_stopRuntimeIfNeeded());
      }
    });
  }

  /// 启动运行时（幂等）。
  ///
  /// 只在 connected 时调用，内部负责：
  /// 1. 绑定会话事件流；
  /// 2. 启动 FPS 采样计时器。
  void _startRuntimeIfNeeded() {
    if (_runtimeStarted || _isDisposing) {
      return;
    }
    _runtimeStarted = true;
    Log.i('VideoView runtime start');
    _bindStreams();
    _startFpsTimer();
  }

  /// 停止运行时（幂等）。
  ///
  /// 内部负责：
  /// 1. 停止 FPS 计时器；
  /// 2. 取消会话事件订阅；
  /// 3. 串行释放当前纹理。
  Future<void> _stopRuntimeIfNeeded({bool fromDispose = false}) async {
    if (!_runtimeStarted && !fromDispose) {
      return;
    }
    _runtimeStarted = false;
    Log.i('VideoView runtime stop: fromDispose=$fromDispose');

    _fpsTimer?.cancel();
    _fpsTimer = null;
    await _eventSub?.cancel();
    _eventSub = null;

    _frameChain = _frameChain.then(
      (_) => _disposeCurrentTexture(
        skipTouchCancel: fromDispose,
        updateUiState: !fromDispose,
      ),
    );
    await _frameChain;
  }

  /// 绑定会话事件流（运行时已启动后才会调用）。
  void _bindStreams() {
    final service = ref.read(deviceServiceProvider);

    // 防止重复绑定旧订阅。
    unawaited(_eventSub?.cancel());
    _eventSub = null;

    _eventSub = service.streamSessionEvents().listen(
      (event) {
        if (_isDisposing) {
          return;
        }
        event.when(
          starting: () {},
          running: () {},
          reconnecting: () {},
          stopped: () {
            // 会话停止释放纹理。
            Log.i('VideoView session event: stopped, schedule dispose');
            _frameChain = _frameChain.then((_) => _disposeCurrentTexture());
          },
          error: (code, message) {
            Log.w('VideoView session error: $code $message');
            // 异常状态释放纹理。
            _frameChain = _frameChain.then((_) => _disposeCurrentTexture());
          },
          orientationChanged: (mode, source) {},
          // 使用事件驱动纹理生命周期。
          // 回调只负责“持续刷新”，分辨率/代际切换由事件控制。
          resolutionChanged: (width, height, newHandle, generation) {
            final gen = generation.toInt();
            _hintWidth = width;
            _hintHeight = height;
            // 所有状态转换进入串行链，避免分辨率事件与停止事件并发交错。
            _frameChain = _frameChain.then(
              (_) => _handleResolutionChanged(
                width,
                height,
                newHandle.toInt(),
                gen,
              ),
            );
          },
        );
      },
      onError: (Object e, StackTrace st) {
        Log.e('VideoView event stream error: $e', e, st);
      },
    );
  }

  /// 每秒拉一次统计信息显示 FPS。
  void _startFpsTimer() {
    _fpsTimer?.cancel();
    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_isDisposing || !mounted || !_runtimeStarted) {
        return;
      }
      final service = ref.read(deviceServiceProvider);
      final stats = await service.getCurrentSessionStats();
      if (!mounted) {
        return;
      }
      setState(() {
        _fps = stats?.fps ?? 0;
      });
    });
  }

  /// 处理分辨率/代际变更：创建并绑定单纹理，后续帧由 Runner 回调驱动。
  ///
  /// 状态机：
  /// 1. 校验 session；
  /// 2. session 切换时先 dispose；
  /// 3. 代际回退直接丢弃；
  /// 4. 尺寸或代际变化触发重建；
  /// 5. 首次创建后调用 `bindTexture` 建立回调驱动链路。
  Future<void> _handleResolutionChanged(
    int width,
    int height,
    int handle,
    int generation,
  ) async {
    if (_isDisposing) {
      return;
    }
    final service = ref.read(deviceServiceProvider);
    final sessionId = service.currentSessionId;
    if (sessionId == null || sessionId.isEmpty) {
      // 无有效会话直接丢弃。
      return;
    }

    // 会话切换时必须先释放旧纹理，再绑定新会话。
    if (_activeSessionId != sessionId) {
      await _disposeCurrentTexture();
      _activeSessionId = sessionId;
      Log.i('VideoView bind session: $_activeSessionId');
    }

    // 尺寸无效直接丢弃；DXGI 模式下还需要校验 handle。
    final handleInvalid = !_useCpuPixel && handle <= 0;
    if (handleInvalid || width <= 0 || height <= 0) {
      Log.w(
        'VideoView drop invalid resolution event: '
        'backend=${widget.backend.name} handle=$handle size=${width}x$height gen=$generation',
      );
      return;
    }

    // 旧代际事件丢弃，防止旋转后回滚旧画面。
    if (generation < _activeGeneration) {
      Log.d(
        'VideoView drop stale resolution event: frame_gen=$generation active_gen=$_activeGeneration',
      );
      return;
    }

    try {
      // 分辨率或代际变化时销毁并重建纹理。
      // 这里保持保守策略，优先保证上线稳定性而非最小重建次数。
      if ((_activeWidth > 0 && _activeHeight > 0) &&
          (width != _activeWidth ||
              height != _activeHeight ||
              generation != _activeGeneration)) {
        await _disposeCurrentTexture();
        _activeSessionId = sessionId;
      }

      if (_textureId == null) {
        // 首次创建纹理。
        final textureId = await _textureBridge.createTexture(
          backend: _bridgeBackend,
          width: width,
          height: height,
          generation: generation,
          handle: _useCpuPixel ? null : handle,
        );

        if (!mounted) {
          await _textureBridge.disposeTexture(
            backend: _bridgeBackend,
            textureId: textureId,
          );
          return;
        }

        setState(() {
          _textureId = textureId;
          _activeHandle = handle;
          _activeWidth = width;
          _activeHeight = height;
          _activeGeneration = generation;
          _hintWidth = width;
          _hintHeight = height;
        });
        Log.i(
          'VideoView create texture: '
          'backend=${widget.backend.name} id=$textureId '
          'handle=$handle size=${width}x$height gen=$generation',
        );
        // 绑定后由 Rust->Runner 回调持续驱动新帧渲染。
        await _textureBridge.bindTexture(
          backend: _bridgeBackend,
          textureId: textureId,
        );
      }

      _activeHandle = handle;
      _activeWidth = width;
      _activeHeight = height;
      _activeGeneration = generation;
      _hintWidth = width;
      _hintHeight = height;
    } catch (e, st) {
      Log.e('VideoView texture bridge failed: $e', e, st);
    }
  }

  /// 释放当前纹理并重置本地渲染状态。
  Future<void> _disposeCurrentTexture({
    bool skipTouchCancel = false,
    bool updateUiState = true,
  }) async {
    Log.i(
      'VideoView dispose texture start: '
      'id=$_textureId backend=${widget.backend.name} '
      'skipTouchCancel=$skipTouchCancel updateUiState=$updateUiState',
    );
    // 正常流程下先取消触控，避免设备端残留按下状态。
    // 销毁流程下跳过该步骤，避免异步阶段继续访问 ref。
    if (!skipTouchCancel && mounted && !_isDisposing) {
      await cancelAllActiveTouches();
    } else {
      resetTouchState();
    }
    final textureId = _textureId;
    _textureId = null;

    if (textureId != null) {
      try {
        // dispose 会在 Runner 侧自动解绑 active texture。
        await _textureBridge.disposeTexture(
          backend: _bridgeBackend,
          textureId: textureId,
        );
      } catch (e, st) {
        Log.e('VideoView dispose texture failed: $e', e, st);
      }
    }

    if (!updateUiState || !mounted || _isDisposing) {
      return;
    }

    setState(() {
      _activeHandle = 0;
      _activeWidth = 0;
      _activeHeight = 0;
      _hintWidth = 0;
      _hintHeight = 0;
      _activeGeneration = -1;
      _activeSessionId = null;
      _fps = 0;
      resetTouchState();
    });
    Log.i('VideoView dispose texture done');
  }

  @override
  void dispose() {
    Log.i('VideoView dispose begin: backend=${widget.backend.name}');
    _isDisposing = true;
    // 解绑窗口监听。
    WidgetsBinding.instance.removeObserver(this);
    // 先取消 gate，再停 runtime，避免 dispose 期间再次触发 start。
    _statusSub?.cancel();
    _statusSub = null;
    // 明确告诉分析器：这里故意不等待，避免 dispose 阻塞 UI 线程。
    unawaited(_stopRuntimeIfNeeded(fromDispose: true));
    Log.i('VideoView dispose end');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 连接状态统一入口。
    final statusAsync = ref.watch(deviceConnectionStatusProvider);

    return statusAsync.when(
      loading: () => const Center(
        child: Text('未连接设备', style: TextStyle(color: Colors.white54)),
      ),
      error: (error, stackTrace) => const Center(
        child: Text('状态读取失败', style: TextStyle(color: Colors.redAccent)),
      ),
      data: (status) {
        if (_lastBuildStatus != status) {
          _lastBuildStatus = status;
          Log.i(
            'VideoView build status changed: '
            'status=$status textureId=$_textureId backend=${widget.backend.name}',
          );
        }
        if (status == ConnectionStatus.connecting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (status != ConnectionStatus.connected) {
          return const Center(
            child: Text('未连接设备', style: TextStyle(color: Colors.white54)),
          );
        }

        if (_textureId == null) {
          return const Center(
            child: Text('未连接设备', style: TextStyle(color: Colors.white54)),
          );
        }

        // 使用当前纹理尺寸计算显示比例。
        final ratio = (_activeWidth > 0 && _activeHeight > 0)
            ? _activeWidth / _activeHeight
            : 16 / 9;

        return Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: ratio,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final localW = constraints.maxWidth;
                    final localH = constraints.maxHeight;

                    // 渲染区域变化日志：用于验证“窗口缩放后触控区域是否同步重算”。
                    final changed =
                        (_lastRenderWidth - localW).abs() > 0.5 ||
                        (_lastRenderHeight - localH).abs() > 0.5;
                    if (changed) {
                      _lastRenderWidth = localW;
                      _lastRenderHeight = localH;
                      Log.i(
                        'VideoView render size changed: '
                        '${localW.toStringAsFixed(1)}x${localH.toStringAsFixed(1)} '
                        'video=${_activeWidth}x$_activeHeight gen=$_activeGeneration',
                      );
                    }

                    // 触控 Listener 包裹 Texture。
                    return buildTouchListener(
                      child: Texture(textureId: _textureId!),
                      localW: localW,
                      localH: localH,
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                color: Colors.black54,
                child: Text(
                  '${widget.backend.name}  FPS ${_fps.toStringAsFixed(1)}  ${_activeWidth}x$_activeHeight  gen=$_activeGeneration',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// VideoTouchMixin 参数适配（尺寸/日志前缀）。
  @override
  int get activeWidth => _activeWidth;

  @override
  int get activeHeight => _activeHeight;

  @override
  int get hintWidth => _hintWidth;

  @override
  int get hintHeight => _hintHeight;

  @override
  double get lastRenderWidth => _lastRenderWidth;

  @override
  double get lastRenderHeight => _lastRenderHeight;

  @override
  set lastRenderWidth(double value) => _lastRenderWidth = value;

  @override
  set lastRenderHeight(double value) => _lastRenderHeight = value;

  @override
  String get touchDebugLabel => 'VideoView(${widget.backend.name})';
}





