import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telephony/telephony.dart';

import '../models/emergency_contact.dart';
import '../models/incident_alert.dart';
import '../utils/phone_utils.dart';
import 'diagnostic_log_service.dart';
import 'emergency_contacts_cache.dart';

class SmsFallbackService {
  static const String _smsSentEventIdsKey = 'jepo_sms_sent_event_ids';
  static const int _maxEventIds = 200;

  final Telephony _telephony;

  SmsFallbackService({Telephony? telephony})
    : _telephony = telephony ?? Telephony.instance;

  Future<bool> trySendFallbackSms(CreateIncidentAlertDto payload) async {
    if (kDebugMode) {
      debugPrint('SmsFallback: start eventId=${payload.clientEventId}');
    }
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      if (kDebugMode) {
        debugPrint('SmsFallback: unsupported platform');
      }
      await DiagnosticLogService.logSmsSkipped(
        eventId: payload.clientEventId,
        reason: 'unsupported_platform',
      );
      return false;
    }

    final contacts = await EmergencyContactsCache.getVerifiedContacts();
    if (contacts.isEmpty) {
      if (kDebugMode) {
        debugPrint('SmsFallback: no cached verified contacts');
      }
      await DiagnosticLogService.logSmsSkipped(
        eventId: payload.clientEventId,
        reason: 'no_cached_contacts',
      );
      return false;
    }

    final eventKey = _eventKey(payload);
    if (await _isEventAlreadyHandled(eventKey)) {
      if (kDebugMode) {
        debugPrint('SmsFallback: duplicate event key=$eventKey');
      }
      await DiagnosticLogService.logSmsSkipped(
        eventId: payload.clientEventId ?? eventKey,
        reason: 'duplicate_event',
      );
      return false;
    }

    final permission = await Permission.sms.status;
    if (!permission.isGranted) {
      if (kDebugMode) {
        debugPrint('SmsFallback: SMS permission denied');
      }
      await DiagnosticLogService.logSmsSkipped(
        eventId: payload.clientEventId ?? eventKey,
        reason: 'permission_denied',
      );
      return false;
    }

    final message = _buildMessage(payload);
    final recipients = _normalizeRecipients(contacts);
    if (recipients.isEmpty) {
      if (kDebugMode) {
        debugPrint('SmsFallback: no valid recipient numbers');
      }
      await DiagnosticLogService.logSmsSkipped(
        eventId: payload.clientEventId ?? eventKey,
        reason: 'no_valid_numbers',
      );
      return false;
    }

    if (kDebugMode) {
      debugPrint(
        'SmsFallback: cached contacts=${contacts.length}, recipients=${recipients.length}',
      );
    }

    if (kDebugMode) {
      debugPrint(
        'SmsFallback: sending to ${recipients.length} recipients, key=$eventKey',
      );
    }

    int sent = 0;
    for (final phone in recipients) {
      try {
        if (kDebugMode) {
          debugPrint('SmsFallback: sendSms to $phone');
        }
        await _telephony.sendSms(to: phone, message: message);
        sent++;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('SmsFallback: sendSms failed to $phone: $e');
        }
        await DiagnosticLogService.logSmsFailed(
          eventId: payload.clientEventId ?? eventKey,
          reason: 'send_error: $e',
        );
      }
    }

    await _recordEvent(eventKey);

    if (sent > 0) {
      if (kDebugMode) {
        debugPrint('SmsFallback: sent=$sent');
      }
      await DiagnosticLogService.logSmsSent(
        eventId: payload.clientEventId ?? eventKey,
        recipients: sent,
      );
      return true;
    }

    if (kDebugMode) {
      debugPrint('SmsFallback: no SMS delivered');
    }
    await DiagnosticLogService.logSmsFailed(
      eventId: payload.clientEventId ?? eventKey,
      reason: 'all_recipients_failed',
    );
    return false;
  }

  String _buildMessage(CreateIncidentAlertDto payload) {
    final type = payload.esProactiva ? 'Alerta proactiva' : 'Alerta manual';
    final lat = payload.latitud.toStringAsFixed(6);
    final lon = payload.longitud.toStringAsFixed(6);
    final mapLink = 'https://maps.google.com/?q=$lat,$lon';
    final timestamp = _formatUtc(payload.fechaHora.toUtc());

    return 'ALERTA JEPO: $type. Ubicacion: $mapLink. Hora: $timestamp UTC.';
  }

  String _formatUtc(DateTime dt) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  List<String> _normalizeRecipients(List<EmergencyContact> contacts) {
    final unique = <String>{};
    for (final contact in contacts) {
      final raw = contact.telefonoContacto;
      final normalized = formatToE164(normalizePhoneForApi(raw));
      if (normalized.isNotEmpty) {
        unique.add(normalized);
      }
    }
    return unique.toList(growable: false);
  }

  String _eventKey(CreateIncidentAlertDto payload) {
    final eventId = payload.clientEventId;
    if (eventId != null && eventId.isNotEmpty) return eventId;
    final lat = payload.latitud.toStringAsFixed(4);
    final lon = payload.longitud.toStringAsFixed(4);
    final ts = payload.fechaHora.toUtc().millisecondsSinceEpoch;
    final type = payload.esProactiva ? 'P' : 'M';
    return 'sms_${ts}_${lat}_${lon}_$type';
  }

  Future<bool> _isEventAlreadyHandled(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_smsSentEventIdsKey) ?? [];
    return ids.contains(eventId);
  }

  Future<void> _recordEvent(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_smsSentEventIdsKey) ?? [];
    ids.add(eventId);
    while (ids.length > _maxEventIds) {
      ids.removeAt(0);
    }
    await prefs.setStringList(_smsSentEventIdsKey, ids);
  }
}
