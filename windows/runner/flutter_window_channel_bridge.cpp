#include "flutter_window.h"

#include <flutter/standard_method_codec.h>

// MethodChannel 分发实现文件。
//
// 设计目标：
// 1) 将桥接职责拆分为独立通道，避免“纹理+事件”语义混杂；
// 2) 把分发逻辑从 flutter_window.cpp 主文件剥离，便于维护。

void FlutterWindow::RegisterWindowTitleChannel() {
  window_title_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "window_title",
          &flutter::StandardMethodCodec::GetInstance());

  window_title_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        const auto& method = call.method_name();
        HWND hwnd = GetHandle();
        if (hwnd == nullptr) {
          result->Error("WINDOW_UNAVAILABLE", "Window handle is null");
          return;
        }

        if (method == "setTitle") {
          if (!call.arguments() ||
              !std::holds_alternative<std::string>(*call.arguments())) {
            result->Error("INVALID_ARGUMENT", "Expected string title");
            return;
          }
          const std::string& title = std::get<std::string>(*call.arguments());
          int len =
              MultiByteToWideChar(CP_UTF8, 0, title.c_str(), -1, nullptr, 0);
          std::wstring wide_title(static_cast<size_t>(len), L'\0');
          MultiByteToWideChar(CP_UTF8, 0, title.c_str(), -1, &wide_title[0],
                              len);
          SetWindowTextW(hwnd, wide_title.c_str());
          result->Success();
          return;
        }

        result->NotImplemented();
      });
}

void FlutterWindow::RegisterTextureBridge() {
  // 纹理桥接通道：只承载纹理生命周期方法。
  texture_bridge_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "texture_bridge",
          &flutter::StandardMethodCodec::GetInstance());

  texture_bridge_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        HandleTextureBridgeCall(call, std::move(result));
      });
}

void FlutterWindow::RegisterClipboardBridge() {
  clipboard_bridge_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "clipboard_bridge",
          &flutter::StandardMethodCodec::GetInstance());

  clipboard_bridge_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        HandleClipboardBridgeCall(call, std::move(result));
      });
}

bool FlutterWindow::HandleTextureBridgeCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  // 纹理桥接统一入口：
  // - 参数必须是 map；
  // - 只处理纹理相关方法；
  // - 错误码按操作类型区分，便于 Dart 侧定位。
  const auto& method = call.method_name();
  std::string error;

  if (!call.arguments() ||
      !std::holds_alternative<flutter::EncodableMap>(*call.arguments())) {
    result->Error("INVALID_ARGUMENT", "Expected map arguments");
    return true;
  }
  const auto& args = std::get<flutter::EncodableMap>(*call.arguments());

  if (method == "createTexture") {
    int64_t texture_id = 0;
    if (!CreateTexture(args, &texture_id, &error)) {
      result->Error("CREATE_FAILED", error);
      return true;
    }
    result->Success(flutter::EncodableValue(texture_id));
    return true;
  }
  if (method == "createCpuPixelTexture") {
    int64_t texture_id = 0;
    if (!CreateCpuPixelTexture(args, &texture_id, &error)) {
      result->Error("CREATE_CPU_PIXEL_FAILED", error);
      return true;
    }
    result->Success(flutter::EncodableValue(texture_id));
    return true;
  }
  if (method == "bindCpuPixelTexture") {
    if (!BindCpuPixelTexture(args, &error)) {
      result->Error("BIND_CPU_PIXEL_FAILED", error);
      return true;
    }
    result->Success(flutter::EncodableValue(true));
    return true;
  }
  if (method == "bindDxgiTexture") {
    if (!BindDxgiTexture(args, &error)) {
      result->Error("BIND_DXGI_FAILED", error);
      return true;
    }
    result->Success(flutter::EncodableValue(true));
    return true;
  }
  if (method == "disposeTexture") {
    if (!DisposeTexture(args, &error)) {
      result->Error("DISPOSE_FAILED", error);
      return true;
    }
    result->Success(flutter::EncodableValue(true));
    return true;
  }
  if (method == "disposeCpuPixelTexture") {
    if (!DisposeCpuPixelTexture(args, &error)) {
      result->Error("DISPOSE_CPU_PIXEL_FAILED", error);
      return true;
    }
    result->Success(flutter::EncodableValue(true));
    return true;
  }

  result->NotImplemented();
  return false;
}

bool FlutterWindow::HandleClipboardBridgeCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto& method = call.method_name();

  if (method == "bindClipboardCallback") {
    std::string error;
    if (!EnsureRustClipboardCallbackRegistered(&error)) {
      result->Error("BIND_CLIPBOARD_FAILED", error);
      return true;
    }
    clipboard_callback_enabled_.store(true, std::memory_order_release);
    result->Success(flutter::EncodableValue(true));
    return true;
  }

  if (method == "unbindClipboardCallback") {
    clipboard_callback_enabled_.store(false, std::memory_order_release);
    {
      std::lock_guard<std::mutex> lock(clipboard_event_mutex_);
      pending_clipboard_events_.clear();
    }
    result->Success(flutter::EncodableValue(true));
    return true;
  }

  result->NotImplemented();
  return false;
}
