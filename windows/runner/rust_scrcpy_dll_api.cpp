#include "rust_scrcpy_dll_api.h"

RustScrcpyDllApi& RustScrcpyDllApi::Instance() {
  static RustScrcpyDllApi api;
  return api;
}

bool RustScrcpyDllApi::EnsureLoaded(std::string* error) {
  std::lock_guard<std::mutex> lock(mutex_);
  if (module_ != nullptr) {
    return true;
  }

  module_ = GetModuleHandleA("rust_scrcpy.dll");
  if (module_ == nullptr) {
    // 兜底：从 exe 同目录显式加载 DLL。
    wchar_t exe_path[MAX_PATH] = {0};
    const DWORD got = GetModuleFileNameW(nullptr, exe_path, MAX_PATH);
    if (got > 0 && got < MAX_PATH) {
      std::wstring full(exe_path);
      const auto pos = full.find_last_of(L"\\/");
      if (pos != std::wstring::npos) {
        full = full.substr(0, pos + 1) + L"rust_scrcpy.dll";
        module_ = LoadLibraryW(full.c_str());
      }
    }
  }

  if (module_ == nullptr) {
    if (error) *error = "未找到 rust_scrcpy.dll";
    return false;
  }
  return true;
}

FARPROC RustScrcpyDllApi::ResolveSymbol(const char* symbol, std::string* error) {
  std::lock_guard<std::mutex> lock(mutex_);
  if (module_ == nullptr) {
    if (error) *error = "rust_scrcpy.dll 尚未加载";
    return nullptr;
  }
  FARPROC p = GetProcAddress(module_, symbol);
  if (p == nullptr && error) {
    *error = std::string("未找到符号: ") + symbol;
  }
  return p;
}

RsRegisterV1FrameCallbackFn RustScrcpyDllApi::RegisterV1(std::string* error) {
  if (!EnsureLoaded(error)) return nullptr;
  if (register_v1_ == nullptr) {
    register_v1_ = reinterpret_cast<RsRegisterV1FrameCallbackFn>(
        ResolveSymbol("rs_register_v1_frame_callback", error));
  }
  return register_v1_;
}

RsRegisterV2FrameCallbackFn RustScrcpyDllApi::RegisterV2(std::string* error) {
  if (!EnsureLoaded(error)) return nullptr;
  if (register_v2_ == nullptr) {
    register_v2_ = reinterpret_cast<RsRegisterV2FrameCallbackFn>(
        ResolveSymbol("rs_register_v2_frame_callback", error));
  }
  return register_v2_;
}

RsRegisterSessionEventCallbackFn RustScrcpyDllApi::RegisterSessionEvent(
    std::string* error) {
  if (!EnsureLoaded(error)) return nullptr;
  if (register_session_event_ == nullptr) {
    register_session_event_ = reinterpret_cast<RsRegisterSessionEventCallbackFn>(
        ResolveSymbol("rs_register_session_event_callback", error));
  }
  return register_session_event_;
}

RsRegisterRustLogCallbackFn RustScrcpyDllApi::RegisterRustLog(
    std::string* error) {
  if (!EnsureLoaded(error)) return nullptr;
  if (register_rust_log_ == nullptr) {
    register_rust_log_ = reinterpret_cast<RsRegisterRustLogCallbackFn>(
        ResolveSymbol("rs_register_rust_log_callback", error));
  }
  return register_rust_log_;
}
