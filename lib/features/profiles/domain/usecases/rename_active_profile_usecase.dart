import '../entities/wg_tunnel_profile.dart';
import 'sync_active_profile_config_usecase.dart';

class RenameActiveProfileUseCase {
  RenameActiveProfileUseCase({SyncActiveProfileConfigUseCase? sync})
    : _sync = sync ?? SyncActiveProfileConfigUseCase();

  final SyncActiveProfileConfigUseCase _sync;

  /// Returns `null` if active profile is missing or [trimmedName] is empty.
  List<WgTunnelProfile>? call({
    required List<WgTunnelProfile> profiles,
    required String? activeProfileId,
    required String currentWgConfigText,
    required String? currentWgConfigFileName,
    required String trimmedName,
  }) {
    if (trimmedName.isEmpty) {
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
    final i = synced.indexWhere((WgTunnelProfile p) => p.id == id);
    if (i < 0) {
      return null;
    }
    final next = List<WgTunnelProfile>.from(synced);
    next[i] = next[i].copyWith(name: trimmedName);
    return next;
  }
}
