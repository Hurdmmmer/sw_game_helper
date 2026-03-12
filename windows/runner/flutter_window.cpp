// ─────────────────────────────────────────────────────────────────────────────
// flutter_window.cpp
//
// Flutter 主窗口实现：
//   1. 创建并管理 FlutterViewController；
//   2. 注册纹理桥接通道 "texture_bridge"；
//   3. 注册会话事件桥接通道 "session_event_bridge"；
//   4. 注册 MethodChannel "window_title"，供 Dart 层设置窗口标题。
//
// 【花屏修复说明】
//   旧代码中 ObtainGpuDescriptor 没有 release_callback，Flutter 释放描述符时
//   我们无从得知，也无法追踪「纹理是否仍被 Flutter 持有」。
//   本次新增 OnGpuSurfaceReleased 回调 + TextureEntry::in_use 标志，
//   与 Rust 侧的 GPU Event Query 同步共同构成完整的跨设备同步方案：
//     - Rust：写完后等 GPU 确认（texture_uploader.rs 中的 wait_gpu_write_done）
//     - C++：追踪 Flutter 持有状态（in_use），为未来 Rust 侧按需等待提供基础
//
// 【旋转支持】
//   旋转时 Rust 侧会重建纹理（新 handle），Flutter 侧通过 ResolutionChanged
//   事件销毁旧纹理对、重建新纹理对。DisposeTexture 确保旧 TextureEntry 在删除
//   前清空 release_callback，防止 Flutter 在删除后仍然调用回调导致崩溃。
//
// 【触控支持】
//   触控坐标映射依赖 _activeWidth / _activeHeight（Dart 层维护），与本文件
//   无直接关系。只要纹理正确渲染，触控坐标映射就能正常工作。
// ─────────────────────────────────────────────────────────────────────────────

#include "flutter_window.h"

#include <flutter/standard_method_codec.h>

#include <d3d11.h>
#include <d3d11_1.h>

#include <cstdio>
#include <cstring>
#include <filesystem>
#include <optional>
#include <string>
#include <vector>

#include "flutter/generated_plugin_registrant.h"
#include "flutter_window_internal.h"
#include "flutter_window_render_utils.h"

namespace {

// 用于把 TextureEntry 生命周期延长到 UnregisterExternalTexture 完成之后。
struct TextureUnregisterPayload {
  std::shared_ptr<void> entry_holder;
};

struct PixelReleaseContext {
  // 用 shared_ptr 延长 PixelTextureEntry 生命周期，直到 Flutter 释放该帧快照。
  // 这样即使外部已调用 DisposePixelTexture，也不会发生悬空指针访问。
  std::shared_ptr<void> entry_holder;
  size_t page_index = 0;
};

}  // namespace

// ─────────────────────────────────────────────────────────────────────────────
// FlutterWindow 成员实现
// ─────────────────────────────────────────────────────────────────────────────

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) return false;

  RECT frame = GetClientArea();
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }

  RegisterPlugins(flutter_controller_->engine());

  // 通过插件注册器拿到 C API 纹理注册器（避免 C++ 封装链接问题）
  const auto registrar_ref = flutter_controller_->engine()->GetRegistrarForPlugin("texture_bridge_runner");
  texture_registrar_ =
      FlutterDesktopRegistrarGetTextureRegistrar(registrar_ref);
  if (texture_registrar_ == nullptr) return false;

  RegisterWindowTitleChannel();
  RegisterTextureBridge();
  RegisterSessionEventBridge();

  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  flutter_controller_->engine()->SetNextFrameCallback(
      [&]() { this->Show(); });
  flutter_controller_->ForceRedraw();
  return true;
}

void FlutterWindow::OnDestroy() {
  DisposeAllTextures();
  texture_bridge_channel_.reset();
  session_event_bridge_channel_.reset();
  window_title_channel_.reset();
  if (flutter_controller_) flutter_controller_ = nullptr;
  texture_registrar_ = nullptr;
  Win32Window::OnDestroy();
}

