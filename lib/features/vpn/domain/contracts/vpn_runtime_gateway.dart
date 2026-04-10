import '../entities/wg_config.dart';

abstract class VpnRuntimeGateway {
  Future<bool> prepareVpn();
  Future<bool> requestRuntimePermissions();
  Future<void> start(RuntimeVpnConfig config, {required bool useUdp, required int threads});
  Future<void> stop();
  Future<String> status();
  Future<Map<String, dynamic>> trafficStats();
  Stream<String> logs();

  Future<bool> isBatteryOptimizationIgnored();
  Future<void> requestDisableBatteryOptimization();

  Future<void> initializeWireguard({
    required String interfaceName,
    required String vpnName,
    String? iosAppGroup,
  });

  Stream<dynamic> wireguardStageSnapshot();
  Stream<Map<String, dynamic>> wireguardTrafficSnapshot();
  Future<void> startWireguardVpn({
    required String serverAddress,
    required String wgQuickConfig,
    required String providerBundleIdentifier,
  });
  Future<void> stopWireguardVpn();

  Future<void> startDesktopTurn({
    required String targetHost,
    required int proxyPort,
    required String vkCallLink,
    required bool useUdp,
    required int threads,
    required String listenHost,
    required int listenPort,
    required void Function(String) onLog,
  });
  Future<void> stopDesktopTurn();
}
