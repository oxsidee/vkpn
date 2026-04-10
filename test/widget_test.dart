import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vkpn/app/vkpn_app.dart';
import 'package:vkpn/features/settings/data/settings_repository_impl.dart';
import 'package:vkpn/features/settings/domain/entities/app_settings.dart';
import 'package:vkpn/features/settings/domain/settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App renders scaffold', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    final SettingsRepository repo =
        SettingsRepositoryImpl(useSecureStorage: false);
    final AppSettings initial = AppSettings.defaults();
    await tester.pumpWidget(
      VkpnApp(
        settingsRepository: repo,
        initialSettings: initial,
      ),
    );
    await tester.pump();
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
