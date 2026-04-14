import '../domain/entities/wg_config.dart';
import '../domain/entities/wgt_tunnel_extensions.dart';

class WgConfigParser {
  WgConfig parse(String input) {
    final sections = _splitSections(input);
    final interfaceData = sections['Interface'];
    final peerData = sections['Peer'];
    if (interfaceData == null) {
      throw const FormatException('Missing [Interface] section');
    }
    if (peerData == null) {
      throw const FormatException('Missing [Peer] section');
    }

    final privateKey = interfaceData['PrivateKey']?.trim();
    final addressRaw = interfaceData['Address']?.trim();
    if (privateKey == null || privateKey.isEmpty) {
      throw const FormatException('Interface.PrivateKey is required');
    }
    if (addressRaw == null || addressRaw.isEmpty) {
      throw const FormatException('Interface.Address is required');
    }

    final dnsRaw = interfaceData['DNS'] ?? '';
    final mtuRaw = interfaceData['MTU'];
    final iface = WgInterface(
      privateKey: privateKey,
      addresses: _splitCsv(addressRaw),
      dns: _splitCsv(dnsRaw),
      mtu: mtuRaw == null || mtuRaw.trim().isEmpty ? null : int.tryParse(mtuRaw),
    );

    final publicKey = peerData['PublicKey']?.trim();
    final allowedIpsRaw = peerData['AllowedIPs']?.trim();
    final endpointRaw = peerData['Endpoint']?.trim();
    if (publicKey == null || publicKey.isEmpty) {
      throw const FormatException('Peer.PublicKey is required');
    }
    if (allowedIpsRaw == null || allowedIpsRaw.isEmpty) {
      throw const FormatException('Peer.AllowedIPs is required');
    }
    if (endpointRaw == null || endpointRaw.isEmpty) {
      throw const FormatException('Peer.Endpoint is required');
    }
    final endpoint = _parseEndpoint(endpointRaw);
    final keepaliveRaw = peerData['PersistentKeepalive'];
    final peer = WgPeer(
      publicKey: publicKey,
      allowedIps: _splitCsv(allowedIpsRaw),
      endpointHost: endpoint.$1,
      endpointPort: endpoint.$2,
      persistentKeepalive: keepaliveRaw == null || keepaliveRaw.trim().isEmpty
          ? null
          : int.tryParse(keepaliveRaw),
    );

    return WgConfig(interface: iface, peer: peer);
  }

  /// Parses `#@wgt:Key = Value` lines anywhere in the file (WireGuard ignores `#` comments).
  WgtTunnelExtensions parseWgtExtensions(String input) {
    final raw = <String, String>{};
    final lineRe = RegExp(
      r'^\s*#\s*@wgt:\s*([^=]+?)\s*=\s*(.*?)\s*$',
      caseSensitive: false,
    );
    for (final rawLine in input.split('\n')) {
      final m = lineRe.firstMatch(rawLine);
      if (m == null) {
        continue;
      }
      var key = m.group(1)!.trim();
      var value = m.group(2)!.trim();
      final hashIdx = value.indexOf('#');
      if (hashIdx >= 0) {
        value = value.substring(0, hashIdx).trim();
      }
      if (key.isEmpty) {
        continue;
      }
      key = _canonicalWgtKey(key);
      raw[key] = value;
    }
    return _wgtFromRaw(raw);
  }

