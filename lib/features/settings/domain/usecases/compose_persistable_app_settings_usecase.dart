import '../../../profiles/domain/entities/wg_tunnel_profile.dart';
import '../../../profiles/domain/usecases/sync_active_profile_config_usecase.dart';
import '../entities/app_settings.dart';

/// Builds the [AppSettings] snapshot that should be persisted (profiles blob, active id, prefs).
class ComposePersistableAppSettingsUseCase {
  ComposePersistableAppSettingsUseCase({SyncActiveProfileConfigUseCase? sync})
    : _sync = sync ?? SyncActiveProfileConfigUseCase();

  final SyncActiveProfileConfigUseCase _sync;

  AppSettings call({
    required List<WgTunnelProfile> profiles,
    required String? activeProfileId,
    required String wgConfigText,
    required String? wgConfigFileName,
    required String vkCallLink,
    required bool useUdp,
    required bool useTurnMode,
    required String proxyPortText,
    required String threadsText,
    required String excludedAppPackages,
    required String? localeCode,
    required String? customArbContent,
    required String Function() newProfileId,
  }) {
    final fileName = wgConfigFileName ?? '';
    var nextProfiles = _sync(
      profiles: profiles,
      activeProfileId: activeProfileId,
      wgConfigText: wgConfigText,
      wgConfigFileName: fileName,
    );
    var nextActiveId = activeProfileId;

    if (nextProfiles.isEmpty && wgConfigText.trim().isNotEmpty) {
      final id = newProfileId();
      nextProfiles = <WgTunnelProfile>[
        WgTunnelProfile(
          id: id,
          name: 'Profile 1',
          wgConfigText: wgConfigText,
          wgConfigFileName: fileName,
        ),
      ];
      nextActiveId = id;
    }

    var activeId = nextActiveId;
    if (nextProfiles.isNotEmpty) {
      if (activeId == null ||
          !nextProfiles.any((WgTunnelProfile p) => p.id == activeId)) {
        activeId = nextProfiles.first.id;
        nextActiveId = activeId;
      }
      final ai = nextProfiles.indexWhere((WgTunnelProfile p) => p.id == activeId);
      if (ai >= 0) {
        nextProfiles = List<WgTunnelProfile>.from(nextProfiles);
        nextProfiles[ai] = nextProfiles[ai].copyWith(
          wgConfigText: wgConfigText,
          wgConfigFileName: fileName,
        );
      }
    }

    return AppSettings(
      proxyPort: int.tryParse(proxyPortText.trim()) ?? 56000,
      vkCallLink: vkCallLink.trim(),
      useUdp: useUdp,
      useTurnMode: useTurnMode,
      threads: int.tryParse(threadsText.trim()) ?? 8,
      wgConfigText: wgConfigText,
      wgConfigFileName: fileName,
      excludedAppPackages: excludedAppPackages,
      profiles: nextProfiles,
      activeProfileId: activeId,
      localeCode: localeCode,
      customArbContent: customArbContent,
    );
  }
}
