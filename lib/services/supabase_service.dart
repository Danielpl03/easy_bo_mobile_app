import 'package:easy_bo_mobile_app/models/documento.dart';
import 'package:easy_bo_mobile_app/models/moneda.dart';
import 'package:easy_bo_mobile_app/models/movimiento.dart';
import 'package:easy_bo_mobile_app/models/pago.dart' show Pago;
import 'package:easy_bo_mobile_app/models/producto.dart';
import 'package:easy_bo_mobile_app/models/flujo_caja.dart';
import 'package:easy_bo_mobile_app/models/documentos_con_flujos.dart'; // Importar el nuevo modelo de ventas
import 'package:easy_bo_mobile_app/models/cliente.dart';
import 'package:easy_bo_mobile_app/models/proveedor.dart';
import 'package:easy_bo_mobile_app/models/producto_proveedor.dart';
import 'package:easy_bo_mobile_app/models/producto_imagen.dart';
import 'package:easy_bo_mobile_app/models/categoria.dart';
import 'package:easy_bo_mobile_app/models/departamento.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tienda.dart';
import '../models/precio.dart';
import '../models/localidad.dart';
import '../models/stock.dart';

/// Resultado de la sincronización de un documento individual
class DocumentoSyncResult {
  final String idDocumento;
  final String tipo;
  final int consec;
  final bool exito;
  final String? error;
  final int movimientosProcesados;
  final int movimientosExitosos;
  final int flujosCajaProcesados;
  final int flujosCajaExitosos;

  DocumentoSyncResult({
    required this.idDocumento,
    required this.tipo,
    required this.consec,
    required this.exito,
    this.error,
    this.movimientosProcesados = 0,
    this.movimientosExitosos = 0,
    this.flujosCajaProcesados = 0,
    this.flujosCajaExitosos = 0,
  });

  String get descripcion => 'Doc #$consec ($tipo)';
}

/// Resultado completo de la sincronización
class SyncResult {
  final int totalDocumentos;
  final int documentosExitosos;
  final int documentosFallidos;
  final List<DocumentoSyncResult> resultados;
  final DateTime fechaInicio;
  final DateTime? fechaFin;

  SyncResult({
    required this.totalDocumentos,
    required this.documentosExitosos,
    required this.documentosFallidos,
    required this.resultados,
    required this.fechaInicio,
    this.fechaFin,
  });

  Duration get duracion =>
      fechaFin != null
          ? fechaFin!.difference(fechaInicio)
          : DateTime.now().difference(fechaInicio);

  bool get completado => fechaFin != null;
  double get porcentajeCompletado =>
      totalDocumentos > 0
          ? (documentosExitosos + documentosFallidos) / totalDocumentos
          : 0.0;
}

class SupabaseService {
  final SupabaseClient _supabaseClient;

  SupabaseService(this._supabaseClient);

  // Tiendas
  Future<List<Tienda>> getTiendas() async {
    final response = await _supabaseClient
        .from('tiendas')
        .select()
        .order('nombre');
    return (response as List).map((json) => Tienda.fromJson(json)).toList();
  }

  Future<Tienda?> getTienda(int id) async {
    final response =
        await _supabaseClient
            .from('tiendas')
            .select()
            .eq('id_tienda', id)
            .single();
    return response != null ? Tienda.fromJson(response) : null;
  }

  Future<List<Localidad>> getLocalidades() async {
    final response = await _supabaseClient
        .from('localidades')
        .select()
        .order('localidad');
    return (response as List).map((json) => Localidad.fromJson(json)).toList();
  }

  Future<Localidad?> getLocalidad(int id) async {
    final response =
        await _supabaseClient
            .from('localidad')
            .select()
            .eq('id_localidad', id)
            .single();
    return response != null ? Localidad.fromJson(response) : null;
  }

  Future<List<Producto>> getProductos() async {
    try {
      final response = await _getFromSupabase('productos');

      final productos =
          (response as List).map((json) {
            return Producto.fromJson(json);
          }).toList();
      print('Productos procesados correctamente: ${productos.length}');
      return productos;
    } catch (e) {
      rethrow;
    }
  }

  Future<Producto> insertProducto({
    required String descripcion,
    String? codigo,
    required int idDepartamento,
    required bool ipv,
    int? idCategoria,
    required bool activo,
    String? barcode,
    num? costo,
    required bool combo,
    required bool web,
    int? idMonedaCosto,
  }) async {
    final response =
        await _supabaseClient
            .from('productos')
            .insert({
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
              'id_moneda_costo': idMonedaCosto,
            })
            .select()
            .single();
    return Producto.fromJson(response);
  }

