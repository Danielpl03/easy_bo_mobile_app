import 'package:hive/hive.dart';

part 'pago.g.dart'; // Genera el archivo .g.dart

@HiveType(typeId: 3) // Asigna un ID único
class Pago {

  @HiveField(0)
  final int idPago;
  
  @HiveField(1)
  final String tipoPago; // Nombre del pago
  
  @HiveField(2)
  final int idMoneda; // ID de la moneda utilizada para el pago
  
  @HiveField(3)
  final bool efectivo; // Indica si el pago fue en efectivo

  Pago({
    required this.idPago,
    required this.tipoPago,
    required this.idMoneda,
    required this.efectivo,
  });

  factory Pago.fromJson(Map<String, dynamic> json) {
    return Pago(
      idPago: json['id_pago'],
      tipoPago: json['tipo_pago'],
      idMoneda: json['id_moneda'],
      efectivo: json['efectivo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_pago': idPago,
      'tipo_pago': tipoPago,
      'id_moneda': idMoneda,
      'efectivo': efectivo,
    };
  }
}