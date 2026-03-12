#include "flutter_window.h"

#include "flutter_window_internal.h"
#include "rust_scrcpy_dll_api.h"

#include <cstring>

namespace {
// Rust -> C++ 桥回调（V2 CPU 像素帧）。
void RustV2FrameBridge(void* user_data,
                       uint64_t frame_id,
                       const uint8_t* data,
                       size_t data_len,
                       uint32_t width,
                       uint32_t height,
                       uint32_t stride,
                       uint32_t pixel_format,
                       uint64_t generation,
                       int64_t pts) {
  auto* self = static_cast<FlutterWindow*>(user_data);
  if (self == nullptr) {
    return;
  }
  self->OnRustV2Frame(frame_id, data, data_len, width, height, stride,
                      pixel_format, generation, pts);
}

// Rust -> C++ 桥回调（V1 共享句柄元信息）。
void RustV1FrameBridge(void* user_data,
                       int64_t handle,
                       uint32_t width,
                       uint32_t height,
                       uint64_t generation,
                       int64_t pts) {
  auto* self = static_cast<FlutterWindow*>(user_data);
  if (self == nullptr) {
    return;
  }
  self->OnRustV1Frame(handle, width, height, generation, pts);
}

// Rust -> C++ 桥回调（SessionEvent JSON）。
void RustSessionEventBridge(void* user_data,
                            const uint8_t* session_id,
                            size_t session_id_len,
                            const uint8_t* event_json,
                            size_t event_json_len) {
  auto* self = static_cast<FlutterWindow*>(user_data);
  if (self == nullptr || session_id == nullptr || event_json == nullptr ||
      session_id_len == 0 || event_json_len == 0) {
    return;
  }
  self->OnRustSessionEvent(
      std::string(reinterpret_cast<const char*>(session_id), session_id_len),
      std::string(reinterpret_cast<const char*>(event_json), event_json_len));
}

// Rust -> C++ 桥回调（Rust tracing 日志）。
void RustLogBridge(void* user_data,
                   const uint8_t* level,
                   size_t level_len,
                   const uint8_t* message,
                   size_t message_len) {
  auto* self = static_cast<FlutterWindow*>(user_data);
  if (self == nullptr || level == nullptr || message == nullptr ||
      level_len == 0 || message_len == 0) {
    return;
  }
  self->OnRustLog(
      std::string(reinterpret_cast<const char*>(level), level_len),
      std::string(reinterpret_cast<const char*>(message), message_len));
}
}  // namespace

bool FlutterWindow::EnsureRustV2CallbackRegistered(std::string* error) {
  // 功能：确保 Rust V2 帧回调注册完成（CPU 像素帧路径）。
  //
  // 参数说明：
  // - error：输出参数。注册失败时写入错误文案，供 Dart/日志定位问题。
  //
  // 设计说明：
  // - 该函数是幂等的；重复调用不会重复注册；
  // - 只有在 bindCpuPixelTexture 成功前调用才有意义。
  if (rust_v2_callback_registered_.load(std::memory_order_acquire)) {
    return true;
  }
  auto& rust_api = RustScrcpyDllApi::Instance();
  const auto register_fn = rust_api.RegisterV2(error);
  if (register_fn == nullptr) {
    return false;
  }
  const bool ok = register_fn(&RustV2FrameBridge, this);
  if (!ok) {
    if (error) *error = "V2 回调注册失败：Rust 返回 false";
    return false;
  }
  rust_v2_callback_registered_.store(true, std::memory_order_release);
  OutputDebugStringA("[渲染-V2] Rust 帧回调注册成功\n");
  return true;
}

bool FlutterWindow::EnsureRustV1CallbackRegistered(std::string* error) {
  // 功能：确保 Rust V1 帧回调注册完成（DXGI 共享句柄路径）。
  //
  // 参数说明：
  // - error：输出参数。注册失败时写入错误文案，供上层诊断。
  //
  // 设计说明：
  // - 该函数是幂等的；重复调用不会重复注册；
  // - 只有在 bindDxgiTexture 成功前调用才有意义。
  if (rust_v1_callback_registered_.load(std::memory_order_acquire)) {
    return true;
  }
  auto& rust_api = RustScrcpyDllApi::Instance();
  const auto register_fn = rust_api.RegisterV1(error);
  if (register_fn == nullptr) {
    return false;
  }
  const bool ok = register_fn(&RustV1FrameBridge, this);
  if (!ok) {
    if (error) *error = "V1 回调注册失败：Rust 返回 false";
    return false;
  }
  rust_v1_callback_registered_.store(true, std::memory_order_release);
  OutputDebugStringA("[渲染-V1] Rust 句柄回调注册成功\n");
  return true;
}

