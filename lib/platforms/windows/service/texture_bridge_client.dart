import 'package:flutter/services.dart';
import 'package:sw_game_helper/utils/logger_service.dart';

/// 统一纹理桥接客户端（DXGI + CPU PixelBuffer）。
///
/// 设计目的：
/// 1. 合并两套几乎重复的 MethodChannel 客户端；
/// 2. 统一 `create/bind/dispose` 调用模型，降低 UI 层分支复杂度；
/// 3. 仅保留发布链路必需方法，避免历史接口继续扩散。
enum TextureBridgeBackend {
  dxgi,
  cpuPixelBuffer,
}

class TextureBridgeClient {
  TextureBridgeClient._();

  static final TextureBridgeClient instance = TextureBridgeClient._();

  static const MethodChannel _channel = MethodChannel('dxgi_texture_bridge');

  /// 创建纹理并返回 Flutter `textureId`。
  ///
  /// 参数约束：
  /// - `dxgi` 模式必须传入有效 `handle`；
  /// - 两种模式都要求 `width/height/generation` 有效。
  Future<int> createTexture({
    required TextureBridgeBackend backend,
    required int width,
    required int height,
    required int generation,
    int? handle,
  }) async {
    if (width <= 0 || height <= 0) {
      throw ArgumentError('createTexture width/height invalid');
    }

    if (backend == TextureBridgeBackend.dxgi) {
      final h = handle ?? 0;
      if (h <= 0) {
        throw ArgumentError('createTexture handle invalid for dxgi');
      }
      final id = await _channel.invokeMethod<int>('createTexture', {
        'handle': h,
        'width': width,
        'height': height,
        'generation': generation,
      });
      if (id == null || id <= 0) {
        throw StateError('createTexture(dxgi) returned invalid id');
      }
      Log.i(
        '[TextureBridge] create dxgi id=$id handle=$h ${width}x$height gen=$generation',
      );
      return id;
    }

    final id = await _channel.invokeMethod<int>('createCpuPixelTexture', {
      'width': width,
      'height': height,
      'generation': generation,
    });
    if (id == null || id <= 0) {
      throw StateError('createTexture(cpuPixelBuffer) returned invalid id');
    }
    Log.i(
      '[TextureBridge] create cpu id=$id ${width}x$height gen=$generation',
    );
    return id;
  }

  /// 绑定纹理到 Runner 回调链路。
  ///
  /// - `dxgi` -> `bindDxgiTexture`
  /// - `cpuPixelBuffer` -> `bindCpuPixelTexture`
  Future<void> bindTexture({
    required TextureBridgeBackend backend,
    required int textureId,
  }) async {
    if (textureId <= 0) {
      throw ArgumentError('bindTexture textureId invalid');
    }

    final method = backend == TextureBridgeBackend.dxgi
        ? 'bindDxgiTexture'
        : 'bindCpuPixelTexture';
    await _channel.invokeMethod<bool>(method, {'textureId': textureId});
    Log.i('[TextureBridge] bind ${backend.name} id=$textureId');
  }

  /// 销毁纹理并释放 Runner 侧资源。
  Future<void> disposeTexture({
    required TextureBridgeBackend backend,
    required int textureId,
  }) async {
    if (textureId <= 0) {
      return;
    }

    final method = backend == TextureBridgeBackend.dxgi
        ? 'disposeTexture'
        : 'disposeCpuPixelTexture';
    await _channel.invokeMethod<bool>(method, {'textureId': textureId});
    Log.i('[TextureBridge] dispose ${backend.name} id=$textureId');
  }
}
