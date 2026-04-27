import '../utils/geo_utils.dart';
import 'emergency_contact.dart';

class IncidentAlert {
  final int? id;
  final int? idUsuario;
  final double latitud;
  final double longitud;
  final String? urlAudioContexto;
  final DateTime? fechaHora;
  final bool esProactiva;

  const IncidentAlert({
    required this.id,
    required this.idUsuario,
    required this.latitud,
    required this.longitud,
    required this.urlAudioContexto,
    required this.fechaHora,
    required this.esProactiva,
  });

  factory IncidentAlert.fromJson(Map<String, dynamic> json) {
    return IncidentAlert(
      id: _toInt(json['id']),
      idUsuario: _toInt(json['id_usuario']),
      latitud: normalizeCoordinate8(json['latitud']),
      longitud: normalizeCoordinate8(json['longitud']),
      urlAudioContexto: json['url_audio_contexto']?.toString(),
      fechaHora: _parseDate(json['fecha_hora']),
      esProactiva: json['es_proactiva'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'id_usuario': idUsuario,
      'latitud': latitud,
      'longitud': longitud,
      'url_audio_contexto': urlAudioContexto,
      'fecha_hora': fechaHora?.toUtc().toIso8601String(),
      'es_proactiva': esProactiva,
    };
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toUtc();
  }
}

class CreateIncidentAlertDto {
  final double latitud;
  final double longitud;
  final String? urlAudioContexto;
  final DateTime fechaHora;
  final bool esProactiva;

  /// Client-generated UUID for deduplication. If two DTOs share the same
  /// [clientEventId], the alert queue will treat them as the same logical
  /// event and only send one.
  final String? clientEventId;

  const CreateIncidentAlertDto({
    required this.latitud,
    required this.longitud,
    required this.urlAudioContexto,
    required this.fechaHora,
    required this.esProactiva,
    this.clientEventId,
  });

  factory CreateIncidentAlertDto.fromJson(Map<String, dynamic> json) {
    return CreateIncidentAlertDto(
      latitud: normalizeCoordinate8(json['latitud']),
      longitud: normalizeCoordinate8(json['longitud']),
      urlAudioContexto: json['url_audio_contexto']?.toString(),
      fechaHora:
          DateTime.tryParse(json['fecha_hora']?.toString() ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      esProactiva: json['es_proactiva'] == true,
      clientEventId: json['client_event_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'latitud': normalizeCoordinate8(latitud),
      'longitud': normalizeCoordinate8(longitud),
      if (urlAudioContexto != null && urlAudioContexto!.isNotEmpty)
        'url_audio_contexto': urlAudioContexto,
      'fecha_hora': fechaHora.toUtc().toIso8601String(),
      'es_proactiva': esProactiva,
      if (clientEventId != null && clientEventId!.isNotEmpty)
        'client_event_id': clientEventId,
    };
  }
}

class UpdateIncidentAlertDto {
  final double? latitud;
  final double? longitud;
  final String? urlAudioContexto;
  final DateTime? fechaHora;
  final bool? esProactiva;

  const UpdateIncidentAlertDto({
    this.latitud,
    this.longitud,
    this.urlAudioContexto,
    this.fechaHora,
    this.esProactiva,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (latitud != null) 'latitud': normalizeCoordinate8(latitud!),
      if (longitud != null) 'longitud': normalizeCoordinate8(longitud!),
      if (urlAudioContexto != null) 'url_audio_contexto': urlAudioContexto,
      if (fechaHora != null) 'fecha_hora': fechaHora!.toUtc().toIso8601String(),
      if (esProactiva != null) 'es_proactiva': esProactiva,
    };
  }
}

class IncidentAlertCreateResult {
  final IncidentAlert? alerta;
  final List<EmergencyContact> contactosNotificar;
  final dynamic notificaciones;

  const IncidentAlertCreateResult({
    required this.alerta,
    required this.contactosNotificar,
    required this.notificaciones,
  });

  factory IncidentAlertCreateResult.fromJson(Map<String, dynamic> json) {
    final rawContacts = json['contactosNotificar'];
    return IncidentAlertCreateResult(
      alerta: json['alerta'] is Map<String, dynamic>
          ? IncidentAlert.fromJson(json['alerta'] as Map<String, dynamic>)
          : null,
      contactosNotificar: rawContacts is List
          ? rawContacts
                .whereType<Map>()
                .map((e) => EmergencyContact.fromJson(e.cast<String, dynamic>()))
                .toList(growable: false)
          : const <EmergencyContact>[],
      notificaciones: json['notificaciones'],
    );
  }
}