LRESULT FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                                      WPARAM const wparam,
                                      LPARAM const lparam) noexcept {
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message,
                                                      wparam, lparam);
    if (result) return *result;
  }
  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    case kRustSessionEventMessage: {
      std::unique_ptr<SessionEventPayload> payload(
          reinterpret_cast<SessionEventPayload*>(wparam));
      if (payload && session_event_bridge_channel_) {
        flutter::EncodableMap args;
        args[flutter::EncodableValue("sessionId")] =
            flutter::EncodableValue(payload->session_id);
        args[flutter::EncodableValue("eventJson")] =
            flutter::EncodableValue(payload->event_json);
        session_event_bridge_channel_->InvokeMethod(
            "onSessionEvent",
            std::make_unique<flutter::EncodableValue>(std::move(args)));
      }
      return 0;
    }
    case kRustLogMessage: {
      std::unique_ptr<RustLogPayload> payload(
          reinterpret_cast<RustLogPayload*>(wparam));
      if (payload && session_event_bridge_channel_) {
        flutter::EncodableMap args;
        args[flutter::EncodableValue("level")] =
            flutter::EncodableValue(payload->level);
        args[flutter::EncodableValue("message")] =
            flutter::EncodableValue(payload->message);
        session_event_bridge_channel_->InvokeMethod(
            "onRustLog",
            std::make_unique<flutter::EncodableValue>(std::move(args)));
      }
      return 0;
    }
  }
  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

bool FlutterWindow::CreateTexture(const flutter::EncodableMap& args,
                                  int64_t* texture_id,
                                  std::string* error) {
  if (texture_registrar_ == nullptr) {
    *error = "texture registrar unavailable";
    return false;
  }

  int64_t handle = 0, width = 0, height = 0, generation = 0;
  if (!ReadInt64(args, "handle", &handle) ||
      !ReadInt64(args, "width", &width) ||
      !ReadInt64(args, "height", &height) ||
      !ReadInt64(args, "generation", &generation)) {
    *error = "missing required args: handle/width/height/generation";
    return false;
  }
  if (handle <= 0 || width <= 0 || height <= 0) {
    *error = "invalid handle or size";
    return false;
  }

#ifndef NDEBUG
  // Debug 构建下：探测共享句柄是否可被正常打开，并采样像素内容用于验证。
  // Release 构建下跳过，避免额外 D3D11 设备创建的性能开销。
  HRESULT legacy_hr = E_FAIL, nt_hr = E_FAIL, create_hr = E_FAIL,
          readback_hr = E_FAIL;
  uint32_t sampled_bgra = 0;
  uint64_t sampled_checksum = 0;
  const bool probed =
      ProbeSharedHandleOpenResult(handle, &legacy_hr, &nt_hr, &create_hr,
                                  &sampled_bgra, &sampled_checksum,
                                  &readback_hr);
  if (probed) {
    LogDxgiProbe("handle=" + std::to_string(handle) +
                 " OpenSharedResource=" + HResultToHex(legacy_hr) +
                 " OpenSharedResource1=" + HResultToHex(nt_hr) +
                 " readback=" + HResultToHex(readback_hr) + " " +
                 PixelToText(sampled_bgra, sampled_checksum));
    if (FAILED(legacy_hr) && FAILED(nt_hr)) {
      *error = "dxgi shared handle cannot be opened: legacy=" +
               HResultToHex(legacy_hr) + ", nt=" + HResultToHex(nt_hr);
      return false;
    }
  } else {
    LogDxgiProbe("probe device create failed hr=" + HResultToHex(create_hr));
  }
#endif

  auto entry = std::make_shared<TextureEntry>();
  entry->handle     = handle;
  entry->width      = static_cast<uint32_t>(width);
  entry->height     = static_cast<uint32_t>(height);
  entry->generation = static_cast<uint64_t>(generation);

  // 填充 Flutter GPU Surface 描述符（handle、尺寸、格式）。
  // release_callback 不在此处设置，而是在每次 ObtainGpuDescriptor 调用时动态设置，
  // 确保 release_context 始终指向有效的 TextureEntry。
  FillDescriptor(
      &entry->descriptor,
      reinterpret_cast<void*>(static_cast<intptr_t>(entry->handle)),
      entry->width, entry->height);

  // 注册 C API GPU Surface 外部纹理：
  //   type     = kFlutterDesktopGpuSurfaceTexture（GPU 表面纹理，不是像素缓冲）
  //   callback = ObtainGpuDescriptor（Flutter 每帧渲染前调用，获取最新描述符）
  //   user_data = entry.get()（裸指针，指向本 TextureEntry）
  entry->gpu_config.struct_size =
      sizeof(FlutterDesktopGpuSurfaceTextureConfig);
  entry->gpu_config.type     = kFlutterDesktopGpuSurfaceTypeDxgiSharedHandle;
  entry->gpu_config.callback = &FlutterWindow::ObtainGpuDescriptor;
  entry->gpu_config.user_data = entry.get();

  entry->texture_info.type             = kFlutterDesktopGpuSurfaceTexture;
  entry->texture_info.gpu_surface_config = entry->gpu_config;

  const int64_t id = FlutterDesktopTextureRegistrarRegisterExternalTexture(
      texture_registrar_, &entry->texture_info);
  if (id <= 0) {
    *error = "FlutterDesktopTextureRegistrarRegisterExternalTexture failed";
    return false;
  }
  entry->texture_id = id;

  {
    std::lock_guard<std::mutex> lock(texture_mutex_);
    texture_entries_[id] = entry;
  }

  *texture_id = id;
  return true;
}

