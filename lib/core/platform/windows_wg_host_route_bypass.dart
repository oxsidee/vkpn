import 'dart:io';

/// Host routes so IPv4 traffic to listed destinations uses the physical default
/// gateway instead of the WireGuard tunnel (same idea as TURN upstream bypass).
///
/// True per-app exclusion like on Android is not available on wireguard-windows
/// without a driver; bypassing by **destination** is what we can do here.
class WindowsWgHostRouteBypass {
  WindowsWgHostRouteBypass();

  /// Shared session state for TURN upstream + user "excluded" host routes.
  static final WindowsWgHostRouteBypass shared = WindowsWgHostRouteBypass();

  /// Typical resolvers so DNS from the tunnel IP reaches the internet without looping in WG+TURN.
  static const List<String> commonPublicDnsIpv4 = <String>[
    '8.8.8.8',
    '8.8.4.4',
    '1.1.1.1',
    '1.0.0.1',
    '9.9.9.9',
    '77.88.8.8',
    '77.88.8.1',
    '208.67.222.222',
    '208.67.220.220',
  ];

  String? _gatewayIpv4;

  /// Physical NIC index for `route ... IF <n>` so Windows does not send bypass traffic via WireGuard.
  int? _physicalIfIndex;

  final Set<String> _addedIpv4s = <String>{};

  /// RFC1918 /24 networks we added (e.g. 192.168.0.0) for `route DELETE`.
  final List<String> _lanSlash24Networks = <String>[];

  bool get hasGateway => _gatewayIpv4 != null && _gatewayIpv4!.isNotEmpty;

  String? get capturedGatewayIpv4 => _gatewayIpv4;

  Future<void> ensureGatewayCaptured(void Function(String) onLog) async {
    if (!Platform.isWindows) {
      return;
    }
    if (hasGateway) {
      return;
    }
    final snap = await readWindowsPhysicalIpv4DefaultRoute(onLog);
    if (snap == null) {
      return;
    }
    _gatewayIpv4 = snap.gateway;
    _physicalIfIndex = snap.interfaceIndex;
    final g = snap.gateway;
    final idx = snap.interfaceIndex;
    if (idx != null && idx > 0) {
      onLog('WGT: Windows bypass: physical default route via $g (IF $idx)');
    } else {
      onLog('WGT: Windows bypass: physical default gateway $g (no IF index)');
    }
  }

  /// Adds /32 routes for each IPv4 address (deduped). Call [ensureGatewayCaptured] first.
  Future<void> addRoutesForIpv4s(
    Iterable<String> ipv4s,
    void Function(String) onLog, {
    String logPrefix = 'WGT: Windows bypass',
  }) async {
    if (!Platform.isWindows) {
      return;
    }
    final gw = _gatewayIpv4;
    if (gw == null || gw.isEmpty) {
      onLog('$logPrefix: no gateway; cannot add host routes.');
      return;
    }
    for (final ip in ipv4s) {
      if (!_looksLikeIpv4(ip) || _addedIpv4s.contains(ip)) {
        continue;
      }
      final ok = await _routeAddHost32(ip, gw, onLog, logPrefix);
      if (ok) {
        _addedIpv4s.add(ip);
      }
    }
  }

  Future<bool> _routeAddHost32(
    String ip,
    String gw,
    void Function(String) onLog,
    String logPrefix,
  ) async {
    final withIf = _routeAddIpv4Args(
      destination: ip,
      mask: '255.255.255.255',
      gateway: gw,
      useIf: true,
    );
    var r = await Process.run('route', withIf, runInShell: false);
    if (r.exitCode != 0 && _physicalIfIndex != null && _physicalIfIndex! > 0) {
      final withoutIf = _routeAddIpv4Args(
        destination: ip,
        mask: '255.255.255.255',
        gateway: gw,
        useIf: false,
      );
      r = await Process.run('route', withoutIf, runInShell: false);
      if (r.exitCode == 0) {
        onLog('$logPrefix: host route $ip -> $gw (retry without IF)');
        return true;
      }
    }
    if (r.exitCode != 0) {
      onLog(
        '$logPrefix: route ADD $ip -> $gw failed: '
        '${r.stderr.toString().trim().isNotEmpty ? r.stderr : r.stdout}',
      );
      return false;
    }
    final idx = _physicalIfIndex;
    final ifNote = (idx != null && idx > 0) ? ' IF $idx' : '';
    onLog('$logPrefix: host route $ip -> $gw$ifNote');
    return true;
  }

