// ignore_for_file: unnecessary_null_comparison, avoid_print

import 'package:easy_bo_mobile_app/models/documento.dart';
import 'package:easy_bo_mobile_app/models/moneda.dart';
import 'package:easy_bo_mobile_app/models/movimiento.dart';
import 'package:easy_bo_mobile_app/models/pago.dart' show Pago;
import 'package:easy_bo_mobile_app/models/producto.dart';
import 'package:easy_bo_mobile_app/models/flujo_caja.dart';
import 'package:easy_bo_mobile_app/models/documentos_con_flujos.dart'; // Importar el nuevo modelo de ventas
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tienda.dart';
// import '../models/venta.dart';
// import '../models/moneda.dart';
import '../models/precio.dart';
import '../models/localidad.dart';
import '../models/stock.dart';
// import 'local_storage_service.dart';

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
    print('Obteniendo Movimientos de Supabase');
    final List<String> ids = documentos.map((d) => d.idDocumento).toList();

    final length = ids.length;
    const limit = 100;
    int start = 0;
    int end = start + limit;
    List<String> batchIds = [];
    List<Map<String, dynamic>> registros = [];

    do {
      PostgrestFilterBuilder<List<Map<String, dynamic>>> query =
          _supabaseClient.from('movimientos').select();
      batchIds = ids.sublist(start, end < length ? end : length);
      query = query.inFilter('id_documento', batchIds);

      start = end;
      end = start + limit;
      final response = await _getFromSupabase('movimientos', queryP: query);

      registros.addAll(response);
    } while (start < length);

    return (registros as List)
        .map((json) => Movimiento.fromJson(json))
        .toList();
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

  Future<void> upsertDocumentosConFlujos(
    List<DocumentosConFlujos> documentosConFlujos,
  ) async {
    print('[SupabaseService] Iniciando upsertDocumentosConFlujos...');
    // 1. Upsert Documentos
    for (DocumentosConFlujos doc in documentosConFlujos) {
      final docsJson = doc.documentoDTOS.map((d) => d.toJson()).toList();
      if (docsJson.isNotEmpty) {
        print(
          '[SupabaseService] Intentando insertar ${docsJson.length} documentos...',
        );
        // final docResponse =
        await _supabaseClient
            .from('documentos')
            .upsert(docsJson, onConflict: 'consec, id_sistema');
        // if (docResponse.error != null) {
        //   throw Exception(
        //     'Error al insertar documentos: ${docResponse.error!.message}',
        //   );
        // }
        print(
          '[SupabaseService] Documentos insertados: ${doc.documentoDTOS.length}',
        );
      }

      List<ProductoDTO> productos = [];
      final Map<int, Map<int, PrecioDTO>> preciosMap = {};
      final Map<int, Map<int, StockDTO>> stockMap = {};

      List<FlujoCajaDTO> allFlujosCaja = [...doc.flujosCajaDTOS];

      print('[SupabaseService] Obteniendo pagos...');
      List<Pago> pagos = await getPagos();
      print('[SupabaseService] Pagos obtenidos: ${pagos.length}');

      for (DocumentoDTO documento in doc.documentoDTOS) {
        print(
          '[SupabaseService] Procesando documento tipo: ${documento.tipo} (ID: ${documento.idDocumento})',
        );
        allFlujosCaja.addAll(documento.flujosCajas);
        if (documento.tipo == "CREADO" || documento.tipo == "MODIFICADO") {
          print(
            '[SupabaseService] Documento tipo ${documento.tipo}. Preparando productos y precios para inserción.',
          );
          for (final mov in documento.movimientos) {
            productos.add(mov.producto);
            preciosMap.putIfAbsent(mov.producto.idProducto, () => {});

            int idMoneda =
                pagos.where((p) => p.idPago == mov.idPago).first.idMoneda;

            preciosMap[mov.producto.idProducto]![idMoneda] = PrecioDTO(
              idPrecio: null,
              idProducto: mov.producto.idProducto,
              idMoneda: idMoneda,
              precio: mov.importe,
            );
          }
        } else {
          print(
            '[SupabaseService] Documento tipo ${documento.tipo}. Preparando stocks para upsert.',
          );
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
      }

      final productosJson = productos.map((p) => p.toJson()).toList();
      if (productosJson.isNotEmpty) {
        print(
          '[SupabaseService] Actualizando ${productosJson.length} productos nuevos...',
        );
        // final pResponse =
        await _supabaseClient
            .from('productos')
            .upsert(productosJson, onConflict: 'id_producto');
        // if (pResponse.error != null) {
        //   throw Exception(
        //     'Error al insertar productos: ${pResponse.error!.message}',
        //   );
        // }
        print(
          '[SupabaseService] Productos actualizados: ${productosJson.length}',
        );
      }

      // 2. Insert Movimientos
      final movimientos =
          doc.documentoDTOS.expand((d) => d.movimientos).toList();
      final movsJson = movimientos.map((m) => m.toJsonDTO()).toList();
      if (movsJson.isNotEmpty) {
        print('[SupabaseService] Insertando ${movsJson.length} movimientos...');
        // final movResponse =
        await _supabaseClient.from('movimientos').insert(movsJson);
        // if (movResponse.error != null) {
        //   throw Exception(
        //     'Error al insertar movimientos: ${movResponse.error!.message}',
        //   );
        // }
        print(
          '[SupabaseService] Movimientos insertados: ${movimientos.length}',
        );
      }

      // 3. Upsert Flujos de Caja (desde la lista de nivel superior de VentasResponse y desde DocumentoDTO si está presente)
      final flujosJson = allFlujosCaja.map((f) => f.toJson()).toList();
      if (flujosJson.isNotEmpty) {
        print(
          '[SupabaseService] Insertando ${flujosJson.length} flujos de caja...',
        );
        // final flujoResponse =
        await _supabaseClient.from('flujos_caja').insert(flujosJson);
        // if (flujoResponse.error != null) {
        //   throw Exception(
        //     'Error al insertar flujos de caja: ${flujoResponse.error!.message}',
        //   );
        // }
        print(
          '[SupabaseService] Flujos de caja upserted: ${allFlujosCaja.length}',
        );
      }

      // 4. Upsert Stocks
      if (stockMap.isNotEmpty) {
        final stocksJson = [];
        for (var element in stockMap.values) {
          stocksJson.addAll(element.values.map((stock)=> stock.toJson()).toList());
        }
        print('[SupabaseService] Upserting ${stocksJson.length} stocks...');
        // final stockResponse =
        await _supabaseClient
            .from('stocks')
            .upsert(stocksJson, onConflict: 'id_producto,id_localidad');
        // if (stockResponse.error != null) {
        //   throw Exception(
        //     'Error al actualizar stocks: ${stockResponse.error!.message}',
        //   );
        // }
        print('[SupabaseService] Stocks upserted: ${stocksJson.length}');
      }

      // 4. Upsert Precios
      if (preciosMap.isNotEmpty) {
        final preciosJson = [];
        for (var element in preciosMap.values) {
          preciosJson.addAll(element.values.map((precio)=> precio.toJson()).toList());
        }
        print(
          '[SupabaseService] Upserting ${preciosJson.length} precios...',
        );
        // final preciosResponse =
        await _supabaseClient
            .from('precios')
            .upsert(preciosJson, onConflict: 'id_producto, id_moneda');
        // if (preciosResponse.error != null) {
        //   throw Exception(
        //     'Error al actualizar precios: ${preciosResponse.error!.message}',
        //   );
        // }
        print('[SupabaseService] Precios upserted: ${preciosJson.length}');
      }
      print('[SupabaseService] upsertDocumentosConFlujos completado.');
    }
  }
}
