import '../entities/wg_tunnel_profile.dart';
import 'sync_active_profile_config_usecase.dart';

class SwitchProfileResult {
  const SwitchProfileResult({
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

class SwitchProfileUseCase {
  SwitchProfileUseCase({SyncActiveProfileConfigUseCase? sync})
    : _sync = sync ?? SyncActiveProfileConfigUseCase();

  final SyncActiveProfileConfigUseCase _sync;

  SwitchProfileResult call({
    required List<WgTunnelProfile> profiles,
    required String? activeProfileId,
    required String targetProfileId,
    required String currentWgConfigText,
    required String? currentWgConfigFileName,
  }) {
    final fileName = currentWgConfigFileName ?? '';
    final synced = _sync(
      profiles: profiles,
      activeProfileId: activeProfileId,
      wgConfigText: currentWgConfigText,
      wgConfigFileName: fileName,
    );
    final p = synced.firstWhere((WgTunnelProfile e) => e.id == targetProfileId);
    return SwitchProfileResult(
      profiles: synced,
      activeProfileId: targetProfileId,
      wgConfigText: p.wgConfigText,
      wgConfigFileName: p.wgConfigFileName.isEmpty ? null : p.wgConfigFileName,
    );
  }
}
