import '../contracts/vpn_runtime_gateway.dart';
import '../entities/wg_config.dart';

class ConnectVpnUseCase {
  ConnectVpnUseCase({required this.gateway});

  final VpnRuntimeGateway gateway;

  Future<void> call(RuntimeVpnConfig config) async {
    await gateway.start(
      config,
      useUdp: config.effectiveUseUdp,
      threads: config.effectiveThreads,
    );
  }
}
