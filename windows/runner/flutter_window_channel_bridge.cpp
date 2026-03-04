#include "flutter_window.h"

#include <flutter/standard_method_codec.h>

// MethodChannel 分发实现文件。
//
// 目的：
// 1) 把 channel 分发逻辑从 flutter_window.cpp 主文件拆出来；
// 2) 让窗口生命周期代码与业务方法分发解耦，方便后续维护。

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
          MultiByteToWideChar(CP_UTF8, 0, title.c_str(), -1, &wide_title[0], len);
          SetWindowTextW(hwnd, wide_title.c_str());
          result->Success();
          return;
        }

        result->NotImplemented();
      });
}

void FlutterWindow::RegisterDxgiTextureBridge() {
  dxgi_texture_bridge_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "dxgi_texture_bridge",
          &flutter::StandardMethodCodec::GetInstance());

  dxgi_texture_bridge_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) { HandleDxgiTextureBridgeCall(call, std::move(result)); });
}

bool FlutterWindow::HandleDxgiTextureBridgeCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto& method = call.method_name();
  std::string error;

  // 会话事件绑定不依赖参数，单独处理。
  if (method == "bindSessionEvents") {
    if (!BindSessionEvents(&error)) {
      result->Error("BIND_SESSION_EVENTS_FAILED", error);
      return true;
    }
    result->Success(flutter::EncodableValue(true));
    return true;
  }

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
