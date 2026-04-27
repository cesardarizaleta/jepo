import '../utils/phone_utils.dart';

class EmergencyContact {
  final int? id;
  final int? idUsuario;
  final String nombreContacto;
  final String telefonoContacto;
  final int prioridad;

  const EmergencyContact({
    required this.id,
    required this.idUsuario,
    required this.nombreContacto,
    required this.telefonoContacto,
    required this.prioridad,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: _toInt(json['id']),
      idUsuario: _toInt(json['id_usuario']),
      nombreContacto: json['nombre_contacto']?.toString() ?? '',
      telefonoContacto: json['telefono_contacto']?.toString() ?? '',
      prioridad: _toInt(json['prioridad']) ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'id_usuario': idUsuario,
      'nombre_contacto': nombreContacto,
      'telefono_contacto': telefonoContacto,
      'prioridad': prioridad,
    };
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
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
