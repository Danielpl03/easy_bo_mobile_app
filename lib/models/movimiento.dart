import 'package:easy_bo_mobile_app/models/producto.dart';
import 'package:hive/hive.dart';

part 'movimiento.g.dart'; // Genera el archivo .g.dart

@HiveType(typeId: 8) 
class Movimiento {

  @HiveField(0)
  final int idMovimiento;
  
  @HiveField(1)
  final int idProducto; // ID del producto asociado al movimiento
  
  @HiveField(2)
  final int cantidad; // Cantidad del producto en el movimiento
  
  @HiveField(3)
  final num precioProducto; // Precio del producto
  
  @HiveField(4)
  final int? idDescuento; // ID del descuento aplicado, si lo hay
  
  @HiveField(5)
  final int? idPago; // ID del pago asociado, si lo hay
  
  @HiveField(6)
  final num? importe; // Importe total del movimiento
  
  @HiveField(7)
  final int? saldoProducto; // Saldo del producto después del movimiento
  
  @HiveField(8)
  final bool espejo; // Indica si es un movimiento espejo
  
  @HiveField(9)
  final String idDocumento; // ID del documento asociado al movimiento
  
  @HiveField(10)
  final num? descuento; // Descuento aplicado al movimiento

  Producto? producto;


  Movimiento({
    required this.idMovimiento,
    required this.idProducto,
    required this.cantidad,
    required this.precioProducto,
    this.idDescuento,
    this.idPago,
    this.importe,
    this.saldoProducto,
    required this.espejo,
    required this.idDocumento,
    this.descuento,
  });

  factory Movimiento.fromJson(Map<String, dynamic> json) {
    return Movimiento(
      idMovimiento: json['id_movimiento'],
      idProducto: json['id_producto'],
      cantidad: json['cantidad'],
      precioProducto: json['precio_producto'],
      idDescuento: json['id_descuento'],
      idPago: json['id_pago'],
      importe: json['importe'],
      saldoProducto: json['saldo_producto'],
      espejo: json['espejo'],
      idDocumento: json['id_documento'],
      descuento: json['descuento'],
    );
  }

  @override
  String toString() => 'Mov: $idMovimiento | $idProducto | $importe';

  Map<String, dynamic> toJson() {
    return {
      'id_movimiento': idMovimiento,
      'id_producto': idProducto,
      'cantidad': cantidad,
      'precio_producto': precioProducto,
      'id_descuento': idDescuento,
      'id_pago': idPago,
      'importe': importe,
      'saldo_producto': saldoProducto,
      'espejo': espejo,
      'id_documento': idDocumento,
      'descuento': descuento,
    };
  }
}