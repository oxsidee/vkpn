// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'VkPN';

  @override
  String get batteryOptimizationTitle => 'Отключить оптимизацию батареи';

  @override
  String get batteryOptimizationBody =>
      'Чтобы VPN стабильно работал в фоне, отключите оптимизацию батареи для VkPN.';

  @override
  String get later => 'Позже';

  @override
  String get openSettings => 'Открыть настройки';

  @override
  String get vkCallLink => 'Ссылка на звонок VK';

  @override
  String get vkCallHint => 'https://vk.ru/call/join/...';

  @override
  String get proxyPort => 'Порт прокси';

  @override
  String get threads => 'Потоки';

  @override
  String get useUdp => 'Использовать UDP';

  @override
  String get excludedAppsTitle => 'Исключённые приложения (в обход VPN)';

  @override
  String get selectInstalledApps => 'Выбрать установленные…';

  @override
  String get noneSelected => 'Ничего не выбрано';

  @override
  String appsSelectedCount(int count) {
    return 'Выбрано приложений: $count';
  }

  @override
  String get importConf => 'Импорт .conf';

  @override
  String currentConf(String name) {
    return 'Текущий conf: $name';
  }

  @override
  String get wgConfigNotLoaded => 'Конфиг WG не загружен';

  @override
  String get connect => 'Подключить';

  @override
  String get disconnect => 'Отключить';

  @override
  String get received => 'Принято';

  @override
  String get sent => 'Отправлено';

  @override
  String get copy => 'КОПИРОВАТЬ';

  @override
  String get clear => 'ОЧИСТИТЬ';

  @override
  String get logsCopied => 'Логи скопированы';

  @override
  String get modeWg => 'WG';

  @override
  String get modeWgTurn => 'WG+TURN';

  @override
  String get excludeFromVpn => 'Исключить из VPN';

  @override
  String get search => 'Поиск…';

  @override
  String get addIdManual => 'Вручную (package / bundle / key)';

  @override
  String get add => 'Добавить';

  @override
  String get cancel => 'Отмена';

  @override
  String get apply => 'Применить';

  @override
  String get noMatchingApps => 'Нет совпадений. Введите ID выше.';

  @override
  String get iosAppsListDisabled =>
      'iOS не показывает список приложений. Укажите bundle ID вручную.';

  @override
  String get windowsBypassVpnHint =>
      'В Windows нельзя исключить приложение из WireGuard как на Android. Укажите IPv4 или имена хостов (например сервера игры) — трафик к ним пойдёт в обход туннеля через маршруты /32. Имена пакетов Android игнорируются.';

  @override
  String get windowsAddHostOrIpManual =>
      'Имя хоста или IPv4 (например api.example.com)';

  @override
  String get manualExclusionOnly => 'Добавляйте записи вручную в поле выше.';

  @override
  String get excludedEntryEditTitle => 'Изменить запись';

  @override
  String get excludedEntryRemove => 'Удалить';

  @override
  String couldNotLoadList(String error) {
    return 'Не удалось загрузить список: $error';
  }

  @override
  String get profilesSection => 'Профили';

  @override
  String get addProfile => 'Добавить';

  @override
  String get renameProfile => 'Переименовать';

  @override
  String get duplicateProfile => 'Дублировать';

  @override
  String get deleteProfile => 'Удалить';

  @override
  String get profileName => 'Имя профиля';

  @override
  String get advancedSection => 'Дополнительно';

  @override
  String get appSettingsSection => 'Настройки приложения';

  @override
  String get language => 'Язык';

  @override
  String get langSystem => 'Как в системе';

  @override
  String get langEnglish => 'English';

  @override
  String get langRussian => 'Русский';

  @override
  String get langCustomArb => 'Свой .arb';

  @override
  String get loadCustomArb => 'Загрузить свой .arb с переводами';

  @override
  String get exportCustomArb => 'Экспорт языка интерфейса (.arb)';

  @override
  String get clearCustomArb => 'Сбросить свои переводы';

  @override
  String get customArbLoaded => 'Свои переводы загружены';

  @override
  String get customArbExported => 'Файл перевода сохранён';

  @override
  String get customArbCleared => 'Свои переводы сброшены';

  @override
  String get vkLinkRequired =>
      'Нужна ссылка на звонок VK (поле в приложении или #@wgt:VKLink в конфиге).';

  @override
  String get wgConfigRequired => 'Конфиг WireGuard не загружен.';

  @override
  String get permissionsDenied => 'Разрешения приложения отклонены.';

  @override
  String get vpnPermissionRequired =>
      'Нужно разрешение VPN. Разрешите и снова нажмите Подключить.';

  @override
  String get trayStatusConnected => 'Статус: подключено';

  @override
  String get trayStatusDisconnected => 'Статус: не подключено';

  @override
  String get trayConnectWg => 'Подключить WG';

  @override
  String get trayConnectWgTurn => 'Подключить WG+TURN';

  @override
  String get trayExit => 'Выход';
}
