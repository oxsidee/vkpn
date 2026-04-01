import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  static const _kAppleAppGroup = 'group.space.iscreation.vkpn';

  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(groupId: _kAppleAppGroup),
    mOptions: MacOsOptions(groupId: _kAppleAppGroup),
  );

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final migratedVkCallLink = await _readAndMigrateLegacySecret(
      prefs: prefs,
      key: _kVkCallLink,
    );
    final migratedWgConfigText = await _readAndMigrateLegacySecret(
      prefs: prefs,
      key: _kWgConfigText,
    );
    return AppSettings(
      proxyPort: prefs.getInt(_kProxyPort) ?? 56000,
      vkCallLink: migratedVkCallLink ?? '',
      useUdp: prefs.getBool(_kUseUdp) ?? true,
      useTurnMode: prefs.getBool(_kUseTurnMode) ?? true,
      threads: prefs.getInt(_kThreads) ?? 8,
      wgConfigText: migratedWgConfigText ?? '',
      wgConfigFileName: prefs.getString(_kWgConfigFileName) ?? '',
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kProxyPort, settings.proxyPort);
    await prefs.setBool(_kUseUdp, settings.useUdp);
    await prefs.setBool(_kUseTurnMode, settings.useTurnMode);
    await prefs.setInt(_kThreads, settings.threads);
    await prefs.setString(_kWgConfigFileName, settings.wgConfigFileName);
    await _writeSecret(_kVkCallLink, settings.vkCallLink);
    await _writeSecret(_kWgConfigText, settings.wgConfigText);
    await prefs.remove(_kVkCallLink);
    await prefs.remove(_kWgConfigText);
  }

  Future<String?> _readAndMigrateLegacySecret({
    required SharedPreferences prefs,
    required String key,
  }) async {
    final secureValue = await _secureStorage.read(key: key);
    if (secureValue != null) {
      if (prefs.containsKey(key)) {
        await prefs.remove(key);
      }
      return secureValue;
    }

    final legacyValue = prefs.getString(key);
    if (legacyValue == null) {
      return null;
    }

    await _writeSecret(key, legacyValue);
    await prefs.remove(key);
    return legacyValue;
  }

  Future<void> _writeSecret(String key, String value) async {
    if (value.isEmpty) {
      await _secureStorage.delete(key: key);
      return;
    }
    await _secureStorage.write(key: key, value: value);
  }
}
