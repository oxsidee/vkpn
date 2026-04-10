import 'package:vkpn/core/platform/desktop_turn_runtime.dart';
import 'package:vkpn/core/platform/unified_platform_bridge.dart';
import 'package:vkpn/features/vpn/domain/contracts/vpn_runtime_gateway.dart';
import 'package:vkpn/features/vpn/domain/entities/wg_config.dart';
import 'package:wireguard_flutter_plus/wireguard_flutter_plus.dart';
import 'package:wireguard_flutter_plus/wireguard_flutter_platform_interface.dart';

class VpnRuntimeGatewayImpl implements VpnRuntimeGateway {
  VpnRuntimeGatewayImpl({
    UnifiedPlatformBridge? bridge,
    DesktopTurnRuntime? desktopTurnRuntime,
    WireGuardFlutterInterface? wireguard,
  }) : _bridge = bridge ?? UnifiedPlatformBridge(),
       _desktopTurnRuntime = desktopTurnRuntime ?? DesktopTurnRuntime(),
       _wireguard = wireguard ?? WireGuardFlutter.instance;

  final UnifiedPlatformBridge _bridge;
  final DesktopTurnRuntime _desktopTurnRuntime;
  final WireGuardFlutterInterface _wireguard;

  @override
  Future<bool> prepareVpn() => _bridge.prepareVpn();

  @override
  Future<bool> requestRuntimePermissions() => _bridge.requestRuntimePermissions();

  @override
  Future<void> start(RuntimeVpnConfig config, {required bool useUdp, required int threads}) {
    return _bridge.start(config, useUdp: useUdp, threads: threads);
  }

  @override
  Future<void> stop() => _bridge.stop();

  @override
  Future<String> status() => _bridge.status();

  @override
  Future<Map<String, dynamic>> trafficStats() => _bridge.trafficStats();

  @override
  Stream<String> logs() => _bridge.logs();

  @override
  Future<bool> isBatteryOptimizationIgnored() => _bridge.isBatteryOptimizationIgnored();

  @override
  Future<void> requestDisableBatteryOptimization() => _bridge.requestDisableBatteryOptimization();

  @override
  Future<void> initializeWireguard({
    required String interfaceName,
    required String vpnName,
    String? iosAppGroup,
  }) {
    return _wireguard.initialize(
      interfaceName: interfaceName,
      vpnName: vpnName,
      iosAppGroup: iosAppGroup,
    );
  }

  @override
  Stream<dynamic> wireguardStageSnapshot() => _wireguard.vpnStageSnapshot;

  @override
  Stream<Map<String, dynamic>> wireguardTrafficSnapshot() => _wireguard.trafficSnapshot;

  @override
  Future<void> startWireguardVpn({
    required String serverAddress,
    required String wgQuickConfig,
    required String providerBundleIdentifier,
  }) {
    return _wireguard.startVpn(
      serverAddress: serverAddress,
      wgQuickConfig: wgQuickConfig,
      providerBundleIdentifier: providerBundleIdentifier,
    );
  }

  @override
  Future<void> stopWireguardVpn() => _wireguard.stopVpn();

  @override
  Future<void> startDesktopTurn({
    required String targetHost,
    required int proxyPort,
    required String vkCallLink,
    required bool useUdp,
    required int threads,
    required String listenHost,
    required int listenPort,
    required void Function(String p1) onLog,
  }) {
    return _desktopTurnRuntime.start(
      targetHost: targetHost,
      proxyPort: proxyPort,
      vkCallLink: vkCallLink,
      useUdp: useUdp,
      threads: threads,
      listenHost: listenHost,
      listenPort: listenPort,
      onLog: onLog,
    );
  }

  @override
  Future<void> stopDesktopTurn() => _desktopTurnRuntime.stop();
}
