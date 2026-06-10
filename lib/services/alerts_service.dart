import 'api_client.dart';
import '../models/api_response.dart';
import '../models/emergency_contact.dart';
import '../models/incident_alert.dart';

class AlertsService {
  final ApiClient api;

  AlertsService(this.api);

  Future<IncidentAlertCreateResult> createAlert(
    CreateIncidentAlertDto payload,
  ) async {
    final url = payload.isManual ? '/api/alertas/manual' : '/api/alertas';
    final envelope = await api.postEnvelope(
      url,
      body: payload.toJson(),
      requiresAuth: true,
    );

    final response = ApiResponse<IncidentAlertCreateResult>.fromJson(
      envelope.raw,
      dataParser: (value) {
        if (value is Map<String, dynamic>) {
          return IncidentAlertCreateResult.fromJson(value);
        }
        if (value is Map) {
          return IncidentAlertCreateResult.fromJson(
            value.cast<String, dynamic>(),
          );
        }
        return const IncidentAlertCreateResult(
          alerta: null,
          contactosNotificar: <EmergencyContact>[],
          notificaciones: null,
        );
      },
    );

    return response.data ??
        const IncidentAlertCreateResult(
          alerta: null,
          contactosNotificar: <EmergencyContact>[],
          notificaciones: null,
        );
  }

  Future<List<IncidentAlert>> listAlerts() async {
    final envelope = await api.getEnvelope('/api/alertas', requiresAuth: true);
    final response = ApiResponse<List<IncidentAlert>>.fromJson(
      envelope.raw,
      dataParser: (value) {
        if (value is! List) return const <IncidentAlert>[];
        return value
            .whereType<Map>()
            .map((e) => IncidentAlert.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false);
      },
    );
    return response.data ?? const <IncidentAlert>[];
  }

  Future<IncidentAlert?> getAlert(int id) async {
    final envelope = await api.getEnvelope('/api/alertas/$id', requiresAuth: true);
    final response = ApiResponse<IncidentAlert>.fromJson(
      envelope.raw,
      dataParser: (value) {
        if (value is Map<String, dynamic>) {
          return IncidentAlert.fromJson(value);
        }
        if (value is Map) {
          return IncidentAlert.fromJson(value.cast<String, dynamic>());
        }
        return null;
      },
    );
    return response.data;
  }

  Future<IncidentAlert?> updateAlertHeartbeat(
    int id,
    double latitud,
    double longitud,
  ) async {
    final envelope = await api.patchEnvelope(
      '/api/alertas/$id',
      body: <String, dynamic>{
        'latitud': latitud,
        'longitud': longitud,
        'fecha_hora': DateTime.now().toUtc().toIso8601String(),
        'es_proactiva': false,
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
        return null;
      },
    );
    return response.data;
  }

  Future<void> deleteAlert(int id) async {
    await api.deleteEnvelope('/api/alertas/$id', requiresAuth: true);
  }

  Future<void> registerFalsoPositivo({
    required double latitud,
    required double longitud,
    DateTime? fechaHora,
  }) async {
    await api.postEnvelope(
      '/api/alertas/falso-positivo',
      body: <String, dynamic>{
        'latitud': latitud,
        'longitud': longitud,
        if (fechaHora != null) 'fecha_hora': fechaHora.toUtc().toIso8601String(),
      },
      requiresAuth: true,
    );
  }

  Future<void> reportSafe() async {
    await api.postEnvelope(
      '/api/alertas/protegido',
      requiresAuth: true,
    );
  }
}
