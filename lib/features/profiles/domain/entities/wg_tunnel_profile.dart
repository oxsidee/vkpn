import 'dart:convert';

/// One saved WireGuard configuration (multi-profile).
class WgTunnelProfile {
  WgTunnelProfile({
    required this.id,
    required this.name,
    required this.wgConfigText,
    this.wgConfigFileName = '',
  });

  final String id;
  final String name;
  final String wgConfigText;
  final String wgConfigFileName;

  WgTunnelProfile copyWith({
    String? id,
    String? name,
    String? wgConfigText,
    String? wgConfigFileName,
  }) {
    return WgTunnelProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      wgConfigText: wgConfigText ?? this.wgConfigText,
      wgConfigFileName: wgConfigFileName ?? this.wgConfigFileName,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'wgConfigText': wgConfigText,
      'wgConfigFileName': wgConfigFileName,
    };
  }

  static WgTunnelProfile fromJson(Map<String, dynamic> json) {
    return WgTunnelProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Profile',
      wgConfigText: json['wgConfigText']?.toString() ?? '',
      wgConfigFileName: json['wgConfigFileName']?.toString() ?? '',
    );
  }

  static String encodeList(List<WgTunnelProfile> list) {
    return jsonEncode(list.map((e) => e.toJson()).toList());
  }

  static List<WgTunnelProfile> decodeList(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return <WgTunnelProfile>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <WgTunnelProfile>[];
      }
      final out = <WgTunnelProfile>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final p = fromJson(item);
          if (p.id.isNotEmpty) {
            out.add(p);
          }
        } else if (item is Map) {
          final p = fromJson(Map<String, dynamic>.from(item));
          if (p.id.isNotEmpty) {
            out.add(p);
          }
        }
      }
      return out;
    } catch (_) {
      return <WgTunnelProfile>[];
    }
  }
}
