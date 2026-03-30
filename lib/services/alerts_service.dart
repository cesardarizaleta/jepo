import 'api_client.dart';

class AlertsService {
  final ApiClient api;

  AlertsService(this.api);

  Future<Map<String, dynamic>> createAlert(Map<String, dynamic> payload) async {
    final resp = await api.post(
      '/api/alertas',
      body: payload,
      requiresAuth: true,
    );
    if (resp is Map<String, dynamic>) return resp;
    return {'success': false, 'message': 'Unexpected response', 'data': null};
  }

  Future<List<dynamic>> listAlerts() async {
    final resp = await api.get('/api/alertas', requiresAuth: true);
    if (resp is Map && resp.containsKey('data'))
      return resp['data'] as List<dynamic>;
    if (resp is List) return resp;
    return [];
  }
}
