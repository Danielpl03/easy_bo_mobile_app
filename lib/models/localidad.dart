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
  @HiveField(4)
  final bool ipv;

  Localidad({
    required this.idLocalidad,
    required this.localidad,
    required this.idTienda,
    required this.tipo,
    required this.ipv,
  });

  factory Localidad.fromJson(Map<String, dynamic> json) {
    return Localidad(
      idLocalidad: json['id_localidad'] as int,
      localidad: json['localidad'] as String,
      idTienda: json['id_tienda'] as int,
      tipo: json['tipo'] as String,
      ipv: json['ipv'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_localidad': idLocalidad,
      'localidad': localidad,
      'id_tienda': idTienda,
      'tipo': tipo,
      'ipv': ipv
    };
  }
}
