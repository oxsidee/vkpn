// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'VkPN';

  @override
  String get batteryOptimizationTitle => 'Disable Battery Optimization';

  @override
  String get batteryOptimizationBody =>
      'To keep VPN stable in background, disable battery optimization for VkPN.';

  @override
  String get later => 'Later';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get vkCallLink => 'VK call link';

  @override
  String get vkCallHint => 'https://vk.ru/call/join/...';

  @override
  String get proxyPort => 'Proxy port';

  @override
  String get threads => 'Threads';

  @override
  String get useUdp => 'Use UDP';

  @override
  String get excludedAppsTitle => 'Excluded apps (bypass VPN)';

  @override
  String get selectInstalledApps => 'Select installed apps…';

  @override
  String get noneSelected => 'None selected';

  @override
  String appsSelectedCount(int count) {
    return '$count apps selected';
  }

  @override
  String get importConf => 'Import .conf';

  @override
  String currentConf(String name) {
    return 'Current conf: $name';
  }

  @override
  String get wgConfigNotLoaded => 'WG config not loaded';

  @override
  String get connect => 'Connect';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get received => 'Received';

  @override
  String get sent => 'Sent';

  @override
  String get copy => 'COPY';

  @override
  String get clear => 'CLEAR';

  @override
  String get logsCopied => 'Logs copied';

  @override
  String get modeWg => 'WG';

  @override
  String get modeWgTurn => 'WG+TURN';

  @override
  String get excludeFromVpn => 'Exclude from VPN';

  @override
  String get search => 'Search…';

  @override
  String get addIdManual => 'Add ID manually (package / bundle / key)';

  @override
  String get add => 'Add';

  @override
  String get cancel => 'Cancel';

  @override
  String get apply => 'Apply';

  @override
  String get noMatchingApps => 'No matching apps. Use manual entry above.';

  @override
  String get iosAppsListDisabled =>
      'iOS does not allow listing installed apps. Add bundle IDs manually below.';

  @override
  String get windowsBypassVpnHint =>
      'Windows cannot exclude apps from WireGuard the same way as Android. Add IPv4 addresses or hostnames (e.g. game servers); traffic to them will bypass the tunnel via host routes. Android-style package names are ignored.';

  @override
  String get windowsAddHostOrIpManual =>
      'Hostname or IPv4 (e.g. api.example.com)';

  @override
  String get manualExclusionOnly =>
      'Use the field above to add entries manually.';

  @override
  String get excludedEntryEditTitle => 'Edit entry';

  @override
  String get excludedEntryRemove => 'Remove';

  @override
  String couldNotLoadList(String error) {
    return 'Could not load list: $error';
  }

  @override
  String get profilesSection => 'Profiles';

  @override
  String get addProfile => 'Add';

  @override
  String get renameProfile => 'Rename';

  @override
  String get duplicateProfile => 'Duplicate';

  @override
  String get deleteProfile => 'Delete';

  @override
  String get profileName => 'Profile name';

  @override
  String get advancedSection => 'Advanced';

  @override
  String get appSettingsSection => 'App settings';

  @override
  String get language => 'Language';

  @override
  String get langSystem => 'System default';

  @override
  String get langEnglish => 'English';

  @override
  String get langRussian => 'Русский';

  @override
  String get langCustomArb => 'Custom .arb';

  @override
  String get loadCustomArb => 'Load custom .arb translations';

  @override
  String get exportCustomArb => 'Export current language (.arb)';

  @override
  String get clearCustomArb => 'Clear custom translations';

  @override
  String get customArbLoaded => 'Custom translations loaded';

  @override
  String get customArbExported => 'Translation file saved';

  @override
  String get customArbCleared => 'Custom translations cleared';

  @override
  String get vkLinkRequired =>
      'VK call link is required (app field or #@wgt:VKLink in config).';

  @override
  String get wgConfigRequired => 'WireGuard config is not loaded.';

  @override
  String get permissionsDenied => 'App permissions denied.';

  @override
  String get vpnPermissionRequired =>
      'VPN permission required. Allow it and tap Connect again.';

  @override
  String get trayStatusConnected => 'Status: connected';

  @override
  String get trayStatusDisconnected => 'Status: disconnected';

  @override
  String get trayConnectWg => 'Connect WG';

  @override
  String get trayConnectWgTurn => 'Connect WG+TURN';

  @override
  String get trayExit => 'Exit';
}
