#ifndef RUNNER_RUST_SCRCPY_DLL_API_H_
#define RUNNER_RUST_SCRCPY_DLL_API_H_

#include <windows.h>

#include <cstddef>
#include <cstdint>
#include <mutex>
#include <string>

// Rust 导出函数指针定义（Runner <-> rust_scrcpy.dll 协议）
//
// 给小白的说明：
// - 这些类型就是“函数签名合同”；
// - Runner 必须用与 Rust 完全一致的签名，GetProcAddress 才能安全调用；
// - 后续如果 Rust 改签名，这里也必须同步修改。
using RsFrameCallbackFn = void (*)(void* user_data,
                                   uint64_t frame_id,
                                   const uint8_t* data,
                                   size_t data_len,
                                   uint32_t width,
                                   uint32_t height,
                                   uint32_t stride,
                                   uint32_t pixel_format,
                                   uint64_t generation,
                                   int64_t pts);
using RsV1FrameCallbackFn = void (*)(void* user_data,
                                     int64_t handle,
                                     uint32_t width,
                                     uint32_t height,
                                     uint64_t generation,
                                     int64_t pts);
using RsRegisterV2FrameCallbackFn = bool (*)(RsFrameCallbackFn callback,
                                             void* user_data);
using RsRegisterV1FrameCallbackFn = bool (*)(RsV1FrameCallbackFn callback,
                                             void* user_data);
using RsClipboardCallbackFn = void (*)(void* user_data,
                                       const uint8_t* data,
                                       size_t data_len);
using RsRegisterClipboardCallbackFn = bool (*)(RsClipboardCallbackFn callback,
                                               void* user_data);

// rust_scrcpy.dll 自动初始化与符号缓存。
//
// 主要职责：
// 1. 首次使用时自动加载 `rust_scrcpy.dll`（优先当前进程已加载模块）；
// 2. 统一解析导出符号，避免各链路重复写 GetProcAddress；
// 3. 缓存函数指针，减少运行时重复查找开销。
class RustScrcpyDllApi final {
 public:
  static RustScrcpyDllApi& Instance();

  // 确保 DLL 已加载。
  // 失败时返回 false，并在 error 中写明原因。
  bool EnsureLoaded(std::string* error);

  // 获取“V1 共享句柄回调注册函数”。
  RsRegisterV1FrameCallbackFn RegisterV1(std::string* error);
  // 获取“V2 CPU 像素回调注册函数”。
  RsRegisterV2FrameCallbackFn RegisterV2(std::string* error);
  // 获取“剪贴板回调注册函数”。
  RsRegisterClipboardCallbackFn RegisterClipboard(std::string* error);

 private:
  RustScrcpyDllApi() = default;
  FARPROC ResolveSymbol(const char* symbol, std::string* error);

  std::mutex mutex_;
  HMODULE module_ = nullptr;
  RsRegisterV1FrameCallbackFn register_v1_ = nullptr;
  RsRegisterV2FrameCallbackFn register_v2_ = nullptr;
  RsRegisterClipboardCallbackFn register_clipboard_ = nullptr;
};

#endif  // RUNNER_RUST_SCRCPY_DLL_API_H_
