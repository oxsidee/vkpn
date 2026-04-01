import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vkpn/application/app_settings.dart';
import 'package:vkpn/application/settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('stores sensitive settings in secure storage instead of shared preferences', () async {
    final repository = SettingsRepository();
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
      ),
    );

    expect(prefs.getString('vkCallLink'), isNull);
    expect(prefs.getString('wgConfigText'), isNull);

    final storage = FlutterSecureStorage();
    expect(await storage.read(key: 'vkCallLink'), 'https://vk.ru/call/join/secret');
    expect(await storage.read(key: 'wgConfigText'), '[Interface]\nPrivateKey = secret');
    expect(prefs.getString('wgConfigFileName'), 'vpn.conf');
  });

  test('migrates legacy plaintext secrets out of shared preferences', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'proxyPort': 12345,
      'vkCallLink': 'https://vk.ru/call/join/legacy',
      'wgConfigText': '[Interface]\nPrivateKey = legacy',
      'wgConfigFileName': 'legacy.conf',
    });

    final repository = SettingsRepository();
    final settings = await repository.load();
    final prefs = await SharedPreferences.getInstance();
    final storage = FlutterSecureStorage();

    expect(settings.proxyPort, 12345);
    expect(settings.vkCallLink, 'https://vk.ru/call/join/legacy');
    expect(settings.wgConfigText, '[Interface]\nPrivateKey = legacy');
    expect(prefs.getString('vkCallLink'), isNull);
    expect(prefs.getString('wgConfigText'), isNull);
    expect(await storage.read(key: 'vkCallLink'), 'https://vk.ru/call/join/legacy');
    expect(await storage.read(key: 'wgConfigText'), '[Interface]\nPrivateKey = legacy');
  });
}
