import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'VkPN'**
  String get appTitle;

  /// No description provided for @batteryOptimizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Disable Battery Optimization'**
  String get batteryOptimizationTitle;

  /// No description provided for @batteryOptimizationBody.
  ///
  /// In en, this message translates to:
  /// **'To keep VPN stable in background, disable battery optimization for VkPN.'**
  String get batteryOptimizationBody;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @vkCallLink.
  ///
  /// In en, this message translates to:
  /// **'VK call link'**
  String get vkCallLink;

  /// No description provided for @vkCallHint.
  ///
  /// In en, this message translates to:
  /// **'https://vk.ru/call/join/...'**
  String get vkCallHint;

  /// No description provided for @proxyPort.
  ///
  /// In en, this message translates to:
  /// **'Proxy port'**
  String get proxyPort;

  /// No description provided for @threads.
  ///
  /// In en, this message translates to:
  /// **'Threads'**
  String get threads;

  /// No description provided for @useUdp.
  ///
  /// In en, this message translates to:
  /// **'Use UDP'**
  String get useUdp;

  /// No description provided for @excludedAppsTitle.
  ///
  /// In en, this message translates to:
  /// **'Excluded apps (bypass VPN)'**
  String get excludedAppsTitle;

  /// No description provided for @selectInstalledApps.
  ///
  /// In en, this message translates to:
  /// **'Select installed apps…'**
  String get selectInstalledApps;

  /// No description provided for @noneSelected.
  ///
  /// In en, this message translates to:
  /// **'None selected'**
  String get noneSelected;

  /// No description provided for @appsSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} apps selected'**
  String appsSelectedCount(int count);

  /// No description provided for @importConf.
  ///
  /// In en, this message translates to:
  /// **'Import .conf'**
  String get importConf;

  /// No description provided for @currentConf.
  ///
  /// In en, this message translates to:
  /// **'Current conf: {name}'**
  String currentConf(String name);

  /// No description provided for @wgConfigNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'WG config not loaded'**
  String get wgConfigNotLoaded;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @received.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get received;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'COPY'**
  String get copy;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'CLEAR'**
  String get clear;

  /// No description provided for @logsCopied.
  ///
  /// In en, this message translates to:
  /// **'Logs copied'**
  String get logsCopied;

  /// No description provided for @modeWg.
  ///
  /// In en, this message translates to:
  /// **'WG'**
  String get modeWg;

  /// No description provided for @modeWgTurn.
  ///
  /// In en, this message translates to:
  /// **'WG+TURN'**
  String get modeWgTurn;

  /// No description provided for @excludeFromVpn.
  ///
  /// In en, this message translates to:
  /// **'Exclude from VPN'**
  String get excludeFromVpn;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search…'**
  String get search;

  /// No description provided for @addIdManual.
  ///
  /// In en, this message translates to:
  /// **'Add ID manually (package / bundle / key)'**
  String get addIdManual;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @noMatchingApps.
  ///
  /// In en, this message translates to:
  /// **'No matching apps. Use manual entry above.'**
  String get noMatchingApps;

  /// No description provided for @iosAppsListDisabled.
  ///
  /// In en, this message translates to:
  /// **'iOS does not allow listing installed apps. Add bundle IDs manually below.'**
  String get iosAppsListDisabled;

  /// No description provided for @windowsBypassVpnHint.
  ///
  /// In en, this message translates to:
  /// **'Windows cannot exclude apps from WireGuard the same way as Android. Add IPv4 addresses or hostnames (e.g. game servers); traffic to them will bypass the tunnel via host routes. Android-style package names are ignored.'**
  String get windowsBypassVpnHint;

  /// No description provided for @windowsAddHostOrIpManual.
  ///
  /// In en, this message translates to:
  /// **'Hostname or IPv4 (e.g. api.example.com)'**
  String get windowsAddHostOrIpManual;

  /// No description provided for @manualExclusionOnly.
  ///
  /// In en, this message translates to:
  /// **'Use the field above to add entries manually.'**
  String get manualExclusionOnly;

  /// No description provided for @excludedEntryEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get excludedEntryEditTitle;

  /// No description provided for @excludedEntryRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get excludedEntryRemove;

  /// No description provided for @couldNotLoadList.
  ///
  /// In en, this message translates to:
  /// **'Could not load list: {error}'**
  String couldNotLoadList(String error);

  /// No description provided for @profilesSection.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get profilesSection;

  /// No description provided for @addProfile.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addProfile;

  /// No description provided for @renameProfile.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameProfile;

  /// No description provided for @duplicateProfile.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicateProfile;

  /// No description provided for @deleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteProfile;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Profile name'**
  String get profileName;

  /// No description provided for @advancedSection.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advancedSection;

  /// No description provided for @appSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'App settings'**
  String get appSettingsSection;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @langSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get langSystem;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langRussian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get langRussian;

  /// No description provided for @langCustomArb.
  ///
  /// In en, this message translates to:
  /// **'Custom .arb'**
  String get langCustomArb;

  /// No description provided for @loadCustomArb.
  ///
  /// In en, this message translates to:
  /// **'Load custom .arb translations'**
  String get loadCustomArb;

  /// No description provided for @exportCustomArb.
  ///
  /// In en, this message translates to:
  /// **'Export current language (.arb)'**
  String get exportCustomArb;

  /// No description provided for @clearCustomArb.
  ///
  /// In en, this message translates to:
  /// **'Clear custom translations'**
  String get clearCustomArb;

  /// No description provided for @customArbLoaded.
  ///
  /// In en, this message translates to:
  /// **'Custom translations loaded'**
  String get customArbLoaded;

  /// No description provided for @customArbExported.
  ///
  /// In en, this message translates to:
  /// **'Translation file saved'**
  String get customArbExported;

  /// No description provided for @customArbCleared.
  ///
  /// In en, this message translates to:
  /// **'Custom translations cleared'**
  String get customArbCleared;

  /// No description provided for @vkLinkRequired.
  ///
  /// In en, this message translates to:
  /// **'VK call link is required (app field or #@wgt:VKLink in config).'**
  String get vkLinkRequired;

  /// No description provided for @wgConfigRequired.
  ///
  /// In en, this message translates to:
  /// **'WireGuard config is not loaded.'**
  String get wgConfigRequired;

  /// No description provided for @permissionsDenied.
  ///
  /// In en, this message translates to:
  /// **'App permissions denied.'**
  String get permissionsDenied;

  /// No description provided for @vpnPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'VPN permission required. Allow it and tap Connect again.'**
  String get vpnPermissionRequired;

  /// No description provided for @trayStatusConnected.
  ///
  /// In en, this message translates to:
  /// **'Status: connected'**
  String get trayStatusConnected;

  /// No description provided for @trayStatusDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Status: disconnected'**
  String get trayStatusDisconnected;

  /// No description provided for @trayConnectWg.
  ///
  /// In en, this message translates to:
  /// **'Connect WG'**
  String get trayConnectWg;

  /// No description provided for @trayConnectWgTurn.
  ///
  /// In en, this message translates to:
  /// **'Connect WG+TURN'**
  String get trayConnectWgTurn;

  /// No description provided for @trayExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get trayExit;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