bool FlutterWindow::DisposeTexture(const flutter::EncodableMap& args,
                                   std::string* error) {
  if (texture_registrar_ == nullptr) {
    *error = "texture registrar unavailable";
    return false;
  }

  int64_t texture_id = 0;
  if (!ReadInt64(args, "textureId", &texture_id) || texture_id <= 0) {
    *error = "invalid textureId";
    return false;
  }
  // 若释放的是当前绑定纹理，先解绑活动标记，避免后续回调继续写入失效纹理。
  const int64_t active_dxgi =
      active_dxgi_texture_id_.load(std::memory_order_acquire);
  if (active_dxgi == texture_id) {
    active_dxgi_texture_id_.store(0, std::memory_order_release);
  }

  std::shared_ptr<TextureEntry> entry_to_release;
  {
    std::lock_guard<std::mutex> lock(texture_mutex_);
    const auto it = texture_entries_.find(texture_id);
    if (it == texture_entries_.end()) {
      return true;  // 已经释放过，幂等处理
    }

    entry_to_release = it->second;
    texture_entries_.erase(it);
  }

  if (entry_to_release) {
    entry_to_release->disposed.store(true, std::memory_order_release);
    entry_to_release->descriptor.release_callback = nullptr;
    entry_to_release->descriptor.release_context = nullptr;
    if (entry_to_release->shared_texture != nullptr) {
      entry_to_release->shared_texture->Release();
      entry_to_release->shared_texture = nullptr;
    }
  }

  auto payload = std::make_unique<TextureUnregisterPayload>();
  payload->entry_holder = entry_to_release;
  FlutterDesktopTextureRegistrarUnregisterExternalTexture(
      texture_registrar_, texture_id, &FlutterWindow::OnTextureUnregistered,
      payload.release());
  return true;
}

bool FlutterWindow::DisposePixelTexture(const flutter::EncodableMap& args,
                                        std::string* error) {
  if (texture_registrar_ == nullptr) {
    *error = "纹理注册器不可用";
    return false;
  }

  int64_t texture_id = 0;
  if (!ReadInt64(args, "textureId", &texture_id) || texture_id <= 0) {
    *error = "textureId 无效";
    return false;
  }

  std::shared_ptr<PixelTextureEntry> entry_to_release;
  {
    std::lock_guard<std::mutex> lock(texture_mutex_);
    const auto it = pixel_texture_entries_.find(texture_id);
    if (it == pixel_texture_entries_.end()) {
      return true;
    }
    entry_to_release = it->second;
    pixel_texture_entries_.erase(it);
  }

  if (entry_to_release) {
    entry_to_release->disposed.store(true, std::memory_order_release);
  }

  auto payload = std::make_unique<TextureUnregisterPayload>();
  payload->entry_holder = entry_to_release;
  FlutterDesktopTextureRegistrarUnregisterExternalTexture(
      texture_registrar_, texture_id, &FlutterWindow::OnTextureUnregistered,
      payload.release());
  return true;
}

