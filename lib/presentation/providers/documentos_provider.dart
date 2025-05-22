import 'dart:async';
import 'dart:io';

import 'package:easy_bo_mobile_app/config/supabase_config.dart';
import 'package:easy_bo_mobile_app/models/documento.dart';
import 'package:easy_bo_mobile_app/models/localidad.dart';
import 'package:easy_bo_mobile_app/models/movimiento.dart';
import 'package:easy_bo_mobile_app/models/pago.dart';
import 'package:easy_bo_mobile_app/models/tienda.dart';
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

class GrupoDocumentos {
  final DateTime fecha;
  final int idTienda;
  final String nombreTienda;
  final List<Documento> documentos;
  double get total => documentos.fold(0, (sum, doc) => sum + doc.importe);

  GrupoDocumentos({
    required this.fecha,
    required this.idTienda,
    required this.nombreTienda,
    required this.documentos,
  });
}

enum OrdenVentas { fecha, tienda, importe }

enum OrdenMovimientos { alfabetico, importe, cantidad }

class DocumentosProvider extends ChangeNotifier {
  bool _isDisposed = false;
  Future? _pendingRequest;

  final SupabaseService _supabaseService = SupabaseService(
    SupabaseConfig.client,
  );
  final LocalStorageService _localStorageService = LocalStorageService();
  final TiendasProvider tiendasProvider;

  final Filtros _filtros = Filtros();
  Filtros get filtros => _filtros;

  void setIncludeCanceled({bool include = false}) {
    _filtros.includeCanceled = include;
    filtrarDocumentos();
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

  List<Documento> _documentos = [];
  List<Documento> _documentosFiltrados = [];
  List<Documento> get documentos => _documentos;
  List<Documento> get documentosFiltrados => _documentosFiltrados;

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

  DocumentosProvider(this.tiendasProvider) {
    // Obtener fecha actual
    final ahora = DateTime.now();

    // Calcular inicio de la semana (lunes)
    final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));

    // Calcular fin de la semana (domingo)
    final finSemana = inicioSemana.add(Duration(days: 6));

    setRangoFechas(
      DateTimeRange(
        start: DateTime(
          inicioSemana.year,
          inicioSemana.month,
          inicioSemana.day,
        ),
        end: DateTime(
          finSemana.year,
          finSemana.month,
          finSemana.day,
          23,
          59,
          59,
        ),
      ),
    );

    getDocumentos(tipo: 'VENTA');
  }

  Future<void> setRangoFechas(DateTimeRange? nuevoRango) async {
    _filtros.rangoFechas = nuevoRango;

    await getDocumentos(tipo: 'VENTA');
    actualizarEstado();
  }

  Future<void> cargarDesdeLocal() async {
    final documentosLocales = await _localStorageService.getDocumentos();
    final movimientosLocales = await _localStorageService.getMovimientos();

    _documentos = enrichDocuments(documentosLocales, movimientosLocales);
    aplicarFiltros();
  }

  void aplicarFiltros() {
    _documentosFiltrados =
        _documentos.where((doc) {
          final enRango =
              _filtros.rangoFechas!.start.isBefore(doc.fecha) &&
              _filtros.rangoFechas!.end.isAfter(doc.fecha);
          return enRango && !doc.cancelado;
        }).toList();
  }

  Future<void> actualizarDesdeRemoto() async {
    final documentosRemotos = await _supabaseService.getDocumentos(
      tipo: 'VENTA',
      start: _filtros.rangoFechas?.start,
      end: _filtros.rangoFechas?.end,
    );

    final movimientosRemotos = await _supabaseService.getMovimientosByDocuments(
      documentosRemotos,
    );

    // Actualizar estado
    _documentos = enrichDocuments(documentosRemotos, movimientosRemotos);

    // Guardar en local
    unawaited(updateDocumentos(_documentos));

    filtrarDocumentos();
  }

  void _mostrarError(String mensaje) {
    _errorMessage = mensaje;
    actualizarEstado();
  }

  void clearError() {
    _errorMessage = null;
    actualizarEstado();
  }

  Future<void> getDocumentos({bool forceUpdate = false, String? tipo}) async {
    cancelPendingRequest();
    final completer = Completer();
    _pendingRequest = completer.future;

    try {
      _errorMessage = null;
      _cargando = true;
      actualizarEstado();
      if (!forceUpdate) {
        cargarDesdeLocal();
        filtrarDocumentos();
        actualizarEstado();
      }
      await actualizarDesdeRemoto();
    } on SocketException catch (_) {
      _mostrarError('Sin conexión - Mostrando datos locales');
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
    List<Documento> documentos,
    List<Movimiento> movimientos,
  ) {
    for (Documento d in documentos) {
      for (Movimiento m in movimientos) {
        if (d.idDocumento == m.idDocumento) {
          // m.producto = _getProductoById(m.idProducto); // Nueva función
          d.movimientos.add(m);
        }
      }
    }
    return documentos;
  }

  Future<void> updateDocumentos(List<Documento> documentos) async {
    unawaited(_localStorageService.saveDocumentos(documentos));
    final List<Movimiento> moves = [];
    for (Documento documento in documentos) {
      print('${documento.idDocumento}: ${documento.movimientos}');
      moves.addAll(documento.movimientos);
    }
    print('${movimientos.length}: $moves');
    unawaited(updateMovimientos(moves));
  }

  Future<void> updateMovimientos(List<Movimiento> movimientos) async {
    _localStorageService.saveMovimientos(movimientos);
  }

  void filtrarDocumentos() {
    _documentosFiltrados.clear();
    _documentosFiltrados.addAll(_documentos);

    if (_filtros.tipo != null) {
      _documentosFiltrados =
          documentosFiltrados.where((d) => d.tipo == _filtros.tipo).toList();
    }
    // if ( _filtros.pago != null ){
    //   _documentosFiltrados = documentosFiltrados.where( (d) =>
    //     d == _filtros.pago
    //    ).toList();
    // }
    if (!_filtros.includeCanceled) {
      _documentosFiltrados =
          documentosFiltrados.where((d) => !d.cancelado).toList();
    }

    _documentosFiltrados = _documentosFiltrados.reversed.toList();
  }

  bool fechasIguales(DateTime fecha1, DateTime fecha2) {
    if (fecha1.year != fecha2.year) return false;
    if (fecha1.month != fecha2.month) return false;
    if (fecha1.day != fecha2.day) return false;

    return true;
  }

  List<GrupoDocumentos> get documentosAgrupados {
    final Map<String, GrupoDocumentos> grupos = {};

    for (final doc in _documentosFiltrados) {
      final tienda = _getTiendaPorLocalidad(doc.idLocalidad);
      final key =
          '${doc.fecha.toIso8601String().substring(0, 10)}-${tienda.idTienda}';

      if (grupos.containsKey(key)) {
        grupos[key]!.documentos.add(doc);
      } else {
        grupos[key] = GrupoDocumentos(
          fecha: DateTime(doc.fecha.year, doc.fecha.month, doc.fecha.day),
          idTienda: tienda.idTienda,
          nombreTienda: tienda.nombre,
          documentos: [doc],
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

    for (final doc in _documentosFiltrados) {
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
