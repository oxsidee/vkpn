import '../../../profiles/domain/entities/wg_tunnel_profile.dart';

class AppSettings {
  AppSettings({
    required this.proxyPort,
    required this.vkCallLink,
    required this.useUdp,
    required this.useTurnMode,
    required this.threads,
    required this.wgConfigText,
    required this.wgConfigFileName,
    required this.excludedAppPackages,
    this.profiles = const <WgTunnelProfile>[],
    this.activeProfileId,
    this.localeCode,
    this.customArbContent,
  });

  final int proxyPort;
  final String vkCallLink;
  final bool useUdp;
  final bool useTurnMode;
  final int threads;
  final String wgConfigText;
  final String wgConfigFileName;
  /// Android: package names (comma or newline), [Interface] ExcludedApplications — bypass VPN.
  final String excludedAppPackages;

  final List<WgTunnelProfile> profiles;
  final String? activeProfileId;

  /// `en`, `ru`, `custom` (use `@@locale` from loaded custom `.arb`), or null (device).
  final String? localeCode;

  /// JSON content of a loaded `.arb` for runtime overrides.
  final String? customArbContent;

  factory AppSettings.defaults() {
    return AppSettings(
      proxyPort: 56000,
      vkCallLink: '',
      useUdp: true,
      useTurnMode: true,
      threads: 8,
      wgConfigText: '',
      wgConfigFileName: '',
      excludedAppPackages: '',
      profiles: <WgTunnelProfile>[],
      activeProfileId: null,
      localeCode: null,
      customArbContent: null,
    );
  }

  /// Раньше custom `.arb` хранился при `localeCode` en/ru — для режима «Свой .arb» нужен код `custom`.
  AppSettings normalizeLocaleForStoredCustomArb() {
    final hasCustom = (customArbContent ?? '').trim().isNotEmpty;
    if (!hasCustom || localeCode == 'custom') {
      return this;
    }
    return AppSettings(
      proxyPort: proxyPort,
      vkCallLink: vkCallLink,
      useUdp: useUdp,
      useTurnMode: useTurnMode,
      threads: threads,
      wgConfigText: wgConfigText,
      wgConfigFileName: wgConfigFileName,
      excludedAppPackages: excludedAppPackages,
      profiles: profiles,
      activeProfileId: activeProfileId,
      localeCode: 'custom',
      customArbContent: customArbContent,
    );
  }
}
