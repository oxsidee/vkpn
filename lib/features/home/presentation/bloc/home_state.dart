import 'package:equatable/equatable.dart';
import 'package:vkpn/features/home/domain/entities/home_error_code.dart';
import 'package:vkpn/features/profiles/domain/entities/wg_tunnel_profile.dart';
import 'package:vkpn/features/settings/domain/entities/app_settings.dart';
import 'package:vkpn/features/vpn/domain/entities/wg_config.dart';

class HomeState extends Equatable {
  const HomeState({
    this.profiles = const <WgTunnelProfile>[],
    this.activeProfileId,
    this.wgConfigText = '',
    this.vkCallLink = '',
    this.proxyPortText = '56000',
    this.threadsText = '8',
    this.excludedAppPackages = '',
    this.configFileName,
    this.useUdp = true,
    this.useTurnMode = true,
    this.localeCode,
    this.customArbContent,
    this.status = 'disconnected',
    this.lastError,
    this.localizedErrorKey,
    this.runtimeConfig,
    this.logs = const <String>[],
    this.rxBytes = 0,
    this.txBytes = 0,
    this.wgInitialized = false,
    this.batteryPromptShown = false,
    this.pendingBatteryPrompt = false,
    this.fieldsEpoch = 0,
  });

  factory HomeState.fromAppSettings(AppSettings s) {
    return HomeState(
      profiles: List<WgTunnelProfile>.from(s.profiles),
      activeProfileId: s.activeProfileId,
      wgConfigText: s.wgConfigText,
      vkCallLink: s.vkCallLink,
      proxyPortText: s.proxyPort.toString(),
      threadsText: s.threads.toString(),
      excludedAppPackages: s.excludedAppPackages,
      configFileName: s.wgConfigFileName.isEmpty ? null : s.wgConfigFileName,
      useUdp: s.useUdp,
      useTurnMode: s.useTurnMode,
      localeCode: s.localeCode,
      customArbContent: s.customArbContent,
    );
  }

  final List<WgTunnelProfile> profiles;
  final String? activeProfileId;
  final String wgConfigText;
  final String vkCallLink;
  final String proxyPortText;
  final String threadsText;
  final String excludedAppPackages;
  final String? configFileName;
  final bool useUdp;
  final bool useTurnMode;
  final String? localeCode;
  final String? customArbContent;
  final String status;
  final String? lastError;
  final HomeErrorCode? localizedErrorKey;
  final RuntimeVpnConfig? runtimeConfig;
  final List<String> logs;
  final int rxBytes;
  final int txBytes;
  final bool wgInitialized;
  final bool batteryPromptShown;
  final bool pendingBatteryPrompt;
  final int fieldsEpoch;

  HomeState copyWith({
    List<WgTunnelProfile>? profiles,
    String? activeProfileId,
    String? wgConfigText,
    String? vkCallLink,
    String? proxyPortText,
    String? threadsText,
    String? excludedAppPackages,
    String? configFileName,
    bool clearConfigFileName = false,
    bool? useUdp,
    bool? useTurnMode,
    String? localeCode,
    bool clearLocaleCode = false,
    String? customArbContent,
    bool clearCustomArb = false,
    String? status,
    String? lastError,
    bool clearLastError = false,
    HomeErrorCode? localizedErrorKey,
    bool clearLocalizedError = false,
    RuntimeVpnConfig? runtimeConfig,
    bool clearRuntimeConfig = false,
    List<String>? logs,
    int? rxBytes,
    int? txBytes,
    bool? wgInitialized,
    bool? batteryPromptShown,
    bool? pendingBatteryPrompt,
    bool clearPendingBatteryPrompt = false,
    int? fieldsEpoch,
  }) {
    return HomeState(
      profiles: profiles ?? this.profiles,
      activeProfileId: activeProfileId ?? this.activeProfileId,
      wgConfigText: wgConfigText ?? this.wgConfigText,
      vkCallLink: vkCallLink ?? this.vkCallLink,
      proxyPortText: proxyPortText ?? this.proxyPortText,
      threadsText: threadsText ?? this.threadsText,
      excludedAppPackages: excludedAppPackages ?? this.excludedAppPackages,
      configFileName: clearConfigFileName
          ? null
          : (configFileName ?? this.configFileName),
      useUdp: useUdp ?? this.useUdp,
      useTurnMode: useTurnMode ?? this.useTurnMode,
      localeCode: clearLocaleCode ? null : (localeCode ?? this.localeCode),
      customArbContent: clearCustomArb
          ? null
          : (customArbContent ?? this.customArbContent),
      status: status ?? this.status,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      localizedErrorKey: clearLocalizedError
          ? null
          : (localizedErrorKey ?? this.localizedErrorKey),
      runtimeConfig: clearRuntimeConfig
          ? null
          : (runtimeConfig ?? this.runtimeConfig),
      logs: logs ?? this.logs,
      rxBytes: rxBytes ?? this.rxBytes,
      txBytes: txBytes ?? this.txBytes,
      wgInitialized: wgInitialized ?? this.wgInitialized,
      batteryPromptShown: batteryPromptShown ?? this.batteryPromptShown,
      pendingBatteryPrompt: clearPendingBatteryPrompt
          ? false
          : (pendingBatteryPrompt ?? this.pendingBatteryPrompt),
      fieldsEpoch: fieldsEpoch ?? this.fieldsEpoch,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    profiles,
    activeProfileId,
    wgConfigText,
    vkCallLink,
    proxyPortText,
    threadsText,
    excludedAppPackages,
    configFileName,
    useUdp,
    useTurnMode,
    localeCode,
    customArbContent,
    status,
    lastError,
    localizedErrorKey,
    runtimeConfig,
    logs,
    rxBytes,
    txBytes,
    wgInitialized,
    batteryPromptShown,
    pendingBatteryPrompt,
    fieldsEpoch,
  ];
}
