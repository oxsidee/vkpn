import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';

class SettingsRepository {
  static const _kProxyPort = 'proxyPort';
  static const _kVkCallLink = 'vkCallLink';
  static const _kUseUdp = 'useUdp';
  static const _kUseTurnMode = 'useTurnMode';
  static const _kThreads = 'threads';
  static const _kWgConfigText = 'wgConfigText';
  static const _kWgConfigFileName = 'wgConfigFileName';
  static const _kExcludedAppPackages = 'excludedAppPackages';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      proxyPort: prefs.getInt(_kProxyPort) ?? 56000,
      vkCallLink: prefs.getString(_kVkCallLink) ?? '',
      useUdp: prefs.getBool(_kUseUdp) ?? true,
      useTurnMode: prefs.getBool(_kUseTurnMode) ?? true,
      threads: prefs.getInt(_kThreads) ?? 8,
      wgConfigText: prefs.getString(_kWgConfigText) ?? '',
      wgConfigFileName: prefs.getString(_kWgConfigFileName) ?? '',
      excludedAppPackages: prefs.getString(_kExcludedAppPackages) ?? '',
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kProxyPort, settings.proxyPort);
    await prefs.setString(_kVkCallLink, settings.vkCallLink);
    await prefs.setBool(_kUseUdp, settings.useUdp);
    await prefs.setBool(_kUseTurnMode, settings.useTurnMode);
    await prefs.setInt(_kThreads, settings.threads);
    await prefs.setString(_kWgConfigText, settings.wgConfigText);
    await prefs.setString(_kWgConfigFileName, settings.wgConfigFileName);
    await prefs.setString(_kExcludedAppPackages, settings.excludedAppPackages);
  }
}