  List<String> _routeAddIpv4Args({
    required String destination,
    required String mask,
    required String gateway,
    required bool useIf,
  }) {
    final args = <String>[
      'ADD',
      destination,
      'MASK',
      mask,
      gateway,
      'METRIC',
      '1',
    ];
    final ifIdx = _physicalIfIndex;
    if (useIf && ifIdx != null && ifIdx > 0) {
      args.addAll(<String>['IF', '$ifIdx']);
    }
    return args;
  }

  /// After WG+TURN: default routes 0.0.0.0/1 send even LAN/DNS via tunnel; vk-turn must reach
  /// the router and public DNS from the physical NIC.
  Future<void> addLanSlash24BypassForGateway(void Function(String) onLog) async {
    if (!Platform.isWindows) {
      return;
    }
    final gw = _gatewayIpv4;
    if (gw == null || gw.isEmpty) {
      return;
    }
    final net = _rfc1918Slash24Network(gw);
    if (net == null) {
      return;
    }
    if (_lanSlash24Networks.contains(net)) {
      return;
    }
    final withIf = _routeAddIpv4Args(
      destination: net,
      mask: '255.255.255.0',
      gateway: gw,
      useIf: true,
    );
    var r = await Process.run('route', withIf, runInShell: false);
    if (r.exitCode != 0 && _physicalIfIndex != null && _physicalIfIndex! > 0) {
      r = await Process.run(
        'route',
        _routeAddIpv4Args(
          destination: net,
          mask: '255.255.255.0',
          gateway: gw,
          useIf: false,
        ),
        runInShell: false,
      );
    }
    if (r.exitCode != 0) {
      onLog(
        'WGT: Windows LAN bypass: route ADD $net/24 -> $gw failed: '
        '${r.stderr.toString().trim().isNotEmpty ? r.stderr : r.stdout}',
      );
      return;
    }
    _lanSlash24Networks.add(net);
    final idx = _physicalIfIndex;
    final ifNote = (idx != null && idx > 0) ? ' IF $idx' : '';
    onLog('WGT: Windows LAN bypass: $net/24 -> $gw$ifNote');
  }

  /// Adds /32 routes for [extraFromWgConfig] plus [commonPublicDnsIpv4].
  Future<void> addPublicDnsBypassRoutes(
    List<String> extraFromWgConfig,
    void Function(String) onLog,
  ) async {
    final merged = <String>{...commonPublicDnsIpv4, ...extraFromWgConfig};
    await addRoutesForIpv4s(
      merged,
      onLog,
      logPrefix: 'WGT: Windows DNS bypass',
    );
  }

  static String? _rfc1918Slash24Network(String gatewayIpv4) {
    final parts = gatewayIpv4.split('.');
    if (parts.length != 4) {
      return null;
    }
    final a = int.tryParse(parts[0]);
    final b = int.tryParse(parts[1]);
    final c = int.tryParse(parts[2]);
    if (a == null || b == null || c == null) {
      return null;
    }
    if (a == 10) {
      return '$a.$b.$c.0';
    }
    if (a == 172 && b >= 16 && b <= 31) {
      return '$a.$b.$c.0';
    }
    if (a == 192 && b == 168) {
      return '$a.$b.$c.0';
    }
    return null;
  }

  Future<void> clear({void Function(String)? onLog}) async {
    if (!Platform.isWindows) {
      return;
    }
    for (final net in List<String>.from(_lanSlash24Networks)) {
      await _routeDelete(net, '255.255.255.0', onLog);
    }
    _lanSlash24Networks.clear();
    for (final ip in List<String>.from(_addedIpv4s)) {
      await _routeDelete(ip, '255.255.255.255', onLog);
    }
    _addedIpv4s.clear();
    _gatewayIpv4 = null;
    _physicalIfIndex = null;
  }

  Future<void> _routeDelete(
    String destination,
    String mask,
    void Function(String)? onLog,
  ) async {
    final withIf = <String>['DELETE', destination, 'MASK', mask];
    final ifIdx = _physicalIfIndex;
    if (ifIdx != null && ifIdx > 0) {
      withIf.addAll(<String>['IF', '$ifIdx']);
    }
    var r = await Process.run('route', withIf, runInShell: false);
    if (r.exitCode != 0 &&
        _physicalIfIndex != null &&
        _physicalIfIndex! > 0) {
      r = await Process.run(
        'route',
        <String>['DELETE', destination, 'MASK', mask],
        runInShell: false,
      );
    }
    if (r.exitCode != 0 && onLog != null) {
      onLog(
        'WGT: Windows bypass: route DELETE $destination/$mask: '
        '${r.stderr.toString().trim().isNotEmpty ? r.stderr : r.stdout}',
      );
    }
  }

