
import 'package:easy_bo_mobile_app/models/movimiento.dart';
import 'package:hive/hive.dart';

part 'documento.g.dart'; // Genera el archivo .g.dart

@HiveType(typeId: 7) 
class Documento {

  @HiveField(0)
  final int consec;
  
  @HiveField(1)
  final DateTime fecha;
  
  @HiveField(2)
  final String tipo;
  
  @HiveField(3)
  final String razon;
  
  @HiveField(4)
  final String? comentario;
  
  @HiveField(5)
  final int? idLocalidad;
  
  @HiveField(6)
  final num importe;
  
  @HiveField(7)
  final num? descuento;
  
  @HiveField(8)
  final int idSistema;
  
  @HiveField(9)
  final int idUsuario;
  
  @HiveField(10)
  final num cambio;
  
  @HiveField(11)
  final int? idLocalidadDestino;
  
  @HiveField(12)
  final String idDocumento;
  
  @HiveField(13)
  final bool cancelado;

  List<Movimiento> movimientos = [];

  Documento({
    required this.consec,
    required this.fecha,
    required this.tipo,
    required this.razon,
    this.comentario,
    this.idLocalidad,
    required this.importe,
    this.descuento,
    required this.idSistema,
    required this.idUsuario,
    required this.cambio,
    this.idLocalidadDestino,
    required this.idDocumento,
    required this.cancelado,
  });

  factory Documento.fromJson(Map<String, dynamic> json) {
    return Documento(
      consec: json['consec'] as int,
      fecha: DateTime.parse(json['fecha'] as String),
      tipo: json['tipo'] as String,
      razon: json['razon'] as String,
      comentario: json['comentario'] as String?,
      idLocalidad: json['id_localidad'] as int?,
      importe: json['importe'] ,
      descuento: json['descuento'] ,
      idSistema: json['id_sistema'] as int,
      idUsuario: json['id_usuario'] as int,
      cambio: json['cambio'],
      idLocalidadDestino: json['id_localidad_destino'] as int?,
      idDocumento: json['id_documento'] as String,
      cancelado: json['cancelado'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'consec': consec,
      'fecha': fecha.toIso8601String(),
      'tipo': tipo,
      'razon': razon,
      'comentario': comentario,
      'id_localidad': idLocalidad,
      'importe': importe,
      'descuento': descuento,
      'id_sistema': idSistema,
      'id_usuario': idUsuario,
      'cambio': cambio,
      'id_localidad_destino': idLocalidadDestino,
      'id_documento': idDocumento,
      'cancelado': cancelado,
    };
  }
} 