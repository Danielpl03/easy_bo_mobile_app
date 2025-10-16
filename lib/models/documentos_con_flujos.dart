import 'package:intl/intl.dart'; // Importar el paquete intl

class DocumentosConFlujos {
  final DateTime fechaI;
  final DateTime fechaF;
  final List<DocumentoDTO> documentoDTOS;
  final List<FlujoCajaDTO> flujosCajaDTOS;

  DocumentosConFlujos({
    required this.fechaI,
    required this.fechaF,
    required this.documentoDTOS,
    required this.flujosCajaDTOS,
  });

  factory DocumentosConFlujos.fromJson(Map<String, dynamic> json) {
    final dateFormat = DateFormat(
      "MMM d, yyyy, h:mm:ss a",
      'en_US',
    ); // Definir el formato de fecha
    return DocumentosConFlujos(
      fechaI: dateFormat.parse(json['fechaI']),
      fechaF: dateFormat.parse(json['fechaF']),
      documentoDTOS:
          (json['documentoDTOS'] as List)
              .map((e) => DocumentoDTO.fromJson(e))
              .toList(),
      flujosCajaDTOS:
          (json['flujosCajaDTOS'] as List)
              .map((e) => FlujoCajaDTO.fromJson(e))
              .toList(),
    );
  }
}

class DocumentoDTO {
  final String idDocumento;
  final DateTime fecha;
  final String tipo;
  final String razon;
  final String? comentario;
  final int? idLocalidad;
  final int? idLocalidadDestino;
  final double importe;
  final double descuento;
  final int? idSistema;
  final int? idUsuario;
  final int consec;
  final bool cancelado;
  List<MovimientoDTO> movimientos;
  List<FlujoCajaDTO> flujosCajas;

  DocumentoDTO({
    required this.idDocumento,
    required this.fecha,
    required this.tipo,
    required this.razon,
    this.comentario,
    this.idLocalidad,
    this.idLocalidadDestino,
    required this.importe,
    required this.descuento,
    this.idSistema,
    this.idUsuario,
    required this.consec,
    required this.cancelado,
    this.movimientos = const [],
    this.flujosCajas = const [],
  });

  factory DocumentoDTO.fromJson(Map<String, dynamic> json) {
    final dateFormat = DateFormat(
      "MMM d, yyyy, h:mm:ss a",
      'en_US',
    ); // Definir el formato de fecha
    return DocumentoDTO(
      idDocumento: json['idDocumento'],
      fecha: dateFormat.parse(json['fecha']),
      tipo: json['tipo'],
      razon: json['razon'],
      comentario: json['comentario'],
      idLocalidad: json['idLocalidad'],
      idLocalidadDestino: json['idLocalidadDestino'],
      importe: (json['importe'] as num).toDouble(),
      descuento: (json['descuento'] as num).toDouble(),
      idSistema: json['idSistema'],
      idUsuario: json['idUsuario'],
      consec: json['consec'],
      cancelado: json['cancelado'],
      movimientos:
          (json['movimientos'] as List)
              .map((e) => MovimientoDTO.fromJson(e))
              .toList(),
      flujosCajas:
          (json['flujosCajas'] as List)
              .map((e) => FlujoCajaDTO.fromJson(e))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_documento': idDocumento,
      'fecha': fecha.toIso8601String(),
      'tipo': tipo,
      'razon': razon,
      'comentario': comentario,
      'id_localidad': idLocalidad,
      'importe': importe,
      'descuento': descuento,
      'id_sistema': idSistema,
      'id_usuario': idUsuario,
      'consec': consec,
      'cancelado': cancelado,
      // Los movimientos y flujos de caja se insertarán/actualizarán por separado
    };
  }
}

class MovimientoDTO {
  final int idMovimiento;
  final ProductoDTO producto;
  final String idDocumento;
  final int cantidad;
  final int? idPago;
  final double precioProducto;
  final double importe;
  final double descuento;
  final int? saldoProducto;
  final bool espejo;

  MovimientoDTO({
    required this.idMovimiento,
    required this.producto,
    required this.idDocumento,
    required this.cantidad,
    this.idPago,
    required this.precioProducto,
    required this.importe,
    required this.descuento,
    this.saldoProducto,
    required this.espejo,
  });