  WgtTunnelExtensions _wgtFromRaw(Map<String, String> raw) {
    bool? enableTurn;
    bool? useUdp;
    String? ipHost;
    int? ipPort;
    String? vkLink;
    String? mode;
    String? peerType;
    int? streamNum;
    int? localPort;
    int? streamsPerCred;
    String? turnIp;
    int? turnPort;
    int? watchdogTimeout;
    final extras = <String, String>{};

    for (final e in raw.entries) {
      final k = e.key;
      final v = e.value;
      if (k == 'enableturn') {
        enableTurn = _parseBool(v);
      } else if (k == 'useudp') {
        useUdp = _parseBool(v);
      } else if (k == 'ipport') {
        final ep = _tryParseHostPort(v);
        if (ep != null) {
          ipHost = ep.$1;
          ipPort = ep.$2;
        }
      } else if (k == 'vklink') {
        vkLink = v.isEmpty ? null : v;
      } else if (k == 'mode') {
        mode = v.isEmpty ? null : v.toLowerCase();
      } else if (k == 'peertype') {
        peerType = v.isEmpty ? null : v.toLowerCase();
      } else if (k == 'streamnum') {
        streamNum = int.tryParse(v);
      } else if (k == 'localport') {
        localPort = int.tryParse(v);
      } else if (k == 'streamspercred') {
        streamsPerCred = int.tryParse(v);
      } else if (k == 'turnip') {
        turnIp = v.isEmpty ? null : v;
      } else if (k == 'turnport') {
        turnPort = int.tryParse(v);
      } else if (k == 'watchdogtimeout') {
        watchdogTimeout = int.tryParse(v);
      } else {
        extras[k] = v;
      }
    }

    return WgtTunnelExtensions(
      enableTurn: enableTurn,
      useUdp: useUdp,
      ipPortHost: ipHost,
      ipPortPort: ipPort,
      vkLink: vkLink,
      mode: mode,
      peerType: peerType,
      streamNum: streamNum,
      localPort: localPort,
      streamsPerCred: streamsPerCred,
      turnIp: turnIp,
      turnPort: turnPort,
      watchdogTimeout: watchdogTimeout,
      extras: extras,
    );
  }

  String _canonicalWgtKey(String key) {
    return key.trim().replaceAll(RegExp(r'\s+'), '').toLowerCase();
  }

