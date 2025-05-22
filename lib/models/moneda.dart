
import 'package:hive/hive.dart';

part 'moneda.g.dart'; // Genera el archivo .g.dart

@HiveType(typeId: 2) // Asigna un ID único
class Moneda {

  @HiveField(0)
  final int idMoneda; 
  
  @HiveField(1)
  final String nombre;
  
  @HiveField(2)
  final String siglas;
  
  @HiveField(3)
  final bool porDefecto;
  
  @HiveField(4)
  final double tazaCambio;

  Moneda({
    required this.idMoneda,
    required this.nombre,
    required this.siglas,
    required this.porDefecto,
    required this.tazaCambio,
  });

  factory Moneda.fromJson(Map<String, dynamic> json) {
    return Moneda(
      idMoneda: json['id_moneda'] as int,
      nombre: json['nombre'] as String,
      siglas: json['siglas'] as String,
      porDefecto: json['por_defecto'] as bool? ?? false,
      tazaCambio: (json['taza_cambio'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_moneda': idMoneda,
      'nombre': nombre,
      'siglas': siglas,
      'por_defecto': porDefecto,
      'taza_cambio': tazaCambio,
    };
  }
} 