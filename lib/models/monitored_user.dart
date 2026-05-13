/// A user that has me as a verified emergency contact. Exposed by
/// `GET /api/mapa/monitoreados` to populate the Family Map pins.
class MonitoredUser {
  final int id;
  final String nombre;
  final String apellido;
  final String telefono;
  final double? ultimaLatitud;
  final double? ultimaLongitud;
  final DateTime? fechaUltimaUbicacion;
  final bool tieneAlertaActiva;

  const MonitoredUser({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.telefono,
    required this.ultimaLatitud,
    required this.ultimaLongitud,
    required this.fechaUltimaUbicacion,
    required this.tieneAlertaActiva,
  });

  String get fullName => '$nombre $apellido'.trim();

  /// True when the user has shared their location at least once.
  bool get hasLocation => ultimaLatitud != null && ultimaLongitud != null;

  factory MonitoredUser.fromJson(Map<String, dynamic> json) {
    return MonitoredUser(
      id: _toInt(json['id']) ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      apellido: json['apellido']?.toString() ?? '',
      telefono: json['telefono']?.toString() ?? '',
      ultimaLatitud: _toDouble(json['ultima_latitud']),
      ultimaLongitud: _toDouble(json['ultima_longitud']),
      fechaUltimaUbicacion: _toDate(json['fecha_ultima_ubicacion']),
      tieneAlertaActiva: json['tiene_alerta_activa'] == true,
    );
  }

  static int? _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '');
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString())?.toUtc();
  }
}
