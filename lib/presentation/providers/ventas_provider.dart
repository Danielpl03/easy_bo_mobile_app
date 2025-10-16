import 'dart:async';
import 'dart:io';

import 'package:easy_bo_mobile_app/config/supabase_config.dart';
import 'package:easy_bo_mobile_app/models/documento.dart';
import 'package:easy_bo_mobile_app/models/localidad.dart';
import 'package:easy_bo_mobile_app/models/movimiento.dart';
import 'package:easy_bo_mobile_app/models/pago.dart';
import 'package:easy_bo_mobile_app/models/producto.dart' show Producto;
import 'package:easy_bo_mobile_app/models/tienda.dart';
import 'package:easy_bo_mobile_app/presentation/providers/productos_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/tiendas_provider.dart';
import 'package:easy_bo_mobile_app/services/local_storage_service.dart';
import 'package:easy_bo_mobile_app/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Filtros {
  String? tipo;
  Pago? pago;
  bool includeCanceled = false;
  DateTimeRange? rangoFechas;
  bool colapsed = false;
}

class GrupoVentas {
  final DateTime fecha;
  final int idTienda;
  final String nombreTienda;
  final List<Documento> ventas;
  double get total => ventas.fold(0, (sum, doc) => sum + doc.importe);

  GrupoVentas({
    required this.fecha,
    required this.idTienda,
    required this.nombreTienda,
    required this.ventas,
  });
}

enum OrdenVentas { fecha, tienda, importe }

enum OrdenMovimientos { alfabetico, importe, cantidad }

class VentasProvider extends ChangeNotifier {
  bool _isDisposed = false;
  Future? _pendingRequest;

  final SupabaseService _supabaseService = SupabaseService(
    SupabaseConfig.client,
  );
  final LocalStorageService _localStorageService = LocalStorageService();
  final TiendasProvider tiendasProvider;
  final ProductosProvider productosProvider;

  final Filtros _filtros = Filtros();
  Filtros get filtros => _filtros;

  void setIncludeCanceled({bool include = false}) {
    _filtros.includeCanceled = include;
    filtrarVentas();
    actualizarEstado();
  }

  @override
  void dispose() {
    _isDisposed = true;
    cancelPendingRequest();
    super.dispose();
  }

  void cancelPendingRequest() {
    if (_pendingRequest != null) {
      _pendingRequest!.ignore();
      _pendingRequest = null;
    }
  }

  List<Documento> _ventas = [];
  List<Documento> _ventasFiltradas = [];
  List<Documento> get ventas => _ventas;
  List<Documento> get ventasFiltradas => _ventasFiltradas;

  final List<Movimiento> _movimientos = [];
  List<Movimiento> get movimientos => _movimientos;

  OrdenVentas _ordenVentas = OrdenVentas.fecha;
  OrdenVentas get ordenVentas => _ordenVentas;
  final Map<String, OrdenMovimientos> _ordenMovimientos = {};

  String? _errorMessage;
  bool _cargando = false;

  String? get errorMessage => _errorMessage;
  bool get cargando => _cargando;

  OrdenMovimientos? getOrdenMov(String doc) => _ordenMovimientos[doc];

  // Métodos para cambiar el orden
  void cambiarOrdenVentas(OrdenVentas nuevoOrden) {
    _ordenVentas = nuevoOrden;
    actualizarEstado();
  }

  void cambiarOrdenMovimientos(
    String idDocumento,
    OrdenMovimientos nuevoOrden,
  ) {
    _ordenMovimientos[idDocumento] = nuevoOrden;
    actualizarEstado();
  }

