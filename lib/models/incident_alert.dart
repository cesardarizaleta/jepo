import 'package:flutter/material.dart';

import '../utils/geo_utils.dart';
import 'emergency_contact.dart';

enum AlertStatus {
  pendiente,
  real,
  falsoPositivo,
  cancelada;

  String get apiValue {
    switch (this) {
      case AlertStatus.pendiente:
        return 'PENDIENTE';
      case AlertStatus.real:
        return 'REAL';
      case AlertStatus.falsoPositivo:
        return 'FALSO_POSITIVO';
      case AlertStatus.cancelada:
        return 'CANCELADA';
    }
  }

  String get label {
    switch (this) {
      case AlertStatus.pendiente:
        return 'Pendiente';
      case AlertStatus.real:
        return 'Alerta real';
      case AlertStatus.falsoPositivo:
        return 'Falso positivo';
      case AlertStatus.cancelada:
        return 'Cancelada';
    }
  }

  Color get color {
    switch (this) {
      case AlertStatus.pendiente:
        return const Color(0xFF42A5F5);
      case AlertStatus.real:
        return const Color(0xFFE53935);
      case AlertStatus.falsoPositivo:
        return const Color(0xFFFFB300);
      case AlertStatus.cancelada:
        return const Color(0xFF90A4AE);
    }
  }

  IconData get icon {
    switch (this) {
      case AlertStatus.pendiente:
        return Icons.pending_outlined;
      case AlertStatus.real:
        return Icons.warning_amber_rounded;
      case AlertStatus.falsoPositivo:
        return Icons.block_outlined;
      case AlertStatus.cancelada:
        return Icons.cancel_outlined;
    }
  }

  static AlertStatus fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'REAL':
        return AlertStatus.real;
      case 'FALSO_POSITIVO':
        return AlertStatus.falsoPositivo;
      case 'CANCELADA':
        return AlertStatus.cancelada;
      default:
        return AlertStatus.pendiente;
    }
  }
}

class IncidentAlert {
  final int? id;
  final int? idUsuario;
  final double latitud;
  final double longitud;
  final String? urlAudioContexto;
  final DateTime? fechaHora;
  final bool esProactiva;
  final AlertStatus estado;
  final DateTime? resueltaEn;
  final String? notasResolucion;