  bool? _parseBool(String v) {
    final s = v.trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes') {
      return true;
    }
    if (s == 'false' || s == '0' || s == 'no') {
      return false;
    }
    return null;
  }

  (String, int)? _tryParseHostPort(String v) {
    final t = v.trim();
    if (t.isEmpty) {
      return null;
    }
    final idx = t.lastIndexOf(':');
    if (idx <= 0 || idx == t.length - 1) {
      return null;
    }
    final host = t.substring(0, idx).trim();
    final port = int.tryParse(t.substring(idx + 1).trim());
    if (host.isEmpty || port == null || port <= 0) {
      return null;
    }
    return (host, port);
  }

  /// Merges Android-only [Interface].ExcludedApplications (WireGuard Android / wg-quick).
  /// Package names are comma-separated; duplicates are removed.
  String mergeExcludedApplications(String configText, Iterable<String> packageNames) {
    final packages = packageNames
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (packages.isEmpty) {
      return configText;
    }
    final lines = configText.split('\n').toList();
    var inInterface = false;
    var interfaceStart = -1;
    var excludedLineIndex = -1;

    for (var i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trim();
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        inInterface = trimmed.toLowerCase() == '[interface]';
        if (inInterface) {
          interfaceStart = i;
        }
        continue;
      }
      if (!inInterface) {
        continue;
      }
      if (trimmed.toLowerCase().startsWith('excludedapplications') && trimmed.contains('=')) {
        excludedLineIndex = i;
        break;
      }
    }

    final merged = <String>{};
    if (excludedLineIndex >= 0) {
      final current = lines[excludedLineIndex];
      final idx = current.indexOf('=');
      final existing = idx >= 0 ? current.substring(idx + 1) : '';
      for (final p in existing.split(',')) {
        final t = p.trim();
        if (t.isNotEmpty) {
          merged.add(t);
        }
      }
    }
    merged.addAll(packages);
    final line = 'ExcludedApplications = ${merged.join(', ')}';

    if (excludedLineIndex >= 0) {
      lines[excludedLineIndex] = line;
    } else if (interfaceStart >= 0) {
      var insertAt = interfaceStart + 1;
      while (insertAt < lines.length) {
        final t = lines[insertAt].trim();
        if (t.startsWith('[') && t.endsWith(']')) {
          break;
        }
        insertAt++;
      }
      lines.insert(insertAt, line);
    } else {
      return configText;
    }
    return lines.join('\n');
  }

  String rewriteEndpoint(String input, {required String host, required int port}) {
    final lines = input.split('\n');
    final rewritten = <String>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('Endpoint') && trimmed.contains('=')) {
        final rawValue = trimmed.split('=').last.trim();
        _parseEndpoint(rawValue);
        rewritten.add('Endpoint = $host:$port');
      } else {
        rewritten.add(line);
      }
    }
    return rewritten.join('\n');
  }

  Map<String, Map<String, String>> _splitSections(String input) {
    final sections = <String, Map<String, String>>{};
    String? currentSection;
    for (final rawLine in input.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#') || line.startsWith(';')) {
        continue;
      }
      if (line.startsWith('[') && line.endsWith(']')) {
        currentSection = line.substring(1, line.length - 1).trim();
        sections[currentSection] = <String, String>{};
        continue;
      }
      if (currentSection == null || !line.contains('=')) {
        continue;
      }
      final idx = line.indexOf('=');
      final key = line.substring(0, idx).trim();
      final value = line.substring(idx + 1).trim();
      sections[currentSection]![key] = value;
    }
    return sections;
  }

  List<String> _splitCsv(String input) {
    return input
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  (String, int) _parseEndpoint(String endpoint) {
    final idx = endpoint.lastIndexOf(':');
    if (idx <= 0 || idx == endpoint.length - 1) {
      throw FormatException('Invalid endpoint: $endpoint');
    }
    final host = endpoint.substring(0, idx).trim();
    final port = int.tryParse(endpoint.substring(idx + 1).trim());
    if (host.isEmpty || port == null) {
      throw FormatException('Invalid endpoint: $endpoint');
    }
    return (host, port);
  }

  /// On Windows, a single peer with `AllowedIPs` containing `0.0.0.0/0` or `::/0`
  /// enables wireguard-windows "kill-switch" firewall rules: DNS to port 53 is
  /// allowed only toward [Interface].DNS. Missing or broken DNS then breaks all
  /// name resolution ("no internet"). Replacing `/0` with two `/1` halves matches
  /// official wireguard-windows guidance and preserves full-tunnel routing.
  String applyWindowsDefaultRouteAllowedIpsFix(String input) {
    final lines = input.split('\n');
    var inPeer = false;
    final out = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        final name = trimmed.substring(1, trimmed.length - 1).trim().toLowerCase();
        inPeer = name == 'peer';
        out.add(line);
        continue;
      }
      if (trimmed.isEmpty || trimmed.startsWith('#') || trimmed.startsWith(';')) {
        out.add(line);
        continue;
      }
      if (inPeer && trimmed.contains('=')) {
        final idx = line.indexOf('=');
        final key = line.substring(0, idx).trim().toLowerCase();
        if (key == 'allowedips') {
          final value = line.substring(idx + 1);
          final newValue = _splitCsv(value)
              .expand<String>((e) {
                if (e == '0.0.0.0/0') {
                  return <String>['0.0.0.0/1', '128.0.0.0/1'];
                }
                if (e == '::/0') {
                  return <String>['::/1', '8000::/1'];
                }
                return <String>[e];
              })
              .join(', ');
          final keyRaw = line.substring(0, idx).trimRight();
          out.add('$keyRaw= $newValue');
          continue;
        }
      }
      out.add(line);
    }
    return out.join('\n');
  }

  /// IPv4-only entries from [Interface].DNS (search domains ignored).
  List<String> parseInterfaceDnsIpv4Addresses(String input) {
    final sections = _splitSections(input);
    final iface = sections['Interface'];
    if (iface == null) {
      return <String>[];
    }
    final dnsRaw = iface['DNS'];
    if (dnsRaw == null || dnsRaw.trim().isEmpty) {
      return <String>[];
    }
    final out = <String>[];
    for (final e in _splitCsv(dnsRaw)) {
      final t = e.trim();
      if (_isBareIpv4DottedDecimal(t)) {
        out.add(t);
      }
    }
    return out;
  }

  bool _isBareIpv4DottedDecimal(String t) {
    final parts = t.split('.');
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
}
