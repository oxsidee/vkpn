import '../domain/wg_config.dart';
import '../domain/wg_config_parser.dart';
import '../platform/unified_platform_bridge.dart';
import 'app_settings.dart';

class VpnController {
  VpnController({
    required this.parser,
    required this.bridge,
  });

  final WgConfigParser parser;
  final UnifiedPlatformBridge bridge;
  static const String localEndpointHost = '127.0.0.1';
  static const int localEndpointPort = 9000;
  /// Must stay excluded in WG+TURN so local vk-turn traffic is not looped into the tunnel.
  static const String androidVkpnPackageId = 'space.iscreation.vkpn';

  RuntimeVpnConfig buildRuntimeConfig(
    String rawConfig,
    AppSettings settings, {
    required bool isAndroid,
  }) {
    final parsed = parser.parse(rawConfig);
    var rewritten = settings.useTurnMode
        ? parser.rewriteEndpoint(
            rawConfig,
            host: localEndpointHost,
            port: localEndpointPort,
          )
        : rawConfig;
    if (isAndroid) {
      final extra = <String>[];
      for (final part in settings.excludedAppPackages.split(RegExp(r'[,\n]'))) {
        final p = part.trim();
        if (p.isNotEmpty) {
          extra.add(p);
        }
      }
      if (settings.useTurnMode) {
        extra.add(androidVkpnPackageId);
      }
      rewritten = parser.mergeExcludedApplications(rewritten, extra);
    }
    return RuntimeVpnConfig(
      rawConfig: rawConfig,
      rewrittenConfig: rewritten,
      targetHost: parsed.peer.endpointHost,
      targetPort: parsed.peer.endpointPort,
      proxyPort: settings.proxyPort,
      vkCallLink: settings.vkCallLink,
      localEndpointHost: localEndpointHost,
      localEndpointPort: localEndpointPort,
      useTurnMode: settings.useTurnMode,
    );
  }
}