  const IncidentAlert({
    required this.id,
    required this.idUsuario,
    required this.latitud,
    required this.longitud,
    required this.urlAudioContexto,
    required this.fechaHora,
    required this.esProactiva,
    this.estado = AlertStatus.pendiente,
    this.resueltaEn,
    this.notasResolucion,
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
      estado: AlertStatus.fromApi(json['estado']?.toString()),
      resueltaEn: _parseDate(json['resuelta_en']),
      notasResolucion: json['notas_resolucion']?.toString(),
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
      'estado': estado.apiValue,
      if (resueltaEn != null)
        'resuelta_en': resueltaEn!.toUtc().toIso8601String(),
      if (notasResolucion != null) 'notas_resolucion': notasResolucion,
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

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class CreateIncidentAlertDto {
  final double latitud;
  final double longitud;
  final String? urlAudioContexto;
  final DateTime fechaHora;
  final bool esProactiva;
  final bool isManual;

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
    this.isManual = false,
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
      isManual: json['is_manual'] == true,
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
      'is_manual': isManual,
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
  final AlertStatus? estado;
  final String? notasResolucion;

  const UpdateIncidentAlertDto({
    this.latitud,
    this.longitud,
    this.urlAudioContexto,
    this.fechaHora,
    this.esProactiva,
    this.estado,
    this.notasResolucion,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (latitud != null) 'latitud': normalizeCoordinate8(latitud!),
      if (longitud != null) 'longitud': normalizeCoordinate8(longitud!),
      if (urlAudioContexto != null) 'url_audio_contexto': urlAudioContexto,
      if (fechaHora != null) 'fecha_hora': fechaHora!.toUtc().toIso8601String(),
      if (esProactiva != null) 'es_proactiva': esProactiva,
      if (estado != null) 'estado': estado!.apiValue,
      if (notasResolucion != null) 'notas_resolucion': notasResolucion,
    };
  }
}

class AlertMonthlyStats {
  final String mes;
  final int total;
  final int reales;
  final int falsosPositivos;
  final int canceladas;

  const AlertMonthlyStats({
    required this.mes,
    required this.total,
    required this.reales,
    required this.falsosPositivos,
    required this.canceladas,
  });

  factory AlertMonthlyStats.fromJson(Map<String, dynamic> json) {
    return AlertMonthlyStats(
      mes: json['mes']?.toString() ?? '',
      total: IncidentAlert._toInt(json['total']) ?? 0,
      reales: IncidentAlert._toInt(json['reales']) ?? 0,
      falsosPositivos: IncidentAlert._toInt(json['falsosPositivos']) ?? 0,
      canceladas: IncidentAlert._toInt(json['canceladas']) ?? 0,
    );
  }
}

class AlertMetrics {
  final int totalAlertas;
  final int alertasReales;
  final int falsosPositivos;
  final int canceladas;
  final int pendientes;
  final double tasaFalsosPositivos;
  final double tasaAlertasReales;
  final double promedioAlertasPorMes;
  final DateTime? ultimaAlerta;
  final List<AlertMonthlyStats> alertasPorMes;

  const AlertMetrics({
    required this.totalAlertas,
    required this.alertasReales,
    required this.falsosPositivos,
    required this.canceladas,
    required this.pendientes,
    required this.tasaFalsosPositivos,
    required this.tasaAlertasReales,
    required this.promedioAlertasPorMes,
    this.ultimaAlerta,
    required this.alertasPorMes,
  });

  factory AlertMetrics.fromJson(Map<String, dynamic> json) {
    final rawMonths = json['alertasPorMes'];
    return AlertMetrics(
      totalAlertas: IncidentAlert._toInt(json['totalAlertas']) ?? 0,
      alertasReales: IncidentAlert._toInt(json['alertasReales']) ?? 0,
      falsosPositivos: IncidentAlert._toInt(json['falsosPositivos']) ?? 0,
      canceladas: IncidentAlert._toInt(json['canceladas']) ?? 0,
      pendientes: IncidentAlert._toInt(json['pendientes']) ?? 0,
      tasaFalsosPositivos: IncidentAlert._toDouble(json['tasaFalsosPositivos']),
      tasaAlertasReales: IncidentAlert._toDouble(json['tasaAlertasReales']),
      promedioAlertasPorMes:
          IncidentAlert._toDouble(json['promedioAlertasPorMes']),
      ultimaAlerta: IncidentAlert._parseDate(json['ultimaAlerta']),
      alertasPorMes: rawMonths is List
          ? rawMonths
                .whereType<Map>()
                .map(
                  (e) => AlertMonthlyStats.fromJson(e.cast<String, dynamic>()),
                )
                .toList(growable: false)
          : const <AlertMonthlyStats>[],
    );
  }

  static const AlertMetrics empty = AlertMetrics(
    totalAlertas: 0,
    alertasReales: 0,
    falsosPositivos: 0,
    canceladas: 0,
    pendientes: 0,
    tasaFalsosPositivos: 0,
    tasaAlertasReales: 0,
    promedioAlertasPorMes: 0,
    alertasPorMes: [],
  );
}

class AlertHistoryPage {
  final List<IncidentAlert> data;
  final int total;
  final int pagina;
  final int porPagina;
  final int totalPaginas;

  const AlertHistoryPage({
    required this.data,
    required this.total,
    required this.pagina,
    required this.porPagina,
    required this.totalPaginas,
  });

  factory AlertHistoryPage.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return AlertHistoryPage(
      data: rawData is List
          ? rawData
                .whereType<Map>()
                .map((e) => IncidentAlert.fromJson(e.cast<String, dynamic>()))
                .toList(growable: false)
          : const <IncidentAlert>[],
      total: IncidentAlert._toInt(json['total']) ?? 0,
      pagina: IncidentAlert._toInt(json['pagina']) ?? 1,
      porPagina: IncidentAlert._toInt(json['porPagina']) ?? 20,
      totalPaginas: IncidentAlert._toInt(json['totalPaginas']) ?? 0,
    );
  }

  bool get hasMore => pagina < totalPaginas;
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
