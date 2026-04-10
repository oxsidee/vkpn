class ParseExcludedAppPackageIdsUseCase {
  Set<String> call(String raw) {
    return raw
        .split(RegExp(r'[,\n]'))
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toSet();
  }
}
