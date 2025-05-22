import 'package:easy_bo_mobile_app/models/detalle_pedido.dart';
import 'package:hive/hive.dart';

part 'pedido.g.dart';

@HiveType(typeId: 9)
class Pedido {
  @HiveField(0)
  final int idPedido;
  
  @HiveField(1)
  final DateTime fecha;
  
  @HiveField(2)
  final int idTienda;
  
  @HiveField(3)
  final String estado;
  
  @HiveField(4)
  final String? observaciones;

  List<DetallePedido> detalles = [];

  Pedido({
    required this.idPedido,
    required this.fecha,
    required this.idTienda,
    this.estado = 'PENDIENTE',
    this.observaciones,
    detalles = const []
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      idPedido: json['id_pedido'] as int,
      fecha: DateTime.parse(json['fecha'] as String),
      idTienda: json['id_tienda'] as int,
      estado: json['estado'] as String,
      observaciones: json['observaciones'] as String?,
      detalles: (json['detalles'] as List) 
          .map((d) => DetallePedido.fromJson(d))
          .toList(),
    );
  }

  Pedido copyWith({
    int? idPedido,
    DateTime? fecha,
    int? idTienda,
    String? estado,
    String? observaciones,
    List<DetallePedido>? detalles,
  }) {
    return Pedido(
      idPedido: idPedido ?? this.idPedido,
      fecha: fecha ?? this.fecha,
      idTienda: idTienda ?? this.idTienda,
      estado: estado ?? this.estado,
      observaciones: observaciones ?? this.observaciones,
      detalles: detalles ?? this.detalles,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_pedido': idPedido,
      'fecha': fecha.toIso8601String(),
      'id_tienda': idTienda,
      'estado': estado,
      'observaciones': observaciones,
      'detalles' : detalles
    };
  }
}