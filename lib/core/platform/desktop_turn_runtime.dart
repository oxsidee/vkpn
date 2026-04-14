import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// VK API preflight failed before WireGuard was started (Windows ordering).
class TurnVkPreflightException implements Exception {
  TurnVkPreflightException(this.logLine);
  final String logLine;

  @override
  String toString() => 'VK TURN preflight failed: $logLine';
}

class DesktopTurnRuntime {
  DesktopTurnRuntime();

  Process? _process;
  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;

  Completer<void>? _windowsWgPreflightCompleter;

  static bool _looksLikeVkPreflightFailure(String line) {
    final l = line.toLowerCase();
    if (l.contains('getcallpreview') && l.contains('failed')) {
      return true;
    }
    if (l.contains('[vk auth]') &&
        (l.contains('i/o timeout') ||
            l.contains('timeout exceeded') ||
            l.contains('context deadline exceeded'))) {
      return true;
    }
    return false;
  }

  /// vk-turn пишет почти всё в stderr — это не ошибки уровня приложения.
  static bool _looksLikeVkPreflightSuccess(String line) {
    final l = line.toLowerCase();
    if (l.contains('established dtls connection')) {
      return true;
    }
    if (l.contains('[vk auth]') && l.contains('success with client_id')) {
      return true;
    }
    if (l.contains('getcallpreview') || l.contains('callpreview')) {
      if (l.contains('failed') || l.contains('warning')) {
        return false;
      }
      return true;
    }
    return false;
  }

  Future<void> start({
    required String targetHost,
    required int proxyPort,
    required String vkCallLink,
    required bool useUdp,
    required int threads,
    required String listenHost,
    required int listenPort,
    required void Function(String) onLog,
  }) async {
    await stop();
    if (Platform.isWindows) {
      _windowsWgPreflightCompleter = Completer<void>();
    }
    final binaryPath = await _materializeBinary();
    final listen = '$listenHost:$listenPort';
    final args = <String>[
      '-peer',
      '$targetHost:$proxyPort',
      '-vk-link',
      vkCallLink,
      '-listen',
      listen,
      '-n',
      threads.toString(),
      if (useUdp) '-udp',
    ];
    onLog(
      'Desktop TURN cmd: $binaryPath -peer $targetHost:$proxyPort -vk-link [REDACTED] '
      '-listen $listen -n $threads${useUdp ? ' -udp' : ''}',
    );
    _process = await Process.start(binaryPath, args);
    _stdoutSub = _process!.stdout
        .transform(SystemEncoding().decoder)
        .transform(const LineSplitter())
        .listen((line) => _onTurnLine(line, onLog));
    _stderrSub = _process!.stderr
        .transform(SystemEncoding().decoder)
        .transform(const LineSplitter())
        .listen((line) => _onTurnLine(line, onLog));
  }

  void _onTurnLine(String line, void Function(String) onLog) {
    // Go-клиент пишет в stderr и при успехе; не префиксуем ERR.
    onLog(line);
    final c = _windowsWgPreflightCompleter;
    if (!Platform.isWindows || c == null || c.isCompleted) {
      return;
    }
    if (_looksLikeVkPreflightFailure(line)) {
      c.completeError(TurnVkPreflightException(line));
      return;
    }
    if (_looksLikeVkPreflightSuccess(line)) {
      c.complete();
    }
  }

  /// Windows WG+TURN: start WireGuard only after vk-turn can talk to VK (no tunnel yet).
  Future<void> waitForWindowsPreflightBeforeWireGuard({
    required String listenHost,
    required int listenPort,
    required void Function(String) onLog,
    Duration listenTimeout = const Duration(seconds: 90),
    Duration logGrace = const Duration(seconds: 90),
  }) async {
    if (!Platform.isWindows) {
      return;
    }
    final c = _windowsWgPreflightCompleter;
    if (c == null) {
      return;
    }
    onLog('WGT: Waiting for TURN listen $listenHost:$listenPort (VK preflight before WG)...');
    await _waitUntilListenAccepts(
      listenHost,
      listenPort,
      timeout: listenTimeout,
    );
    if (c.isCompleted) {
      await c.future;
      onLog('WGT: VK preflight: ready (log signal).');
      return;
    }
    try {
      await c.future.timeout(logGrace);
      onLog('WGT: VK preflight: ready (log signal).');
    } on TimeoutException {
      if (_process == null) {
        throw StateError('Desktop TURN exited before VK preflight finished');
      }
      onLog(
        'WGT: VK preflight: no explicit success in log after ${logGrace.inSeconds}s; '
        'starting WG anyway (if calls fail, check link or network).',
      );
      if (!c.isCompleted) {
        c.complete();
      }
    }
  }

  Future<void> _waitUntilListenAccepts(
    String host,
    int port, {
    required Duration timeout,
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final c = _windowsWgPreflightCompleter;
      if (c != null && c.isCompleted) {
        await c.future;
        return;
      }
      if (_process == null) {
        throw StateError('Desktop TURN process not running');
      }
      try {
        final s = await Socket.connect(host, port, timeout: const Duration(seconds: 1));
        s.destroy();
        return;
      } on Object {
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
    }
    throw TimeoutException('TURN did not open $host:$port', timeout);
  }

  Future<void> stop() async {
    final c = _windowsWgPreflightCompleter;
    _windowsWgPreflightCompleter = null;
    if (c != null && !c.isCompleted) {
      c.completeError(StateError('Desktop TURN stopped'));
    }
    await _stdoutSub?.cancel();
    await _stderrSub?.cancel();
    _stdoutSub = null;
    _stderrSub = null;
    _process?.kill(ProcessSignal.sigterm);
    _process = null;
  }

  Future<String> _materializeBinary() async {
    final dir = await getApplicationSupportDirectory();
    final isWindows = Platform.isWindows;
    final asset = isWindows ? 'assets/bin/client-windows-amd64.exe' : 'assets/bin/client-darwin-arm64';
    final out = File(
      '${dir.path}${Platform.pathSeparator}${isWindows ? 'client-windows-amd64.exe' : 'client-darwin-arm64'}',
    );
    final ByteData data = await rootBundle.load(asset);
    await out.writeAsBytes(data.buffer.asUint8List(), flush: true);
    if (!isWindows) {
      await Process.run('chmod', <String>['700', out.path]);
    }
    return out.path;
  }
}
