import 'dart:convert';

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/widgets.dart';
import 'package:vkpn/l10n/app_localizations.dart';

/// Inline `#` comments in `.arb` JSON are not valid JSON — strip lines starting with `#`.
String stripArbComments(String raw) {
  final buf = StringBuffer();
  for (final line in raw.split('\n')) {
    final t = line.trimLeft();
    if (t.startsWith('#')) {
      continue;
    }
    buf.writeln(line);
  }
  return buf.toString();
}

/// Reads `@@locale` from a template `.arb` (e.g. `"@@locale": "ru"`).
String? readArbTemplateLocaleCode(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }
  try {
    final cleaned = stripArbComments(raw);
    final decoded = jsonDecode(cleaned);
    if (decoded is Map && decoded['@@locale'] != null) {
      return decoded['@@locale'].toString();
    }
  } catch (_) {}
  return null;
}

/// Parses `.arb` JSON into a flat key → message map (skips `@meta` keys).
Map<String, String> parseArbToMap(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return <String, String>{};
  }
  try {
    final cleaned = stripArbComments(raw);
    final decoded = jsonDecode(cleaned);
    if (decoded is! Map) {
      return <String, String>{};
    }
    final out = <String, String>{};
    decoded.forEach((dynamic k, dynamic v) {
      final ks = k.toString();
      if (ks.startsWith('@')) {
        return;
      }
      if (v is String) {
        out[ks] = v;
      }
    });
    return out;
  } catch (_) {
    return <String, String>{};
  }
}

/// Overrides for strings when a custom `.arb` was loaded.
class CustomArbScope extends InheritedWidget {
  const CustomArbScope({
    super.key,
    required this.overrides,
    required super.child,
  });

  final Map<String, String> overrides;

  static Map<String, String> overridesOf(BuildContext context) {
    final scope = context
        .getElementForInheritedWidgetOfExactType<CustomArbScope>()
        ?.widget as CustomArbScope?;
    return scope?.overrides ?? const <String, String>{};
  }

  @override
  bool updateShouldNotify(CustomArbScope oldWidget) {
    return !mapEquals(oldWidget.overrides, overrides);
  }
}

String tr(
  BuildContext context,
  String key,
  String Function(AppLocalizations l) fallback,
) {
  final o = CustomArbScope.overridesOf(context);
  if (o.containsKey(key)) {
    return o[key]!;
  }
  final l = AppLocalizations.of(context);
  if (l == null) {
    return key;
  }
  return fallback(l);
}
