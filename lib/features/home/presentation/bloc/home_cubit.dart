import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show Locale;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vkpn/core/l10n/l10n_helpers.dart';
import 'package:vkpn/core/common/log_sanitizer.dart';
import 'package:vkpn/core/platform/desktop_turn_runtime.dart';
import 'package:vkpn/core/platform/unified_platform_bridge.dart';
import 'package:vkpn/features/home/domain/entities/home_error_code.dart';
import 'package:vkpn/features/home/domain/usecases/map_home_error_message_usecase.dart';
import 'package:vkpn/features/apps_exclusion/domain/usecases/build_excluded_apps_summary_usecase.dart';
import 'package:vkpn/features/profiles/domain/entities/wg_tunnel_profile.dart';
import 'package:vkpn/features/profiles/domain/usecases/add_profile_usecase.dart';
import 'package:vkpn/features/profiles/domain/usecases/delete_active_profile_usecase.dart';
import 'package:vkpn/features/profiles/domain/usecases/duplicate_active_profile_usecase.dart';
import 'package:vkpn/features/profiles/domain/usecases/rename_active_profile_usecase.dart';
import 'package:vkpn/features/profiles/domain/usecases/switch_profile_usecase.dart';
import 'package:vkpn/features/settings/domain/contracts/file_picker_gateway.dart';
import 'package:vkpn/features/settings/domain/entities/app_settings.dart';
import 'package:vkpn/features/settings/domain/settings_repository.dart';
import 'package:vkpn/features/settings/domain/usecases/compose_config_button_label_usecase.dart';
import 'package:vkpn/features/settings/domain/usecases/compose_current_locale_arb_usecase.dart';
import 'package:vkpn/features/settings/domain/usecases/compose_persistable_app_settings_usecase.dart';
import 'package:vkpn/features/vpn/data/wg_config_parser.dart';
import 'package:vkpn/features/vpn/domain/usecases/build_runtime_vpn_config_usecase.dart';
import 'package:vkpn/features/vpn/domain/usecases/validate_vpn_connect_inputs_usecase.dart';
import 'package:wireguard_flutter_plus/wireguard_flutter_plus.dart';
import 'package:wireguard_flutter_plus/wireguard_flutter_platform_interface.dart';

