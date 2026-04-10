import '../contracts/vpn_runtime_gateway.dart';

class DisconnectVpnUseCase {
  DisconnectVpnUseCase({required this.gateway});

  final VpnRuntimeGateway gateway;

  Future<void> call() => gateway.stop();
}
