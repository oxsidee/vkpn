import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vkpn/features/settings/domain/usecases/compose_current_locale_arb_usecase.dart';

void main() {
  test('merges overrides and sets @@locale', () {
    const base = '{"@@locale":"en","appTitle":"A","@appTitle":{}}';
    final uc = ComposeCurrentLocaleArbUseCase();
    final out = uc(
      baseArbRaw: base,
      customOverrides: <String, String>{'appTitle': 'B'},
      arbLocaleCode: 'ru',
    );
    final decoded = jsonDecode(out) as Map<String, dynamic>;
    expect(decoded['@@locale'], 'ru');
    expect(decoded['appTitle'], 'B');
  });
}
