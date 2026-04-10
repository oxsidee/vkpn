import 'package:equatable/equatable.dart';
import 'package:vkpn/features/profiles/domain/entities/wg_tunnel_profile.dart';

class ProfilesState extends Equatable {
  const ProfilesState({
    this.profiles = const <WgTunnelProfile>[],
    this.activeProfileId,
    this.wgConfigText = '',
    this.configFileName,
  });

  final List<WgTunnelProfile> profiles;
  final String? activeProfileId;
  final String wgConfigText;
  final String? configFileName;

  ProfilesState copyWith({
    List<WgTunnelProfile>? profiles,
    String? activeProfileId,
    String? wgConfigText,
    String? configFileName,
    bool clearConfigFileName = false,
  }) {
    return ProfilesState(
      profiles: profiles ?? this.profiles,
      activeProfileId: activeProfileId ?? this.activeProfileId,
      wgConfigText: wgConfigText ?? this.wgConfigText,
      configFileName: clearConfigFileName
          ? null
          : (configFileName ?? this.configFileName),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    profiles,
    activeProfileId,
    wgConfigText,
    configFileName,
  ];
}
