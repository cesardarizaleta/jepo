import 'api_client.dart';
import '../models/api_response.dart';
import '../models/emergency_contact.dart';

class EmergencyContactsService {
  final ApiClient api;

  EmergencyContactsService(this.api);

  Future<List<EmergencyContact>> listContacts() async {
    final envelope = await api.getEnvelope(
      '/api/usuarios/contactos',
      requiresAuth: true,
    );
    final response = ApiResponse<List<EmergencyContact>>.fromJson(
      envelope.raw,
      dataParser: (value) {
        if (value is! List) return const <EmergencyContact>[];
        return value
            .whereType<Map>()
            .map(
              (e) => EmergencyContact.fromJson(e.cast<String, dynamic>()),
            )
            .toList(growable: false);
      },
    );

    final contacts = response.data ?? const <EmergencyContact>[];
    final sorted = contacts.toList(growable: false)
      ..sort((a, b) => a.prioridad.compareTo(b.prioridad));
    return sorted;
  }

  Future<EmergencyContact?> createContact(CreateEmergencyContactDto payload) async {
    final envelope = await api.postEnvelope(
      '/api/usuarios/contactos',
      body: payload.toJson(),
      requiresAuth: true,
    );
    final response = ApiResponse<EmergencyContact>.fromJson(
      envelope.raw,
      dataParser: (value) {
        if (value is Map<String, dynamic>) {
          return EmergencyContact.fromJson(value);
        }
        if (value is Map) {
          return EmergencyContact.fromJson(value.cast<String, dynamic>());
        }
        return null;
      },
    );
    return response.data;
  }

  Future<EmergencyContact?> getContact(int id) async {
    final envelope = await api.getEnvelope(
      '/api/usuarios/contactos/$id',
      requiresAuth: true,
    );
    final response = ApiResponse<EmergencyContact>.fromJson(
      envelope.raw,
      dataParser: (value) {
        if (value is Map<String, dynamic>) {
          return EmergencyContact.fromJson(value);
        }
        if (value is Map) {
          return EmergencyContact.fromJson(value.cast<String, dynamic>());
        }
        return null;
      },
    );
    return response.data;
  }

  Future<EmergencyContact?> updateContact(
    int id,
    UpdateEmergencyContactDto payload,
  ) async {
    final envelope = await api.patchEnvelope(
      '/api/usuarios/contactos/$id',
      body: payload.toJson(),
      requiresAuth: true,
    );
    final response = ApiResponse<EmergencyContact>.fromJson(
      envelope.raw,
      dataParser: (value) {
        if (value is Map<String, dynamic>) {
          return EmergencyContact.fromJson(value);
        }
        if (value is Map) {
          return EmergencyContact.fromJson(value.cast<String, dynamic>());
        }
        return null;
      },
    );
    return response.data;
  }

  Future<void> deleteContact(int id) async {
    await api.delete('/api/usuarios/contactos/$id', requiresAuth: true);
  }
}