  VentasProvider(this.tiendasProvider, this.productosProvider) {
    // Obtener fecha actual
    final ahora = DateTime.now();

    // Calcular inicio de la semana (lunes)
    final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));

    // Calcular fin de la semana (domingo)
    final finSemana = inicioSemana.add(Duration(days: 6));

    _filtros.rangoFechas = DateTimeRange(
      start: DateTime(inicioSemana.year, inicioSemana.month, inicioSemana.day),
      end: DateTime(finSemana.year, finSemana.month, finSemana.day, 23, 59, 59),
    );

    // getVentas(tipo: 'VENTA');
  }

  Future<void> setRangoFechas(DateTimeRange? nuevoRango) async {
    _filtros.rangoFechas = nuevoRango;

    await getVentas(tipo: 'VENTA');
    actualizarEstado();
  }

  Future<void> cargarDesdeLocal() async {
    final documentosLocales = await _localStorageService.getDocumentos();
    final movimientosLocales = await _localStorageService.getMovimientos();
    final productosLocales = await _localStorageService.getProductos();

    _ventas = enrichDocuments(
        documentosLocales, movimientosLocales, productosLocales);
    aplicarFiltros();
    }

  void aplicarFiltros() {
    _ventasFiltradas =
        _ventas.where((doc) {
          final enRango =
              _filtros.rangoFechas!.start.isBefore(doc.fecha) &&
              _filtros.rangoFechas!.end.isAfter(doc.fecha);
          return enRango && !doc.cancelado;
        }).toList();
  }

  Future<void> actualizarDesdeRemoto() async {
    final ventasRemotas = await _supabaseService.getDocumentos(
      tipo: 'VENTA',
      start: _filtros.rangoFechas?.start,
      end: _filtros.rangoFechas?.end,
    );

    final movimientosRemotos = await _supabaseService.getMovimientosByDocuments(
      ventasRemotas,
    );
    await productosProvider.getProductos(); // Ensure products are up-to-date
    final productosRemotos = productosProvider.productos;

    // Actualizar estado
    _ventas = enrichDocuments(
        ventasRemotas, movimientosRemotos, productosRemotos);

    // Guardar en local
    unawaited(_localStorageService.saveDocumentos(_ventas));

    final List<Movimiento> moves = [];
    for (Documento venta in ventasRemotas) {
      moves.addAll(venta.movimientos);
    }
    unawaited(updateMovimientos(moves));

    filtrarVentas();
  }

  void _mostrarError(String mensaje) {
    _errorMessage = mensaje;
    actualizarEstado();
  }

  void clearError() {
    _errorMessage = null;
    actualizarEstado();
  }

  Future<void> getVentas({bool forceUpdate = false, String? tipo}) async {
    cancelPendingRequest();
    _errorMessage = null;
    _cargando = true;
    actualizarEstado();

    await cargarDesdeLocal();
    filtrarVentas();
    actualizarEstado();

    final completer = Completer();
    _pendingRequest = completer.future;

    try {
      await actualizarDesdeRemoto();
    } on SocketException catch (_) {
      _mostrarError('Sin conexión - Mostrando datos locales (pueden no estar actualizados)');
    } on PostgrestException catch (e) {
      _mostrarError('Error en Supabase: ${e.message}');
    } finally {
      _cargando = false;
      if (!completer.isCompleted) completer.complete();
      actualizarEstado();
    }
  }

  void actualizarEstado() {
    if (!_isDisposed) notifyListeners();
  }

  List<Documento> enrichDocuments(
    List<Documento> ventas,
    List<Movimiento> movimientos,
    List<Producto> productos,
  ) {
    final Map<String, List<Movimiento>> movimientosPorDocumento = {};

    final Map<int, Producto> productosMap = {
      for (var p in productos) p.idProducto: p,
    };

    for (final movimiento in movimientos) {
      movimientosPorDocumento
          .putIfAbsent(movimiento.idDocumento, () => [])
          .add(movimiento);
      movimiento.producto = productosMap[movimiento.idProducto];
    }

    for (Documento d in ventas) {
      if (movimientosPorDocumento.containsKey(d.idDocumento)) {
        d.movimientos.addAll(movimientosPorDocumento[d.idDocumento]!);
      }
    }
    return ventas;
  }

  Future<void> updateDocumentos(List<Documento> ventas) async {
    unawaited(_localStorageService.saveDocumentos(ventas));
    final List<Movimiento> moves = [];
    for (Documento venta in ventas) {
      print('${venta.idDocumento}: ${venta.movimientos}');
      moves.addAll(venta.movimientos);
    }
    print('${movimientos.length}: $moves');
    unawaited(updateMovimientos(moves));
  }

  Future<void> updateMovimientos(List<Movimiento> movimientos) async {
    _localStorageService.saveMovimientos(movimientos);
  }

  void filtrarVentas() {
    _ventasFiltradas.clear();
    _ventasFiltradas.addAll(_ventas);

    if (_filtros.tipo != null) {
      _ventasFiltradas =
          ventasFiltradas.where((d) => d.tipo == _filtros.tipo).toList();
    }
    // if ( _filtros.pago != null ){
    //   _documentosFiltrados = documentosFiltrados.where( (d) =>
    //     d == _filtros.pago
    //    ).toList();
    // }
    if (!_filtros.includeCanceled) {
      _ventasFiltradas =
          ventasFiltradas.where((d) => !d.cancelado).toList();
    }

    _ventasFiltradas = _ventasFiltradas.reversed.toList();
  }

  bool fechasIguales(DateTime fecha1, DateTime fecha2) {
    if (fecha1.year != fecha2.year) return false;
    if (fecha1.month != fecha2.month) return false;
    if (fecha1.day != fecha2.day) return false;

    return true;
  }

  List<GrupoVentas> get ventasAgrupadas {
    final Map<String, GrupoVentas> grupos = {};

    for (final doc in _ventasFiltradas) {
      final tienda = _getTiendaPorLocalidad(doc.idLocalidad);
      final key =
          '${doc.fecha.toIso8601String().substring(0, 10)}-${tienda.idTienda}';

      if (grupos.containsKey(key)) {
        grupos[key]!.ventas.add(doc);
      } else {
        grupos[key] = GrupoVentas(
          fecha: DateTime(doc.fecha.year, doc.fecha.month, doc.fecha.day),
          idTienda: tienda.idTienda,
          nombreTienda: tienda.nombre,
          ventas: [doc],
        );
      }
    }

    return grupos.values.toList()..sort((a, b) {
      switch (_ordenVentas) {
        case OrdenVentas.fecha:
          return b.fecha.compareTo(a.fecha);
        case OrdenVentas.tienda:
          return a.nombreTienda.compareTo(b.nombreTienda);
        case OrdenVentas.importe:
          return b.total.compareTo(a.total);
      }
    });
    // return grupos.values.toList()..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  Map<String, double> get resumenPorTienda {
    final Map<int, double> totales = {};

    for (final doc in _ventasFiltradas) {
      final tienda = _getTiendaPorLocalidad(doc.idLocalidad);
      final total = totales[tienda.idTienda] ?? 0;
      totales[tienda.idTienda] = total + doc.importe;
    }

    final Map<String, double> resumen = {};
    for (final entry in totales.entries) {
      final tienda = tiendasProvider.tiendas.firstWhere(
        (t) => t.idTienda == entry.key,
        orElse: () => Tienda(idTienda: 0, nombre: 'Otras Tiendas'),
      );
      resumen[tienda.nombre] = entry.value;
    }

    return resumen;
  }

  List<Movimiento> movimientosOrdenados(Documento doc) {
    final orden =
        _ordenMovimientos[doc.idDocumento] ?? OrdenMovimientos.alfabetico;

    return doc.movimientos..sort((a, b) {
      switch (orden) {
        case OrdenMovimientos.alfabetico:
          return a.producto?.descripcion.compareTo(
                b.producto?.descripcion ?? '',
              ) ??
              0;
        case OrdenMovimientos.importe:
          return (b.importe ?? 0).compareTo(a.importe ?? 0);
        case OrdenMovimientos.cantidad:
          return b.cantidad.compareTo(a.cantidad);
      }
    });
  }

  Tienda _getTiendaPorLocalidad(int? idLocalidad) {
    final localidad = tiendasProvider.localidades.firstWhere(
      (l) => l.idLocalidad == idLocalidad,
      orElse:
          () => Localidad(
            idLocalidad: 0,
            localidad: 'Desconocida',
            idTienda: 0,
            tipo: '',
          ),
    );

    return tiendasProvider.tiendas.firstWhere(
      (t) => t.idTienda == localidad.idTienda,
      orElse:
          () => Tienda(
            idTienda: 0,
            nombre: 'Tienda Desconocida',
            direccion: '',
            coordenadas: '',
            telefono: '',
          ),
    );
  }
}
