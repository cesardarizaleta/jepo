class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final List<String> errors;
  final String? path;
  final DateTime? timestamp;
  final Map<String, dynamic> raw;

  const ApiResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.errors,
    required this.path,
    required this.timestamp,
    required this.raw,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T? Function(dynamic value)? dataParser,
  }) {
    final rawErrors = json['errors'];
    final parsedErrors = rawErrors is List
        ? rawErrors.map((e) => e.toString()).toList(growable: false)
        : const <String>[];

    final ts = json['timestamp'];
    final parsedTs = ts == null ? null : DateTime.tryParse(ts.toString())?.toUtc();

    final dynamic rawData = json['data'];

    return ApiResponse<T>(
      success: json['success'] == true,
      message: json['message']?.toString() ?? 'Operacion completada',
      data: dataParser == null ? rawData as T? : dataParser(rawData),
      errors: parsedErrors,
      path: json['path']?.toString(),
      timestamp: parsedTs,
      raw: json,
    );
  }
}
