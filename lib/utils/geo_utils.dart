double normalizeCoordinate8(dynamic value) {
  final parsed = value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '0') ?? 0.0;
  return double.parse(parsed.toStringAsFixed(8));
}
