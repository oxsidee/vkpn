import 'package:equatable/equatable.dart';
import 'package:vkpn/features/home/domain/entities/home_error_code.dart';
import 'package:vkpn/features/vpn/domain/entities/wg_config.dart';

class VpnSessionState extends Equatable {
  const VpnSessionState({
    this.status = 'disconnected',
    this.lastError,
    this.localizedErrorCode,
    this.runtimeConfig,
    this.logs = const <String>[],
    this.rxBytes = 0,
    this.txBytes = 0,
    this.wgInitialized = false,
  });

  final String status;
  final String? lastError;
  final HomeErrorCode? localizedErrorCode;
  final RuntimeVpnConfig? runtimeConfig;
  final List<String> logs;
  final int rxBytes;
  final int txBytes;
  final bool wgInitialized;

  VpnSessionState copyWith({
    String? status,
    String? lastError,
    bool clearLastError = false,
    HomeErrorCode? localizedErrorCode,
    bool clearLocalizedError = false,
    RuntimeVpnConfig? runtimeConfig,
    bool clearRuntimeConfig = false,
    List<String>? logs,
    int? rxBytes,
    int? txBytes,
    bool? wgInitialized,
  }) {
    return VpnSessionState(
      status: status ?? this.status,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      localizedErrorCode: clearLocalizedError
          ? null
          : (localizedErrorCode ?? this.localizedErrorCode),
      runtimeConfig: clearRuntimeConfig
          ? null
          : (runtimeConfig ?? this.runtimeConfig),
      logs: logs ?? this.logs,
      rxBytes: rxBytes ?? this.rxBytes,
      txBytes: txBytes ?? this.txBytes,
      wgInitialized: wgInitialized ?? this.wgInitialized,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    lastError,
    localizedErrorCode,
    runtimeConfig,
    logs,
    rxBytes,
    txBytes,
    wgInitialized,
  ];
}
