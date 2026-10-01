import 'package:hive/hive.dart';

part 'producto_proveedor.g.dart'; // Genera el archivo .g.dart

@HiveType(typeId: 18) // Asigna un ID único
class ProductoProveedor {
  @HiveField(0)
  final int idRelacion;
  @HiveField(1)
  final int idProducto;
  @HiveField(2)
  final int idProveedor;
  @HiveField(3)
  final num ultimoCosto;

  ProductoProveedor({
    required this.idRelacion,
    required this.idProducto,
    required this.idProveedor,
    required this.ultimoCosto,
  });

  factory ProductoProveedor.fromJson(Map<String, dynamic> json) {
    return ProductoProveedor(
      idRelacion: json['id_relacion'] as int,
      idProducto: json['id_producto'] as int,
      idProveedor: json['id_proveedor'] as int,
      ultimoCosto: json['costo'] as num,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_relacion': idRelacion,
      'id_producto': idProducto,
      'id_proveedor': idProveedor,
      'costo': ultimoCosto,
    };
  }
}