import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required SettingsRepository settingsRepository,
    required void Function(AppSettings settings) onAppSettingsUpdated,
    required AppSettings bootstrapSettings,
    UnifiedPlatformBridge? bridge,
    DesktopTurnRuntime? desktopTurnRuntime,
    WireGuardFlutterInterface? wireguard,
    required FilePickerGateway filePickerGateway,
  }) : _settingsRepo = settingsRepository,
       _onAppSettingsUpdated = onAppSettingsUpdated,
       _bridge = bridge ?? UnifiedPlatformBridge(),
       _desktopTurnRuntime = desktopTurnRuntime ?? DesktopTurnRuntime(),
       _wireguard = wireguard ?? WireGuardFlutter.instance,
       _filePickerGateway = filePickerGateway,
       _buildRuntimeConfig = BuildRuntimeVpnConfigUseCase(
         parser: WgConfigParser(),
       ),
       _composeAppSettings = ComposePersistableAppSettingsUseCase(),
       _switchProfileUsecase = SwitchProfileUseCase(),
       _addProfileUsecase = AddProfileUseCase(),
       _renameActiveProfileUsecase = RenameActiveProfileUseCase(),
       _duplicateActiveProfileUsecase = DuplicateActiveProfileUseCase(),
       _deleteActiveProfileUsecase = DeleteActiveProfileUseCase(),
       _validateConnectInputs = ValidateVpnConnectInputsUseCase(),
       _mapErrorMessageUseCase = MapHomeErrorMessageUseCase(),
       _buildExcludedSummaryUseCase = BuildExcludedAppsSummaryUseCase(),
       _composeConfigButtonLabelUseCase = ComposeConfigButtonLabelUseCase(),
       _composeCurrentLocaleArbUseCase = ComposeCurrentLocaleArbUseCase(),
       super(HomeState.fromAppSettings(bootstrapSettings));

  final SettingsRepository _settingsRepo;
  final void Function(AppSettings settings) _onAppSettingsUpdated;
  final UnifiedPlatformBridge _bridge;
  final DesktopTurnRuntime _desktopTurnRuntime;
  final WireGuardFlutterInterface _wireguard;
  final FilePickerGateway _filePickerGateway;
  final BuildRuntimeVpnConfigUseCase _buildRuntimeConfig;
  final ComposePersistableAppSettingsUseCase _composeAppSettings;
  final SwitchProfileUseCase _switchProfileUsecase;
  final AddProfileUseCase _addProfileUsecase;
  final RenameActiveProfileUseCase _renameActiveProfileUsecase;
  final DuplicateActiveProfileUseCase _duplicateActiveProfileUsecase;
  final DeleteActiveProfileUseCase _deleteActiveProfileUsecase;
  final ValidateVpnConnectInputsUseCase _validateConnectInputs;
  final MapHomeErrorMessageUseCase _mapErrorMessageUseCase;
  final BuildExcludedAppsSummaryUseCase _buildExcludedSummaryUseCase;
  final ComposeConfigButtonLabelUseCase _composeConfigButtonLabelUseCase;
  final ComposeCurrentLocaleArbUseCase _composeCurrentLocaleArbUseCase;

  String? localizedErrorL10nKey() => _mapErrorMessageUseCase(state.localizedErrorKey);

  ExcludedAppsSummary buildExcludedAppsSummary() =>
      _buildExcludedSummaryUseCase(state.excludedAppPackages);

  ConfigButtonLabelResult configButtonLabel() => _composeConfigButtonLabelUseCase(
    wgConfigText: state.wgConfigText,
    configFileName: state.configFileName,
  );

  StreamSubscription<String>? _logSub;
  Timer? _trafficTimer;
  StreamSubscription<dynamic>? _wgStageSub;
  StreamSubscription<dynamic>? _wgTrafficSub;

  static const String _appleAppGroup = 'group.space.iscreation.vkpn';
  static const String _appleProviderBundleId =
      'space.iscreation.vkpn.WGExtension';

  bool get _isAndroid => Platform.isAndroid;
  bool get _isDesktop => Platform.isWindows || Platform.isMacOS;
  bool get _isIOS => Platform.isIOS;

  bool get _isIosSimulator =>
      Platform.isIOS &&
      Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');

  String _newProfileId() => 'p_${DateTime.now().millisecondsSinceEpoch}';

  Future<void> start() async {
    await loadSettings();
    _logSub = _bridge.logs().listen(_appendLogLine);
    _startTrafficPolling();
    await initCrossPlatformWireGuard();
  }

  Future<void> checkBatteryOptimizationIfNeeded() async {
    if (isClosed || state.batteryPromptShown) return;
    final ignored = await _bridge.isBatteryOptimizationIgnored();
    if (isClosed || ignored) return;
    emit(state.copyWith(pendingBatteryPrompt: true));
  }

  void consumeBatteryPrompt() {
    if (isClosed) return;
    emit(
      state.copyWith(
        clearPendingBatteryPrompt: true,
        batteryPromptShown: true,
      ),
    );
  }

  Future<void> requestDisableBatteryOptimization() async {
    await _bridge.requestDisableBatteryOptimization();
  }

  Future<void> loadSettings() async {
    final loaded = await _settingsRepo.load();
    final settings = loaded.normalizeLocaleForStoredCustomArb();
    if (!identical(loaded, settings)) {
      await _settingsRepo.save(settings);
    }
    if (isClosed) return;
    final runtimeStatus = _isAndroid ? await _bridge.status() : state.status;
    emit(
      state.copyWith(
        profiles: List<WgTunnelProfile>.from(settings.profiles),
        activeProfileId: settings.activeProfileId,
        wgConfigText: settings.wgConfigText,
        vkCallLink: settings.vkCallLink,
        proxyPortText: settings.proxyPort.toString(),
        threadsText: settings.threads.toString(),
        excludedAppPackages: settings.excludedAppPackages,
        localeCode: settings.localeCode,
        customArbContent: settings.customArbContent,
        useUdp: settings.useUdp,
        useTurnMode: settings.useTurnMode,
        configFileName: settings.wgConfigFileName.isEmpty
            ? null
            : settings.wgConfigFileName,
        status: runtimeStatus,
        fieldsEpoch: state.fieldsEpoch + 1,
      ),
    );
  }

  /// Pull latest values from text fields before any logic that reads [state] or calls [collectAndSave].
  void applyFormSnapshot({
    required String wgConfigText,
    required String vkCallLink,
    required String proxyPortText,
    required String threadsText,
    required String excludedAppPackages,
  }) {
    emit(
      state.copyWith(
        wgConfigText: wgConfigText,
        vkCallLink: vkCallLink,
        proxyPortText: proxyPortText,
        threadsText: threadsText,
        excludedAppPackages: excludedAppPackages,
        clearLocalizedError: true,
        clearLastError: true,
      ),
    );
  }

  void wgConfigChanged(String v) => emit(
    state.copyWith(
      wgConfigText: v,
      clearLocalizedError: true,
      clearLastError: true,
    ),
  );

  void vkCallLinkChanged(String v) => emit(
    state.copyWith(
      vkCallLink: v,
      clearLocalizedError: true,
      clearLastError: true,
    ),
  );

  void proxyPortChanged(String v) => emit(
    state.copyWith(
      proxyPortText: v,
      clearLocalizedError: true,
      clearLastError: true,
    ),
  );

  void threadsChanged(String v) => emit(
    state.copyWith(
      threadsText: v,
      clearLocalizedError: true,
      clearLastError: true,
    ),
  );

  void excludedAppsChanged(String v) => emit(
    state.copyWith(
      excludedAppPackages: v,
      clearLocalizedError: true,
      clearLastError: true,
    ),
  );

  void setUseUdp(bool v) {
    emit(
      state.copyWith(
        useUdp: v,
        clearLocalizedError: true,
        clearLastError: true,
      ),
    );
    unawaited(collectAndSave());
  }

  void setUseTurnMode(bool v) {
    emit(
      state.copyWith(
        useTurnMode: v,
        clearLocalizedError: true,
        clearLastError: true,
      ),
    );
    unawaited(collectAndSave());
  }

  void setLocaleCode(String? code) {
    emit(
      state.copyWith(
        localeCode: code,
        clearLocaleCode: code == null,
        clearLocalizedError: true,
        clearLastError: true,
      ),
    );
    unawaited(collectAndSave());
  }

  Future<void> applyCustomArbContent(String? content) async {
    final dropCustomLocale =
        content == null && state.localeCode == 'custom';
    emit(
      state.copyWith(
        customArbContent: content,
        clearCustomArb: content == null,
        clearLocaleCode: dropCustomLocale,
        localeCode: content == null ? null : 'custom',
        clearLocalizedError: true,
        clearLastError: true,
      ),
    );
    await collectAndSave();
  }

  Future<bool> pickCustomArbAndSave() async {
    final content = await _filePickerGateway.pickCustomArbContent();
    if (content == null) {
      return false;
    }
    await applyCustomArbContent(content);
    return true;
  }

  /// Exports a single `.arb` for [resolvedLocale] (en/ru): bundled template +
  /// custom overrides merged; user picks path via the platform save dialog.
  Future<bool> exportCurrentLocaleArb(Locale resolvedLocale) async {
    final lang = resolvedLocale.languageCode == 'ru' ? 'ru' : 'en';
    try {
      final baseRaw = await rootBundle.loadString('lib/l10n/app_$lang.arb');
      final overrides = parseArbToMap(state.customArbContent);
      final merged = _composeCurrentLocaleArbUseCase(
        baseArbRaw: baseRaw,
        customOverrides: overrides,
        arbLocaleCode: lang,
      );
      return _filePickerGateway.saveArbFile(
        merged,
        suggestedFileName: 'app_$lang.arb',
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> applyImportedConfig(String text, String fileName) async {
    emit(
      state.copyWith(
        wgConfigText: text,
        configFileName: fileName,
        clearLocalizedError: true,
        clearLastError: true,
      ),
    );
    await collectAndSave();
  }

  Future<bool> pickConfigAndSave() async {
    final picked = await _filePickerGateway.pickConfigFile();
    if (picked == null) {
      return false;
    }
    await applyImportedConfig(picked.content, picked.fileName);
    return true;
  }

  Future<void> applyExcludedPackagesFromPicker(Set<String> ids) async {
    emit(
      state.copyWith(
        excludedAppPackages: ids.join(', '),
        clearLocalizedError: true,
        clearLastError: true,
      ),
    );
    await collectAndSave();
  }

  Future<void> switchProfile(String id) async {
    if (state.activeProfileId == id) return;
    final r = _switchProfileUsecase(
      profiles: state.profiles,
      activeProfileId: state.activeProfileId,
      targetProfileId: id,
      currentWgConfigText: state.wgConfigText,
      currentWgConfigFileName: state.configFileName,
    );
    emit(
      state.copyWith(
        profiles: r.profiles,
        activeProfileId: r.activeProfileId,
        wgConfigText: r.wgConfigText,
        configFileName: r.wgConfigFileName,
        clearConfigFileName: r.wgConfigFileName == null,
        fieldsEpoch: state.fieldsEpoch + 1,
        clearLocalizedError: true,
        clearLastError: true,
      ),
    );
    await collectAndSave();
  }

  Future<void> addProfile() async {
    final r = _addProfileUsecase(
      profiles: state.profiles,
      activeProfileId: state.activeProfileId,
      currentWgConfigText: state.wgConfigText,
      currentWgConfigFileName: state.configFileName,
      newProfileId: _newProfileId(),
    );
    emit(
      state.copyWith(
        profiles: r.profiles,
        activeProfileId: r.activeProfileId,
        wgConfigText: '',
        clearConfigFileName: true,
        fieldsEpoch: state.fieldsEpoch + 1,
        clearLocalizedError: true,
        clearLastError: true,
      ),
    );
    await collectAndSave();
  }

  Future<void> renameActiveProfile(String trimmedName) async {
    final next = _renameActiveProfileUsecase(
      profiles: state.profiles,
      activeProfileId: state.activeProfileId,
      currentWgConfigText: state.wgConfigText,
      currentWgConfigFileName: state.configFileName,
      trimmedName: trimmedName,
    );
    if (next == null) return;
    emit(
      state.copyWith(
        profiles: next,
        clearLocalizedError: true,
        clearLastError: true,
      ),
    );
    await collectAndSave();
  }

  Future<void> duplicateProfile() async {
    final r = _duplicateActiveProfileUsecase(
      profiles: state.profiles,
      activeProfileId: state.activeProfileId,
      currentWgConfigText: state.wgConfigText,
      currentWgConfigFileName: state.configFileName,
      newProfileId: _newProfileId(),
    );
    if (r == null) return;
    emit(
      state.copyWith(
        profiles: r.profiles,
        activeProfileId: r.activeProfileId,
        fieldsEpoch: state.fieldsEpoch + 1,
        clearLocalizedError: true,
        clearLastError: true,
      ),
    );
    await collectAndSave();
  }

  Future<void> deleteProfile() async {
    final r = _deleteActiveProfileUsecase(
      profiles: state.profiles,
      activeProfileId: state.activeProfileId,
      currentWgConfigText: state.wgConfigText,
      currentWgConfigFileName: state.configFileName,
    );
    if (r == null) return;
    emit(
      state.copyWith(
        profiles: r.profiles,
        activeProfileId: r.activeProfileId,
        wgConfigText: r.wgConfigText,
        configFileName: r.wgConfigFileName,
        clearConfigFileName: r.wgConfigFileName == null,
        fieldsEpoch: state.fieldsEpoch + 1,
        clearLocalizedError: true,
        clearLastError: true,
      ),
    );
    await collectAndSave();
  }

  Future<AppSettings> collectAndSave() async {
    final settings = _composeAppSettings(
      profiles: state.profiles,
      activeProfileId: state.activeProfileId,
      wgConfigText: state.wgConfigText,
      wgConfigFileName: state.configFileName,
      vkCallLink: state.vkCallLink,
      useUdp: state.useUdp,
      useTurnMode: state.useTurnMode,
      proxyPortText: state.proxyPortText,
      threadsText: state.threadsText,
      excludedAppPackages: state.excludedAppPackages,
      localeCode: state.localeCode,
      customArbContent: state.customArbContent,
      newProfileId: _newProfileId,
    );
    await _settingsRepo.save(settings);
    if (isClosed) return settings;
    emit(
      state.copyWith(
        profiles: List<WgTunnelProfile>.from(settings.profiles),
        activeProfileId: settings.activeProfileId,
        clearLocalizedError: true,
        clearLastError: true,
      ),
    );
    _onAppSettingsUpdated(settings);
    return settings;
  }

  Future<void> prepareRuntimeConfig() async {
    try {
      final settings = await collectAndSave();
      if (isClosed) return;
      final runtimeConfig = _buildRuntimeConfig.call(
        settings.wgConfigText,
        settings,
        isAndroid: _isAndroid,
      );
      emit(
        state.copyWith(
          runtimeConfig: runtimeConfig,
          clearLastError: true,
          clearLocalizedError: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(lastError: e.toString(), clearLocalizedError: true));
    }
  }

  Future<void> connect() async {
    final preIssue = _validateConnectInputs.forRawWgConfig(state.wgConfigText);
    if (preIssue != null) {
      emit(
        state.copyWith(
          localizedErrorKey: HomeErrorCode.wgConfigRequired,
          clearLastError: true,
        ),
      );
      return;
    }
    if (_isAndroid) {
      final runtimePerms = await _bridge.requestRuntimePermissions();
      if (isClosed) return;
      if (!runtimePerms) {
        emit(
          state.copyWith(
            localizedErrorKey: HomeErrorCode.permissionsDenied,
            clearLastError: true,
          ),
        );
        return;
      }
      final prepared = await _bridge.prepareVpn();
      if (isClosed) return;
      if (!prepared) {
        emit(
          state.copyWith(
            localizedErrorKey: HomeErrorCode.vpnPermissionRequired,
            clearLastError: true,
          ),
        );
        return;
      }
    }
    await prepareRuntimeConfig();
    if (isClosed) return;
    final config = state.runtimeConfig;
    if (config == null) return;
    final postIssue = _validateConnectInputs.forRuntimeConfig(config);
    if (postIssue != null) {
      emit(
        state.copyWith(
          localizedErrorKey: HomeErrorCode.vkLinkRequired,
          clearLastError: true,
        ),
      );
      return;
    }
    await collectAndSave();
    if (isClosed) return;
    for (final hint in config.wgtUnsupportedHints) {
      _appendLogLine('WGT: $hint');
    }
    try {
      if (_isAndroid) {
        await _bridge.start(
          config,
          useUdp: config.effectiveUseUdp,
          threads: config.effectiveThreads,
        );
        final newStatus = await _bridge.status();
        if (isClosed) return;
        emit(
          state.copyWith(
            status: newStatus,
            clearLastError: true,
            clearLocalizedError: true,
          ),
        );
        _startTrafficPolling();
        return;
      }

      await initCrossPlatformWireGuard();
      if (isClosed || !state.wgInitialized) return;

      final runtimeOk = await _bridge.requestRuntimePermissions();
      if (isClosed) return;
      if (!runtimeOk) {
        emit(
          state.copyWith(
            lastError: Platform.isWindows
                ? 'Administrator rights are required on Windows. Restart VkPN and accept the UAC prompt (the app requests elevation on launch).'
                : 'Required permissions were not granted.',
            clearLocalizedError: true,
          ),
        );
        return;
      }
      final preparedVpn = await _bridge.prepareVpn();
      if (isClosed) return;
      if (!preparedVpn) {
        emit(
          state.copyWith(
            lastError: Platform.isMacOS
                ? 'VPN could not be prepared. Check System Settings → General → VPN & Filters (or Network Extension approval).'
                : 'VPN could not be prepared. Try again.',
            clearLocalizedError: true,
          ),
        );
        return;
      }

      var wgConfigToUse = config.rawConfig;
      if (config.useTurnMode) {
        if (_isDesktop) {
          await _desktopTurnRuntime.start(
            targetHost: config.targetHost,
            proxyPort: config.proxyPort,
            vkCallLink: config.vkCallLink,
            useUdp: config.effectiveUseUdp,
            threads: config.effectiveThreads,
            listenHost: config.localEndpointHost,
            listenPort: config.localEndpointPort,
            onLog: _appendLogLine,
          );
          wgConfigToUse = config.rewrittenConfig;
        } else if (_isIOS) {
          emit(
            state.copyWith(
              lastError:
                  'WG+TURN on iOS is not yet available in this build. Use WG mode.',
              clearLocalizedError: true,
            ),
          );
          return;
        } else {
          _appendLogLine(
            'Mode WG+TURN requested; fallback to WG on this platform.',
          );
        }
      }
      await _wireguard.startVpn(
        serverAddress: config.useTurnMode
            ? '${config.localEndpointHost}:${config.localEndpointPort}'
            : '${config.targetHost}:${config.targetPort}',
        wgQuickConfig: wgConfigToUse,
        providerBundleIdentifier: (_isIOS || Platform.isMacOS)
            ? _appleProviderBundleId
            : '',
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          status: 'connected',
          clearLastError: true,
          clearLocalizedError: true,
        ),
      );
    } catch (e) {
      if (_isDesktop) {
        await _desktopTurnRuntime.stop();
      }
      if (isClosed) return;
      emit(
        state.copyWith(
          lastError: 'Connect failed: $e',
          clearLocalizedError: true,
        ),
      );
    }
  }

  Future<void> disconnect() async {
    if (!_isAndroid) {
      try {
        if (_isDesktop) {
          await _desktopTurnRuntime.stop();
        }
        await _wireguard.stopVpn();
        if (isClosed) return;
        emit(
          state.copyWith(
            status: 'disconnected',
            rxBytes: 0,
            txBytes: 0,
            clearLastError: true,
            clearLocalizedError: true,
          ),
        );
      } catch (e) {
        if (isClosed) return;
        emit(state.copyWith(lastError: e.toString(), clearLocalizedError: true));
      }
      return;
    }
    try {
      await _bridge.stop();
      final newStatus = await _bridge.status();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: newStatus,
          rxBytes: 0,
          txBytes: 0,
          clearLastError: true,
          clearLocalizedError: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(lastError: e.toString(), clearLocalizedError: true));
    }
  }

  void clearLogs() {
    emit(state.copyWith(logs: <String>[]));
  }

  Future<void> initCrossPlatformWireGuard() async {
    if (_isAndroid) return;
    if (state.wgInitialized) return;
    if (_isIosSimulator) {
      if (isClosed) return;
      emit(
        state.copyWith(
          lastError:
              'VPN is not available in the iOS Simulator. Use a physical iPhone with Network Extension entitlements and signing.',
          clearLocalizedError: true,
        ),
      );
      return;
    }
    try {
      await _wireguard.initialize(
        interfaceName: 'wg0',
        vpnName: 'VkPN',
        iosAppGroup: (_isIOS || Platform.isMacOS) ? _appleAppGroup : null,
      );
      if (isClosed) return;
      emit(state.copyWith(wgInitialized: true, clearLastError: true));
      _wgStageSub = _wireguard.vpnStageSnapshot.listen((event) {
        if (isClosed) return;
        emit(state.copyWith(status: event.code));
      });
      _wgTrafficSub = _wireguard.trafficSnapshot.listen((data) {
        if (isClosed) return;
        emit(
          state.copyWith(
            rxBytes: _parseTrafficValue(data['totalDownload']),
            txBytes: _parseTrafficValue(data['totalUpload']),
          ),
        );
      });
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          lastError: 'WireGuard init failed on this platform: $e',
          clearLocalizedError: true,
        ),
      );
    }
  }

  void _appendLogLine(String line) {
    if (isClosed) return;
    const maxLogs = 200;
    final sanitized = sanitizeLogLine(line);
    final next = List<String>.from(state.logs)..add(sanitized);
    while (next.length > maxLogs) {
      next.removeAt(0);
    }
    emit(state.copyWith(logs: next));
  }

  void _startTrafficPolling() {
    if (!_isAndroid) return;
    _trafficTimer?.cancel();
    _trafficTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final stats = await _bridge.trafficStats();
      if (isClosed) return;
      emit(
        state.copyWith(
          rxBytes: (stats['rxBytes'] as num?)?.toInt() ?? 0,
          txBytes: (stats['txBytes'] as num?)?.toInt() ?? 0,
        ),
      );
    });
  }

  int _parseTrafficValue(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Future<void> close() async {
    _logSub?.cancel();
    _trafficTimer?.cancel();
    _wgStageSub?.cancel();
    _wgTrafficSub?.cancel();
    await _desktopTurnRuntime.stop();
    return super.close();
  }
}
