String formatBytes(int bytes) {
  const units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
  double value = bytes.toDouble();
  int idx = 0;
  while (value >= 1024 && idx < units.length - 1) {
    value /= 1024;
    idx++;
  }
  final fixed =
      value >= 100 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  return '$fixed ${units[idx]}';
}
