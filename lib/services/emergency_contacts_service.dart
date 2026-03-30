import 'api_client.dart';
import '../utils/phone_utils.dart';

class EmergencyContactsService {
  final ApiClient api;

  EmergencyContactsService(this.api);

  Future<List<dynamic>> listContacts() async {
    final resp = await api.get('/api/usuarios/contactos', requiresAuth: true);
    if (resp is Map && resp.containsKey('data')) {
      return resp['data'] as List<dynamic>;
    }
    if (resp is List) return resp;
    return [];
  }

  Future<Map<String, dynamic>> createContact(
    Map<String, dynamic> payload,
  ) async {
    // Ensure telefono_contacto is normalized to a numeric string expected by the API
    if (payload.containsKey('telefono_contacto')) {
      try {
        final raw = payload['telefono_contacto']?.toString() ?? '';
        payload['telefono_contacto'] = normalizePhoneForApi(raw);
      } catch (_) {}
    }
    final resp = await api.post(
      '/api/usuarios/contactos',
      body: payload,
      requiresAuth: true,
    );
    if (resp is Map<String, dynamic>) return resp;
    return {'success': false, 'message': 'Unexpected response', 'data': null};
  }

  Future<Map<String, dynamic>> updateContact(
    int id,
    Map<String, dynamic> payload,
  ) async {
    // Normalize phone before updating
    if (payload.containsKey('telefono_contacto')) {
      try {
        final raw = payload['telefono_contacto']?.toString() ?? '';
        payload['telefono_contacto'] = normalizePhoneForApi(raw);
      } catch (_) {}
    }
    final resp = await api.patch(
      '/api/usuarios/contactos/$id',
      body: payload,
      requiresAuth: true,
    );
    if (resp is Map<String, dynamic>) return resp;
    return {'success': false, 'message': 'Unexpected response', 'data': null};
  }

  Future<void> deleteContact(int id) async {
    await api.delete('/api/usuarios/contactos/$id', requiresAuth: true);
  }
}
