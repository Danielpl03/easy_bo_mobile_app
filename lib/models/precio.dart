import 'package:hive/hive.dart';

part 'precio.g.dart'; // Genera el archivo .g.dart

@HiveType(typeId: 5) // Asigna un ID único
class Precio {

  @HiveField(0)
  final int idPrecio;
  
  @HiveField(1)
  final int idProducto;
  
  @HiveField(2)
  final int idMoneda;
  
  @HiveField(3)
  final double precio;

  Precio({
    required this.idPrecio,
    required this.idProducto,
    required this.idMoneda,
    required this.precio,
  });

  factory Precio.fromJson(Map<String, dynamic> json) {
    return Precio(
      idPrecio: json['id_precio'] as int,
      idProducto: json['id_producto'] as int,
      idMoneda: json['id_moneda'] as int,
      precio: (json['precio'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_precio': idPrecio,
      'id_producto': idProducto,
      'id_moneda': idMoneda,
      'precio': precio,
    };
  }
}
