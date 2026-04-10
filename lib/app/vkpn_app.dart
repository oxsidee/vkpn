import 'package:flutter/foundation.dart' show mapEquals, ValueNotifier;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vkpn/core/l10n/l10n_helpers.dart';
import 'package:vkpn/features/home/presentation/bloc/home_cubit.dart';
import 'package:vkpn/features/home/presentation/home_page.dart';
import 'package:vkpn/features/settings/data/file_picker_gateway_impl.dart';
import 'package:vkpn/features/settings/domain/entities/app_settings.dart';
import 'package:vkpn/features/settings/domain/settings_repository.dart';
import 'package:vkpn/l10n/app_localizations.dart';

/// Locale + custom ARB overrides applied under [MaterialApp] without rebuilding
/// [MaterialApp] (avoids tearing down the navigator overlay on every save).
final class _AppL10nShell {
  const _AppL10nShell({
    required this.userLocale,
    required this.arbMap,
  });

  /// null = use [Localizations.localeOf] from [MaterialApp] (system / resolution).
  final Locale? userLocale;
  final Map<String, String> arbMap;

  factory _AppL10nShell.fromAppSettings(AppSettings s) {
    final String? code = s.localeCode;
    Locale? userLocale;
    final Map<String, String> arbMap;
    // Полный custom `.arb` применяем только в режиме «Свой .arb», иначе выбор en/ru/система
    // не меняет UI — все ключи из файла перекрывали бы встроенные строки в [tr].
    if (code == 'custom') {
      arbMap = parseArbToMap(s.customArbContent);
      final String? lang = readArbTemplateLocaleCode(s.customArbContent);
      final String primary =
          (lang == null || lang.isEmpty) ? 'en' : lang.split(RegExp('[-_]')).first;
      userLocale = Locale(primary);
    } else {
      arbMap = <String, String>{};
      if (code != null && code.isNotEmpty) {
        userLocale = Locale(code);
      }
    }
    return _AppL10nShell(userLocale: userLocale, arbMap: arbMap);
  }

  bool sameAs(_AppL10nShell o) {
    if (userLocale != o.userLocale) {
      return false;
    }
    return mapEquals(arbMap, o.arbMap);
  }
}

final ThemeData _vkpnTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF050B1A),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF1F6BFF),
    brightness: Brightness.dark,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: false,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF132B57),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 12,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
  ),
);

class VkpnApp extends StatefulWidget {
  const VkpnApp({
    super.key,
    required this.settingsRepository,
    required this.initialSettings,
  });

  final SettingsRepository settingsRepository;
  final AppSettings initialSettings;

  @override
  State<VkpnApp> createState() => _VkpnAppState();
}

class _VkpnAppState extends State<VkpnApp> {
  late AppSettings _appSettings;
  late final ValueNotifier<_AppL10nShell> _l10nShell;
  final FilePickerGatewayImpl _filePickerGateway = FilePickerGatewayImpl();
  /// Only [setState] when [Locale] changes so [MaterialApp] is not rebuilt on ARB-only updates.
  Locale? _trackedUserLocale;

  static String? _normLocale(String? c) =>
      (c == null || c.isEmpty) ? null : c;

  static String? _normArb(String? c) {
    if (c == null) {
      return null;
    }
    final String t = c.trim();
    return t.isEmpty ? null : c;
  }

  @override
  void initState() {
    super.initState();
    _appSettings = widget.initialSettings;
    _l10nShell = ValueNotifier(_AppL10nShell.fromAppSettings(widget.initialSettings));
    _trackedUserLocale = _l10nShell.value.userLocale;
    _l10nShell.addListener(_onL10nShellChanged);
  }

  void _onL10nShellChanged() {
    final Locale? next = _l10nShell.value.userLocale;
    if (next != _trackedUserLocale) {
      _trackedUserLocale = next;
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _l10nShell.removeListener(_onL10nShellChanged);
    _l10nShell.dispose();
    super.dispose();
  }

  void _onAppSettingsUpdated(AppSettings s) {
    final bool localeChanged =
        _normLocale(s.localeCode) != _normLocale(_appSettings.localeCode);
    final bool arbChanged =
        _normArb(s.customArbContent) != _normArb(_appSettings.customArbContent);
    _appSettings = s;
    if (localeChanged || arbChanged) {
      final _AppL10nShell next = _AppL10nShell.fromAppSettings(s);
      if (!_l10nShell.value.sameAs(next)) {
        _l10nShell.value = next;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit(
        settingsRepository: widget.settingsRepository,
        onAppSettingsUpdated: _onAppSettingsUpdated,
        bootstrapSettings: _appSettings,
        filePickerGateway: _filePickerGateway,
      )..start(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _vkpnTheme,
        locale: _l10nShell.value.userLocale,
        onGenerateTitle: (BuildContext context) =>
            AppLocalizations.of(context)?.appTitle ?? 'VkPN',
        localeResolutionCallback:
            (Locale? deviceLocale, Iterable<Locale> supported) {
          for (final Locale l in supported) {
            if (l.languageCode == deviceLocale?.languageCode) {
              return l;
            }
          }
          return supported.first;
        },
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (BuildContext context, Widget? child) {
          return ValueListenableBuilder<_AppL10nShell>(
            valueListenable: _l10nShell,
            builder: (BuildContext context, _AppL10nShell shell, Widget? _) {
              final Locale base = Localizations.localeOf(context);
              final Locale effective = shell.userLocale ?? base;
              return Localizations.override(
                context: context,
                locale: effective,
                child: CustomArbScope(
                  overrides: shell.arbMap,
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
          );
        },
        home: const HomeScreen(),
      ),
    );
  }
}
