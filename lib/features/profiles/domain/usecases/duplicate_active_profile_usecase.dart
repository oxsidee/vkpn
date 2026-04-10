import '../entities/wg_tunnel_profile.dart';
import 'sync_active_profile_config_usecase.dart';

class DuplicateActiveProfileResult {
  const DuplicateActiveProfileResult({
    required this.profiles,
    required this.activeProfileId,
  });

  final List<WgTunnelProfile> profiles;
  final String activeProfileId;
}

class DuplicateActiveProfileUseCase {
  DuplicateActiveProfileUseCase({SyncActiveProfileConfigUseCase? sync})
    : _sync = sync ?? SyncActiveProfileConfigUseCase();

  final SyncActiveProfileConfigUseCase _sync;

  /// Returns `null` if there is no active profile.
  DuplicateActiveProfileResult? call({
    required List<WgTunnelProfile> profiles,
    required String? activeProfileId,
    required String currentWgConfigText,
    required String? currentWgConfigFileName,
    required String newProfileId,
  }) {
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
    final i = synced.indexWhere((WgTunnelProfile e) => e.id == id);
    if (i < 0) {
      return null;
    }
    final p = synced[i];
    return DuplicateActiveProfileResult(
      profiles: <WgTunnelProfile>[
        ...synced,
        WgTunnelProfile(
          id: newProfileId,
          name: '${p.name} (copy)',
          wgConfigText: p.wgConfigText,
          wgConfigFileName: p.wgConfigFileName,
        ),
      ],
      activeProfileId: newProfileId,
    );
  }
}
