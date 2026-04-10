import '../contracts/vpn_runtime_gateway.dart';

class ObserveVpnTrafficUseCase {
  ObserveVpnTrafficUseCase({required this.gateway});

  final VpnRuntimeGateway gateway;

  Stream<Map<String, dynamic>> call() async* {
    while (true) {
      yield await gateway.trafficStats();
      await Future<void>.delayed(const Duration(seconds: 1));
    }
  }
}
