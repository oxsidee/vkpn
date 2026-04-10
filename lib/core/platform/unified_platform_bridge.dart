import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:vkpn/features/vpn/domain/entities/wg_config.dart';

class UnifiedPlatformBridge {
  static const MethodChannel _channel = MethodChannel('unified_vpn/methods');
  static const EventChannel _logsChannel = EventChannel('unified_vpn/logs');

  Future<bool> prepareVpn() async {
    try {
      final result = await _channel.invokeMethod<bool>('prepareVpn');
      return result ?? false;
    } on MissingPluginException {
      return true;
    }
  }

  Future<bool> requestRuntimePermissions() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestRuntimePermissions');
      return result ?? true;
    } on MissingPluginException {
      return true;
    }
  }

  Future<void> start(RuntimeVpnConfig config, {required bool useUdp, required int threads}) async {
    await _channel.invokeMethod<void>('start', <String, dynamic>{
      ...config.toJson(),
      'useUdp': useUdp,
      'threads': threads,
    });
  }

  Future<void> stop() async {
    await _channel.invokeMethod<void>('stop');
  }

  Future<String> status() async {
    final result = await _channel.invokeMethod<String>('status');
    return result ?? 'unknown';
  }

  Future<Map<String, dynamic>> trafficStats() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('trafficStats');
      if (result == null) {
        return <String, dynamic>{'rxBytes': 0, 'txBytes': 0};
      }
      return result.map((key, value) => MapEntry(key.toString(), value));
    } on MissingPluginException {
      return <String, dynamic>{'rxBytes': 0, 'txBytes': 0};
    }
  }

  Future<bool> isBatteryOptimizationIgnored() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      final result = await _channel.invokeMethod<bool>('isBatteryOptimizationIgnored');
      return result ?? true;
    } on MissingPluginException {
      return true;
    }
  }

  Future<void> requestDisableBatteryOptimization() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('requestDisableBatteryOptimization');
    } on MissingPluginException {
      return;
    }
  }

  Stream<String> logs() {
    return _logsChannel
        .receiveBroadcastStream()
        .map((e) => e.toString())
        .handleError((_) {});
  }
}
