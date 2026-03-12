#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <dbghelp.h>

#include <cstdlib>
#include <filesystem>
#include <string>

#include "flutter_window.h"
#include "utils.h"

namespace {

/// 生成崩溃转储文件路径（%LOCALAPPDATA%\sw_game_helper\crash_dumps\*.dmp）。
std::wstring BuildCrashDumpPath() {
  wchar_t* local_app_data = nullptr;
  size_t local_app_data_len = 0;
  _wdupenv_s(&local_app_data, &local_app_data_len, L"LOCALAPPDATA");
  std::filesystem::path dump_dir = local_app_data != nullptr
                                       ? std::filesystem::path(local_app_data)
                                       : std::filesystem::temp_directory_path();
  if (local_app_data != nullptr) {
    free(local_app_data);
  }
  dump_dir /= L"sw_game_helper";
  dump_dir /= L"crash_dumps";
  std::error_code ec;
  std::filesystem::create_directories(dump_dir, ec);

  SYSTEMTIME st{};
  GetLocalTime(&st);
  wchar_t filename[128] = {0};
  swprintf_s(filename, L"sw_game_helper_%04u%02u%02u_%02u%02u%02u_%lu.dmp",
             st.wYear, st.wMonth, st.wDay, st.wHour, st.wMinute, st.wSecond,
             GetCurrentProcessId());
  return (dump_dir / filename).wstring();
}

/// 顶层未处理异常过滤器：写入 minidump，便于定位 native 崩溃。
LONG WINAPI TopLevelExceptionFilter(EXCEPTION_POINTERS* exception_info) {
  const std::wstring dump_path = BuildCrashDumpPath();
  HANDLE dump_file = CreateFileW(dump_path.c_str(), GENERIC_WRITE, 0, nullptr,
                                 CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (dump_file != INVALID_HANDLE_VALUE) {
    MINIDUMP_EXCEPTION_INFORMATION mei{};
    mei.ThreadId = GetCurrentThreadId();
    mei.ExceptionPointers = exception_info;
    mei.ClientPointers = FALSE;
    MiniDumpWriteDump(GetCurrentProcess(), GetCurrentProcessId(), dump_file,
                      static_cast<MINIDUMP_TYPE>(MiniDumpWithDataSegs |
                                                 MiniDumpWithThreadInfo),
                      &mei, nullptr, nullptr);
    CloseHandle(dump_file);
  }
  return EXCEPTION_EXECUTE_HANDLER;
}

/// 安装进程级崩溃处理器。
void InstallCrashHandlers() {
  SetErrorMode(SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX);
  SetUnhandledExceptionFilter(TopLevelExceptionFilter);
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // 进程入口优先安装崩溃处理器，尽量覆盖启动早期崩溃。
  InstallCrashHandlers();

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"sw_game_helper", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
