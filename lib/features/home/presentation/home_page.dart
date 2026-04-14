import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vkpn/core/common/format_bytes.dart';
import 'package:vkpn/core/common/log_sanitizer.dart';
import 'package:vkpn/core/l10n/l10n_helpers.dart';
import 'package:vkpn/features/apps_exclusion/presentation/widgets/excluded_apps_sheet.dart';
import 'package:vkpn/features/home/presentation/bloc/home_cubit.dart';
import 'package:vkpn/features/home/presentation/bloc/home_state.dart';
import 'package:vkpn/features/profiles/presentation/widgets/profile_switcher.dart';
import 'package:vkpn/features/settings/presentation/widgets/app_settings_section.dart';
import 'package:vkpn/features/vpn/presentation/widgets/vpn_panel.dart';
import 'package:vkpn/l10n/app_localizations.dart';

/// Root screen; [HomeCubit] is provided by [VkpnApp] above [MaterialApp].
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomeView();
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  late final TextEditingController _configCtrl;
  late final TextEditingController _vkLinkCtrl;
  late final TextEditingController _proxyPortCtrl;
  late final TextEditingController _threadsCtrl;
  late final TextEditingController _excludedAppsCtrl;

  final _pageScrollController = ScrollController();
  final _logScrollController = ScrollController();

  bool _renameProfileOpen = false;
  TextEditingController? _renameProfileCtrl;

  @override
  void initState() {
    super.initState();
    final s = context.read<HomeCubit>().state;
    _configCtrl = TextEditingController(text: s.wgConfigText);
    _vkLinkCtrl = TextEditingController(text: s.vkCallLink);
    _proxyPortCtrl = TextEditingController(text: s.proxyPortText);
    _threadsCtrl = TextEditingController(text: s.threadsText);
    _excludedAppsCtrl = TextEditingController(text: s.excludedAppPackages);
    _configCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HomeCubit>().checkBatteryOptimizationIfNeeded();
    });
  }

  @override
  void dispose() {
    _renameProfileCtrl?.dispose();
    _configCtrl.dispose();
    _vkLinkCtrl.dispose();
    _proxyPortCtrl.dispose();
    _threadsCtrl.dispose();
    _excludedAppsCtrl.dispose();
    _pageScrollController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  void _flushForm() {
    if (!mounted) return;
    context.read<HomeCubit>().applyFormSnapshot(
      wgConfigText: _configCtrl.text,
      vkCallLink: _vkLinkCtrl.text,
      proxyPortText: _proxyPortCtrl.text,
      threadsText: _threadsCtrl.text,
      excludedAppPackages: _excludedAppsCtrl.text,
    );
  }

  void _scrollLogsToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_logScrollController.hasClients) return;
      _logScrollController.jumpTo(
        _logScrollController.position.maxScrollExtent,
      );
    });
  }

  void _syncControllersFromState(HomeState state) {
    void setIfChanged(TextEditingController c, String next) {
      if (c.text != next) {
        c.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      }
    }

    setIfChanged(_configCtrl, state.wgConfigText);
    setIfChanged(_vkLinkCtrl, state.vkCallLink);
    setIfChanged(_proxyPortCtrl, state.proxyPortText);
    setIfChanged(_threadsCtrl, state.threadsText);
    setIfChanged(_excludedAppsCtrl, state.excludedAppPackages);
  }

  String? _displayError(BuildContext context, HomeCubit cubit, HomeState state) {
    final key = cubit.localizedErrorL10nKey();
    if (key != null) {
      final localized = tr(context, key, (_) => '');
      if (localized.trim().isNotEmpty) {
        return localized;
      }
      switch (key) {
        case 'wgConfigRequired':
          return 'WireGuard config is required.';
        case 'vkLinkRequired':
          return 'VK call link is required for WG+TURN mode.';
        case 'permissionsDenied':
          return 'Required permissions were denied.';
        case 'vpnPermissionRequired':
          return 'VPN permission is required.';
      }
    }
    return state.lastError;
  }

  Color _statusColor(String status) {
    if (status.toLowerCase() == 'connected') {
      return const Color(0xFF4ADE80);
    }
    return const Color(0xFFF87171);
  }

  String _excludedAppsSummary(BuildContext context, String raw) {
    final summary = context.read<HomeCubit>().buildExcludedAppsSummary();
    final ids = summary.ids;
    if (ids.isEmpty) {
      return tr(context, 'noneSelected', (l) => l.noneSelected);
    }
    if (summary.commaSeparatedIfShort != null) {
      return summary.commaSeparatedIfShort!;
    }
    final o = CustomArbScope.overridesOf(context);
    if (o.containsKey('appsSelectedCount')) {
      return o['appsSelectedCount']!.replaceAll(
        '{count}',
        '${ids.length}',
      );
    }
    return AppLocalizations.of(context)!.appsSelectedCount(ids.length);
  }

  Future<void> _openExcludedAppsPicker() async {
    final cubit = context.read<HomeCubit>();
    _flushForm();
    final picked = await showModalBottomSheet<Set<String>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A1D45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext ctx) => ExcludedAppsSheet(
        initialIds: cubit.buildExcludedAppsSummary().ids,
        isIos: Platform.isIOS,
        isWindows: Platform.isWindows,
      ),
    );
    if (picked == null || !mounted) return;
    await cubit.applyExcludedPackagesFromPicker(picked);
    if (!mounted) return;
    _syncControllersFromState(context.read<HomeCubit>().state);
  }

  Future<void> _pickCustomArb() async {
    final cubit = context.read<HomeCubit>();
    _flushForm();
    final loaded = await cubit.pickCustomArbAndSave();
    if (!loaded || !mounted) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(context, 'customArbLoaded', (l) => l.customArbLoaded),
        ),
      ),
    );
  }

  Future<void> _clearCustomArb() async {
    _flushForm();
    await context.read<HomeCubit>().applyCustomArbContent(null);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(context, 'customArbCleared', (l) => l.customArbCleared),
        ),
      ),
    );
  }

  Future<void> _exportCustomArb() async {
    _flushForm();
    final locale = Localizations.localeOf(context);
    final exported =
        await context.read<HomeCubit>().exportCurrentLocaleArb(locale);
    if (!exported || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(context, 'customArbExported', (l) => l.customArbExported),
        ),
      ),
    );
  }

  Future<void> _pickConfigFile() async {
    final cubit = context.read<HomeCubit>();
    _flushForm();
    await cubit.pickConfigAndSave();
    if (mounted) {
      _syncControllersFromState(context.read<HomeCubit>().state);
    }
  }

  Future<void> _renameProfile() async {
    final cubit = context.read<HomeCubit>();
    _flushForm();
    final st = cubit.state;
    final id = st.activeProfileId;
    if (id == null) return;
    final i = st.profiles.indexWhere((p) => p.id == id);
    if (i < 0) return;
    _renameProfileCtrl?.dispose();
    _renameProfileCtrl = TextEditingController(text: st.profiles[i].name);
    if (!mounted) return;
    setState(() => _renameProfileOpen = true);
  }

  void _cancelRenameProfile() {
    if (!_renameProfileOpen) return;
    _renameProfileCtrl?.dispose();
    _renameProfileCtrl = null;
    setState(() => _renameProfileOpen = false);
  }

  Future<void> _submitRenameProfile() async {
    final ctrl = _renameProfileCtrl;
    if (ctrl == null || !mounted) return;
    final name = ctrl.text.trim();
    if (name.isEmpty) return;
    ctrl.dispose();
    _renameProfileCtrl = null;
    if (!mounted) return;
    setState(() => _renameProfileOpen = false);
    await context.read<HomeCubit>().renameActiveProfile(name);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_renameProfileOpen,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && _renameProfileOpen) {
          _cancelRenameProfile();
        }
      },
      child: MultiBlocListener(
      listeners: <BlocListener<HomeCubit, HomeState>>[
        BlocListener<HomeCubit, HomeState>(
          listenWhen: (HomeState p, HomeState c) =>
              p.fieldsEpoch != c.fieldsEpoch,
          listener: (BuildContext context, HomeState state) {
            _syncControllersFromState(state);
          },
        ),
        BlocListener<HomeCubit, HomeState>(
          listenWhen: (HomeState p, HomeState c) =>
              p.logs.length < c.logs.length,
          listener: (BuildContext context, HomeState state) {
            _scrollLogsToBottom();
          },
        ),
        BlocListener<HomeCubit, HomeState>(
          listenWhen: (HomeState p, HomeState c) =>
              !p.pendingBatteryPrompt && c.pendingBatteryPrompt,
          listener: (BuildContext context, HomeState state) {
            final homeCubit = context.read<HomeCubit>();
            unawaited(
              showDialog<void>(
                context: context,
                builder: (BuildContext ctx) {
                  return AlertDialog(
                    title: Text(
                      tr(
                        ctx,
                        'batteryOptimizationTitle',
                        (l) => l.batteryOptimizationTitle,
                      ),
                    ),
                    content: Text(
                      tr(
                        ctx,
                        'batteryOptimizationBody',
                        (l) => l.batteryOptimizationBody,
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!ctx.mounted) return;
                            Navigator.of(ctx).pop();
                            homeCubit.consumeBatteryPrompt();
                          });
                        },
                        child: Text(tr(ctx, 'later', (l) => l.later)),
                      ),
                      FilledButton(
                        onPressed: () {
                          WidgetsBinding.instance
                              .addPostFrameCallback((_) async {
                            if (!ctx.mounted) return;
                            Navigator.of(ctx).pop();
                            await homeCubit
                                .requestDisableBatteryOptimization();
                            homeCubit.consumeBatteryPrompt();
                          });
                        },
                        child: Text(
                          tr(ctx, 'openSettings', (l) => l.openSettings),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ],
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (BuildContext context, HomeState state) {
          final cubit = context.read<HomeCubit>();
          final Widget stack = Stack(
            children: <Widget>[
              Scaffold(
                body: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[Color(0xFF0A1D45), Color(0xFF050B1A)],
                    ),
                  ),
                  child: SafeArea(
                    child: SingleChildScrollView(
                      controller: _pageScrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Column(
                        children: <Widget>[
                      VpnPanel(
                        useTurnMode: state.useTurnMode,
                        status: state.status,
                        statusColor: _statusColor(state.status),
                        configLoaded: _configCtrl.text.trim().isNotEmpty,
                        lastError: _displayError(context, cubit, state),
                        rxBytesText: formatBytes(state.rxBytes),
                        txBytesText: formatBytes(state.txBytes),
                        logsText: state.logs.join('\n'),
                        logScrollController: _logScrollController,
                        onModeChanged: (bool value) {
                          _flushForm();
                          cubit.setUseTurnMode(value);
                        },
                        onConnect: () {
                          _flushForm();
                          unawaited(cubit.connect());
                        },
                        onDisconnect: () => unawaited(cubit.disconnect()),
                        onCopyLogs: () {
                          final sanitizedLogs = state.logs
                              .map(sanitizeLogLine)
                              .join('\n');
                          Clipboard.setData(ClipboardData(text: sanitizedLogs));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                tr(context, 'logsCopied', (l) => l.logsCopied),
                              ),
                            ),
                          );
                        },
                        onClearLogs: cubit.clearLogs,
                        beforeConnect: <Widget>[
                          ProfileSwitcher(
                            profiles: state.profiles,
                            activeProfileId: state.activeProfileId,
                            onSwitchProfile: (String id) async {
                              _flushForm();
                              await cubit.switchProfile(id);
                            },
                            onAddProfile: () async {
                              _flushForm();
                              await cubit.addProfile();
                            },
                            onRenameProfile: _renameProfile,
                            onDuplicateProfile: () async {
                              _flushForm();
                              await cubit.duplicateProfile();
                            },
                            onDeleteProfile: () async {
                              _flushForm();
                              await cubit.deleteProfile();
                            },
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: const Color(0xFF132B57),
                                    side: BorderSide.none,
                                    minimumSize: const Size.fromHeight(48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: _pickConfigFile,
                                  child: Text(
                                    cubit.configButtonLabel().showImportLabel
                                        ? tr(
                                            context,
                                            'importConf',
                                            (l) => l.importConf,
                                          )
                                        : AppLocalizations.of(context)!
                                              .currentConf(
                                                cubit
                                                    .configButtonLabel()
                                                    .fileName!,
                                              ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              tr(context, 'vkCallLink', (l) => l.vkCallLink),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _vkLinkCtrl,
                            decoration: InputDecoration(
                              hintText: tr(
                                context,
                                'vkCallHint',
                                (l) => l.vkCallHint,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AppSettingsSection(
                        localeCode: state.localeCode,
                        customArbContent: state.customArbContent,
                        proxyPortCtrl: _proxyPortCtrl,
                        threadsCtrl: _threadsCtrl,
                        useUdp: state.useUdp,
                        excludedAppsSummary: _excludedAppsSummary(
                          context,
                          _excludedAppsCtrl.text,
                        ),
                        onSetLocaleCode: (String? code) {
                          _flushForm();
                          cubit.setLocaleCode(code);
                        },
                        onPickCustomArb: _pickCustomArb,
                        onExportCustomArb: _exportCustomArb,
                        onClearCustomArb: _clearCustomArb,
                        onUseUdpChanged: (bool v) {
                          _flushForm();
                          cubit.setUseUdp(v);
                        },
                        onOpenExcludedAppsPicker: _openExcludedAppsPicker,
                      ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_renameProfileOpen) _renameProfileOverlay(context),
            ],
          );
          if (Platform.isWindows) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: stack,
            );
          }
          return stack;
        },
      ),
    ),
    );
  }

  Widget _renameProfileOverlay(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _cancelRenameProfile,
        child: ColoredBox(
          color: Colors.black54,
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: AlertDialog(
                title: Text(tr(context, 'profileName', (l) => l.profileName)),
                content: TextField(
                  controller: _renameProfileCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: _cancelRenameProfile,
                    child: Text(tr(context, 'cancel', (l) => l.cancel)),
                  ),
                  FilledButton(
                    onPressed: () => unawaited(_submitRenameProfile()),
                    child: Text(tr(context, 'apply', (l) => l.apply)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
