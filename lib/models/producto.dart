import 'package:easy_bo_mobile_app/models/precio.dart';
import 'package:easy_bo_mobile_app/models/stock.dart';

import 'package:hive/hive.dart';

part 'producto.g.dart'; // Genera el archivo .g.dart

@HiveType(typeId: 4) // Asigna un ID único
class Producto {
  @HiveField(0)
  final int idProducto;

  @HiveField(1)
  final String descripcion;

  @HiveField(2)
  final String? codigo;

  @HiveField(3)
  final int idDepartamento;

  @HiveField(4)
  final bool ipv;

  @HiveField(5)
  final int? idCategoria;

  @HiveField(6)
  final bool activo;

  @HiveField(7)
  final String? barcode;

  @HiveField(8)
  final double? costo;

  @HiveField(9)
  final bool combo;

  @HiveField(10)
  final bool web;

  List<Precio> precios = [];
  List<Stock> stocks = [];

  Producto({
    required this.idProducto,
    required this.descripcion,
    this.codigo,
    required this.idDepartamento,
    required this.ipv,
    this.idCategoria,
    required this.activo,
    this.barcode,
    this.costo,
    required this.combo,
    required this.web,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      idProducto: json['id_producto'] as int,
      descripcion: json['descripcion'] as String,
      codigo: json['codigo'] as String?,
      idDepartamento: json['id_departamento'] as int,
      ipv: json['ipv'] as bool,
      idCategoria: json['id_categoria'] as int?,
      activo: json['activo'] as bool,
      barcode: json['barcode'] as String?,
      costo: (json['costo'] as num?)?.toDouble(),
      combo: json['combo'] as bool,
      web: json['web'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_producto': idProducto,
      'descripcion': descripcion,
      'codigo': codigo,
      'id_departamento': idDepartamento,
      'ipv': ipv,
      'id_categoria': idCategoria,
      'activo': activo,
      'barcode': barcode,
      'costo': costo,
      'combo': combo,
      'web': web,
    };
  }

  String fullDescripction({int precio = 0, bool inversed = false}) {
    String d = '';
    if (inversed) {
      d = codigo != null ? ('$codigo ${descripcion.toUpperCase()}') : descripcion.toUpperCase();
    } else {
      d = codigo != null ? ('${descripcion.toUpperCase()} -${codigo!}') : (descripcion.toUpperCase());
    }

    if(precio > 0){
      final precioP = precios.firstWhere( (p) => p.idMoneda == precio, orElse: () => Precio(idPrecio: 0, idProducto: 0, idMoneda: 0, precio: 0) );
      d = precioP.idPrecio > 0 ? ('$d  \$${precioP.precio}' ) : d;
    }
    return d;
  }
}
