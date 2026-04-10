import '../entities/wg_config.dart';

enum VpnConnectInputIssue { emptyWgConfig, vkLinkRequiredForTurn }

class ValidateVpnConnectInputsUseCase {
  VpnConnectInputIssue? forRawWgConfig(String wgConfigText) {
    if (wgConfigText.trim().isEmpty) {
      return VpnConnectInputIssue.emptyWgConfig;
    }
    return null;
  }

  VpnConnectInputIssue? forRuntimeConfig(RuntimeVpnConfig config) {
    if (config.useTurnMode && config.vkCallLink.trim().isEmpty) {
      return VpnConnectInputIssue.vkLinkRequiredForTurn;
    }
    return null;
  }
}
