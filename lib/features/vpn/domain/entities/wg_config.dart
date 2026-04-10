class WgInterface {
  WgInterface({
    required this.privateKey,
    required this.addresses,
    required this.dns,
    this.mtu,
  });

  final String privateKey;
  final List<String> addresses;
  final List<String> dns;
  final int? mtu;
}

class WgPeer {
  WgPeer({
    required this.publicKey,
    required this.allowedIps,
    required this.endpointHost,
    required this.endpointPort,
    this.persistentKeepalive,
  });

  final String publicKey;
  final List<String> allowedIps;
  final String endpointHost;
  final int endpointPort;
  final int? persistentKeepalive;
}

class WgConfig {
  WgConfig({
    required this.interface,
    required this.peer,
  });

  final WgInterface interface;
  final WgPeer peer;
}

class RuntimeVpnConfig {
  RuntimeVpnConfig({
    required this.rawConfig,
    required this.rewrittenConfig,
    required this.targetHost,
    required this.targetPort,
    required this.proxyPort,
    required this.vkCallLink,
    required this.localEndpointHost,
    required this.localEndpointPort,
    required this.useTurnMode,
    required this.effectiveUseUdp,
    required this.effectiveThreads,
    this.wgtUnsupportedHints = const <String>[],
  });

  final String rawConfig;
  final String rewrittenConfig;
  final String targetHost;
  final int targetPort;
  final int proxyPort;
  final String vkCallLink;
  final String localEndpointHost;
  final int localEndpointPort;
  final bool useTurnMode;

  /// After merging `#@wgt` with app settings (WGT overrides UI).
  final bool effectiveUseUdp;
  final int effectiveThreads;

  /// Human-readable hints for `#@wgt` keys ignored in this build (for logs/UI).
  final List<String> wgtUnsupportedHints;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'rawConfig': rawConfig,
      'rewrittenConfig': rewrittenConfig,
      'targetHost': targetHost,
      'targetPort': targetPort,
      'proxyPort': proxyPort,
      'vkCallLink': vkCallLink,
      'localEndpointHost': localEndpointHost,
      'localEndpointPort': localEndpointPort,
      'useTurnMode': useTurnMode,
    };
  }
}
