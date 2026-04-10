import '../entities/wg_tunnel_profile.dart';

/// Writes the in-editor WG text into the active profile row (immutable copy).
class SyncActiveProfileConfigUseCase {
  List<WgTunnelProfile> call({
    required List<WgTunnelProfile> profiles,
    required String? activeProfileId,
    required String wgConfigText,
    required String wgConfigFileName,
  }) {
    final id = activeProfileId;
    if (id == null) {
      return List<WgTunnelProfile>.from(profiles);
    }
    final i = profiles.indexWhere((WgTunnelProfile p) => p.id == id);
    if (i < 0) {
      return List<WgTunnelProfile>.from(profiles);
    }
    final next = List<WgTunnelProfile>.from(profiles);
    next[i] = next[i].copyWith(
      wgConfigText: wgConfigText,
      wgConfigFileName: wgConfigFileName,
    );
    return next;
  }
}
