import 'package:flutter/widgets.dart';
import 'package:vkpn/app/vkpn_app.dart';
import 'package:vkpn/features/settings/data/settings_repository_impl.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = SettingsRepositoryImpl();
  final loaded = await repo.load();
  final initial = loaded.normalizeLocaleForStoredCustomArb();
  if (!identical(loaded, initial)) {
    await repo.save(initial);
  }
  runApp(VkpnApp(settingsRepository: repo, initialSettings: initial));
}
