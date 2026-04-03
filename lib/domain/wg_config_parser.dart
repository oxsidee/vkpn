import 'wg_config.dart';

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
}