bool FlutterWindow::EnsureRustSessionEventCallbackRegistered(std::string* error) {
  // 功能：确保 Rust SessionEvent 回调注册完成（事件 JSON 路径）。
  //
  // 参数说明：
  // - error：输出参数。注册失败时写入错误文案。
  //
  // 设计说明：
  // - 会话事件回调只需要注册一次，重复调用直接返回成功；
  // - 由 bindSessionEvents 间接触发，作为事件桥初始化前置步骤。
  if (rust_session_event_callback_registered_.load(std::memory_order_acquire)) {
    return true;
  }
  auto& rust_api = RustScrcpyDllApi::Instance();
  const auto register_fn = rust_api.RegisterSessionEvent(error);
  if (register_fn == nullptr) {
    return false;
  }
  const bool ok = register_fn(&RustSessionEventBridge, this);
  if (!ok) {
    if (error) *error = "SessionEvent 回调注册失败：Rust 返回 false";
    return false;
  }
  rust_session_event_callback_registered_.store(true, std::memory_order_release);
  OutputDebugStringA("[事件] Rust SessionEvent 回调注册成功\n");
  return true;
}

bool FlutterWindow::EnsureRustLogCallbackRegistered(std::string* error) {
  // 功能：确保 Rust tracing 日志回调注册完成。
  //
  // 参数说明：
  // - error：输出参数。注册失败时写入错误文案。
  //
  // 设计说明：
  // - 回调只需要注册一次，重复调用直接返回成功；
  // - 由 bindSessionEvents 一并触发，避免 Dart 侧额外初始化流程。
  if (rust_log_callback_registered_.load(std::memory_order_acquire)) {
    return true;
  }
  auto& rust_api = RustScrcpyDllApi::Instance();
  const auto register_fn = rust_api.RegisterRustLog(error);
  if (register_fn == nullptr) {
    return false;
  }
  const bool ok = register_fn(&RustLogBridge, this);
  if (!ok) {
    if (error) *error = "RustLog 回调注册失败：Rust 返回 false";
    return false;
  }
  rust_log_callback_registered_.store(true, std::memory_order_release);
  OutputDebugStringA("[日志] Rust tracing 回调注册成功\n");
  return true;
}

bool FlutterWindow::BindSessionEvents(std::string* error) {
  // 功能：对外提供“会话事件桥绑定”动作。
  //
  // 参数说明：
  // - error：输出参数。绑定失败时写入错误文案。
  //
  // 行为说明：
  // - 该函数不接收业务参数，只负责完成回调链路初始化；
  // - 成功后 Rust 事件将通过窗口消息转发到 session_event_bridge。
  if (!EnsureRustSessionEventCallbackRegistered(error)) {
    return false;
  }
  if (!EnsureRustLogCallbackRegistered(error)) {
    return false;
  }
  OutputDebugStringA("[事件] 已绑定 SessionEvent 回调链路\n");
  return true;
}

bool FlutterWindow::BindCpuPixelTexture(const flutter::EncodableMap& args,
                                        std::string* error) {
  // 绑定 CPU PixelBuffer 纹理到 Rust V2 回调链路。
  //
  // 行为：
  // 1) 校验 textureId 存在；
  // 2) 确保已注册 V2 回调；
  // 3) 记录当前激活纹理 ID，后续 Rust 帧回调只刷新该纹理。
  int64_t texture_id = 0;
  if (!ReadInt64(args, "textureId", &texture_id) || texture_id <= 0) {
    *error = "textureId 无效";
    return false;
  }
  {
    std::lock_guard<std::mutex> lock(texture_mutex_);
    if (pixel_texture_entries_.find(texture_id) == pixel_texture_entries_.end()) {
      *error = "CPU PixelBuffer 纹理不存在";
      return false;
    }
  }
  if (!EnsureRustV2CallbackRegistered(error)) {
    return false;
  }
  active_cpu_pixel_texture_id_.store(texture_id, std::memory_order_release);
  OutputDebugStringA(
      ("[渲染-V2] 绑定 CPU PixelBuffer 纹理: textureId=" +
       std::to_string(texture_id) + "\n")
          .c_str());
  return true;
}

