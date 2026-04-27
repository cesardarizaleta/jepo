class User {
  final int? id;
  final String? cedula;
  final String? nombre;
  final String? apellido;
  final String? email;
  final String? telefono;
  final String? tokenFcm;
  final Map<String, dynamic> extra;

  const User({
    required this.id,
    required this.cedula,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.telefono,
    required this.tokenFcm,
    this.extra = const <String, dynamic>{},
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);
    copy.remove('id');
    copy.remove('cedula');
    copy.remove('nombre');
    copy.remove('apellido');
    copy.remove('email');
    copy.remove('telefono');
    copy.remove('token_fcm');

    return User(
      id: _toInt(json['id']),
      cedula: json['cedula']?.toString(),
      nombre: json['nombre']?.toString(),
      apellido: json['apellido']?.toString(),
      email: json['email']?.toString(),
      telefono: json['telefono']?.toString(),
      tokenFcm: json['token_fcm']?.toString(),
      extra: copy,
    );
  }

  User copyWith({
    int? id,
    String? cedula,
    String? nombre,
    String? apellido,
    String? email,
    String? telefono,
    String? tokenFcm,
    Map<String, dynamic>? extra,
  }) {
    return User(
      id: id ?? this.id,
      cedula: cedula ?? this.cedula,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      tokenFcm: tokenFcm ?? this.tokenFcm,
      extra: extra ?? this.extra,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'cedula': cedula,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'telefono': telefono,
      'token_fcm': tokenFcm,
      ...extra,
    };
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}

class CreateUserDto {
  final String? cedula;
  final String nombre;
  final String apellido;
  final String email;
  final String telefono;
  final String password;
  final String? tokenFcm;

  const CreateUserDto({
    this.cedula,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.telefono,
    required this.password,
    this.tokenFcm,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (cedula != null && cedula!.isNotEmpty) 'cedula': cedula,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'telefono': telefono,
      'password': password,
      if (tokenFcm != null && tokenFcm!.isNotEmpty) 'token_fcm': tokenFcm,
    };
  }
}

class UpdateUserDto {
  final String? nombre;
  final String? apellido;
  final String? telefono;
  final String? tokenFcm;

  const UpdateUserDto({this.nombre, this.apellido, this.telefono, this.tokenFcm});

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (nombre != null) 'nombre': nombre,
      if (apellido != null) 'apellido': apellido,
      if (telefono != null) 'telefono': telefono,
      if (tokenFcm != null) 'token_fcm': tokenFcm,
    };
  }
}
