import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/emergency_contact.dart';
import '../services/api_client.dart';
import '../services/emergency_contacts_service.dart';
import '../utils/phone_utils.dart';
import 'api_providers.dart';

/// Immutable view-model of a family member used by the UI layer.
///
/// Kept intentionally thin to decouple the widget tree from raw API DTOs.
class FamilyContact {
  final int? id;
  final String name;
  final String phone; // E.164 format for display
  final int priority;

  const FamilyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.priority,
  });

  FamilyContact copyWith({
    int? id,
    String? name,
    String? phone,
    int? priority,
  }) {
    return FamilyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      priority: priority ?? this.priority,
    );
  }
}

/// Exposes the [EmergencyContactsService] wired to the app's [ApiClient].
final emergencyContactsServiceProvider = Provider<EmergencyContactsService>((
  ref,
) {
  return EmergencyContactsService(ref.watch(apiClientProvider));
});

/// Asynchronous loader for the authenticated user's emergency contacts.
///
/// Uses [FutureProvider.autoDispose] so the list is refetched whenever the
/// FamilyScreen is re-opened (no stale data between sessions), but stays
/// alive while the screen is mounted.
///
/// Invalidate it after a mutation to trigger a refresh:
/// ```dart
/// ref.invalidate(contactsProvider);
/// ```
final contactsProvider = FutureProvider.autoDispose<List<FamilyContact>>((
  ref,
) async {
  final service = ref.watch(emergencyContactsServiceProvider);
  final raw = await service.listContacts();

  return raw
      .map<FamilyContact>((EmergencyContact e) {
        final rawPhone = e.telefonoContacto;
        return FamilyContact(
          id: e.id,
          name: e.nombreContacto.isEmpty ? 'Desconocido' : e.nombreContacto,
          phone: rawPhone.isEmpty
              ? ''
              : formatToE164(normalizePhoneForApi(rawPhone)),
          priority: e.prioridad,
        );
      })
      .toList(growable: false);
});

/// Notifier that encapsulates write operations (create / update / delete)
/// and invalidates [contactsProvider] on success so the UI refreshes without
/// manual state juggling.
class ContactsMutations {
  final Ref _ref;
  ContactsMutations(this._ref);

  EmergencyContactsService get _service =>
      _ref.read(emergencyContactsServiceProvider);

  Future<void> add({
    required String name,
    required String phone,
    required int priority,
  }) async {
    await _service.createContact(
      CreateEmergencyContactDto(
        nombreContacto: name,
        telefonoContacto: phone,
        prioridad: priority,
      ),
    );
    _ref.invalidate(contactsProvider);
  }

  Future<void> update({
    required int id,
    required String name,
    required String phone,
    required int priority,
  }) async {
    await _service.updateContact(
      id,
      UpdateEmergencyContactDto(
        nombreContacto: name,
        telefonoContacto: phone,
        prioridad: priority,
      ),
    );
    _ref.invalidate(contactsProvider);
  }

  Future<void> remove(int id) async {
    await _service.deleteContact(id);
    _ref.invalidate(contactsProvider);
  }
}

final contactsMutationsProvider = Provider<ContactsMutations>((ref) {
  return ContactsMutations(ref);
});
