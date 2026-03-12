#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/encodable_value.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter_windows.h>

#include <windows.h>
#include <d3d11.h>

// ────────────────────────────────────────────────────────────────────────────
// 引入 <atomic>，用于 TextureEntry::in_use 原子标志（线程安全）。
// std::atomic<bool> 支持在渲染线程（ObtainGpuDescriptor 回调）和
// Dart/主线程（DisposeTexture / MarkFrameAvailable）之间无锁安全访问。
// ────────────────────────────────────────────────────────────────────────────
#include <atomic>
#include <cstdint>
#include <memory>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

#include "win32_window.h"

class FlutterWindow : public Win32Window {
 public:
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();
  void OnRustV2Frame(uint64_t frame_id,
                     const uint8_t* data,
                     size_t data_len,
                     uint32_t width,
                     uint32_t height,
                     uint32_t stride,
                     uint32_t pixel_format,
                     uint64_t generation,
                     int64_t pts);
  void OnRustV1Frame(int64_t handle,
                     uint32_t width,
                     uint32_t height,
                     uint64_t generation,
                     int64_t pts);
  /// Rust 会话事件回调入口（JSON 字符串透传到 Dart）。
  void OnRustSessionEvent(const std::string& session_id,
                          const std::string& event_json);
  /// Rust 日志回调入口（level + message 透传到 Dart）。
  void OnRustLog(const std::string& level, const std::string& message);

 protected:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // ──────────────────────────────────────────────────────────────────────────
  // TextureEntry：每张 Flutter 外部纹理（对应一个 DXGI 共享句柄）的运行时状态。
  //
  // 生命周期：
  //   CreateTexture/CreateTexturePair → 分配 → MarkFrameAvailable 驱动渲染
  //   → DisposeTexture → 释放
  //
  // 线程模型：
  //   - texture_mutex_ 保护 texture_entries_ map 的增删改；
  //   - in_use 是原子变量，不在 mutex 保护范围内（避免死锁），
  //     由渲染线程（ObtainGpuDescriptor）写 true、由 Flutter 描述符释放
  //     回调（OnGpuSurfaceReleased）写 false。
  // ──────────────────────────────────────────────────────────────────────────
  struct TextureEntry {
    /// Flutter 注册的纹理 ID，用于 markFrameAvailable / unregister 调用
    int64_t texture_id = 0;

    /// DXGI 共享句柄值（Rust 侧 GetSharedHandle() 返回的 HANDLE 转为 int64_t）
    int64_t handle = 0;

    /// 纹理分辨率（像素）。旋转/重配置时 Rust 会重建纹理，handle 会变化。
    uint32_t width = 0;
    uint32_t height = 0;

    /// 代际编号（Rust generation 值），用于区分旋转前后的纹理对，
    /// 防止 Flutter 渲染旋转前的旧帧。
    uint64_t generation = 0;

    /// markFrameAvailable 调用计数（调试/日志采样用）。
    /// 使用原子类型，避免回调线程与主线程并发递增时发生 data race。
    std::atomic<uint64_t> mark_count{0};

    /// 已打开的共享纹理对象（当前未主动使用，保留供未来调试/读回用）
    ID3D11Texture2D* shared_texture = nullptr;

    /// Flutter GPU Surface 描述符：ObtainGpuDescriptor 直接返回此结构的指针。
    /// 字段由 FillDescriptor() 填充，release_callback 在 ObtainGpuDescriptor
    /// 中设置（每次获取时重新设置，确保 context 始终正确）。
    FlutterDesktopGpuSurfaceDescriptor descriptor{};

    /// Flutter 纹理注册所需的元信息（类型 = kFlutterDesktopGpuSurfaceTexture）
    FlutterDesktopTextureInfo texture_info{};

    /// GPU Surface 纹理配置（类型 = kFlutterDesktopGpuSurfaceTypeDxgiSharedHandle，
    /// 回调 = ObtainGpuDescriptor，user_data = this）
    FlutterDesktopGpuSurfaceTextureConfig gpu_config{};

    // 保护 V1 回调路径下对 handle/size/generation/descriptor 的并发访问。
    // - 写入线程：RustV1FrameBridge -> OnRustV1Frame
    // - 读取线程：Flutter 渲染线程 -> ObtainGpuDescriptor
    std::mutex state_mutex;

