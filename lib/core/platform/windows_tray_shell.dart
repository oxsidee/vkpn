import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:vkpn/core/platform/vkpn_windows_window.dart';

const Size _kFlyoutSize = Size(420, 680);

/// Зазор между нижним краем окна и таскбаром / треем (логические px).
/// Используется в alignBottomRight для позиционирования окна.
const double _kGapAboveTaskbar = 8;

/// Трей + окно без кнопки на панели задач (аналог OneDrive).
/// Окно управляется нативно ([vkpn/window]), без `window_manager` / `screen_retriever`.
final class VkpnWindowsChrome with TrayListener {
  VkpnWindowsChrome();

  bool _ready = false;

  Future<void> init() async {
    await VkpnWindowsWindow.ensureReady(
      width: _kFlyoutSize.width,
      height: _kFlyoutSize.height,
      skipTaskbar: true,
    );
    await VkpnWindowsWindow.setPreventClose(true);

    trayManager.addListener(this);

    // Windows: LoadImage(..., IMAGE_ICON) понимает только .ico, не PNG.
    await trayManager.setIcon('assets/tray_icon.ico');
    await trayManager.setToolTip('VkPN');
    // Меню задаётся в [WindowsTrayMenuHost] после появления [AppLocalizations].

    await VkpnWindowsWindow.setAlwaysOnTop(false);
    await _positionFlyout();
    await VkpnWindowsWindow.show();
    await VkpnWindowsWindow.focus();
    _ready = true;
  }

  Future<void> _toggleFlyout() async {
    if (!_ready) {
      return;
    }
    if (await VkpnWindowsWindow.isVisible()) {
      await VkpnWindowsWindow.hide();
      return;
    }
    await _positionFlyout();
    await VkpnWindowsWindow.setAlwaysOnTop(true);
    await VkpnWindowsWindow.show();
    await VkpnWindowsWindow.focus();
  }

  Future<void> _positionFlyout() async {
    await VkpnWindowsWindow.alignBottomRight(marginFromBottom: _kGapAboveTaskbar);
  }

  /// Windows tray_manager шлёт левый клик как [onTrayIconMouseDown] (см. WM_LBUTTONUP в плагине).
  @override
  void onTrayIconMouseDown() {
    _toggleFlyout();
  }

  /// Контекстное меню не открывается само — нужно вызвать [TrayManager.popUpContextMenu].
  @override
  void onTrayIconRightMouseDown() {
    unawaited(
      trayManager.popUpContextMenu(bringAppToFront: true),
    );
  }
}

VkpnWindowsChrome? _vkpnWindowsChrome;

Future<void> initWindowsTrayShell() async {
  _vkpnWindowsChrome ??= VkpnWindowsChrome();
  await _vkpnWindowsChrome!.init();
}
