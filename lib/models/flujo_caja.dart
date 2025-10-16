import 'package:hive/hive.dart';
import 'package:easy_bo_mobile_app/models/localidad.dart';

part 'flujo_caja.g.dart';

@HiveType(typeId: 12)
class FlujoCaja {
  @HiveField(0)
  final int idFlujo;

  @HiveField(1)
  final String tipo;

  @HiveField(2)
  final String motivo;

  @HiveField(3)
  final num importe;

  @HiveField(4)
  final DateTime fecha;

  @HiveField(5)
  final int formaPago;

  @HiveField(6)
  final String? idDocumento;

  @HiveField(7)
  final num? monto;

  @HiveField(8)
  final int idLocalidad;

  @HiveField(9)
  final int idSistema;

  @HiveField(10)
  final Localidad? localidad;

@HiveField(11)
  final int? idUsuario;

  FlujoCaja({
    required this.idFlujo,
    required this.tipo,
    required this.motivo,
    required this.importe,
    required this.fecha,
    required this.formaPago,
    this.idDocumento,
    this.monto,
    required this.idLocalidad,
    required this.idSistema,
    required this.idUsuario,
    this.localidad,
  });

  factory FlujoCaja.fromJson(Map<String, dynamic> json) {
    return FlujoCaja(
      idFlujo: json['id_flujo'],
      tipo: json['tipo'],
      motivo: json['motivo'],
      importe: json['importe'],
      fecha: DateTime.parse(json['fecha']),
      formaPago: json['forma_pago'],
      idDocumento: json['id_documento'],
      monto: json['monto'],
      idLocalidad: json['id_localidad'],
      idSistema: json['id_sistema'],
      idUsuario: json['id_usuario'],
      localidad: json['localidad'] != null ? Localidad.fromJson(json['localidad']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_flujo': idFlujo,
      'tipo': tipo,
      'motivo': motivo,
      'importe': importe,
      'fecha': fecha.toIso8601String(),
      'forma_pago': formaPago,
      'id_documento': idDocumento,
      'monto': monto,
      'id_localidad': idLocalidad,
      'id_sistema': idSistema,
      'id_usuario': idUsuario,
    };
  }
} 