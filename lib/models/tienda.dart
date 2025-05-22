import 'package:hive/hive.dart';

part 'tienda.g.dart'; // Genera el archivo .g.dart

@HiveType(typeId: 0) // Asigna un ID único
class Tienda {
  @HiveField(0)
  final int idTienda;
  @HiveField(1)
  final String nombre;

  @HiveField(2)
  final String? direccion;

  @HiveField(3)
  final String? coordenadas;

  @HiveField(4)
  final String? telefono;

  Tienda({
    required this.idTienda,
    required this.nombre,
    this.direccion,
    this.coordenadas,
    this.telefono,
  });

  factory Tienda.fromJson(Map<String, dynamic> json) {
    return Tienda(
      idTienda: json['id_tienda'] as int,
      nombre: json['nombre'] as String,
      direccion: json['direccion'] as String?,
      coordenadas: json['coordenadas'] as String?,
      telefono: json['telefono'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_tienda': idTienda,
      'nombre': nombre,
      'direccion': direccion,
      'coordenadas': coordenadas,
      'telefono': telefono,
    };
  }
}
