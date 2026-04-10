import 'parse_excluded_app_package_ids_usecase.dart';

class ExcludedAppsSummary {
  const ExcludedAppsSummary({
    required this.ids,
    required this.commaSeparatedIfShort,
  });

  final Set<String> ids;
  final String? commaSeparatedIfShort;
}

class BuildExcludedAppsSummaryUseCase {
  BuildExcludedAppsSummaryUseCase({
    ParseExcludedAppPackageIdsUseCase? parseIds,
  }) : _parseIds = parseIds ?? ParseExcludedAppPackageIdsUseCase();

  final ParseExcludedAppPackageIdsUseCase _parseIds;

  ExcludedAppsSummary call(String raw) {
    final ids = _parseIds(raw);
    final short = ids.length <= 4 ? ids.join(', ') : null;
    return ExcludedAppsSummary(ids: ids, commaSeparatedIfShort: short);
  }
}
