import 'dart:convert';

import 'package:vkpn/core/l10n/l10n_helpers.dart';

/// Builds one `.arb` for a single locale: template + optional custom overrides.
class ComposeCurrentLocaleArbUseCase {
  String call({
    required String baseArbRaw,
    required Map<String, String> customOverrides,
    required String arbLocaleCode,
  }) {
    final cleaned = stripArbComments(baseArbRaw);
    final decoded = jsonDecode(cleaned);
    if (decoded is! Map) {
      throw const FormatException('Invalid ARB JSON');
    }
    final map = Map<String, dynamic>.from(decoded);
    customOverrides.forEach((String k, String v) {
      if (!k.startsWith('@')) {
        map[k] = v;
      }
    });
    map['@@locale'] = arbLocaleCode;
    return const JsonEncoder.withIndent('  ').convert(map);
  }
}
