import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class DesktopTurnRuntime {
  Process? _process;
  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;

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
        .listen(onLog);
    _stderrSub = _process!.stderr
        .transform(SystemEncoding().decoder)
        .transform(const LineSplitter())
        .listen((line) => onLog('ERR: $line'));
  }

  Future<void> stop() async {
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