    // ── 【新增】双缓冲安全追踪标志 ─────────────────────────────────────────
    //
    // in_use：标记此纹理描述符当前是否正被 Flutter 渲染引擎持有。
    //
    // 工作流程：
    //   1. Flutter 调用 ObtainGpuDescriptor()  → in_use 置 true
    //   2. Flutter 完成本帧渲染后调用 release_callback → in_use 置 false
    //
    // 用途（当前 + 未来）：
    //   - 当前：日志/调试时可查看哪个槽仍在被 Flutter 持有；
    //   - 未来：Rust 侧轮询此标志，可实现「不覆写正在被读取的槽」，
    //           进一步加固双缓冲安全性（需配合 Rust 侧逻辑扩展）。
    //
    // 线程安全：std::atomic<bool> 保证无锁读写正确性。
    std::atomic<bool> in_use{false};

    // 释放标记：DisposeTexture 会先置 true，渲染线程读取到后不再返回描述符。
    // 真正的对象销毁延迟到 UnregisterExternalTexture 完成回调，避免 UAF。
    std::atomic<bool> disposed{false};
  };

  // PixelBuffer 回调链路纹理条目：
  // 1) Dart 创建 CPU PixelBuffer 纹理并绑定；
  // 2) Rust 回调线程写入快照环；
  // 3) Flutter 通过 kFlutterDesktopPixelBufferTexture 回调读取。
  struct PixelTextureEntry {
    int64_t texture_id = 0;
    int64_t handle = 0;
    uint32_t width = 0;
    uint32_t height = 0;
    uint64_t generation = 0;
    // 帧标记计数（日志采样用）。
    // PixelBuffer 路径存在回调线程/主线程并发访问，必须使用原子计数。
    std::atomic<uint64_t> mark_count{0};
    FlutterDesktopTextureInfo texture_info{};
    FlutterDesktopPixelBufferTextureConfig pixel_config{};
    FlutterDesktopPixelBuffer pixel_buffer{};
    // latest_frame: 最新完整帧（生产线程写入）
    std::vector<uint8_t> latest_frame;
    // render_snapshots: 给 Flutter 回调使用的快照环，避免读写同一块内存导致花屏
    std::vector<std::vector<uint8_t>> render_snapshots;
    // 每个快照页是否仍被 Flutter 持有（由 release_callback 回收）
    std::vector<uint8_t> snapshot_in_use;
    size_t next_snapshot_index = 0;
    size_t published_snapshot_index = 0;
    bool has_published_snapshot = false;
    std::string pixel_format = "bgra32";
    std::mutex buffer_mutex;
    // 供 CopyPixelBuffer 回调在“仅拿到裸 user_data”场景下恢复 shared_ptr 持有。
    // 用于防止 release_callback 延迟回调期间对象被提前析构。
    std::weak_ptr<PixelTextureEntry> weak_self;
    std::atomic<bool> disposed{false};
  };

  flutter::DartProject project_;
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
  FlutterDesktopTextureRegistrarRef texture_registrar_ = nullptr;

  std::mutex texture_mutex_;
  std::unordered_map<int64_t, std::shared_ptr<TextureEntry>> texture_entries_;
  std::unordered_map<int64_t, std::shared_ptr<PixelTextureEntry>>
      pixel_texture_entries_;
  std::atomic<int64_t> active_cpu_pixel_texture_id_{0};
  // 当前绑定到 V1 回调链路的 DXGI textureId。
  // Rust 回调每到一帧都会直接驱动该纹理刷新。
  std::atomic<int64_t> active_dxgi_texture_id_{0};
  std::atomic<bool> rust_v2_callback_registered_{false};
  // V1 回调注册标记：确保只向 Rust 注册一次回调函数指针。
  std::atomic<bool> rust_v1_callback_registered_{false};
  // SessionEvent 回调注册标记：确保只向 Rust 注册一次回调函数指针。
  std::atomic<bool> rust_session_event_callback_registered_{false};
  // RustLog 回调注册标记：确保只向 Rust 注册一次回调函数指针。
  std::atomic<bool> rust_log_callback_registered_{false};

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      window_title_channel_;
  /// 纹理桥接通道：
  /// - Dart -> Runner：create/bind/dispose 纹理；
  /// - 不承载会话事件绑定与分发。
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      texture_bridge_channel_;
  /// 会话事件桥接通道：
  /// - Dart -> Runner：bindSessionEvents（一次性绑定）；
  /// - Runner -> Dart：onSessionEvent（事件分发）。
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      session_event_bridge_channel_;

  void RegisterWindowTitleChannel();
  /// 注册纹理桥接通道。
  ///
  /// 作用：
  /// - 建立 MethodChannel `texture_bridge`；
  /// - 绑定纹理方法分发入口（HandleTextureBridgeCall）。
  void RegisterTextureBridge();
  /// 注册会话事件桥接通道。
  ///
  /// 作用：
  /// - 建立 MethodChannel `session_event_bridge`；
  /// - 绑定事件方法分发入口（HandleSessionEventBridgeCall）。
  void RegisterSessionEventBridge();

