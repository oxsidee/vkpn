import '../domain/entities/wg_tunnel_profile.dart';

/// Codec for persisted multi-profile list (used by [SettingsRepository] implementation).
class ProfilesLocalDatasource {
  List<WgTunnelProfile> decodeProfiles(String? raw) =>
      WgTunnelProfile.decodeList(raw);

  String encodeProfiles(List<WgTunnelProfile> profiles) =>
      WgTunnelProfile.encodeList(profiles);
}
