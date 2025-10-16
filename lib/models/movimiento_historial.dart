import 'package:easy_bo_mobile_app/models/documento.dart';
import 'package:easy_bo_mobile_app/models/movimiento.dart';

class MovimientoHistorial extends Movimiento {
  final Documento documento;

  MovimientoHistorial({
    required super.idMovimiento,
    required super.idDocumento,
    required super.idProducto,
    required super.cantidad,
    required super.precioProducto,
    required super.importe,
    required super.descuento,
    required super.espejo,
    required super.idPago,
    required super.saldoProducto,
    required this.documento,
  });

  factory MovimientoHistorial.fromMovimiento(Movimiento movimiento, Documento documento) {
    return MovimientoHistorial(
      idMovimiento: movimiento.idMovimiento,
      idDocumento: movimiento.idDocumento,
      idProducto: movimiento.idProducto,
      cantidad: movimiento.cantidad,
      precioProducto: movimiento.precioProducto,
      importe: movimiento.importe,
      descuento: movimiento.descuento,
      espejo: movimiento.espejo,
      idPago: movimiento.idPago,
      saldoProducto: movimiento.saldoProducto,
      documento: documento,
    );
  }
} 