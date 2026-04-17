#include "flutter_window.h"

#include <optional>

#include <windows.h>

#include <dwmapi.h>
#include <shobjidl.h>

#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include "flutter/generated_plugin_registrant.h"

#pragma comment(lib, "dwmapi.lib")
#pragma comment(lib, "ole32.lib")

#ifndef DWMWA_WINDOW_CORNER_PREFERENCE
#define DWMWA_WINDOW_CORNER_PREFERENCE 33
#endif
#ifndef DWMWCP_ROUND
#define DWMWCP_ROUND 2
#endif

namespace {

bool g_prevent_close = false;
ITaskbarList* g_taskbar_list = nullptr;

void EnsureTaskbarList() {
  if (g_taskbar_list) {
    return;
  }
  HRESULT hr =
      CoCreateInstance(CLSID_TaskbarList, nullptr, CLSCTX_INPROC_SERVER,
                       IID_ITaskbarList, reinterpret_cast<void**>(&g_taskbar_list));
  if (SUCCEEDED(hr) && g_taskbar_list) {
    g_taskbar_list->HrInit();
  }
}

double GetDouble(const flutter::EncodableMap& map, const char* key) {
  auto it = map.find(flutter::EncodableValue(key));
  if (it == map.end()) {
    return 0.0;
  }
  if (const auto* d = std::get_if<double>(&it->second)) {
    return *d;
  }
  if (const auto* i = std::get_if<int32_t>(&it->second)) {
    return static_cast<double>(*i);
  }
  if (const auto* l = std::get_if<int64_t>(&it->second)) {
    return static_cast<double>(*l);
  }
  return 0.0;
}

void ApplyBorderlessNoCaption(HWND hwnd) {
  LONG_PTR style = GetWindowLongPtr(hwnd, GWL_STYLE);
  style &= ~(WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX |
             WS_MAXIMIZEBOX);
  SetWindowLongPtr(hwnd, GWL_STYLE, style);
  SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
               SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);

