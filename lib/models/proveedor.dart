import 'package:hive/hive.dart';

part 'proveedor.g.dart'; // Genera el archivo .g.dart

@HiveType(typeId: 16) // Asigna un ID único
class Proveedor {
  @HiveField(0)
  final int idProveedor;
  @HiveField(1)
  final String nombre;

  Proveedor({required this.idProveedor, required this.nombre});

  factory Proveedor.fromJson(Map<String, dynamic> json) {
    return Proveedor(
      idProveedor: json['id_proveedor'] as int,
      nombre: json['nombre'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id_proveedor': idProveedor, 'nombre': nombre};
  }
}
