import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/emergency_contact.dart';

class EmergencyContactsCache {
  static const String _cacheKey = 'jepo_verified_contacts_cache_v1';
  static const String _cacheUpdatedKey =
      'jepo_verified_contacts_cache_updated_at';

  static Future<void> replaceVerifiedContacts(
    List<EmergencyContact> contacts,
  ) async {
    final verified = contacts
        .where((c) => c.isVerified)
        .toList(growable: false);
    await _writeContacts(verified);
  }

  static Future<List<EmergencyContact>> getVerifiedContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return const <EmergencyContact>[];
    return _decodeContacts(raw);
  }

  static Future<void> upsertContact(EmergencyContact contact) async {
    final id = contact.id;
    if (id == null) return;

    final current = await getVerifiedContacts();
    final updated = current.where((c) => c.id != id).toList(growable: true);
    if (contact.isVerified) {
      updated.add(contact);
    }

    await _writeContacts(updated);
  }

  static Future<void> removeContact(int id) async {
    final current = await getVerifiedContacts();
    final updated = current.where((c) => c.id != id).toList(growable: false);
    await _writeContacts(updated);
  }

  static Future<void> _writeContacts(List<EmergencyContact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      contacts.map((c) => c.toJson()).toList(growable: false),
    );
    await prefs.setString(_cacheKey, encoded);
    await prefs.setString(
      _cacheUpdatedKey,
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  static List<EmergencyContact> _decodeContacts(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <EmergencyContact>[];
      return decoded
          .whereType<Map>()
          .map((e) => EmergencyContact.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false);
    } catch (_) {
      return const <EmergencyContact>[];
    }
  }
}
