#ifndef RUNNER_FLUTTER_WINDOW_RENDER_UTILS_H_
#define RUNNER_FLUTTER_WINDOW_RENDER_UTILS_H_

#include <windows.h>

#include <cstdint>
#include <string>

// DXGI 诊断工具：HRESULT 格式化。
std::string HResultToHex(HRESULT hr);
// DXGI 诊断工具：把 BGRA 采样值转文本。
std::string PixelToText(uint32_t bgra, uint64_t checksum);
// DXGI 诊断工具：输出统一日志前缀。
void LogDxgiProbe(const std::string& text);

// 探测共享句柄能否被 OpenSharedResource/OpenSharedResource1 正常打开。
bool ProbeSharedHandleOpenResult(int64_t handle,
                                 HRESULT* legacy_hr,
                                 HRESULT* nt_hr,
                                 HRESULT* create_device_hr,
                                 uint32_t* out_bgra,
                                 uint64_t* out_checksum,
                                 HRESULT* out_readback_hr);

#endif  // RUNNER_FLUTTER_WINDOW_RENDER_UTILS_H_
