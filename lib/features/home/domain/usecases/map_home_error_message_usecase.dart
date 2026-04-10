import '../entities/home_error_code.dart';

/// Returns i18n key for a domain-level home error code.
class MapHomeErrorMessageUseCase {
  String? call(HomeErrorCode? code) {
    if (code == null) {
      return null;
    }
    switch (code) {
      case HomeErrorCode.wgConfigRequired:
        return 'wgConfigRequired';
      case HomeErrorCode.vkLinkRequired:
        return 'vkLinkRequired';
      case HomeErrorCode.permissionsDenied:
        return 'permissionsDenied';
      case HomeErrorCode.vpnPermissionRequired:
        return 'vpnPermissionRequired';
    }
  }
}
