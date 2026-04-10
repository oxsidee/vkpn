import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../domain/entities/installed_app.dart';

/// Loads installed applications per OS. Android/macOS/iOS use [MethodChannel];
/// Linux parses .desktop files; Windows uses PowerShell + Uninstall registry.
class InstalledAppsLoader {
  static const MethodChannel _channel = MethodChannel('unified_vpn/methods');

  static Future<List<InstalledApp>> load() async {
    if (Platform.isLinux) {
      return _loadLinuxDesktopFiles();
    }
    if (Platform.isWindows) {
      return _loadWindowsViaPowerShell();
    }
    try {
      final dynamic raw = await _channel.invokeMethod<dynamic>('listInstalledApps');
      return _parseList(raw);
    } on MissingPluginException {
      return [];
    } catch (_) {
      return [];
    }
  }

  static List<InstalledApp> _parseList(dynamic raw) {
    if (raw is! List) {
      return [];
    }
    final out = <InstalledApp>[];
    for (final item in raw) {
      if (item is! Map) {
        continue;
      }
      final id = item['id']?.toString() ?? '';
      final label = item['label']?.toString() ?? id;
      if (id.isEmpty) {
        continue;
      }
      out.add(InstalledApp(id: id, label: label));
    }
    return out;
  }

  static Future<List<InstalledApp>> _loadLinuxDesktopFiles() async {
    final home = Platform.environment['HOME'] ?? '';
    final dirs = <String>[
      '/usr/share/applications',
      '/usr/local/share/applications',
      if (home.isNotEmpty) '$home/.local/share/applications',
    ];
    final map = <String, InstalledApp>{};
    for (final dirPath in dirs) {
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        continue;
      }
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File || !entity.path.endsWith('.desktop')) {
          continue;
        }
        final parsed = await _parseDesktopFile(entity);
        if (parsed == null) {
          continue;
        }
        map.putIfAbsent(parsed.id, () => parsed);
      }
    }
    final list = map.values.toList()
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return list;
  }

  static Future<InstalledApp?> _parseDesktopFile(File file) async {
    String? name;
    var noDisplay = false;
    var hidden = false;
    try {
      final lines = await file.readAsLines();
      var inDesktopEntry = false;
      for (final raw in lines) {
        final line = raw.trim();
        if (line.startsWith('[')) {
          inDesktopEntry = line == '[Desktop Entry]';
          continue;
        }
        if (!inDesktopEntry) {
          continue;
        }
        if (line.startsWith('Name=') && !line.startsWith('Name[')) {
          name = line.substring(5).trim();
        } else if (line == 'NoDisplay=true') {
          noDisplay = true;
        } else if (line == 'Hidden=true') {
          hidden = true;
        }
      }
    } catch (_) {
      return null;
    }
    if (noDisplay || hidden || name == null || name.isEmpty) {
      return null;
    }
    final base = file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : file.path;
    final id = base.endsWith('.desktop') ? base.substring(0, base.length - 8) : base;
    return InstalledApp(id: id, label: name);
  }

  static Future<List<InstalledApp>> _loadWindowsViaPowerShell() async {
    const script = r'''
$ErrorActionPreference = 'SilentlyContinue'
$items = [System.Collections.Generic.List[object]]::new()
foreach ($pattern in @(
  'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
  'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
)) {
  Get-ItemProperty $pattern -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName } | ForEach-Object {
    $id = $_.PSChildName
    if ([string]::IsNullOrWhiteSpace($id)) { $id = [guid]::NewGuid().ToString() }
    $items.Add([PSCustomObject]@{ id = $id; label = $_.DisplayName })
  }
}
if ($items.Count -eq 0) { '[]' } else { $items | ConvertTo-Json -Compress -Depth 3 }
''';
    try {
      final r = await Process.run(
        'powershell.exe',
        <String>['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', script],
        runInShell: false,
      );
      if (r.exitCode != 0) {
        return [];
      }
      final stdout = r.stdout.toString().trim();
      if (stdout.isEmpty) {
        return [];
      }
      final decoded = jsonDecode(stdout);
      if (decoded is Map) {
        return _parseList(<dynamic>[decoded]);
      }
      if (decoded is! List) {
        return [];
      }
      final out = <InstalledApp>[];
      final seen = <String>{};
      for (final item in decoded) {
        if (item is! Map) {
          continue;
        }
        final id = item['id']?.toString() ?? '';
        final label = item['label']?.toString() ?? '';
        if (id.isEmpty || label.isEmpty) {
          continue;
        }
        if (seen.add(id)) {
          out.add(InstalledApp(id: id, label: label));
        }
      }
      out.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
      return out;
    } catch (_) {
      return [];
    }
  }
}
