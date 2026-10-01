import 'package:hive/hive.dart';

part 'departamento.g.dart'; // Genera el archivo .g.dart

@HiveType(typeId: 15) // Asigna un ID único
class Departamento {
  @HiveField(0)
  final int idDepartamento;
  @HiveField(1)
  final String nombre;
  @HiveField(2)
  final bool web;
  @HiveField(3)
  final int orden;

  Departamento({
    required this.idDepartamento,
    required this.nombre,
    this.web = true,
    this.orden = 0,
  });

  factory Departamento.fromJson(Map<String, dynamic> json) {
    final id = json['id_departamento'] as int;
    return Departamento(
      idDepartamento: id,
      nombre:
          (json['departamento'] ?? json['nombre']) as String? ??
          'Departamento $id',
      web: json['web'] as bool? ?? true,
      orden: (json['orden'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_departamento': idDepartamento,
      'departamento': nombre,
      'web': web,
      'orden': orden,
    };
  }
}
