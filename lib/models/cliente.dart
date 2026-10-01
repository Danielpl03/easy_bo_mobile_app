import 'package:hive/hive.dart';

part 'cliente.g.dart'; // Genera el archivo .g.dart

@HiveType(typeId: 17) // Asigna un ID único
class Cliente {
  @HiveField(0)
  final int idCliente;
  @HiveField(1)
  final String nombre;
  @HiveField(2)
  final num? gastoLimite;
  @HiveField(3)
  final num? gastoActual;

  Cliente({
    required this.idCliente,
    required this.nombre,
    this.gastoLimite,
    this.gastoActual,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      idCliente: json['id_cliente'] as int,
      nombre: json['nombre'] as String,
      gastoLimite: (json['gasto_limite'] as num?),
      gastoActual: (json['gasto_actual'] as num?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_cliente': idCliente,
      'nombre': nombre,
      'gasto_limite': gastoLimite,
      'gasto_actual': gastoActual,
    };
  }
}
