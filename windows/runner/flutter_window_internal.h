#ifndef RUNNER_FLUTTER_WINDOW_INTERNAL_H_
#define RUNNER_FLUTTER_WINDOW_INTERNAL_H_

#include "flutter_window.h"

#include <string>

// Rust 线程 -> UI 线程的消息号（通过 PostMessage 转发 SessionEvent）。
constexpr UINT kRustSessionEventMessage = WM_APP + 0x142;
// Rust 线程 -> UI 线程的消息号（通过 PostMessage 转发 Rust 日志）。
constexpr UINT kRustLogMessage = WM_APP + 0x143;

// SessionEvent 跨线程传输载荷：
// Rust 回调线程构造 payload，UI 线程接收后转发给 Dart MethodChannel。
struct SessionEventPayload {
  std::string session_id;
  std::string event_json;
};

// RustLog 跨线程传输载荷：
// Rust 回调线程构造 payload，UI 线程接收后转发给 Dart MethodChannel。
struct RustLogPayload {
  std::string level;
  std::string message;
};

// 读取 MethodChannel 参数中的 int（兼容 int32/int64）。
inline bool ReadInt64(const flutter::EncodableMap& args,
                      const char* key,
                      int64_t* out_value) {
  const auto it = args.find(flutter::EncodableValue(std::string(key)));
  if (it == args.end()) {
    return false;
  }
  const auto& value = it->second;
  if (std::holds_alternative<int32_t>(value)) {
    *out_value = static_cast<int64_t>(std::get<int32_t>(value));
    return true;
  }
  if (std::holds_alternative<int64_t>(value)) {
    *out_value = std::get<int64_t>(value);
    return true;
  }
  return false;
}

// 统一填充 Flutter GPU Surface 描述符（DXGI 共享句柄路径）。
inline void FillDescriptor(FlutterDesktopGpuSurfaceDescriptor* descriptor,
                           void* shared_handle,
                           uint32_t width,
                           uint32_t height) {
  descriptor->struct_size = sizeof(FlutterDesktopGpuSurfaceDescriptor);
  descriptor->handle = shared_handle;
  descriptor->width = static_cast<size_t>(width);
  descriptor->height = static_cast<size_t>(height);
  descriptor->visible_width = static_cast<size_t>(width);
  descriptor->visible_height = static_cast<size_t>(height);
  descriptor->format = kFlutterDesktopPixelFormatBGRA8888;
  descriptor->release_callback = nullptr;
  descriptor->release_context = nullptr;
}

#endif  // RUNNER_FLUTTER_WINDOW_INTERNAL_H_
