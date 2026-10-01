import 'package:hive/hive.dart';

part 'producto_imagen.g.dart';

@HiveType(typeId: 19)
class ProductoImagen {
  @HiveField(0)
  final int idRelacion;

  @HiveField(1)
  final int idProducto;

  @HiveField(2)
  final String nombre;

  @HiveField(3)
  final String ext;

  @HiveField(4)
  final bool principal;

  ProductoImagen({
    required this.idRelacion,
    required this.idProducto,
    required this.nombre,
    required this.ext,
    required this.principal,
  });

  factory ProductoImagen.fromJson(Map<String, dynamic> json) {
    return ProductoImagen(
      idRelacion: json['id_relacion'] as int,
      idProducto: json['id_producto'] as int,
      nombre: json['nombre'] as String,
      ext: json['ext'] as String,
      principal: json['principal'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_relacion': idRelacion,
      'id_producto': idProducto,
      'nombre': nombre,
      'ext': ext,
      'principal': principal,
    };
  }

  ProductoImagen copyWith({bool? principal}) {
    return ProductoImagen(
      idRelacion: idRelacion,
      idProducto: idProducto,
      nombre: nombre,
      ext: ext,
      principal: principal ?? this.principal,
    );
  }

  /// Clave del archivo en Supabase Storage: nombre formateado + id de relación.
  String get storageKey {
    final formatted =
        nombre
            .replaceAll(RegExp(r'[<>:"/\\|?*¨ñÑ&ÁÉÍÓÚÜ]'), '_')
            .replaceAll(' ', '_')
            .toUpperCase();
    return '${formatted}_$idRelacion';
  }

  /// Alias usado en operaciones de storage (subida, borrado, descarga).
  String get nombreArchivo => storageKey;

  String url(String baseUrl) => '$baseUrl$storageKey';
}
