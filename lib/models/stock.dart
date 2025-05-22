import 'package:hive/hive.dart';

part 'stock.g.dart'; // Genera el archivo .g.dart

@HiveType(typeId: 6) // Asigna un ID único
class Stock {

  @HiveField(0)
  final int idStock;
  
  @HiveField(1)
  final int idLocalidad;
  
  @HiveField(2)
  final int idProducto;

  @HiveField(3)
  final int stock;

  Stock({
    required this.idStock,
    required this.idLocalidad,
    required this.idProducto,
    required this.stock,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      idStock: json['id_stock'] as int,
      idLocalidad: json['id_localidad'] as int,
      idProducto: json['id_producto'] as int,
      stock: json['stock'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_stock': idStock,
      'id_localidad': idLocalidad,
      'id_producto': idProducto,
      'stock': stock,
    };
  }
}
