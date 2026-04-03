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
    );
  }
}
