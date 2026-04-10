import '../../../settings/domain/entities/app_settings.dart';
import '../entities/wg_config.dart';
import '../entities/wgt_tunnel_extensions.dart';
import '../../data/wg_config_parser.dart';

/// Builds [RuntimeVpnConfig] from raw WireGuard text + app settings + `#@wgt` extensions.
class BuildRuntimeVpnConfigUseCase {
  BuildRuntimeVpnConfigUseCase({required this.parser});

  final WgConfigParser parser;

  static const String localEndpointHost = '127.0.0.1';
  static const int localEndpointPort = 9000;

  /// Must stay excluded in WG+TURN so local vk-turn traffic is not looped into the tunnel.
  static const String androidVkpnPackageId = 'space.iscreation.vkpn';

  RuntimeVpnConfig call(
    String rawConfig,
    AppSettings settings, {
    required bool isAndroid,
  }) {
    final parsed = parser.parse(rawConfig);
    final wgt = parser.parseWgtExtensions(rawConfig);

    final bool useTurnMode = wgt.enableTurn ?? settings.useTurnMode;
    final String vkCallLink = _nonEmpty(wgt.vkLink) ?? settings.vkCallLink.trim();

    final String targetHost;
    final int proxyPort;
    if (wgt.hasIpPort) {
      targetHost = wgt.ipPortHost!;
      proxyPort = wgt.ipPortPort!;
    } else {
      targetHost = parsed.peer.endpointHost;
      proxyPort = settings.proxyPort;
    }

    final int localPort = wgt.localPort ?? localEndpointPort;

    var rewritten = useTurnMode
        ? parser.rewriteEndpoint(
            rawConfig,
            host: localEndpointHost,
            port: localPort,
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
      if (useTurnMode) {
        extra.add(androidVkpnPackageId);
      }
      rewritten = parser.mergeExcludedApplications(rewritten, extra);
    }
    return RuntimeVpnConfig(
      rawConfig: rawConfig,
      rewrittenConfig: rewritten,
      targetHost: targetHost,
      targetPort: parsed.peer.endpointPort,
      proxyPort: proxyPort,
      vkCallLink: vkCallLink,
      localEndpointHost: localEndpointHost,
      localEndpointPort: localPort,
      useTurnMode: useTurnMode,
      effectiveUseUdp: wgt.useUdp ?? settings.useUdp,
      effectiveThreads: wgt.streamNum ?? settings.threads,
      wgtUnsupportedHints: _wgtHints(wgt),
    );
  }

  String? _nonEmpty(String? s) {
    if (s == null) {
      return null;
    }
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  List<String> _wgtHints(WgtTunnelExtensions wgt) {
    final out = <String>[];
    if (wgt.mode != null && wgt.mode!.isNotEmpty) {
      out.add('WGT Mode=${wgt.mode} (not applied in this VkPN build)');
    }
    if (wgt.peerType != null && wgt.peerType!.isNotEmpty) {
      out.add('WGT PeerType=${wgt.peerType} (not applied in this VkPN build)');
    }
    if (wgt.streamsPerCred != null) {
      out.add('WGT StreamsPerCred=${wgt.streamsPerCred} (not applied in this VkPN build)');
    }
    if (wgt.turnIp != null && wgt.turnIp!.isNotEmpty) {
      out.add('WGT TurnIP (not applied in this VkPN build)');
    }
    if (wgt.turnPort != null) {
      out.add('WGT TurnPort=${wgt.turnPort} (not applied in this VkPN build)');
    }
    if (wgt.watchdogTimeout != null) {
      out.add('WGT WatchdogTimeout=${wgt.watchdogTimeout} (not applied in this VkPN build)');
    }
    for (final k in wgt.extras.keys) {
      out.add('WGT unknown key: $k');
    }
    return out;
  }
}
