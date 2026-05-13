import '../utils/phone_utils.dart';

/// Possible verification states of an emergency contact returned by the API.
enum ContactVerificationStatus {
  pending,
  verified,
  rejected;

  static ContactVerificationStatus fromString(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'VERIFIED':
        return ContactVerificationStatus.verified;
      case 'REJECTED':
        return ContactVerificationStatus.rejected;
      case 'PENDING':
      default:
        return ContactVerificationStatus.pending;
    }
  }

  String get apiValue {
    switch (this) {
      case ContactVerificationStatus.pending:
        return 'PENDING';
      case ContactVerificationStatus.verified:
        return 'VERIFIED';
      case ContactVerificationStatus.rejected:
        return 'REJECTED';
    }
  }
}

class EmergencyContact {
  final int? id;
  final int? idUsuario;
  final String nombreContacto;
  final String telefonoContacto;
  final int prioridad;
  final ContactVerificationStatus estadoVerificacion;
  final DateTime? acceptedAt;

  const EmergencyContact({
    required this.id,
    required this.idUsuario,
    required this.nombreContacto,
    required this.telefonoContacto,
    required this.prioridad,
    this.estadoVerificacion = ContactVerificationStatus.pending,
    this.acceptedAt,
  });

  bool get isVerified =>
      estadoVerificacion == ContactVerificationStatus.verified;
  bool get isPending => estadoVerificacion == ContactVerificationStatus.pending;

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: _toInt(json['id']),
      idUsuario: _toInt(json['id_usuario']),
      nombreContacto: json['nombre_contacto']?.toString() ?? '',
      telefonoContacto: json['telefono_contacto']?.toString() ?? '',
      prioridad: _toInt(json['prioridad']) ?? 1,
      estadoVerificacion: ContactVerificationStatus.fromString(
        json['estado_verificacion']?.toString(),
      ),
      acceptedAt: _toDate(json['accepted_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'id_usuario': idUsuario,
      'nombre_contacto': nombreContacto,
      'telefono_contacto': telefonoContacto,
      'prioridad': prioridad,
      'estado_verificacion': estadoVerificacion.apiValue,
      'accepted_at': acceptedAt?.toUtc().toIso8601String(),
    };
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toUtc();
  }
}

class CreateEmergencyContactDto {
  final String nombreContacto;
  final String telefonoContacto;
  final int prioridad;

  const CreateEmergencyContactDto({
    required this.nombreContacto,
    required this.telefonoContacto,
    required this.prioridad,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'nombre_contacto': nombreContacto,
      'telefono_contacto': normalizePhoneForApi(telefonoContacto),
      'prioridad': prioridad,
    };
  }
}

class UpdateEmergencyContactDto {
  final String? nombreContacto;
  final String? telefonoContacto;
  final int? prioridad;

  const UpdateEmergencyContactDto({
    this.nombreContacto,
    this.telefonoContacto,
    this.prioridad,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (nombreContacto != null) 'nombre_contacto': nombreContacto,
      if (telefonoContacto != null)
        'telefono_contacto': normalizePhoneForApi(telefonoContacto!),
      if (prioridad != null) 'prioridad': prioridad,
    };
  }
}
