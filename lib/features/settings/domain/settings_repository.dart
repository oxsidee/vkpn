import 'entities/app_settings.dart';

/// Persistence for app settings (VPN prefs, profiles blob, locale, custom ARB).
abstract class SettingsRepository {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}