bool FlutterWindow::BindDxgiTexture(const flutter::EncodableMap& args,
                                    std::string* error) {
  // 绑定 DXGI 纹理到 Rust V1 回调链路。
  //
  // 行为：
  // 1) 校验 textureId 存在；
  // 2) 确保已注册 V1 回调；
  // 3) 记录当前激活纹理 ID，后续 Rust 句柄帧只刷新该纹理。
  int64_t texture_id = 0;
  if (!ReadInt64(args, "textureId", &texture_id) || texture_id <= 0) {
    *error = "textureId 无效";
    return false;
  }
  {
    std::lock_guard<std::mutex> lock(texture_mutex_);
    if (texture_entries_.find(texture_id) == texture_entries_.end()) {
      *error = "DXGI 纹理不存在";
      return false;
    }
  }
  if (!EnsureRustV1CallbackRegistered(error)) {
    return false;
  }
  active_dxgi_texture_id_.store(texture_id, std::memory_order_release);
  OutputDebugStringA(
      ("[渲染-V1] 绑定 DXGI 纹理: textureId=" + std::to_string(texture_id) + "\n")
          .c_str());
  return true;
}

void FlutterWindow::OnRustSessionEvent(const std::string& session_id,
                                       const std::string& event_json) {
  // 此处不解析业务 JSON，只负责跨线程转发到窗口消息队列。
  if (session_event_bridge_channel_ == nullptr) {
    return;
  }
  const HWND hwnd = GetHandle();
  if (hwnd == nullptr) {
    return;
  }
  auto payload = std::make_unique<SessionEventPayload>();
  payload->session_id = session_id;
  payload->event_json = event_json;
  // 通过窗口消息切换到 UI 线程再调用 MethodChannel，避免跨线程直接触达 Dart。
  if (!PostMessageW(hwnd, kRustSessionEventMessage,
                    reinterpret_cast<WPARAM>(payload.get()), 0)) {
    return;
  }
  payload.release();
}

void FlutterWindow::OnRustLog(const std::string& level,
                              const std::string& message) {
  // 此处不做日志格式化，仅负责跨线程转发到窗口消息队列。
  if (session_event_bridge_channel_ == nullptr) {
    return;
  }
  const HWND hwnd = GetHandle();
  if (hwnd == nullptr) {
    return;
  }
  auto payload = std::make_unique<RustLogPayload>();
  payload->level = level;
  payload->message = message;
  // 通过窗口消息切换到 UI 线程再调用 MethodChannel，避免跨线程直接触达 Dart。
  if (!PostMessageW(hwnd, kRustLogMessage,
                    reinterpret_cast<WPARAM>(payload.get()), 0)) {
    return;
  }
  payload.release();
}

void FlutterWindow::OnRustV1Frame(int64_t handle,
                                  uint32_t width,
                                  uint32_t height,
                                  uint64_t generation,
                                  int64_t /*pts*/) {
  // V1 路径：Rust 回调传入共享句柄元信息，不拷贝像素。
  //
  // 线程说明：
  // - 此函数运行在 Rust 回调线程；
  // - 通过 state_mutex 保护 descriptor 相关字段并发访问。
  if (texture_registrar_ == nullptr) {
    return;
  }
  const int64_t texture_id =
      active_dxgi_texture_id_.load(std::memory_order_acquire);
  if (texture_id <= 0 || handle <= 0 || width == 0 || height == 0) {
    return;
  }

  std::shared_ptr<TextureEntry> entry;
  {
    std::lock_guard<std::mutex> lock(texture_mutex_);
    const auto it = texture_entries_.find(texture_id);
    if (it == texture_entries_.end()) {
      return;
    }
    entry = it->second;
  }
  if (!entry) {
    return;
  }

  // 核心逻辑：回调线程直接更新 descriptor，再触发 Flutter 渲染。
  {
    std::lock_guard<std::mutex> state_guard(entry->state_mutex);
    if (generation < entry->generation) {
      return;
    }
    entry->handle = handle;
    entry->width = width;
    entry->height = height;
    entry->generation = generation;
    FillDescriptor(&entry->descriptor,
                   reinterpret_cast<void*>(static_cast<intptr_t>(entry->handle)),
                   entry->width, entry->height);
  }

  entry->mark_count.fetch_add(1, std::memory_order_relaxed);
  const bool ok = FlutterDesktopTextureRegistrarMarkExternalTextureFrameAvailable(
      texture_registrar_, texture_id);
  if (!ok) {
    OutputDebugStringA("[错误][渲染-V1] Rust 回调标记新帧失败\n");
  }
}

