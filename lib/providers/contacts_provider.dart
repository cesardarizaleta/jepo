import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/emergency_contact.dart';
import '../services/api_client.dart';
import '../services/emergency_contacts_service.dart';
import '../utils/phone_utils.dart';
import 'api_providers.dart';

/// Immutable view-model for the Family screen.
class FamilyContact {
  final int? id;
  final String name;
  final String phone;
  final int priority;
  final ContactVerificationStatus status;
  final DateTime? acceptedAt;

  const FamilyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.priority,
    required this.status,
    this.acceptedAt,
  });

  bool get isVerified => status == ContactVerificationStatus.verified;
  bool get isPending => status == ContactVerificationStatus.pending;

  FamilyContact copyWith({
    int? id,
    String? name,
    String? phone,
    int? priority,
    ContactVerificationStatus? status,
    DateTime? acceptedAt,
  }) {
    return FamilyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      acceptedAt: acceptedAt ?? this.acceptedAt,
    );
  }
}

final emergencyContactsServiceProvider = Provider<EmergencyContactsService>((
  ref,
) {
  return EmergencyContactsService(ref.watch(apiClientProvider));
});

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
          status: e.estadoVerificacion,
          acceptedAt: e.acceptedAt,
        );
      })
      .toList(growable: false);
});

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

  /// Submit the OTP typed by the user. Throws [ApiException] on failure
  /// so the caller can map 401 → "codigo invalido".
  Future<void> verify(int contactId, String otp) async {
    await _service.verifyContact(contactId, otp);
    _ref.invalidate(contactsProvider);
  }

  /// Request a new OTP. Throws [ApiException] if cooldown is active.
  Future<void> resend(int contactId) async {
    await _service.resendContactCode(contactId);
  }
}

final contactsMutationsProvider = Provider<ContactsMutations>((ref) {
  return ContactsMutations(ref);
});
