final RegExp _vkLinkArgumentPattern = RegExp(
  r'(-vk-link\s+)(\S+)',
  caseSensitive: false,
);
final RegExp _peerArgumentPattern = RegExp(
  r'(-peer\s+)(\S+)',
  caseSensitive: false,
);
final RegExp _vkCallJoinUrlPattern = RegExp(
  r'https://vk\.(?:ru|com)/call/join/\S+',
  caseSensitive: false,
);
final RegExp _wireGuardSecretPattern = RegExp(
  r'^(\s*(?:PrivateKey|PresharedKey)\s*=\s*).*$',
  caseSensitive: false,
  multiLine: true,
);

const List<String> _sensitiveKeys = <String>[
  'access_token',
  'anonymToken',
  'client_secret',
  'joinLink',
  'session_key',
  'vkCallLink',
  'vk_join_link',
];

String sanitizeLogLine(String input) {
  var sanitized = input;
  sanitized = sanitized.replaceAllMapped(
    _peerArgumentPattern,
    (match) => '${match.group(1)}[REDACTED]',
  );
  sanitized = sanitized.replaceAllMapped(
    _vkLinkArgumentPattern,
    (match) => '${match.group(1)}[REDACTED]',
  );
  sanitized = sanitized.replaceAll(_vkCallJoinUrlPattern, '[REDACTED]');
  for (final key in _sensitiveKeys) {
    final assignmentPattern = RegExp(
      '(${RegExp.escape(key)}=)[^&\\s]+',
      caseSensitive: false,
    );
    sanitized = sanitized.replaceAllMapped(
      assignmentPattern,
      (match) => '${match.group(1)}[REDACTED]',
    );
  }
  sanitized = sanitized.replaceAllMapped(
    _wireGuardSecretPattern,
    (match) => '${match.group(1)}[REDACTED]',
  );
  return sanitized;
}
