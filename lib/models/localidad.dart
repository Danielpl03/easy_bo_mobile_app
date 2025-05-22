import 'package:hive/hive.dart';

part 'localidad.g.dart'; // Genera el archivo .g.dart

@HiveType(typeId: 1) // Asigna un ID único
class Localidad {
  @HiveField(0)
  final int idLocalidad;
  @HiveField(1)
  final String localidad;
  @HiveField(2)
  final int idTienda;
  @HiveField(3)
  final String tipo;

  Localidad({
    required this.idLocalidad,
    required this.localidad,
    required this.idTienda,
    required this.tipo,
  });

  factory Localidad.fromJson(Map<String, dynamic> json) {
    return Localidad(
      idLocalidad: json['id_localidad'] as int,
      localidad: json['localidad'] as String,
      idTienda: json['id_tienda'] as int,
      tipo: json['tipo'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_localidad': idLocalidad,
      'localidad': localidad,
      'id_tienda': idTienda,
      'tipo': tipo,
    };
  }
}
