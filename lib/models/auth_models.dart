import 'user.dart';

class AuthSession {
  final String accessToken;
  final String tokenType;
  final String? expiresIn;
  final User user;

  const AuthSession({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token']?.toString() ?? '',
      tokenType: json['token_type']?.toString() ?? 'Bearer',
      expiresIn: json['expires_in']?.toString(),
      user: User.fromJson(
        (json['user'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'access_token': accessToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
      'user': user.toJson(),
    };
  }
}

class LoginDto {
  final String email;
  final String password;

  const LoginDto({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'email': email, 'password': password};
  }
}

class RegisterDto {
  final String? cedula;
  final String nombre;
  final String apellido;
  final String email;
  final String telefono;
  final String password;
  final String? tokenFcm;

  const RegisterDto({
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
      if (tokenFcm != null) 'token_fcm': tokenFcm,
    };
  }
}
