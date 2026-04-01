import 'dart:async';
import 'dart:io' show Platform;

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wireguard_flutter_plus/wireguard_flutter_plus.dart';

import 'application/app_settings.dart';
import 'application/log_sanitizer.dart';
import 'application/settings_repository.dart';
import 'application/vpn_controller.dart';
import 'domain/wg_config.dart';
import 'domain/wg_config_parser.dart';
import 'platform/desktop_turn_runtime.dart';
import 'platform/unified_platform_bridge.dart';

void main() {
  runApp(const UnifiedApp());
}

class UnifiedApp extends StatelessWidget {
  const UnifiedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VkPN',
      theme: ThemeData(
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
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const file_selector.XTypeGroup _macOsConfigTypeGroup =
      file_selector.XTypeGroup(
        label: 'WireGuard config',
        extensions: <String>['conf', 'txt'],
        uniformTypeIdentifiers: <String>['public.text'],
      );

  final _settingsRepo = SettingsRepository();
  final _bridge = UnifiedPlatformBridge();
  late final VpnController _controller;
  final DesktopTurnRuntime _desktopTurnRuntime = DesktopTurnRuntime();

  final _configCtrl = TextEditingController();
  final _vkLinkCtrl = TextEditingController();
  final _proxyPortCtrl = TextEditingController();
  final _threadsCtrl = TextEditingController();

  bool _useUdp = true;
  bool _useTurnMode = true;
  String _status = 'disconnected';
  String? _lastError;
  RuntimeVpnConfig? _runtimeConfig;
  String? _configFileName;
  final List<String> _logs = <String>[];
  StreamSubscription<String>? _logSub;
  final ScrollController _pageScrollController = ScrollController();
  final ScrollController _logScrollController = ScrollController();
  Timer? _trafficTimer;
  StreamSubscription<dynamic>? _wgStageSub;
  StreamSubscription<dynamic>? _wgTrafficSub;
  final _wireguard = WireGuardFlutter.instance;
  bool _wgInitialized = false;
  int _rxBytes = 0;
  int _txBytes = 0;
  bool _batteryPromptShown = false;

  @override
  void initState() {
    super.initState();
    _controller = VpnController(parser: WgConfigParser(), bridge: _bridge);
    _loadSettings();
    _initCrossPlatformWireGuard();
    _logSub = _bridge.logs().listen(_appendLogLine);
    _startTrafficPolling();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBatteryOptimizationOnLaunch();
    });
  }

  @override
  void dispose() {
    _logSub?.cancel();
    unawaited(_desktopTurnRuntime.stop());
    _configCtrl.dispose();
    _vkLinkCtrl.dispose();
    _proxyPortCtrl.dispose();
    _threadsCtrl.dispose();
    _trafficTimer?.cancel();
    _wgStageSub?.cancel();
    _wgTrafficSub?.cancel();
    _pageScrollController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  void _scrollLogsToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_logScrollController.hasClients) return;
      _logScrollController.jumpTo(
        _logScrollController.position.maxScrollExtent,
      );
    });
  }

  void _appendLogLine(String line) {
    if (!mounted) return;
    final sanitized = sanitizeLogLine(line);
    setState(() {
      _logs.add(sanitized);
      if (_logs.length > 200) {
        _logs.removeAt(0);
      }
    });
    _scrollLogsToBottom();
  }

  void _startTrafficPolling() {
    if (!_isAndroid) return;
    _trafficTimer?.cancel();
    _trafficTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final stats = await _bridge.trafficStats();
      if (!mounted) return;
      setState(() {
        _rxBytes = (stats['rxBytes'] as num?)?.toInt() ?? 0;
        _txBytes = (stats['txBytes'] as num?)?.toInt() ?? 0;
      });
    });
  }

  bool get _isAndroid => Platform.isAndroid;
  bool get _isDesktop => Platform.isWindows || Platform.isMacOS;
  bool get _isIOS => Platform.isIOS;

  /// Network Extension / VPN APIs (WireGuard) are not supported on iOS Simulator — nehelper IPC fails.
  bool get _isIosSimulator =>
      Platform.isIOS &&
      Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');
  static const String _appleAppGroup = 'group.space.iscreation.vkpn';
  static const String _appleProviderBundleId =
      'space.iscreation.vkpn.WGExtension';

  Future<void> _initCrossPlatformWireGuard() async {
    if (_isAndroid) return;
    if (_wgInitialized) return;
    if (_isIosSimulator) {
      // Avoid calling NETunnelProviderManager on simulator — it throws IPC / nehelper errors.
      if (mounted) {
        setState(() {
          _lastError =
              'VPN is not available in the iOS Simulator. Use a physical iPhone with Network Extension entitlements and signing.';
        });
      }
      return;
    }
    try {
      await _wireguard.initialize(
        interfaceName: 'wg0',
        vpnName: 'VkPN',
        iosAppGroup: (_isIOS || Platform.isMacOS) ? _appleAppGroup : null,
      );
      _wgInitialized = true;
      _wgStageSub = _wireguard.vpnStageSnapshot.listen((event) {
        if (!mounted) return;
        setState(() {
          _status = event.code;
        });
      });
      _wgTrafficSub = _wireguard.trafficSnapshot.listen((data) {
        if (!mounted) return;
        setState(() {
          _rxBytes = _parseTrafficValue(data['totalDownload']);
          _txBytes = _parseTrafficValue(data['totalUpload']);
        });
      });
    } catch (e) {
      setState(() {
        _lastError = 'WireGuard init failed on this platform: $e';
      });
    }
  }

  int _parseTrafficValue(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _formatBytes(int bytes) {
    const units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
    double value = bytes.toDouble();
    int idx = 0;
    while (value >= 1024 && idx < units.length - 1) {
      value /= 1024;
      idx++;
    }
    final fixed = value >= 100
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '$fixed ${units[idx]}';
  }

  Future<void> _checkBatteryOptimizationOnLaunch() async {
    final ignored = await _bridge.isBatteryOptimizationIgnored();
    if (!mounted || ignored || _batteryPromptShown) return;
    _batteryPromptShown = true;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Disable Battery Optimization'),
          content: const Text(
            'To keep VPN stable in background, disable battery optimization for VkPN.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _bridge.requestDisableBatteryOptimization();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  Color _statusColor() {
    final s = _status.toLowerCase();
    if (s == 'connected') return const Color(0xFF4ADE80);
    return const Color(0xFFF87171);
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsRepo.load();
    final runtimeStatus = _isAndroid ? await _bridge.status() : _status;
    _vkLinkCtrl.text = settings.vkCallLink;
    _proxyPortCtrl.text = settings.proxyPort.toString();
    _threadsCtrl.text = settings.threads.toString();
    _configCtrl.text = settings.wgConfigText;
    setState(() {
      _useUdp = settings.useUdp;
      _useTurnMode = settings.useTurnMode;
      _configFileName = settings.wgConfigFileName.isEmpty
          ? null
          : settings.wgConfigFileName;
      _status = runtimeStatus;
    });
  }

  Future<void> _pickConfigFile() async {
    if (Platform.isMacOS) {
      final file = await file_selector.openFile(
        acceptedTypeGroups: const <file_selector.XTypeGroup>[
          _macOsConfigTypeGroup,
        ],
        confirmButtonText: 'Import',
      );
      if (file == null) return;
      _configCtrl.text = await file.readAsString();
      setState(() {
        _configFileName = file.name;
      });
      await _collectSettings();
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const <String>['conf', 'txt'],
    );
    final file = (result == null || result.files.isEmpty)
        ? null
        : result.files.first;
    if (file?.bytes == null) return;
    _configCtrl.text = String.fromCharCodes(file!.bytes!);
    setState(() {
      _configFileName = file.name;
    });
    await _collectSettings();
  }

  Future<AppSettings> _collectSettings() async {
    final settings = AppSettings(
      proxyPort: int.tryParse(_proxyPortCtrl.text.trim()) ?? 56000,
      vkCallLink: _vkLinkCtrl.text.trim(),
      useUdp: _useUdp,
      useTurnMode: _useTurnMode,
      threads: int.tryParse(_threadsCtrl.text.trim()) ?? 8,
      wgConfigText: _configCtrl.text,
      wgConfigFileName: _configFileName ?? '',
    );
    await _settingsRepo.save(settings);
    return settings;
  }

  Future<void> _prepareConfig() async {
    try {
      final settings = await _collectSettings();
      final runtimeConfig = _controller.buildRuntimeConfig(
        _configCtrl.text,
        settings,
      );
      setState(() {
        _runtimeConfig = runtimeConfig;
        _lastError = null;
      });
    } catch (e) {
      setState(() {
        _lastError = e.toString();
      });
    }
  }

  Future<void> _connect() async {
    if (_useTurnMode && _vkLinkCtrl.text.trim().isEmpty) {
      setState(() {
        _lastError = 'VK call link is required.';
      });
      return;
    }
    if (_configCtrl.text.trim().isEmpty) {
      setState(() {
        _lastError = 'WireGuard config is not loaded.';
      });
      return;
    }
    if (_isAndroid) {
      final runtimePerms = await _bridge.requestRuntimePermissions();
      if (!runtimePerms) {
        setState(() {
          _lastError = 'App permissions denied.';
        });
        return;
      }
      final prepared = await _bridge.prepareVpn();
      if (!prepared) {
        setState(() {
          _lastError =
              'VPN permission required. Allow it and tap Connect again.';
        });
        return;
      }
    }
    await _prepareConfig();
    final config = _runtimeConfig;
    if (config == null) return;
    final settings = await _collectSettings();
    try {
      if (_isAndroid) {
        await _bridge.start(
          config,
          useUdp: settings.useUdp,
          threads: settings.threads,
        );
        final newStatus = await _bridge.status();
        setState(() {
          _status = newStatus;
        });
        _startTrafficPolling();
        return;
      }

      await _initCrossPlatformWireGuard();
      if (!_wgInitialized) return;

      final runtimeOk = await _bridge.requestRuntimePermissions();
      if (!runtimeOk) {
        setState(() {
          _lastError = Platform.isWindows
              ? 'Administrator rights are required on Windows. Restart VkPN and accept the UAC prompt (the app requests elevation on launch).'
              : 'Required permissions were not granted.';
        });
        return;
      }
      final preparedVpn = await _bridge.prepareVpn();
      if (!preparedVpn) {
        setState(() {
          _lastError = Platform.isMacOS
              ? 'VPN could not be prepared. Check System Settings → General → VPN & Filters (or Network Extension approval).'
              : 'VPN could not be prepared. Try again.';
        });
        return;
      }

      String wgConfigToUse = config.rawConfig;
      if (_useTurnMode) {
        if (_isDesktop) {
          await _desktopTurnRuntime.start(
            targetHost: config.targetHost,
            proxyPort: config.proxyPort,
            vkCallLink: _vkLinkCtrl.text.trim(),
            useUdp: settings.useUdp,
            threads: settings.threads,
            onLog: _appendLogLine,
          );
          wgConfigToUse = config.rewrittenConfig;
        } else if (_isIOS) {
          setState(() {
            _lastError =
                'WG+TURN on iOS is not yet available in this build. Use WG mode.';
          });
          return;
        } else {
          _appendLogLine(
            'Mode WG+TURN requested; fallback to WG on this platform.',
          );
        }
      }
      await _wireguard.startVpn(
        serverAddress: '${config.targetHost}:${config.targetPort}',
        wgQuickConfig: wgConfigToUse,
        providerBundleIdentifier: (_isIOS || Platform.isMacOS)
            ? _appleProviderBundleId
            : '',
      );
      setState(() {
        _status = 'connected';
        _lastError = null;
      });
    } catch (e) {
      if (_isDesktop) {
        await _desktopTurnRuntime.stop();
      }
      setState(() {
        _lastError = 'Connect failed: $e';
      });
    }
  }

  Future<void> _disconnect() async {
    if (!_isAndroid) {
      try {
        if (_isDesktop) {
          await _desktopTurnRuntime.stop();
        }
        await _wireguard.stopVpn();
        setState(() {
          _status = 'disconnected';
          _rxBytes = 0;
          _txBytes = 0;
        });
      } catch (e) {
        setState(() {
          _lastError = e.toString();
        });
      }
      return;
    }
    try {
      await _bridge.stop();
      final newStatus = await _bridge.status();
      setState(() {
        _status = newStatus;
        _rxBytes = 0;
        _txBytes = 0;
      });
    } catch (e) {
      setState(() {
        _lastError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 14),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xAA163063),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/vkpn_logo.png',
                          width: 46,
                          height: 46,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'VkPN',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          ToggleButtons(
                            isSelected: <bool>[!_useTurnMode, _useTurnMode],
                            borderRadius: BorderRadius.circular(10),
                            constraints: const BoxConstraints(
                              minHeight: 30,
                              minWidth: 68,
                            ),
                            onPressed: (index) async {
                              setState(() {
                                _useTurnMode = index == 1;
                              });
                              await _collectSettings();
                            },
                            children: const <Widget>[
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'WG',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'WG+TURN',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              _status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _statusColor(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _buildFieldTitle('VK call link'),
                const SizedBox(height: 6),
                TextField(
                  controller: _vkLinkCtrl,
                  decoration: const InputDecoration(
                    hintText: 'https://vk.ru/call/join/...',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _buildFieldTitle('Proxy port'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _proxyPortCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '56000',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _buildFieldTitle('Threads'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _threadsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: '8'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Use UDP'),
                  value: _useUdp,
                  onChanged: (v) => setState(() => _useUdp = v),
                ),
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
                          _configCtrl.text.trim().isEmpty
                              ? 'Import .conf'
                              : 'Current conf: ${_configFileName ?? 'inline config'}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_configCtrl.text.trim().isEmpty)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'WG config not loaded',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                if (_lastError != null) ...<Widget>[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _lastError!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF132B57),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _connect,
                        child: const Text('Connect'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF132B57),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _disconnect,
                        child: const Text('Disconnect'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    SizedBox(
                      width: 140,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x40132B57),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          'Received: ${_formatBytes(_rxBytes)}\nSent: ${_formatBytes(_txBytes)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        final sanitizedLogs = _logs
                            .map(sanitizeLogLine)
                            .join('\n');
                        Clipboard.setData(ClipboardData(text: sanitizedLogs));
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Logs copied')),
                        );
                      },
                      child: const Text('COPY'),
                    ),
                    TextButton(
                      onPressed: () => setState(_logs.clear),
                      child: const Text('CLEAR'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.27,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xAA08142B),
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SingleChildScrollView(
                    controller: _logScrollController,
                    child: Text(
                      _logs.join('\n'),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        textAlign: TextAlign.left,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
