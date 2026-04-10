import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vkpn/features/profiles/domain/entities/wg_tunnel_profile.dart';
import 'package:vkpn/features/settings/data/settings_repository_impl.dart';
import 'package:vkpn/features/settings/domain/entities/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test(
    'stores sensitive settings in secure storage instead of shared preferences',
    () async {
      final repository = SettingsRepositoryImpl(useSecureStorage: true);
      final prefs = await SharedPreferences.getInstance();

      await repository.save(
        AppSettings(
          proxyPort: 56000,
          vkCallLink: 'https://vk.ru/call/join/secret',
          useUdp: true,
          useTurnMode: true,
          threads: 8,
          wgConfigText: '[Interface]\nPrivateKey = secret',
          wgConfigFileName: 'vpn.conf',
          excludedAppPackages: 'com.example.app',
          profiles: const <WgTunnelProfile>[],
          activeProfileId: null,
          localeCode: null,
          customArbContent: null,
        ),
      );

      expect(prefs.getString('vkCallLink'), isNull);
      expect(prefs.getString('wgConfigText'), isNull);

      final storage = FlutterSecureStorage();
      expect(
        await storage.read(key: 'vkCallLink'),
        'https://vk.ru/call/join/secret',
      );
      expect(
        await storage.read(key: 'wgConfigText'),
        '[Interface]\nPrivateKey = secret',
      );
      expect(prefs.getString('wgConfigFileName'), 'vpn.conf');
    },
  );

  test('migrates legacy plaintext secrets out of shared preferences', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'proxyPort': 12345,
      'vkCallLink': 'https://vk.ru/call/join/legacy',
      'wgConfigText': '[Interface]\nPrivateKey = legacy',
      'wgConfigFileName': 'legacy.conf',
    });

    final repository = SettingsRepositoryImpl(useSecureStorage: true);
    final settings = await repository.load();
    final prefs = await SharedPreferences.getInstance();
    final storage = FlutterSecureStorage();

    expect(settings.proxyPort, 12345);
    expect(settings.vkCallLink, 'https://vk.ru/call/join/legacy');
    expect(settings.wgConfigText, '[Interface]\nPrivateKey = legacy');
    expect(prefs.getString('vkCallLink'), isNull);
    expect(prefs.getString('wgConfigText'), isNull);
    expect(
      await storage.read(key: 'vkCallLink'),
      'https://vk.ru/call/join/legacy',
    );
    expect(
      await storage.read(key: 'wgConfigText'),
      '[Interface]\nPrivateKey = legacy',
    );
  });

  test(
    'keeps sensitive settings in shared preferences when secure storage is disabled',
    () async {
      final repository = SettingsRepositoryImpl(useSecureStorage: false);
      final prefs = await SharedPreferences.getInstance();

      await repository.save(
        AppSettings(
          proxyPort: 56000,
          vkCallLink: 'https://vk.ru/call/join/mac',
          useUdp: true,
          useTurnMode: true,
          threads: 8,
          wgConfigText: '[Interface]\nPrivateKey = mac',
          wgConfigFileName: 'mac.conf',
          excludedAppPackages: '',
          profiles: const <WgTunnelProfile>[],
          activeProfileId: null,
          localeCode: null,
          customArbContent: null,
        ),
      );

      expect(prefs.getString('vkCallLink'), 'https://vk.ru/call/join/mac');
      expect(prefs.getString('wgConfigText'), '[Interface]\nPrivateKey = mac');

      final storage = FlutterSecureStorage();
      expect(await storage.read(key: 'vkCallLink'), isNull);
      expect(await storage.read(key: 'wgConfigText'), isNull);
    },
  );
}
