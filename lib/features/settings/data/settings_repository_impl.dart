import 'dart:io' show Platform;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../profiles/data/profiles_local_datasource.dart';
import '../../profiles/domain/entities/wg_tunnel_profile.dart';
import '../domain/entities/app_settings.dart';
import '../domain/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({
    bool? useSecureStorage,
    FlutterSecureStorage? secureStorage,
    ProfilesLocalDatasource? profilesDatasource,
  }) : _useSecureStorage = useSecureStorage ?? !Platform.isMacOS,
       _secureStorage = secureStorage ?? _defaultSecureStorage,
       _profilesDatasource = profilesDatasource ?? ProfilesLocalDatasource();

  static const _kProxyPort = 'proxyPort';
  static const _kVkCallLink = 'vkCallLink';
  static const _kUseUdp = 'useUdp';
  static const _kUseTurnMode = 'useTurnMode';
  static const _kThreads = 'threads';
  static const _kWgConfigText = 'wgConfigText';
  static const _kWgConfigFileName = 'wgConfigFileName';
  static const _kExcludedAppPackages = 'excludedAppPackages';
  static const _kWgProfilesJson = 'wgProfilesJson';
  static const _kActiveProfileId = 'activeProfileId';
  static const _kLocaleCode = 'localeCode';
  static const _kCustomArbContent = 'customArbContent';
  static const _kAppleAppGroup = 'group.space.iscreation.vkpn';

  static final FlutterSecureStorage _defaultSecureStorage =
      FlutterSecureStorage(
        aOptions: AndroidOptions(),
        iOptions: IOSOptions(groupId: _kAppleAppGroup),
        mOptions: MacOsOptions(groupId: _kAppleAppGroup),
      );

  final bool _useSecureStorage;
  final FlutterSecureStorage _secureStorage;
  final ProfilesLocalDatasource _profilesDatasource;

  @override
  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final migratedVkCallLink = await _readSecret(
      prefs: prefs,
      key: _kVkCallLink,
    );
    final migratedWgConfigText = await _readSecret(
      prefs: prefs,
      key: _kWgConfigText,
    );
    final migratedProfilesRaw = await _readSecret(
      prefs: prefs,
      key: _kWgProfilesJson,
    );
    final migratedCustomArb = await _readSecret(
      prefs: prefs,
      key: _kCustomArbContent,
    );

    var profiles = _profilesDatasource.decodeProfiles(migratedProfilesRaw);
    var activeId = prefs.getString(_kActiveProfileId);

    if (profiles.isEmpty && (migratedWgConfigText ?? '').trim().isNotEmpty) {
      const id = 'default';
      profiles = <WgTunnelProfile>[
        WgTunnelProfile(
          id: id,
          name: 'Profile 1',
          wgConfigText: migratedWgConfigText!,
          wgConfigFileName: prefs.getString(_kWgConfigFileName) ?? '',
        ),
      ];
      activeId = id;
    }

    WgTunnelProfile? active;
    if (profiles.isNotEmpty) {
      if (activeId != null) {
        for (final p in profiles) {
          if (p.id == activeId) {
            active = p;
            break;
          }
        }
      }
      active ??= profiles.first;
    }

    return AppSettings(
      proxyPort: prefs.getInt(_kProxyPort) ?? 56000,
      vkCallLink: migratedVkCallLink ?? '',
      useUdp: prefs.getBool(_kUseUdp) ?? true,
      useTurnMode: prefs.getBool(_kUseTurnMode) ?? true,
      threads: prefs.getInt(_kThreads) ?? 8,
      wgConfigText: active?.wgConfigText ?? '',
      wgConfigFileName: active?.wgConfigFileName ?? '',
      excludedAppPackages: prefs.getString(_kExcludedAppPackages) ?? '',
      profiles: profiles,
      activeProfileId: active?.id,
      localeCode: prefs.getString(_kLocaleCode),
      customArbContent: migratedCustomArb,
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kProxyPort, settings.proxyPort);
    await prefs.setBool(_kUseUdp, settings.useUdp);
    await prefs.setBool(_kUseTurnMode, settings.useTurnMode);
    await prefs.setInt(_kThreads, settings.threads);
    await prefs.setString(_kWgConfigFileName, settings.wgConfigFileName);
    await prefs.setString(_kExcludedAppPackages, settings.excludedAppPackages);
    if (settings.activeProfileId != null) {
      await prefs.setString(_kActiveProfileId, settings.activeProfileId!);
    } else {
      await prefs.remove(_kActiveProfileId);
    }
    if (settings.localeCode != null && settings.localeCode!.isNotEmpty) {
      await prefs.setString(_kLocaleCode, settings.localeCode!);
    } else {
      await prefs.remove(_kLocaleCode);
    }

    await _writeSecret(
      prefs: prefs,
      key: _kVkCallLink,
      value: settings.vkCallLink,
    );
    await _writeSecret(
      prefs: prefs,
      key: _kWgProfilesJson,
      value: _profilesDatasource.encodeProfiles(settings.profiles),
    );
    await _writeSecret(
      prefs: prefs,
      key: _kCustomArbContent,
      value: settings.customArbContent ?? '',
    );

    await _writeSecret(
      prefs: prefs,
      key: _kWgConfigText,
      value: settings.wgConfigText,
    );
  }

  Future<String?> _readSecret({
    required SharedPreferences prefs,
    required String key,
  }) async {
    if (_useSecureStorage) {
      try {
        final secureValue = await _secureStorage.read(key: key);
        if (secureValue != null) {
          if (prefs.containsKey(key)) {
            await prefs.remove(key);
          }
          return secureValue;
        }
      } on PlatformException {
        return prefs.getString(key);
      }
    }

    final legacyValue = prefs.getString(key);
    if (legacyValue == null) {
      return null;
    }

    if (_useSecureStorage) {
      await _writeSecret(prefs: prefs, key: key, value: legacyValue);
    }
    return legacyValue;
  }

  Future<void> _writeSecret({
    required SharedPreferences prefs,
    required String key,
    required String value,
  }) async {
    if (!_useSecureStorage) {
      if (value.isEmpty) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, value);
      }
      return;
    }

    try {
      if (value.isEmpty) {
        await _secureStorage.delete(key: key);
      } else {
        await _secureStorage.write(key: key, value: value);
      }
      await prefs.remove(key);
    } on PlatformException {
      if (value.isEmpty) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, value);
      }
    }
  }
}