  factory MovimientoDTO.fromJson(Map<String, dynamic> json) {
    return MovimientoDTO(
      idMovimiento: json['idMovimiento'],
      producto: ProductoDTO.fromJson(json['producto']),
      idDocumento: json['idDocumento'],
      cantidad: json['cantidad'],
      idPago: json['idPago'],
      precioProducto: (json['precio_producto'] as num).toDouble(),
      importe: (json['importe'] as num).toDouble(),
      descuento: (json['descuento'] as num).toDouble(),
      saldoProducto: json['saldoProducto'],
      espejo: json['espejo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_movimiento': idMovimiento,
      'producto': producto,
      'id_documento': idDocumento,
      'cantidad': cantidad,
      'id_pago': idPago,
      'precio_producto': precioProducto,
      'importe': importe,
      'descuento': descuento,
      'saldo_producto': saldoProducto,
      'espejo': espejo,
    };
  }

  Map<String, dynamic> toJsonDTO() {
    return {
      'id_producto': producto.idProducto,
      'id_documento': idDocumento,
      'cantidad': cantidad,
      'id_pago': idPago,
      'precio_producto': precioProducto,
      'importe': importe,
      'descuento': descuento,
      'saldo_producto': saldoProducto,
      'espejo': espejo,
    };
  }
}

class ProductoDTO {
    final int idProducto;
    final String descripcion;
    final String? codigo;
    final int idDepartamento;
    final bool ipv;
    final int? idCategoria;
    final bool activo;
    final String? barcode;
    final double? costo;
    final bool combo;
    final bool web;

  List<PrecioDTO> precios = [];
  List<StockDTO> stocks = [];

  ProductoDTO({
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

  factory ProductoDTO.fromJson(Map<String, dynamic> json) {
    print(json);
    return ProductoDTO(
      idProducto: json['idProducto'] as int,
      descripcion: json['descripcion'] as String,
      codigo: json['codigo'] as String?,
      idDepartamento: json['idDepartamento'] as int,
      ipv: json['ipv'] as bool,
      idCategoria: json['idCategoria'] as int?,
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
}

class PrecioDTO {
  final int? idPrecio;
  final int idProducto;
  final int idMoneda;
  final double precio;

  PrecioDTO({
    required this.idPrecio,
    required this.idProducto,
    required this.idMoneda,
    required this.precio,
  });

  factory PrecioDTO.fromJson(Map<String, dynamic> json) {
    return PrecioDTO(
      idPrecio: json['idPrecio'] as int,
      idProducto: json['idProducto'] as int,
      idMoneda: json['idMoneda'] as int,
      precio: (json['precio'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_producto': idProducto,
      'id_moneda': idMoneda,
      'precio': precio,
    };
  }
}

class StockDTO {
  final int? idStock;
  final int idLocalidad;
  final int idProducto;  final int stock;

  StockDTO({
    required this.idStock,
    required this.idLocalidad,
    required this.idProducto,
    required this.stock,
  });

  factory StockDTO.fromJson(Map<String, dynamic> json) {
    return StockDTO(
      idStock: json['idStock'] as int,
      idLocalidad: json['idLocalidad'] as int,
      idProducto: json['idProducto'] as int,
      stock: json['stock'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_localidad': idLocalidad,
      'id_producto': idProducto,
      'stock': stock,
    };
  }
}

class FlujoCajaDTO {
  final int? idFlujo;
  final String? idDocumento;
  final DateTime fecha;
  final String? tipo;
  final String? motivo;
  final num? monto;
  final num importe;
  final int? formaPago;
  final int? idUsuario;
  final int idLocalidad;
  final int idSistema;

  FlujoCajaDTO({
    this.idFlujo,
    required this.tipo,
    required this.motivo,
    required this.importe,
    required this.fecha,
    required this.formaPago,
    this.idDocumento,
    this.monto,
    required this.idLocalidad,
    required this.idSistema,
    required this.idUsuario
  });

  factory FlujoCajaDTO.fromJson(Map<String, dynamic> json) {
    final dateFormat = DateFormat(
      "MMM d, yyyy, h:mm:ss a",
      'en_US',
    ); // Definir el formato de fecha
    return FlujoCajaDTO(
      idFlujo: json['idFlujo'],
      tipo: json['tipo'],
      motivo: json['motivo'],
      importe: (json['importe'] as num).toDouble(),
      fecha: dateFormat.parse(json['fecha']),
      formaPago: json['formaPago'],
      idDocumento: json['idDocumento'],
      monto: (json['monto'] as num?)?.toDouble(),
      idLocalidad: json['idLocalidad'],
      idSistema: json['idSistema'],
      idUsuario: json['idUsuario'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
