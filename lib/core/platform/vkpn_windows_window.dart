import 'package:flutter/services.dart';

/// Управление главным окном без плагина [window_manager] (нет зависимости от
/// `screen_retriever` / `screen_retriever_windows_plugin.dll`).
abstract final class VkpnWindowsWindow {
  static const MethodChannel _ch = MethodChannel('vkpn/window');

  static Future<void> ensureReady({
    required double width,
    required double height,
    required bool skipTaskbar,
  }) {
    return _ch.invokeMethod<void>('ensureReady', <String, Object?>{
      'width': width,
      'height': height,
      'skipTaskbar': skipTaskbar,
    });
  }

  static Future<void> setPreventClose(bool value) {
    return _ch.invokeMethod<void>('setPreventClose', <String, Object?>{
      'value': value,
    });
  }

  static Future<void> hide() => _ch.invokeMethod<void>('hide');

  static Future<void> show() => _ch.invokeMethod<void>('show');

  static Future<void> focus() => _ch.invokeMethod<void>('focus');

  static Future<bool> isVisible() async {
    final bool? v = await _ch.invokeMethod<bool>('isVisible');
    return v ?? false;
  }

  static Future<void> setAlwaysOnTop(bool value) {
    return _ch.invokeMethod<void>('setAlwaysOnTop', <String, Object?>{
      'value': value,
    });
  }

  static Future<void> setPosition(double x, double y) {
    return _ch.invokeMethod<void>('setPosition', <String, Object?>{
      'x': x,
      'y': y,
    });
  }

  /// Рабочая область: нижний правый угол. [marginFromBottom] — логические px
  /// отступа от нижнего края рабочей области (над таскбаром).
  static Future<void> alignBottomRight({double marginFromBottom = 12}) {
    return _ch.invokeMethod<void>('alignBottomRight', <String, Object?>{
      'margin': marginFromBottom,
    });
  }
}