  DWORD corner_pref = DWMWCP_ROUND;
  DwmSetWindowAttribute(hwnd, DWMWA_WINDOW_CORNER_PREFERENCE, &corner_pref,
                        sizeof(corner_pref));
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  auto messenger = flutter_controller_->engine()->messenger();
  auto method_channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "unified_vpn/methods", &flutter::StandardMethodCodec::GetInstance());
  auto logs_channel = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
      messenger, "unified_vpn/logs", &flutter::StandardMethodCodec::GetInstance());
  static std::string status = "disconnected";
  static int64_t rx_bytes = 0;
  static int64_t tx_bytes = 0;
  static std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink;
  method_channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "requestRuntimePermissions") {
          BOOL is_admin = FALSE;
          PSID admin_group = nullptr;
          SID_IDENTIFIER_AUTHORITY nt_authority = SECURITY_NT_AUTHORITY;
          if (AllocateAndInitializeSid(&nt_authority, 2, SECURITY_BUILTIN_DOMAIN_RID,
                                       DOMAIN_ALIAS_RID_ADMINS, 0, 0, 0, 0, 0, 0,
                                       &admin_group)) {
            CheckTokenMembership(nullptr, admin_group, &is_admin);
            FreeSid(admin_group);
          }
          result->Success(flutter::EncodableValue(static_cast<bool>(is_admin)));
        } else if (call.method_name() == "prepareVpn") {
          result->Success(flutter::EncodableValue(true));
        } else if (call.method_name() == "start") {
          bool use_turn_mode = true;
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          if (args) {
            auto it = args->find(flutter::EncodableValue("useTurnMode"));
            if (it != args->end()) {
              if (const auto* v = std::get_if<bool>(&it->second)) use_turn_mode = *v;
            }
          }
          status = "connected";
          if (event_sink) event_sink->Success(flutter::EncodableValue(use_turn_mode ? "Windows: mode = WG+TURN" : "Windows: mode = WG"));
          if (event_sink) event_sink->Success(flutter::EncodableValue("Windows: start requested"));
          result->Success();
        } else if (call.method_name() == "stop") {
          status = "disconnected";
          if (event_sink) event_sink->Success(flutter::EncodableValue("Windows: stop requested"));
          result->Success();
        } else if (call.method_name() == "status") {
          result->Success(flutter::EncodableValue(status));
        } else if (call.method_name() == "trafficStats") {
          if (status == "connected") {
            rx_bytes += 1024;
            tx_bytes += 768;
          }
          flutter::EncodableMap map;
          map[flutter::EncodableValue("rxBytes")] = flutter::EncodableValue(rx_bytes);
          map[flutter::EncodableValue("txBytes")] = flutter::EncodableValue(tx_bytes);
          result->Success(flutter::EncodableValue(map));
        } else if (call.method_name() == "isBatteryOptimizationIgnored") {
          result->Success(flutter::EncodableValue(true));
        } else if (call.method_name() == "requestDisableBatteryOptimization") {
          result->Success();
        } else {
          result->NotImplemented();
        }
      });
  logs_channel->SetStreamHandler(
      std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
          [](const flutter::EncodableValue* arguments,
             std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events)
              -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
            event_sink = std::move(events);
            if (event_sink) event_sink->Success(flutter::EncodableValue("Windows: log stream connected"));
            return nullptr;
          },
          [](const flutter::EncodableValue* arguments)
              -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
            event_sink.reset();
            return nullptr;
          }));
  // Keep channels alive for app lifetime.
  static auto s_method_channel = std::move(method_channel);
  static auto s_logs_channel = std::move(logs_channel);

  auto vkpn_window_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger, "vkpn/window",
          &flutter::StandardMethodCodec::GetInstance());
  vkpn_window_channel->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        HWND hwnd = this->GetHandle();
        if (!hwnd) {
          result->Error("no_hwnd", "Window handle is null");
          return;
        }
        if (call.method_name() == "ensureReady") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          if (!args) {
            result->Error("bad_args", "Expected map");
            return;
          }
          double width = GetDouble(*args, "width");
          double height = GetDouble(*args, "height");
          bool skip_taskbar = false;
          const auto skip_it = args->find(flutter::EncodableValue("skipTaskbar"));
          if (skip_it != args->end()) {
            if (const auto* b = std::get_if<bool>(&skip_it->second)) {
              skip_taskbar = *b;
            }
          }

          EnsureTaskbarList();
          if (skip_taskbar && g_taskbar_list) {
            g_taskbar_list->DeleteTab(hwnd);
          }

          UINT dpi = GetDpiForWindow(hwnd);
          double scale = static_cast<double>(dpi) / 96.0;
          int phys_client_w = static_cast<int>(width * scale + 0.5);
          int phys_client_h = static_cast<int>(height * scale + 0.5);
          LONG style = GetWindowLong(hwnd, GWL_STYLE);
          RECT frame = {0, 0, phys_client_w, phys_client_h};
          AdjustWindowRect(&frame, style, FALSE);
          int outer_w = frame.right - frame.left;
          int outer_h = frame.bottom - frame.top;
          RECT cur{};
          GetWindowRect(hwnd, &cur);
          SetWindowPos(hwnd, nullptr, cur.left, cur.top, outer_w, outer_h,
                       SWP_NOZORDER | SWP_NOMOVE);
          ApplyBorderlessNoCaption(hwnd);
          result->Success();
        } else if (call.method_name() == "setPreventClose") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          if (args) {
            const auto it = args->find(flutter::EncodableValue("value"));
            if (it != args->end()) {
              if (const auto* b = std::get_if<bool>(&it->second)) {
                g_prevent_close = *b;
              }
            }
          }
          result->Success();
        } else if (call.method_name() == "hide") {
          ShowWindow(hwnd, SW_HIDE);
          result->Success();
        } else if (call.method_name() == "show") {
          ShowWindow(hwnd, SW_SHOW);
          result->Success();
        } else if (call.method_name() == "focus") {
          ShowWindow(hwnd, SW_SHOW);
          SetForegroundWindow(hwnd);
          result->Success();
        } else if (call.method_name() == "isVisible") {
          result->Success(
              flutter::EncodableValue(static_cast<bool>(IsWindowVisible(hwnd))));
        } else if (call.method_name() == "setAlwaysOnTop") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          bool on_top = false;
          if (args) {
            const auto it = args->find(flutter::EncodableValue("value"));
            if (it != args->end()) {
              if (const auto* b = std::get_if<bool>(&it->second)) {
                on_top = *b;
              }
            }
          }
          SetWindowPos(hwnd, on_top ? HWND_TOPMOST : HWND_NOTOPMOST, 0, 0, 0, 0,
                       SWP_NOMOVE | SWP_NOSIZE);
          result->Success();
        } else if (call.method_name() == "setPosition") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          if (!args) {
            result->Error("bad_args", "Expected map");
            return;
          }
          double x = GetDouble(*args, "x");
          double y = GetDouble(*args, "y");
          UINT dpi = GetDpiForWindow(hwnd);
          double s = static_cast<double>(dpi) / 96.0;
          int px = static_cast<int>(x * s + 0.5);
          int py = static_cast<int>(y * s + 0.5);
          RECT wr{};
          GetWindowRect(hwnd, &wr);
          int w = wr.right - wr.left;
          int h = wr.bottom - wr.top;
          SetWindowPos(hwnd, nullptr, px, py, w, h, SWP_NOZORDER);
          result->Success();
        } else if (call.method_name() == "alignBottomRight") {
          double margin_logical = 12.0;
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          if (args) {
            margin_logical = GetDouble(*args, "margin");
            if (margin_logical < 0) {
              margin_logical = 0;
            }
          }
          RECT wr{};
          GetWindowRect(hwnd, &wr);
          int w = wr.right - wr.left;
          int h = wr.bottom - wr.top;
          MONITORINFO mi{};
          mi.cbSize = sizeof(MONITORINFO);
          HMONITOR mon = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
          if (mon && GetMonitorInfo(mon, &mi)) {
            const RECT& work = mi.rcWork;
            UINT dpi = GetDpiForWindow(hwnd);
            double scale = static_cast<double>(dpi) / 96.0;
            int margin_px = static_cast<int>(margin_logical * scale + 0.5);
            int x = work.right - w - margin_px;
            int y = work.bottom - h - margin_px;
            SetWindowPos(hwnd, nullptr, x, y, w, h, SWP_NOZORDER);
          }
          result->Success();
        } else {
          result->NotImplemented();
        }
      });
  static auto s_vkpn_window_channel = std::move(vkpn_window_channel);

  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    ShowWindow(this->GetHandle(), SW_SHOW);
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (message == WM_CLOSE && g_prevent_close) {
    ShowWindow(hwnd, SW_HIDE);
    return 0;
  }

  // Автоматическое скрытие окна при клике вне его (поведение как у системного трея).
  if (message == WM_ACTIVATE) {
    if (LOWORD(wparam) == WA_INACTIVE) {
      ShowWindow(hwnd, SW_HIDE);
      return 0;
    }
  }

  // Дополнительная защита - скрытие при потере фокуса.
  if (message == WM_KILLFOCUS) {
    if (IsWindowVisible(hwnd)) {
      ShowWindow(hwnd, SW_HIDE);
    }
    return 0;
  }

  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  if (message == WM_NCHITTEST) {
    return HTCLIENT;
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
