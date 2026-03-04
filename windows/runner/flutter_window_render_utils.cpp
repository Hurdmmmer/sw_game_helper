#include "flutter_window_render_utils.h"

#include <d3d11.h>
#include <d3d11_1.h>

#include <cstdio>
#include <cstring>

namespace {
}

std::string HResultToHex(HRESULT hr) {
  char buf[16] = {};
  std::snprintf(buf, sizeof(buf), "0x%08X", static_cast<unsigned int>(hr));
  return std::string(buf);
}

std::string PixelToText(uint32_t bgra, uint64_t checksum) {
  const unsigned int b = (bgra & 0x000000FFu);
  const unsigned int g = (bgra & 0x0000FF00u) >> 8;
  const unsigned int r = (bgra & 0x00FF0000u) >> 16;
  const unsigned int a = (bgra & 0xFF000000u) >> 24;
  char buf[128] = {};
  std::snprintf(buf, sizeof(buf), "pixel(B,G,R,A)=(%u,%u,%u,%u) checksum=%llu", b,
                g, r, a, static_cast<unsigned long long>(checksum));
  return std::string(buf);
}

void LogDxgiProbe(const std::string& text) {
  const std::string line = "[dxgi_probe] " + text + "\n";
  OutputDebugStringA(line.c_str());
  std::fprintf(stderr, "%s", line.c_str());
}

bool ReadbackTextureSample(ID3D11Device* device, ID3D11DeviceContext* context,
                           ID3D11Texture2D* source, uint32_t* out_bgra,
                           uint64_t* out_checksum, HRESULT* out_hr) {
  if (!device || !context || !source || !out_bgra || !out_checksum || !out_hr) {
    return false;
  }
  *out_hr = E_FAIL;
  *out_bgra = 0;
  *out_checksum = 0;

  D3D11_TEXTURE2D_DESC src_desc = {};
  source->GetDesc(&src_desc);
  if (src_desc.Width == 0 || src_desc.Height == 0) {
    *out_hr = E_INVALIDARG;
    return false;
  }

  D3D11_TEXTURE2D_DESC staging_desc = src_desc;
  staging_desc.BindFlags = 0;
  staging_desc.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
  staging_desc.Usage = D3D11_USAGE_STAGING;
  staging_desc.MiscFlags = 0;

  ID3D11Texture2D* staging = nullptr;
  *out_hr = device->CreateTexture2D(&staging_desc, nullptr, &staging);
  if (FAILED(*out_hr) || !staging) return false;

  context->CopyResource(staging, source);
  D3D11_MAPPED_SUBRESOURCE mapped = {};
  *out_hr = context->Map(staging, 0, D3D11_MAP_READ, 0, &mapped);
  if (FAILED(*out_hr)) {
    staging->Release();
    return false;
  }
  const auto* data = static_cast<const uint8_t*>(mapped.pData);
  if (!data || mapped.RowPitch < 4) {
    context->Unmap(staging, 0);
    staging->Release();
    *out_hr = E_FAIL;
    return false;
  }

  *out_bgra = *reinterpret_cast<const uint32_t*>(data);
  uint64_t checksum = 1469598103934665603ull;
  const uint32_t sw = src_desc.Width < 8 ? src_desc.Width : 8;
  const uint32_t sh = src_desc.Height < 8 ? src_desc.Height : 8;
  for (uint32_t y = 0; y < sh; ++y) {
    const auto* row = data + static_cast<size_t>(y) * mapped.RowPitch;
    for (uint32_t x = 0; x < sw; ++x) {
      const uint32_t px = *reinterpret_cast<const uint32_t*>(row + x * 4u);
      checksum ^= static_cast<uint64_t>(px);
      checksum *= 1099511628211ull;
    }
  }
  *out_checksum = checksum;
  context->Unmap(staging, 0);
  staging->Release();
  *out_hr = S_OK;
  return true;
}

bool ProbeSharedHandleOpenResult(int64_t handle,
                                 HRESULT* legacy_hr,
                                 HRESULT* nt_hr,
                                 HRESULT* create_device_hr,
                                 uint32_t* out_bgra,
                                 uint64_t* out_checksum,
                                 HRESULT* out_readback_hr) {
  if (!legacy_hr || !nt_hr || !create_device_hr) return false;
  *legacy_hr = *nt_hr = *create_device_hr = E_FAIL;
  if (out_bgra) *out_bgra = 0;
  if (out_checksum) *out_checksum = 0;
  if (out_readback_hr) *out_readback_hr = E_FAIL;

  ID3D11Device* device = nullptr;
  ID3D11DeviceContext* context = nullptr;
  D3D_FEATURE_LEVEL fl = D3D_FEATURE_LEVEL_11_0;
  *create_device_hr = D3D11CreateDevice(
      nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, D3D11_CREATE_DEVICE_BGRA_SUPPORT,
      nullptr, 0, D3D11_SDK_VERSION, &device, &fl, &context);
  if (FAILED(*create_device_hr) || !device) {
    if (context) context->Release();
    if (device) device->Release();
    return false;
  }

  HANDLE raw = reinterpret_cast<HANDLE>(static_cast<intptr_t>(handle));
  ID3D11Texture2D* tex_legacy = nullptr;
  *legacy_hr = device->OpenSharedResource(raw, __uuidof(ID3D11Texture2D),
                                          reinterpret_cast<void**>(&tex_legacy));
  if (tex_legacy) {
    if (out_bgra && out_checksum && out_readback_hr) {
      ReadbackTextureSample(device, context, tex_legacy, out_bgra, out_checksum,
                            out_readback_hr);
    }
    tex_legacy->Release();
  }

  ID3D11Device1* device1 = nullptr;
  HRESULT qi_hr = device->QueryInterface(__uuidof(ID3D11Device1),
                                         reinterpret_cast<void**>(&device1));
  if (SUCCEEDED(qi_hr) && device1) {
    ID3D11Texture2D* tex_nt = nullptr;
    *nt_hr = device1->OpenSharedResource1(raw, __uuidof(ID3D11Texture2D),
                                          reinterpret_cast<void**>(&tex_nt));
    if (tex_nt) tex_nt->Release();
    device1->Release();
  } else {
    *nt_hr = qi_hr;
  }

  context->Release();
  device->Release();
  return true;
}
