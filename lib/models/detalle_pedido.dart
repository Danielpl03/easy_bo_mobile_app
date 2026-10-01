import 'package:hive/hive.dart';

part 'detalle_pedido.g.dart';

@HiveType(typeId: 10)
class DetallePedido {
  @HiveField(0)
  final int idPedido;
  
  @HiveField(1)
  final int idProducto;
  
  @HiveField(2)
  final num cantidad;
  

  DetallePedido({
    required this.idPedido,
    required this.idProducto,
    required this.cantidad,
  });

  factory DetallePedido.fromJson(Map<String, dynamic> json) {
    return DetallePedido(
      idPedido: json['id_pedido'] as int,
      idProducto: json['id_producto'] as int,
      cantidad: json['cantidad'] as num,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_pedido': idPedido,
      'id_producto': idProducto,
      'cantidad': cantidad,
    };
  }
}