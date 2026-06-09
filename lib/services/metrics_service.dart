import 'api_client.dart';
import '../models/api_response.dart';
import '../models/incident_alert.dart';

class MetricsService {
  final ApiClient api;

  MetricsService(this.api);

  Future<AlertMetrics> getMetrics() async {
    final envelope = await api.getEnvelope(
      '/api/alertas/metricas',
      requiresAuth: true,
    );

    final response = ApiResponse<AlertMetrics>.fromJson(
      envelope.raw,
      dataParser: (value) {
        if (value is Map<String, dynamic>) {
          return AlertMetrics.fromJson(value);
        }
        if (value is Map) {
          return AlertMetrics.fromJson(value.cast<String, dynamic>());
        }
        return AlertMetrics.empty;
      },
    );

    return response.data ?? AlertMetrics.empty;
  }

  Future<AlertHistoryPage> getHistorial({
    int pagina = 1,
    String? estado,
    DateTime? desde,
    DateTime? hasta,
    int porPagina = 20,
  }) async {
    final query = <String, String>{
      'pagina': pagina.toString(),
      'porPagina': porPagina.toString(),
      if (estado != null && estado.isNotEmpty) 'estado': estado,
      if (desde != null) 'desde': desde.toUtc().toIso8601String(),
      if (hasta != null) 'hasta': hasta.toUtc().toIso8601String(),
    };

    final envelope = await api.getEnvelope(
      '/api/alertas/historial',
      queryParameters: query,
      requiresAuth: true,
    );

    final response = ApiResponse<AlertHistoryPage>.fromJson(
      envelope.raw,
      dataParser: (value) {
        if (value is Map<String, dynamic>) {
          return AlertHistoryPage.fromJson(value);
        }
        if (value is Map) {
          return AlertHistoryPage.fromJson(value.cast<String, dynamic>());
        }
        return const AlertHistoryPage(
          data: [],
          total: 0,
          pagina: 1,
          porPagina: 20,
          totalPaginas: 0,
        );
      },
    );

    return response.data ??
        const AlertHistoryPage(
          data: [],
          total: 0,
          pagina: 1,
          porPagina: 20,
          totalPaginas: 0,
        );
  }

  Future<IncidentAlert> resolveAlert(
    int id,
    AlertStatus estado, {
    String? notas,
  }) async {
    final envelope = await api.patchEnvelope(
      '/api/alertas/$id/resolver',
      body: <String, dynamic>{
        'estado': estado.apiValue,
        if (notas != null && notas.isNotEmpty) 'notas_resolucion': notas,
      },
      requiresAuth: true,
    );

    final response = ApiResponse<IncidentAlert>.fromJson(
      envelope.raw,
      dataParser: (value) {
        if (value is Map<String, dynamic>) {
          return IncidentAlert.fromJson(value);
        }
        if (value is Map) {
          return IncidentAlert.fromJson(value.cast<String, dynamic>());
        }
        throw const FormatException('Respuesta de resolución inválida');
      },
    );

    final alert = response.data;
    if (alert == null) {
      throw const FormatException('No se pudo resolver la alerta');
    }
    return alert;
  }
}