  Future<void> updateProducto(Producto producto) async {
    final data = producto.toJson();
    data.remove('id_producto');
    await _supabaseClient
        .from('productos')
        .update(data)
        .eq('id_producto', producto.idProducto);
  }

  Future<List<Precio>> upsertPrecios(List<Precio> precios) async {
    if (precios.isEmpty) return [];

    final preciosJson =
        precios.map((p) {
          final json = <String, dynamic>{
            'id_producto': p.idProducto,
            'id_moneda': p.idMoneda,
            'precio': p.precio,
          };
          if (p.idPrecio > 0) json['id_precio'] = p.idPrecio;
          return json;
        }).toList();

    final response = await _supabaseClient
        .from('precios')
        .upsert(preciosJson, onConflict: 'id_producto, id_moneda')
        .select();

    return (response as List).map((json) => Precio.fromJson(json)).toList();
  }

  Future<List<Precio>> getPrecios() async {
    try {
      final response = await _getFromSupabase('precios');

      final precios =
          (response as List).map((json) {
            return Precio.fromJson(json);
          }).toList();

      print('precios procesados correctamente: ${precios.length}');
      return precios;
    } catch (e) {
      print('Error al procesar precios: $e');
      rethrow;
    }
  }

  Future<List<Stock>> getStocks({List<int>? localidades, int? producto}) async {
    try {
      final where =
          localidades != null
              ? 'id_localidad'
              : producto != null
              ? 'id_producto'
              : null;

      final response =
          localidades != null
              ? await _getFromSupabase(
                'stocks',
                where: where,
                whereIn: localidades,
              )
              : producto != null
              ? await _getFromSupabase(
                'stocks',
                where: 'id_producto',
                whereEq: producto,
              )
              : await _getFromSupabase('stocks');

      final stocks =
          (response as List).map((json) {
            return Stock.fromJson(json);
          }).toList();

      print('stocks procesados correctamente: ${stocks.length}');
      return stocks;
    } catch (e) {
      print('Error al procesar stocks: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _getFromSupabase(
    String tableName, {
    String? orderBy,
    bool asc = true,
    String? where,
    List<Object>? whereIn,
    Object? whereEq,
    PostgrestFilterBuilder<List<Map<String, dynamic>>>? queryP,
  }) async {
    try {
      print('Iniciando consulta a Supabase para $tableName...');
      List<Map<String, dynamic>> registros = [];
      int offset = 0;
      const int limit = 1000;
      bool hayMasRegistros = true;

      while (hayMasRegistros) {
        // print('Consultando registros desde offset $offset...');
        PostgrestFilterBuilder<List<Map<String, dynamic>>> query =
            _supabaseClient.from(tableName).select('*');
        if (queryP == null) {
          if (where != null && whereIn != null) {
            query = query.inFilter(where, whereIn);
          } else if (where != null && whereEq != null) {
            query = query.eq(where, whereEq);
          }

          if (orderBy != null) {
            query.order(orderBy, ascending: asc);
          }
        } else {
          query = queryP;
        }

        final fQuery = query.range(offset, offset + limit - 1);

        final response = await fQuery;
        if (response.isEmpty) {
          break;
        }

        registros.addAll(response);

        // print('Registros procesados correctamente: ${registros.length}');

        if (response.length < limit) {
          hayMasRegistros = false;
        } else {
          offset += limit;
        }
      }

      print('Total de registros obtenidos de Supabase: ${registros.length}');
      return registros;
    } catch (_) {
      rethrow;
    }
  }

  Future<List<Moneda>> getMonedas() async {
    print('Obteniendo monedas de Supabase');
    final response = await _supabaseClient
        .from('monedas')
        .select()
        .order('id_moneda');
    return (response as List).map((json) => Moneda.fromJson(json)).toList();
  }

  Future<List<Pago>> getPagos() async {
    print('Obteniendo Pagos de Supabase');
    final response = await _supabaseClient.from('pagos').select();
    return (response as List).map((json) => Pago.fromJson(json)).toList();
  }

  Future<List<Documento>> getDocumentos({
    String? tipo,
    DateTime? start,
    DateTime? end,
    // bool moves = false
  }) async {
    print('Obteniendo Documentos de Supabase desde $start hasta $end');
    // String select = moves ? '*' : '*, movimientos(*)';
    PostgrestFilterBuilder<List<Map<String, dynamic>>> query =
        _supabaseClient.from('documentos').select();

    if (start != null) {
      query = query.gte('fecha', start);
    }
    if (end != null) {
      query = query.lte('fecha', end);
    }
    if (tipo != null) {
      query = query.eq('tipo', tipo);
    }

    final response = await _getFromSupabase('documentos', queryP: query);

    return (response as List).map((json) => Documento.fromJson(json)).toList();
  }

  Future<List<Movimiento>> getMovimientosByIdD(String idDocumento) async {
    print('Obteniendo Movimientos de Supabase');
    final response = await _supabaseClient
        .from('movimientos')
        .select()
        .eq('id_documento', idDocumento);
    return (response as List).map((json) => Movimiento.fromJson(json)).toList();
  }

  Future<List<Movimiento>> getMovimientosByDocuments(
    List<Documento> documentos,
  ) async {
    print(
      '📥 [SupabaseService] Obteniendo Movimientos de Supabase para ${documentos.length} documentos',
    );
    final List<String> ids = documentos.map((d) => d.idDocumento).toList();

    final length = ids.length;
    const limit = 100;
    int start = 0;
    int end = start + limit;
    List<String> batchIds = [];
    List<Map<String, dynamic>> registros = [];

    do {
      // Asegurar que se seleccionen todos los campos, incluyendo costo_producto
      PostgrestFilterBuilder<List<Map<String, dynamic>>> query = _supabaseClient
          .from('movimientos')
          .select('*');
      batchIds = ids.sublist(start, end < length ? end : length);
      query = query.inFilter('id_documento', batchIds);

      start = end;
      end = start + limit;
      final response = await _getFromSupabase('movimientos', queryP: query);

      print(
        '📥 [SupabaseService] Lote ${start ~/ limit + 1}: ${response.length} movimientos obtenidos',
      );

      // Log de muestra de los primeros movimientos para verificar costo_producto
      if (response.isNotEmpty) {
        final muestra = response.take(3).toList();
        for (var mov in muestra) {
          final keys = mov.keys.toList();
          final tieneCostoProducto = mov.containsKey('costo_producto');
          print(
            '📊 [SupabaseService] Muestra movimiento id=${mov['id_movimiento']}:',
          );
          print('   - Campos disponibles: ${keys.join(", ")}');
          print('   - Tiene costo_producto: $tieneCostoProducto');
          print('   - costo_producto valor: ${mov['costo_producto']}');
          print('   - importe: ${mov['importe']}');
        }
      }

      registros.addAll(response);
    } while (start < length);

    print(
      '📥 [SupabaseService] Total movimientos obtenidos: ${registros.length}',
    );

    final movimientos =
        (registros as List).map((json) => Movimiento.fromJson(json)).toList();

    // Contar movimientos con costo
    final conCosto =
        movimientos
            .where((m) => m.costoProducto != null && m.costoProducto! > 0)
            .length;
    print(
      '💰 [SupabaseService] Movimientos con costo: $conCosto de ${movimientos.length}',
    );

    return movimientos;
  }

  Future<List<FlujoCaja>> getFlujosCaja({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    PostgrestFilterBuilder<List<Map<String, dynamic>>> query = _supabaseClient
        .from('flujos_caja')
        .select('*, localidad:id_localidad(*)');

    if (fechaInicio != null) {
      final inicio = DateTime(
        fechaInicio.year,
        fechaInicio.month,
        fechaInicio.day,
      );
      query = query.gte('fecha', inicio);
    }
    if (fechaFin != null) {
      final fin = DateTime(
        fechaFin.year,
        fechaFin.month,
        fechaFin.day,
        23,
        59,
        59,
      );
      query = query.lte('fecha', fin);
    }
    final response = await _getFromSupabase('flujos_caja', queryP: query);
    return (response as List).map((json) => FlujoCaja.fromJson(json)).toList();
  }

  // Clientes
  Future<List<Cliente>> getClientes() async {
    print('Obteniendo Clientes de Supabase');
    final response = await _getFromSupabase('clientes', orderBy: 'nombre');
    return (response as List).map((json) => Cliente.fromJson(json)).toList();
  }

  Future<Cliente?> getClientePorId(int idCliente) async {
    try {
      final response =
          await _supabaseClient
              .from('clientes')
              .select()
              .eq('id_cliente', idCliente)
              .single();
      return response != null ? Cliente.fromJson(response) : null;
    } catch (e) {
      print('⚠️ [SupabaseService] Error al obtener cliente $idCliente: $e');
      return null;
    }
  }

  // Proveedores
  Future<List<Proveedor>> getProveedores() async {
    print('Obteniendo Proveedores de Supabase');
    final response = await _getFromSupabase('proveedores');
    return (response as List).map((json) => Proveedor.fromJson(json)).toList();
  }

  Future<Proveedor?> getProveedorPorId(int idProveedor) async {
    try {
      final response =
          await _supabaseClient
              .from('proveedores')
              .select()
              .eq('id_proveedor', idProveedor)
              .single();
      return response != null ? Proveedor.fromJson(response) : null;
    } catch (e) {
      print('⚠️ [SupabaseService] Error al obtener proveedor $idProveedor: $e');
      return null;
    }
  }

  // Productos Imagenes
  Future<List<ProductoImagen>> getProductosImagenes() async {
    print('Obteniendo Productos Imagenes de Supabase');
    final response = await _getFromSupabase('productos_imagenes');
    return (response as List)
        .map((json) => ProductoImagen.fromJson(json))
        .toList();
  }

  Future<ProductoImagen> insertProductoImagen({
    required int idProducto,
    required String nombre,
    required String ext,
    required bool principal,
  }) async {
    if (principal) {
      await _supabaseClient
          .from('productos_imagenes')
          .update({'principal': false})
          .eq('id_producto', idProducto);
    }

    final response =
        await _supabaseClient
            .from('productos_imagenes')
            .insert({
              'id_producto': idProducto,
              'nombre': nombre,
              'ext': ext,
              'principal': principal,
            })
            .select()
            .single();

    return ProductoImagen.fromJson(response);
  }

  Future<void> deleteProductoImagen(int idRelacion) async {
    await _supabaseClient
        .from('productos_imagenes')
        .delete()
        .eq('id_relacion', idRelacion);
  }

  Future<void> setImagenPrincipal(int idProducto, int idRelacion) async {
    await _supabaseClient
        .from('productos_imagenes')
        .update({'principal': false})
        .eq('id_producto', idProducto);
    await _supabaseClient
        .from('productos_imagenes')
        .update({'principal': true})
        .eq('id_relacion', idRelacion);
  }

  // Productos Proveedores
  Future<List<ProductoProveedor>> getProductosProveedores() async {
    print('Obteniendo Productos Proveedores de Supabase');
    final response = await _getFromSupabase('productos_proveedores');
    return (response as List)
        .map((json) => ProductoProveedor.fromJson(json))
        .toList();
  }

  Future<List<ProductoProveedor>> getProductosProveedoresByProveedor(
    int idProveedor,
  ) async {
    print('Obteniendo Productos Proveedores para $idProveedor de Supabase');
    final response = await _getFromSupabase(
      'productos_proveedores',
      where: 'id_proveedor',
      whereEq: idProveedor,
    );
    return (response as List)
        .map((json) => ProductoProveedor.fromJson(json))
        .toList();
  }

  // Categorias visibles (web != false; null se trata como visible)
  Future<List<Categoria>> getCategorias() async {
    print('Obteniendo Categorias de Supabase');
    final response = await _getFromSupabase('categorias', orderBy: 'nombre');
    return (response as List)
        .map((json) => Categoria.fromJson(json))
        .where((c) => c.web)
        .toList();
  }

  // Departamentos visibles, ordenados por campo orden
  Future<List<Departamento>> getDepartamentos() async {
    print('Obteniendo Departamentos de Supabase');
    final response = await _getFromSupabase('departamentos', orderBy: 'orden');
    return (response as List)
        .map((json) => Departamento.fromJson(json))
        .where((d) => d.web)
        .toList()
      ..sort((a, b) => a.orden.compareTo(b.orden));
  }

  /// Procesa un documento individual con todos sus movimientos y flujos de caja
  Future<DocumentoSyncResult> _procesarDocumentoIndividual(
    DocumentoDTO documento,
    List<Pago> pagos,
  ) async {
    try {
      // 1. Upsert del documento (solo si no está cancelado)
      if (!documento.cancelado) {
        final docJson = documento.toJson();
        await _supabaseClient.from('documentos').upsert([
          docJson,
        ], onConflict: 'consec, id_sistema');
        print(
          '[SupabaseService] ✓ Documento ${documento.idDocumento} (consec: ${documento.consec}) insertado/actualizado',
        );
      } else {
        print(
          '[SupabaseService] ⊘ Documento ${documento.idDocumento} (consec: ${documento.consec}) está cancelado, se omite',
        );
      }

      // 2. Preparar productos y precios si es necesario
      List<ProductoDTO> productos = [];
      final Map<int, Map<int, PrecioDTO>> preciosMap = {};
      final Map<int, Map<int, StockDTO>> stockMap = {};

      if (documento.tipo == "CREADO" || documento.tipo == "MODIFICADO") {
        for (final mov in documento.movimientos) {
          productos.add(mov.producto);
          preciosMap.putIfAbsent(mov.producto.idProducto, () => {});

          int idMoneda =
              mov.idPago != null
                  ? (pagos.where((p) => p.idPago == mov.idPago).first.idMoneda)
                  : 1;

          preciosMap[mov.producto.idProducto]![idMoneda] = PrecioDTO(
            idPrecio: null,
            idProducto: mov.producto.idProducto,
            idMoneda: idMoneda,
            precio: mov.importe ?? 0,
          );
        }
      } else {
        if (documento.idLocalidad != null) {
          for (final mov in documento.movimientos) {
            if (mov.saldoProducto != null) {
              int idLocalidad =
                  mov.espejo
                      ? documento.idLocalidadDestino!
                      : documento.idLocalidad!;
              stockMap.putIfAbsent(mov.producto.idProducto, () => {});
              stockMap[mov.producto.idProducto]![idLocalidad] = StockDTO(
                idStock: null,
                idLocalidad: idLocalidad,
                idProducto: mov.producto.idProducto,
                stock: mov.saldoProducto!,
              );
            }
          }
        }
      }

      // 3. Upsert productos (si hay)
      if (productos.isNotEmpty) {
        final productosJson = productos.map((p) => p.toJson()).toList();
        await _supabaseClient
            .from('productos')
            .upsert(productosJson, onConflict: 'id_producto');
        print(
          '[SupabaseService] ✓ ${productos.length} productos procesados para documento ${documento.idDocumento}',
        );
      }

      // 4. Insertar movimientos uno por uno para mejor control de errores
      int movimientosExitosos = 0;
      int movimientosProcesados = documento.movimientos.length;

      for (final movimiento in documento.movimientos) {
        try {
          final movJson = movimiento.toJsonDTO();
          await _supabaseClient.from('movimientos').insert([movJson]);
          movimientosExitosos++;
        } catch (e) {
          print(
            '[SupabaseService] ✗ Error al insertar movimiento ${movimiento.idMovimiento} del documento ${documento.idDocumento}: $e',
          );
          // Continuar con el siguiente movimiento
        }
      }

      // 5. Insertar flujos de caja uno por uno
      int flujosExitosos = 0;
      int flujosProcesados = documento.flujosCajas.length;

      for (final flujo in documento.flujosCajas) {
        try {
          final flujoJson = flujo.toJson();
          await _supabaseClient.from('flujos_caja').insert([flujoJson]);
          flujosExitosos++;
        } catch (e) {
          print(
            '[SupabaseService] ✗ Error al insertar flujo de caja del documento ${documento.idDocumento}: $e',
          );
          // Continuar con el siguiente flujo
        }
      }

      // 6. Upsert stocks (si hay)
      if (stockMap.isNotEmpty) {
        final stocksJson = [];
        for (var element in stockMap.values) {
          stocksJson.addAll(
            element.values.map((stock) => stock.toJson()).toList(),
          );
        }
        await _supabaseClient
            .from('stocks')
            .upsert(stocksJson, onConflict: 'id_producto,id_localidad');
        print(
          '[SupabaseService] ✓ ${stocksJson.length} stocks procesados para documento ${documento.idDocumento}',
        );
      }

      // 7. Upsert precios (si hay)
      if (preciosMap.isNotEmpty) {
        final preciosJson = [];
        for (var element in preciosMap.values) {
          preciosJson.addAll(
            element.values.map((precio) => precio.toJson()).toList(),
          );
        }
        await _supabaseClient
            .from('precios')
            .upsert(preciosJson, onConflict: 'id_producto, id_moneda');
        print(
          '[SupabaseService] ✓ ${preciosJson.length} precios procesados para documento ${documento.idDocumento}',
        );
      }

      // Verificar si todos los movimientos y flujos se procesaron correctamente
      final todosMovimientosOk = movimientosExitosos == movimientosProcesados;
      final todosFlujosOk = flujosExitosos == flujosProcesados;

      return DocumentoSyncResult(
        idDocumento: documento.idDocumento,
        tipo: documento.tipo,
        consec: documento.consec,
        exito: todosMovimientosOk && todosFlujosOk,
        error:
            todosMovimientosOk && todosFlujosOk
                ? null
                : 'Algunos movimientos o flujos fallaron (Mov: $movimientosExitosos/$movimientosProcesados, Flujos: $flujosExitosos/$flujosProcesados)',
        movimientosProcesados: movimientosProcesados,
        movimientosExitosos: movimientosExitosos,
        flujosCajaProcesados: flujosProcesados,
        flujosCajaExitosos: flujosExitosos,
      );
    } catch (e, stackTrace) {
      print(
        '[SupabaseService] ✗ Error crítico al procesar documento ${documento.idDocumento}: $e',
      );
      print('[SupabaseService] Stack trace: $stackTrace');
      return DocumentoSyncResult(
        idDocumento: documento.idDocumento,
        tipo: documento.tipo,
        consec: documento.consec,
        exito: false,
        error: e.toString(),
        movimientosProcesados: documento.movimientos.length,
        movimientosExitosos: 0,
        flujosCajaProcesados: documento.flujosCajas.length,
        flujosCajaExitosos: 0,
      );
    }
  }

  /// Sincroniza documentos con flujos de forma robusta, procesando cada documento individualmente
  Future<SyncResult> upsertDocumentosConFlujos(
    List<DocumentosConFlujos> documentosConFlujos, {
    Function(SyncResult)? onProgress,
  }) async {
    final fechaInicio = DateTime.now();
    print(
      '[SupabaseService] Iniciando sincronización robusta de documentos...',
    );

    // Obtener pagos una sola vez
    print('[SupabaseService] Obteniendo pagos...');
    List<Pago> pagos = await getPagos();
    print('[SupabaseService] Pagos obtenidos: ${pagos.length}');

    // Recopilar todos los documentos de todos los DocumentosConFlujos
    final List<DocumentoDTO> todosDocumentos = [];
    final List<FlujoCajaDTO> flujosCajaGlobales = [];

    for (final doc in documentosConFlujos) {
      todosDocumentos.addAll(doc.documentoDTOS);
      flujosCajaGlobales.addAll(doc.flujosCajaDTOS);
    }

    // Procesar flujos de caja globales primero
    if (flujosCajaGlobales.isNotEmpty) {
      try {
        final flujosJson = flujosCajaGlobales.map((f) => f.toJson()).toList();
        await _supabaseClient.from('flujos_caja').insert(flujosJson);
        print(
          '[SupabaseService] ✓ ${flujosCajaGlobales.length} flujos de caja globales insertados',
        );
      } catch (e) {
        print(
          '[SupabaseService] ✗ Error al insertar flujos de caja globales: $e',
        );
      }
    }

    // Procesar cada documento individualmente
    final List<DocumentoSyncResult> resultados = [];
    int documentosExitosos = 0;
    int documentosFallidos = 0;

    for (int i = 0; i < todosDocumentos.length; i++) {
      final documento = todosDocumentos[i];
      print(
        '[SupabaseService] Procesando documento ${i + 1}/${todosDocumentos.length}: ${documento.idDocumento} (consec: ${documento.consec})',
      );

      final resultado = await _procesarDocumentoIndividual(documento, pagos);
      resultados.add(resultado);

      if (resultado.exito) {
        documentosExitosos++;
      } else {
        documentosFallidos++;
      }

      // Notificar progreso si hay callback
      if (onProgress != null) {
        final syncResult = SyncResult(
          totalDocumentos: todosDocumentos.length,
          documentosExitosos: documentosExitosos,
          documentosFallidos: documentosFallidos,
          resultados: resultados,
          fechaInicio: fechaInicio,
        );
        onProgress(syncResult);
      }
    }

    final fechaFin = DateTime.now();
    final resultadoFinal = SyncResult(
      totalDocumentos: todosDocumentos.length,
      documentosExitosos: documentosExitosos,
      documentosFallidos: documentosFallidos,
      resultados: resultados,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );

    print(
      '[SupabaseService] Sincronización completada: ${documentosExitosos} exitosos, ${documentosFallidos} fallidos de ${todosDocumentos.length} totales',
    );
    print(
      '[SupabaseService] Duración: ${resultadoFinal.duracion.inSeconds} segundos',
    );

    return resultadoFinal;
  }
}
