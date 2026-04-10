import '../entities/wg_tunnel_profile.dart';
import 'sync_active_profile_config_usecase.dart';

class AddProfileResult {
  const AddProfileResult({
    required this.profiles,
    required this.activeProfileId,
  });

  final List<WgTunnelProfile> profiles;
  final String activeProfileId;
}

class AddProfileUseCase {
  AddProfileUseCase({SyncActiveProfileConfigUseCase? sync})
    : _sync = sync ?? SyncActiveProfileConfigUseCase();

  final SyncActiveProfileConfigUseCase _sync;

  AddProfileResult call({
    required List<WgTunnelProfile> profiles,
    required String? activeProfileId,
    required String currentWgConfigText,
    required String? currentWgConfigFileName,
    required String newProfileId,
  }) {
    final fileName = currentWgConfigFileName ?? '';
    final synced = _sync(
      profiles: profiles,
      activeProfileId: activeProfileId,
      wgConfigText: currentWgConfigText,
      wgConfigFileName: fileName,
    );
    final n = synced.length + 1;
    return AddProfileResult(
      profiles: <WgTunnelProfile>[
        ...synced,
        WgTunnelProfile(
          id: newProfileId,
          name: 'Profile $n',
          wgConfigText: '',
          wgConfigFileName: '',
        ),
      ],
      activeProfileId: newProfileId,
    );
  }
}