bool FlutterWindow::CreateCpuPixelTexture(const flutter::EncodableMap& args,
                                          int64_t* texture_id,
                                          std::string* error) {
  if (texture_registrar_ == nullptr) {
    *error = "纹理注册器不可用";
    return false;
  }

  int64_t width = 0, height = 0, generation = 0;
  if (!ReadInt64(args, "width", &width) ||
      !ReadInt64(args, "height", &height) ||
      !ReadInt64(args, "generation", &generation)) {
    *error = "缺少参数: width/height/generation";
    return false;
  }
  if (width <= 0 || height <= 0) {
    *error = "参数无效: width/height <= 0";
    return false;
  }

  auto entry = std::make_shared<PixelTextureEntry>();
  entry->weak_self = entry;
  entry->width = static_cast<uint32_t>(width);
  entry->height = static_cast<uint32_t>(height);
  entry->generation = static_cast<uint64_t>(generation);
  entry->latest_frame.resize(static_cast<size_t>(entry->width) * entry->height * 4u);
  entry->render_snapshots.resize(3);
  entry->snapshot_in_use.assign(entry->render_snapshots.size(), 0);
  entry->pixel_buffer.buffer = entry->latest_frame.data();
  entry->pixel_buffer.width = entry->width;
  entry->pixel_buffer.height = entry->height;
  entry->pixel_buffer.release_callback = nullptr;
  entry->pixel_buffer.release_context = nullptr;

  entry->pixel_config.callback = &FlutterWindow::CopyPixelBuffer;
  entry->pixel_config.user_data = entry.get();
  entry->texture_info.type = kFlutterDesktopPixelBufferTexture;
  entry->texture_info.pixel_buffer_config = entry->pixel_config;

  const int64_t id = FlutterDesktopTextureRegistrarRegisterExternalTexture(
      texture_registrar_, &entry->texture_info);
  if (id <= 0) {
    *error = "注册 CPU PixelBuffer 纹理失败";
    return false;
  }
  entry->texture_id = id;

  {
    std::lock_guard<std::mutex> lock(texture_mutex_);
    pixel_texture_entries_[id] = entry;
  }

  *texture_id = id;
  return true;
}

bool FlutterWindow::DisposeCpuPixelTexture(const flutter::EncodableMap& args,
                                           std::string* error) {
  int64_t texture_id = 0;
  if (ReadInt64(args, "textureId", &texture_id) && texture_id > 0) {
    const int64_t active = active_cpu_pixel_texture_id_.load(std::memory_order_acquire);
    if (active == texture_id) {
      active_cpu_pixel_texture_id_.store(0, std::memory_order_release);
    }
  }
  return DisposePixelTexture(args, error);
}

