import 'package:flutter_test/flutter_test.dart';
import 'package:vkpn/features/apps_exclusion/domain/usecases/build_excluded_apps_summary_usecase.dart';

void main() {
  test('builds short comma separated summary', () {
    final usecase = BuildExcludedAppsSummaryUseCase();
    final out = usecase('a.b.c, d.e.f');
    expect(out.ids.length, 2);
    expect(out.commaSeparatedIfShort, 'a.b.c, d.e.f');
  });

  test('returns null short summary for large selection', () {
    final usecase = BuildExcludedAppsSummaryUseCase();
    final out = usecase('a, b, c, d, e');
    expect(out.ids.length, 5);
    expect(out.commaSeparatedIfShort, isNull);
  });
}
