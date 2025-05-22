// ignore_for_file: unnecessary_null_comparison, avoid_print

import 'package:easy_bo_mobile_app/models/documento.dart';
import 'package:easy_bo_mobile_app/models/moneda.dart';
import 'package:easy_bo_mobile_app/models/movimiento.dart';
import 'package:easy_bo_mobile_app/models/producto.dart';
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
  }) async {
    try {
      print('Iniciando consulta a Supabase para $tableName...');
      List<Map<String, dynamic>> registros = [];
      int offset = 0;
      const int limit = 1000;
      bool hayMasRegistros = true;

      while (hayMasRegistros) {
        print('Consultando registros desde offset $offset...');
        PostgrestFilterBuilder<List<Map<String, dynamic>>> query =
            _supabaseClient.from(tableName).select('*');

        if (where != null && whereIn != null) {
          query = query.inFilter(where, whereIn);
        } else if (where != null && whereEq != null) {
          query = query.eq(where, whereEq);
        }

        if (orderBy != null) {
          query.order(orderBy, ascending: asc);
        }

        final fQuery = query.range(offset, offset + limit - 1);

        final response = await fQuery;
        if (response.isEmpty) {
          break;
        }

        registros.addAll(response);

        print('Registros procesados correctamente: ${registros.length}');

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

  Future<List<Documento>> getDocumentos({
    String? tipo,
    DateTime? start,
    DateTime? end,
  }) async {
    print('Obteniendo Documentos de Supabase');
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

    final response = await query;

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
    final response = await _getFromSupabase(
      'movimientos',
      where: 'id_documento',
      whereIn: ids,
    );
    return (response as List).map((json) => Movimiento.fromJson(json)).toList();
  }
}
