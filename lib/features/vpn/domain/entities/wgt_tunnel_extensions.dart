/// Metadata from `#@wgt:Key = Value` comments (compatible with
/// [wireguard-turn-android](https://github.com/kiper292/wireguard-turn-android)).
class WgtTunnelExtensions {
  const WgtTunnelExtensions({
    this.enableTurn,
    this.useUdp,
    this.ipPortHost,
    this.ipPortPort,
    this.vkLink,
    this.mode,
    this.peerType,
    this.streamNum,
    this.localPort,
    this.streamsPerCred,
    this.turnIp,
    this.turnPort,
    this.watchdogTimeout,
    this.extras = const <String, String>{},
  });

  final bool? enableTurn;
  final bool? useUdp;

  /// From `IPPort` — remote vk-turn peer host (when set with [ipPortPort]).
  final String? ipPortHost;
  final int? ipPortPort;

  /// VK call link for TURN credentials.
  final String? vkLink;

  /// `vk_link` or `wb` (may be unsupported by current vk-turn build).
  final String? mode;

  /// `proxy_v2`, `proxy_v1`, or `wireguard`.
  final String? peerType;

  /// Maps to vk-turn `-n` (parallel streams / threads).
  final int? streamNum;

  /// Local listen port for vk-turn; WireGuard endpoint rewrite uses this port.
  final int? localPort;

  final int? streamsPerCred;
  final String? turnIp;
  final int? turnPort;
  final int? watchdogTimeout;

  /// Unknown or future `#@wgt` keys (canonical key → raw value).
  final Map<String, String> extras;

  bool get hasIpPort =>
      ipPortHost != null &&
      ipPortHost!.isNotEmpty &&
      ipPortPort != null &&
      ipPortPort! > 0;
}
