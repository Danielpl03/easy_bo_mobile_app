import 'package:hive/hive.dart';

part 'categoria.g.dart'; // Genera el archivo .g.dart

@HiveType(typeId: 14) // Asigna un ID único
class Categoria {
  @HiveField(0)
  final int idCategoria;
  @HiveField(1)
  final int idDepartamento;
  @HiveField(2)
  final String nombre;
  @HiveField(3)
  final bool web;

  Categoria({
    required this.idCategoria,
    required this.idDepartamento,
    required this.nombre,
    this.web = true,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    final id = json['id_categoria'] as int;
    return Categoria(
      idCategoria: id,
      idDepartamento: json['id_departamento'] as int,
      nombre: json['nombre'] as String? ?? 'Categoría $id',
      web: json['web'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_categoria': idCategoria,
      'id_departamento': idDepartamento,
      'nombre': nombre,
      'web': web,
    };
  }
}