  /// Next hop + interface index of the current IPv4 default route on a non-WireGuard adapter.
  static Future<({String gateway, int? interfaceIndex})?> readWindowsPhysicalIpv4DefaultRoute(
    void Function(String) onLog,
  ) async {
    const script = r'''
$routes = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -AddressFamily IPv4 -ErrorAction SilentlyContinue |
  Where-Object { $_.NextHop -and $_.NextHop -ne '0.0.0.0' -and $_.InterfaceAlias -notmatch 'WireGuard' } |
  Sort-Object { $_.RouteMetric }
if (-not $routes) {
  $routes = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.NextHop -and $_.NextHop -ne '0.0.0.0' } |
    Sort-Object { $_.RouteMetric }
}
if ($routes) {
  $x = $routes | Select-Object -First 1
  "$($x.NextHop)|$($x.InterfaceIndex)"
} else { '' }
''';
    final r = await Process.run(
      'powershell',
      <String>['-NoProfile', '-NonInteractive', '-Command', script],
      runInShell: false,
    );
    final out = r.stdout.toString().trim();
    if (r.exitCode != 0 || out.isEmpty) {
      onLog(
        'WGT: Windows bypass: could not read default IPv4 gateway '
        '(exit=${r.exitCode}).',
      );
      return null;
    }
    final pipe = out.lastIndexOf('|');
    if (pipe < 0) {
      if (!_looksLikeIpv4(out)) {
        onLog('WGT: Windows bypass: unexpected gateway value "$out".');
        return null;
      }
      return (gateway: out, interfaceIndex: null);
    }
    final gw = out.substring(0, pipe).trim();
    final idxRaw = out.substring(pipe + 1).trim();
    if (!_looksLikeIpv4(gw)) {
      onLog('WGT: Windows bypass: unexpected gateway value "$gw".');
      return null;
    }
    final idx = int.tryParse(idxRaw);
    return (gateway: gw, interfaceIndex: (idx != null && idx > 0) ? idx : null);
  }

  static bool _looksLikeIpv4(String s) {
    final parts = s.split('.');
    if (parts.length != 4) {
      return false;
    }
    for (final p in parts) {
      final n = int.tryParse(p);
      if (n == null || n < 0 || n > 255) {
        return false;
      }
    }
    return true;
  }

  static Future<List<String>> resolveIpv4Addresses(String host) async {
    final parsed = InternetAddress.tryParse(host);
    if (parsed != null) {
      if (parsed.type == InternetAddressType.IPv4) {
        return <String>[host];
      }
      return <String>[];
    }
    try {
      final addrs = await InternetAddress.lookup(host);
      return addrs
          .where((a) => a.type == InternetAddressType.IPv4)
          .map((a) => a.address)
          .toSet()
          .toList();
    } on SocketException {
      return <String>[];
    }
  }
}

/// Picks tokens from the shared "excluded apps" field that are usable on Windows
/// as **hostnames or IPv4** for route bypass. Skips Android-style package ids, paths, .exe.
List<String> parseWindowsExcludedRouteTokens(String raw) {
  final out = <String>[];
  for (final part in raw.split(RegExp(r'[,\n]'))) {
    final t = part.trim();
    if (t.isEmpty) {
      continue;
    }
    if (t.contains('\\') || t.toLowerCase().endsWith('.exe')) {
      continue;
    }
    if (_looksLikeAndroidPackageId(t)) {
      continue;
    }
    out.add(t);
  }
  return out;
}

bool _looksLikeAndroidPackageId(String s) {
  if (s.contains('-')) {
    return false;
  }
  final lower = s.toLowerCase();
  if (!RegExp(r'^[a-z][a-z0-9_]*(\.[a-z0-9_]+)+$').hasMatch(lower)) {
    return false;
  }
  const roots = <String>{
    'com',
    'org',
    'net',
    'io',
    'in',
    'edu',
    'gov',
    'space',
    'app',
    'dev',
    'tv',
    'me',
  };
  final first = lower.split('.').first;
  return roots.contains(first);
}
