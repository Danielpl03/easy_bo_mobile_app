import 'package:hive/hive.dart';

part 'usuario.g.dart';

@HiveType(typeId: 13)
class Usuario extends HiveObject {
  @HiveField(0)
  final int idUsuario;

  @HiveField(1)
  final String nombre;

  @HiveField(2)
  final String password;

  @HiveField(3)
  final String rol;

  @HiveField(4)
  final String? email;

  @HiveField(5)
  final DateTime? ultimoAcceso;

  @HiveField(6)
  final bool activo;

  Usuario({
    required this.idUsuario,
    required this.nombre,
    required this.password,
    required this.rol,
    this.email,
    this.ultimoAcceso,
    this.activo = true,
  });

  String get nombreCompleto {
    return nombre;
  }

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      idUsuario: json['id_usuario'] ?? 0,
      nombre: json['nombre'] ?? '',
      password: json['password'] ?? '',
      rol: json['rol'] ?? '',
      email: json['email'],
      ultimoAcceso: json['ultimo_acceso'] != null 
          ? DateTime.parse(json['ultimo_acceso']) 
          : null,
      activo: json['activo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_usuario': idUsuario,
      'nombre': nombre,
      'password': password,
      'rol': rol,
      'email': email,
      'ultimo_acceso': ultimoAcceso?.toIso8601String(),
      'activo': activo,
    };
  }

  Usuario copyWith({
    int? idUsuario,
    String? nombre,
    String? password,
    String? rol,
    String? email,
    DateTime? ultimoAcceso,
    bool? activo,
  }) {
    return Usuario(
      idUsuario: idUsuario ?? this.idUsuario,
      nombre: nombre ?? this.nombre,
      password: password ?? this.password,
      rol: rol ?? this.rol,
      email: email ?? this.email,
      ultimoAcceso: ultimoAcceso ?? this.ultimoAcceso,
      activo: activo ?? this.activo,
    );
  }
} 