void FlutterWindow::DisposeAllTextures() {
  if (texture_registrar_ == nullptr) return;
  active_dxgi_texture_id_.store(0, std::memory_order_release);
  active_cpu_pixel_texture_id_.store(0, std::memory_order_release);

  std::vector<std::pair<int64_t, std::shared_ptr<TextureEntry>>> entries;
  {
    std::lock_guard<std::mutex> lock(texture_mutex_);
    entries.reserve(texture_entries_.size());
    for (auto& item : texture_entries_) {
      entries.emplace_back(item.first, item.second);
    }
    texture_entries_.clear();
  }

  for (auto& item : entries) {
    const int64_t id = item.first;
    auto& entry = item.second;
    if (entry) {
      entry->disposed.store(true, std::memory_order_release);
      entry->descriptor.release_callback = nullptr;
      entry->descriptor.release_context = nullptr;
      if (entry->shared_texture != nullptr) {
        entry->shared_texture->Release();
        entry->shared_texture = nullptr;
      }
    }
    auto payload = std::make_unique<TextureUnregisterPayload>();
    payload->entry_holder = entry;
    FlutterDesktopTextureRegistrarUnregisterExternalTexture(
        texture_registrar_, id, &FlutterWindow::OnTextureUnregistered,
        payload.release());
  }

  std::vector<std::pair<int64_t, std::shared_ptr<PixelTextureEntry>>>
      pixel_entries;
  {
    std::lock_guard<std::mutex> lock(texture_mutex_);
    pixel_entries.reserve(pixel_texture_entries_.size());
    for (auto& item : pixel_texture_entries_) {
      pixel_entries.emplace_back(item.first, item.second);
    }
    pixel_texture_entries_.clear();
  }

  for (auto& item : pixel_entries) {
    const int64_t id = item.first;
    auto& entry = item.second;
    if (entry) {
      entry->disposed.store(true, std::memory_order_release);
    }
    auto payload = std::make_unique<TextureUnregisterPayload>();
    payload->entry_holder = entry;
    FlutterDesktopTextureRegistrarUnregisterExternalTexture(
        texture_registrar_, id, &FlutterWindow::OnTextureUnregistered,
        payload.release());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 静态回调函数（Flutter 引擎调用，运行在 Flutter 渲染线程）
// ─────────────────────────────────────────────────────────────────────────────

/// Flutter 引擎每帧渲染前调用此函数，获取当前纹理的 GPU Surface 描述符。
///
/// 【花屏修复配套】
///   此处动态设置 release_callback 和 release_context，使 Flutter 在用完描述符
///   后能回调 OnGpuSurfaceReleased，从而更新 TextureEntry::in_use 标志。
///
/// 【线程说明】
///   此函数在 Flutter 渲染线程调用，而 texture_entries_ 的修改（DisposeTexture
///   等）在主线程调用，两者可能并发。V1 回调线程也会并发写 descriptor，
///   因此这里通过 TextureEntry::state_mutex 保护 descriptor/handle/size 访问，
///   优先保证上线稳定性与一致性。
///
/// 【旋转支持】
///   旋转时 Dart 层调用 disposeTexture + createTexturePair 重建纹理对，
///   此后 ObtainGpuDescriptor 会被新 TextureEntry 的 user_data 调用，
///   描述符中的 handle/width/height 已更新为新分辨率，无需额外处理。
const FlutterDesktopGpuSurfaceDescriptor* FlutterWindow::ObtainGpuDescriptor(
    size_t /*width*/, size_t /*height*/, void* user_data) {
  auto* entry = static_cast<TextureEntry*>(user_data);
  if (entry == nullptr) {
    return nullptr;
  }
  if (entry->disposed.load(std::memory_order_acquire)) {
    return nullptr;
  }

  // ── 【新增】设置 release_callback ─────────────────────────────────────────
  //
  // 每次 ObtainGpuDescriptor 调用时重新设置 release_callback 和 release_context，
  // 这样即使 handle 发生变化（旋转/重配置），release_context 始终指向正确的 entry。
  //
  // OnGpuSurfaceReleased 会在 Flutter 用完此描述符后被调用，将 in_use 置 false，
  // 告知系统「Flutter 已不再持有该描述符，Rust 可以安全覆写此纹理槽」。
  {
    std::lock_guard<std::mutex> state_guard(entry->state_mutex);
    entry->descriptor.release_callback = &FlutterWindow::OnGpuSurfaceReleased;
    entry->descriptor.release_context  = entry;
  }

  // 标记此纹理描述符正在被 Flutter 引擎持有
  // memory_order_release：确保上面的 release_callback 设置对 OnGpuSurfaceReleased
  // 所在线程可见（happens-before 关系）
  entry->in_use.store(true, std::memory_order_release);
  if (entry->disposed.load(std::memory_order_acquire)) {
    std::lock_guard<std::mutex> state_guard(entry->state_mutex);
    entry->descriptor.release_callback = nullptr;
    entry->descriptor.release_context = nullptr;
    entry->in_use.store(false, std::memory_order_release);
    return nullptr;
  }

  return &entry->descriptor;
}

/// Flutter 引擎释放 GPU Surface 描述符时调用（与 ObtainGpuDescriptor 配对）。
///
/// 将 TextureEntry::in_use 置 false，表示 Flutter 已完成对该描述符的持有。
///
/// 【注意】此时 Flutter 的 GPU 渲染命令可能仍在驱动队列中（尚未执行完），
/// 因此 in_use = false 只代表「Flutter 不再持有描述符引用」，不代表「GPU 读完了」。
/// 完整的 GPU 读写同步由 Rust 侧的 wait_gpu_write_done() 负责。
///
/// 【UAF 保护】
///   DisposeTexture 在删除 TextureEntry 前会将 release_callback 置 nullptr，
///   因此此函数不会在 TextureEntry 已销毁后被调用（Flutter 引擎不会对
///   nullptr callback 发起调用）。
void FlutterWindow::OnGpuSurfaceReleased(void* release_context) {
  auto* entry = static_cast<TextureEntry*>(release_context);
  if (entry == nullptr) {
    return;
  }
  // memory_order_release：确保对 in_use 的清除对后续加载此值的线程可见
  entry->in_use.store(false, std::memory_order_release);
}

const FlutterDesktopPixelBuffer* FlutterWindow::CopyPixelBuffer(
    size_t width, size_t height, void* user_data) {
  auto* raw_entry = static_cast<PixelTextureEntry*>(user_data);
  if (raw_entry == nullptr) {
    return nullptr;
  }
  // 从弱引用恢复共享持有，避免 release_callback 回来前对象被析构。
  auto entry = raw_entry->weak_self.lock();
  if (!entry) {
    return nullptr;
  }
  if (entry->disposed.load(std::memory_order_acquire)) {
    return nullptr;
  }

  std::lock_guard<std::mutex> guard(entry->buffer_mutex);
  if (!entry->has_published_snapshot) {
    return nullptr;
  }

  if (entry->render_snapshots.empty()) {
    entry->render_snapshots.resize(3);
  }
  if (entry->snapshot_in_use.size() != entry->render_snapshots.size()) {
    entry->snapshot_in_use.assign(entry->render_snapshots.size(), 0);
  }
  const size_t selected = entry->published_snapshot_index;
  if (selected >= entry->render_snapshots.size()) {
    return nullptr;
  }
  auto& snapshot = entry->render_snapshots[selected];
  if (snapshot.empty()) {
    return nullptr;
  }
  if (entry->snapshot_in_use[selected] < 255) {
    entry->snapshot_in_use[selected] += 1;
  }
  
  // 以“快照帧”为准，避免 Flutter 读取期间被生产线程覆写。
  entry->pixel_buffer.buffer = snapshot.data();
  entry->pixel_buffer.width = entry->width > 0 ? entry->width : width;
  entry->pixel_buffer.height = entry->height > 0 ? entry->height : height;
  auto* release_ctx = new PixelReleaseContext();
  release_ctx->entry_holder = entry;
  release_ctx->page_index = selected;
  entry->pixel_buffer.release_callback = &FlutterWindow::OnPixelBufferReleased;
  entry->pixel_buffer.release_context = release_ctx;
  return &entry->pixel_buffer;
}

void FlutterWindow::OnPixelBufferReleased(void* release_context) {
  auto* ctx = static_cast<PixelReleaseContext*>(release_context);
  if (ctx == nullptr) {
    return;
  }
  auto entry = std::static_pointer_cast<PixelTextureEntry>(ctx->entry_holder);
  if (entry) {
    std::lock_guard<std::mutex> guard(entry->buffer_mutex);
    if (ctx->page_index < entry->snapshot_in_use.size()) {
      if (entry->snapshot_in_use[ctx->page_index] > 0) {
        entry->snapshot_in_use[ctx->page_index] -= 1;
      }
    }
  }
  delete ctx;
}

void FlutterWindow::OnTextureUnregistered(void* user_data) {
  std::unique_ptr<TextureUnregisterPayload> payload(
      static_cast<TextureUnregisterPayload*>(user_data));
  (void)payload;
}