  bool CreateTexture(const flutter::EncodableMap& args, int64_t* texture_id,
                     std::string* error);
  bool DisposeTexture(const flutter::EncodableMap& args, std::string* error);
  bool DisposePixelTexture(const flutter::EncodableMap& args,
                           std::string* error);
  bool CreateCpuPixelTexture(const flutter::EncodableMap& args,
                             int64_t* texture_id,
                             std::string* error);
  bool BindCpuPixelTexture(const flutter::EncodableMap& args, std::string* error);
  // 绑定 V1 DXGI 纹理到 Rust 回调驱动链路。
  bool BindDxgiTexture(const flutter::EncodableMap& args, std::string* error);
  /// 绑定会话事件回调链路（Rust -> Runner -> Dart）。
  ///
  /// 调用时机：
  /// - 由 Dart 侧初始化调用 `bindSessionEvents` 触发；
  /// - 仅需绑定一次，重复调用幂等。
  bool BindSessionEvents(std::string* error);
  bool DisposeCpuPixelTexture(const flutter::EncodableMap& args,
                              std::string* error);
  /// 确保 Rust V2 回调已注册（CPU 像素帧路径）。
  ///
  /// 参数：
  /// - error：失败时写入可读错误信息；成功时保持不变。
  ///
  /// 返回：
  /// - true：已注册成功（包含“此前已注册”的幂等成功）；
  /// - false：注册失败，调用方应中止后续绑定流程。
  ///
  /// 失败场景：
  /// - 无法从 rust_scrcpy.dll 解析注册函数符号；
  /// - Rust 侧注册函数返回 false。
  bool EnsureRustV2CallbackRegistered(std::string* error);
  /// 确保 Rust V1 回调已注册（共享句柄元信息路径）。
  ///
  /// 参数：
  /// - error：失败时写入可读错误信息；成功时保持不变。
  ///
  /// 返回：
  /// - true：已注册成功（包含“此前已注册”的幂等成功）；
  /// - false：注册失败，调用方应中止后续绑定流程。
  bool EnsureRustV1CallbackRegistered(std::string* error);
  /// 确保 Rust SessionEvent 回调已注册（会话事件 JSON 路径）。
  ///
  /// 参数：
  /// - error：失败时写入可读错误信息；成功时保持不变。
  ///
  /// 返回：
  /// - true：已注册成功（包含“此前已注册”的幂等成功）；
  /// - false：注册失败，调用方应中止后续事件绑定流程。
  bool EnsureRustSessionEventCallbackRegistered(std::string* error);
  /// 确保 Rust 日志回调已注册（Rust tracing 日志路径）。
  ///
  /// 参数：
  /// - error：失败时写入可读错误信息；成功时保持不变。
  ///
  /// 返回：
  /// - true：已注册成功（包含“此前已注册”的幂等成功）；
  /// - false：注册失败，调用方应中止后续日志绑定流程。
  bool EnsureRustLogCallbackRegistered(std::string* error);
  /// 纹理桥接方法分发入口（用于收敛 flutter_window.cpp 体积）。
  ///
  /// 承载的方法族：
  /// - createTexture/createCpuPixelTexture；
  /// - bindDxgiTexture/bindCpuPixelTexture；
  /// - disposeTexture/disposeCpuPixelTexture。
  bool HandleTextureBridgeCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  /// 会话事件桥接方法分发入口。
  ///
  /// 承载的方法族：
  /// - bindSessionEvents。
  bool HandleSessionEventBridgeCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void DisposeAllTextures();

  // ── Flutter 纹理回调（静态方法，符合 C 函数指针签名要求）────────────────

  /// Flutter 引擎调用此函数获取 GPU Surface 描述符（每帧渲染前调用一次）。
  ///
  /// 此时设置 release_callback，以便 Flutter 用完描述符后通知我们，
  /// 从而追踪哪个纹理槽「正在被 Flutter 使用」。
  static const FlutterDesktopGpuSurfaceDescriptor* ObtainGpuDescriptor(
      size_t width, size_t height, void* user_data);

  /// Flutter 引擎释放 GPU Surface 描述符时调用此回调。
  ///
  /// 将对应 TextureEntry 的 in_use 标志置 false，
  /// 表示 Flutter 已完成对该描述符的持有，Rust 侧可安全写入该槽。
  static void OnGpuSurfaceReleased(void* release_context);

  static const FlutterDesktopPixelBuffer* CopyPixelBuffer(size_t width,
                                                           size_t height,
                                                           void* user_data);
  static void OnPixelBufferReleased(void* release_context);

  /// Flutter 完成注销外部纹理后调用，用于延迟释放 TextureEntry 生命周期。
  static void OnTextureUnregistered(void* user_data);
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