void FlutterWindow::OnRustV2Frame(uint64_t frame_id,
                                  const uint8_t* data,
                                  size_t data_len,
                                  uint32_t width,
                                  uint32_t height,
                                  uint32_t stride,
                                  uint32_t pixel_format,
                                  uint64_t generation,
                                  int64_t /*pts*/) {
  // V2 路径：Rust 回调直接传入 CPU 像素数据。
  //
  // 关键策略：
  // - 使用快照环（render_snapshots）避免 Flutter 读取时被生产线程覆写；
  // - 当所有快照都在使用中时，当前帧直接丢弃以换取稳定性和低延迟。
  if (texture_registrar_ == nullptr) {
    return;
  }
  const int64_t texture_id =
      active_cpu_pixel_texture_id_.load(std::memory_order_acquire);
  if (texture_id <= 0 || frame_id == 0 || data == nullptr || width == 0 ||
      height == 0 || stride < width * 4u) {
    return;
  }

  std::shared_ptr<PixelTextureEntry> entry;
  {
    std::lock_guard<std::mutex> lock(texture_mutex_);
    const auto it = pixel_texture_entries_.find(texture_id);
    if (it == pixel_texture_entries_.end()) {
      return;
    }
    entry = it->second;
  }
  if (!entry) {
    return;
  }

  const size_t required = static_cast<size_t>(stride) * static_cast<size_t>(height);
  if (data_len < required) {
    OutputDebugStringA("[错误][渲染-V2] 回调帧数据长度不足\n");
    return;
  }

  const size_t expected =
      static_cast<size_t>(width) * static_cast<size_t>(height) * 4u;
  {
    std::lock_guard<std::mutex> guard(entry->buffer_mutex);
    entry->width = width;
    entry->height = height;
    entry->generation = generation;
    if (entry->render_snapshots.empty()) {
      entry->render_snapshots.resize(3);
    }
    if (entry->snapshot_in_use.size() != entry->render_snapshots.size()) {
      entry->snapshot_in_use.assign(entry->render_snapshots.size(), 0);
    }
    size_t selected = entry->render_snapshots.size();
    for (size_t i = 0; i < entry->render_snapshots.size(); ++i) {
      const size_t idx =
          (entry->next_snapshot_index + i) % entry->render_snapshots.size();
      if (entry->snapshot_in_use[idx] == 0) {
        selected = idx;
        break;
      }
    }
    if (selected == entry->render_snapshots.size()) {
      return;
    }
    entry->next_snapshot_index = (selected + 1) % entry->render_snapshots.size();
    auto& snapshot = entry->render_snapshots[selected];
    snapshot.resize(expected);
    const auto* src_rows = data;
    uint8_t* dst = snapshot.data();
    const bool is_bgra = (pixel_format == 4u);
    const bool is_rgba = (pixel_format == 5u);
    if (!is_bgra && !is_rgba) {
      OutputDebugStringA("[错误][渲染-V2] 暂不支持的像素格式\n");
      return;
    }
    if (is_rgba) {
      const size_t row_bytes = static_cast<size_t>(width) * 4u;
      if (stride == row_bytes) {
        std::memcpy(dst, src_rows, expected);
      } else {
        for (uint32_t y = 0; y < height; ++y) {
          const uint8_t* row = src_rows + static_cast<size_t>(y) * stride;
          uint8_t* out_row = dst + static_cast<size_t>(y) * row_bytes;
          std::memcpy(out_row, row, row_bytes);
        }
      }
    } else {
      for (uint32_t y = 0; y < height; ++y) {
        const uint8_t* row = src_rows + static_cast<size_t>(y) * stride;
        for (uint32_t x = 0; x < width; ++x) {
          const size_t si = static_cast<size_t>(x) * 4u;
          const size_t di = (static_cast<size_t>(y) * width + x) * 4u;
          dst[di + 0] = row[si + 2];
          dst[di + 1] = row[si + 1];
          dst[di + 2] = row[si + 0];
          dst[di + 3] = row[si + 3];
        }
      }
    }
    entry->published_snapshot_index = selected;
    entry->has_published_snapshot = true;
    entry->pixel_buffer.buffer = snapshot.data();
    entry->pixel_buffer.width = width;
    entry->pixel_buffer.height = height;
    entry->mark_count.fetch_add(1, std::memory_order_relaxed);
  }

  const bool ok = FlutterDesktopTextureRegistrarMarkExternalTextureFrameAvailable(
      texture_registrar_, texture_id);
  if (!ok) {
    OutputDebugStringA("[错误][渲染-V2] Rust 回调标记新帧失败\n");
  }
}
