import '../entities/wg_tunnel_profile.dart';
import 'sync_active_profile_config_usecase.dart';

class DeleteActiveProfileResult {
  const DeleteActiveProfileResult({
    required this.profiles,
    required this.activeProfileId,
    required this.wgConfigText,
    required this.wgConfigFileName,
  });

  final List<WgTunnelProfile> profiles;
  final String activeProfileId;
  final String wgConfigText;
  final String? wgConfigFileName;
}

class DeleteActiveProfileUseCase {
  DeleteActiveProfileUseCase({SyncActiveProfileConfigUseCase? sync})
    : _sync = sync ?? SyncActiveProfileConfigUseCase();

  final SyncActiveProfileConfigUseCase _sync;

  /// Returns `null` if fewer than two profiles or no active id.
  DeleteActiveProfileResult? call({
    required List<WgTunnelProfile> profiles,
    required String? activeProfileId,
    required String currentWgConfigText,
    required String? currentWgConfigFileName,
  }) {
    if (profiles.length <= 1) {
      return null;
    }
    final id = activeProfileId;
    if (id == null) {
      return null;
    }
    final fileName = currentWgConfigFileName ?? '';
    final synced = _sync(
      profiles: profiles,
      activeProfileId: id,
      wgConfigText: currentWgConfigText,
      wgConfigFileName: fileName,
    );
    final remaining = synced.where((WgTunnelProfile p) => p.id != id).toList();
    final first = remaining.first;
    return DeleteActiveProfileResult(
      profiles: remaining,
      activeProfileId: first.id,
      wgConfigText: first.wgConfigText,
      wgConfigFileName:
          first.wgConfigFileName.isEmpty ? null : first.wgConfigFileName,
    );
  }
}
