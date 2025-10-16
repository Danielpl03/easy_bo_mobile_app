import 'dart:async';
import 'dart:io';

import 'package:easy_bo_mobile_app/config/supabase_config.dart';
import 'package:easy_bo_mobile_app/models/documento.dart';
import 'package:easy_bo_mobile_app/models/movimiento.dart';
import 'package:easy_bo_mobile_app/models/movimiento_historial.dart';
import 'package:easy_bo_mobile_app/models/rango_fechas.dart';
import 'package:easy_bo_mobile_app/presentation/providers/tiendas_provider.dart';
import 'package:easy_bo_mobile_app/services/local_storage_service.dart';
import 'package:easy_bo_mobile_app/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Filtros {
  DateTimeRange? rangoFechas;
  List<int> localidadesSeleccionadas = [];
}

class DocumentosProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService(
    SupabaseConfig.client,
  );
  final LocalStorageService _localStorageService = LocalStorageService();
  final TiendasProvider tiendasProvider;

  final Filtros _filtros = Filtros();
  Filtros get filtros => _filtros;

  bool _isDisposed = false;
  bool _cargando = false;
  String? _errorMessage;
  Future? _pendingRequest;

  List<Documento> _documentos = [];
  List<Documento> _documentosFiltrados = [];
  List<MovimientoHistorial> _movimientosHistorial = [];

  bool get cargando => _cargando;
  String? get errorMessage => _errorMessage;
  List<Documento> get documentos => _documentos;
  List<Documento> get documentosFiltrados => _documentosFiltrados;
  List<MovimientoHistorial> get movimientosHistorial => _movimientosHistorial;

  DocumentosProvider(this.tiendasProvider) {
    _inicializarFiltros();
    // unawaited(getDocumentos());
  }

  void _inicializarFiltros() {
    final ahora = DateTime.now();
    _filtros.rangoFechas = DateTimeRange(
      start: DateTime(ahora.year, ahora.month, 1),
      end: DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59),
    );
    print(
      '📅 [Provider] Filtros inicializados con rango: ${_filtros.rangoFechas!.start} - ${_filtros.rangoFechas!.end}',
    );
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

  Future<void> setRangoFechas(DateTimeRange? nuevoRango) async {
    if (nuevoRango == null) {
      _inicializarFiltros();
    } else {
      // Validar que el rango no sea futuro
      final ahora = DateTime.now();
      if (nuevoRango.start.isAfter(ahora)) {
        print('⚠️ [Provider] Intento de establecer rango futuro');
        return;
      }

      // Ajustar la fecha fin si es necesario
      final fechaFin =
          nuevoRango.end.isAfter(ahora)
              ? DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59)
              : DateTime(
                nuevoRango.end.year,
                nuevoRango.end.month,
                nuevoRango.end.day,
                23,
                59,
                59,
              );

      _filtros.rangoFechas = DateTimeRange(
        start: nuevoRango.start,
        end: fechaFin,
      );
      print(
        '📅 [Provider] Nuevo rango establecido: ${_filtros.rangoFechas!.start} - ${_filtros.rangoFechas!.end}',
      );
    }
    // await getDocumentos(forceUpdate: true);
  }

  void setLocalidadesSeleccionadas(List<int> localidades) {
    _filtros.localidadesSeleccionadas = localidades;
    filtrarDocumentos();
    actualizarEstado();
  }

  Future<void> getDocumentos({bool forceUpdate = false}) async {
    print('🔄 [Provider] Iniciando getDocumentos (forceUpdate: $forceUpdate)');
    if (_filtros.rangoFechas == null) {
      print('❌ [Provider] No hay rango de fechas definido');
      return;
    }

    print(
      '📅 [Provider] Rango de fechas solicitado: ${_filtros.rangoFechas!.start} - ${_filtros.rangoFechas!.end}',
    );

    // Cancelar cualquier solicitud pendiente
    cancelPendingRequest();
    final completer = Completer();
    _pendingRequest = completer.future;

    try {
      _errorMessage = null;
      _cargando = true;
      actualizarEstado();

      print('🔍 [Provider] Obteniendo rangos de fechas faltantes...');
      final rangosFaltantes = await _localStorageService.getRangosFaltantes(
        _filtros.rangoFechas!,
      );

      print(
        '📅 [Provider] Rangos faltantes encontrados: ${rangosFaltantes.length}',
      );
      for (var rango in rangosFaltantes) {
        print('  - ${rango.start} a ${rango.end}');
      }

      if (rangosFaltantes.isNotEmpty) {
        await actualizarDesdeRemoto(rangosFaltantes);
      }

      // Cargar datos locales una sola vez
      print('📥 [Provider] Cargando datos locales...');
      await cargarDesdeLocal();
      print(
        '📥 [Provider] Datos locales cargados: ${_documentos.length} documentos',
      );

      // Filtrar documentos
      filtrarDocumentos();
      print(
        '🔍 [Provider] Documentos filtrados: ${_documentosFiltrados.length}',
      );
      actualizarEstado();
    } on SocketException catch (_) {
      print('❌ [Provider] Error de conexión');
      _mostrarError('Sin conexión - Mostrando datos locales');
    } on PostgrestException catch (e) {
      print('❌ [Provider] Error en Supabase: ${e.message}');
      _mostrarError('Error en Supabase: ${e.message}');
    } finally {
      _cargando = false;
      if (!completer.isCompleted) completer.complete();
      actualizarEstado();
      print('✅ [Provider] getDocumentos completado');
    }
  }

  Future<void> cargarDesdeLocal() async {
    final documentosLocales = await _localStorageService.getDocumentos();
    final movimientosLocales = await _localStorageService.getMovimientos();

    final docFiltrados = filtrarPorFecha(documentosLocales);

    _documentos = _enriquecerDocumentos(docFiltrados, movimientosLocales);
  }

  Future<void> actualizarDesdeRemoto(
    List<DateTimeRange> rangosFaltantes,
  ) async {
    // Obtener los rangos de fechas que faltan
    List<Documento> documentosRemotos = [];
    List<Movimiento> movimientosRemotos = [];

    // Obtener documentos solo para los rangos faltantes
    for (var rango in rangosFaltantes) {
      print(
        '📥 [Provider] Obteniendo documentos para rango: ${rango.start} - ${rango.end}',
      );
      final docs = await _supabaseService.getDocumentos(
        start: rango.start,
        end: rango.end,
      );
      print(
        '📥 [Provider] Documentos obtenidos para este rango: ${docs.length}',
      );
      documentosRemotos.addAll(docs);
    }

    if (documentosRemotos.isNotEmpty) {
      print(
        '📥 [Provider] Obteniendo movimientos para ${documentosRemotos.length} documentos...',
      );
      movimientosRemotos = await _supabaseService.getMovimientosByDocuments(
        documentosRemotos,
      );
      print(
        '📥 [Provider] Movimientos obtenidos: ${movimientosRemotos.length}',
      );

      // Actualizar estado
      // _documentos = _enriquecerDocumentos(
      //   documentosRemotos,
      //   movimientosRemotos,
      // );
      // print('📦 [Provider] Documentos enriquecidos: ${_documentos.length}');

      // Guardar en local
      print('💾 [Provider] Guardando datos en local...');
      await _guardarEnLocal(documentosRemotos, movimientosRemotos);

      // Registrar los nuevos rangos de fechas (meses completos)
      if (rangosFaltantes.isNotEmpty) {
        for (var rangoFaltante in rangosFaltantes) {
          print(
            '📅 [Provider] Registrando nuevo rango de fechas: ${rangoFaltante.start} - ${rangoFaltante.end}',
          );
          _localStorageService.agregarRangoFechas(
            RangoFechas(inicio: rangoFaltante.start, fin: rangoFaltante.end),
          );
        }
      }
    } else {
      print('ℹ️ [Provider] No se encontraron documentos nuevos para obtener');
    }
    print('✅ [Provider] Actualización desde remoto completada');
  }

  Future<void> _guardarEnLocal(
    List<Documento> documentos,
    List<Movimiento> movimientos,
  ) async {
    await _localStorageService.saveDocumentos(documentos);
    await _localStorageService.saveMovimientos(movimientos);
  }

  List<Documento> _enriquecerDocumentos(
    List<Documento> documentos,
    List<Movimiento> movimientos,
  ) {
    final Map<String, List<Movimiento>> movimientosPorDocumento = {};

    for (final movimiento in movimientos) {
      movimientosPorDocumento
          .putIfAbsent(movimiento.idDocumento, () => [])
          .add(movimiento);
    }

    for (Documento doc in documentos) {
      if (movimientosPorDocumento.containsKey(doc.idDocumento)) {
        doc.movimientos.addAll(movimientosPorDocumento[doc.idDocumento]!);
      }
    }
    return documentos;
  }

  List<Documento> filtrarPorFecha(List<Documento> documentos) {
    return documentos.where((doc) {
      if (_filtros.rangoFechas == null) {
        print('❌ No hay rango de fechas definido');
        return false;
      }

      final enRango =
          doc.fecha.isAfter(_filtros.rangoFechas!.start) &&
          doc.fecha.isBefore(_filtros.rangoFechas!.end);

      return enRango;
    }).toList();
  }

  void filtrarDocumentos() {
    print('🔍 Iniciando filtrado de documentos');
    print('📊 Total documentos antes de filtrar: ${_documentos.length}');

    _documentosFiltrados =
        _documentos.where((doc) {
          // if (_filtros.rangoFechas == null) {
          //   print('❌ No hay rango de fechas definido');
          //   return false;
          // }

          // final enRango =
          //     doc.fecha.isAfter(_filtros.rangoFechas!.start) &&
          //     doc.fecha.isBefore(_filtros.rangoFechas!.end);

          // if (!enRango) return false;

          if (_filtros.localidadesSeleccionadas.isNotEmpty) {
            final cumpleFiltro =
                _filtros.localidadesSeleccionadas.contains(doc.idLocalidad) ||
                doc.tipo == 'CREADO' ||
                doc.tipo == 'MODIFICADO';
            return cumpleFiltro;
          }

          return true;
        }).toList();
    print('📊 Documentos después de filtrar: ${_documentosFiltrados.length}');
    print('✅ Filtrado completado');
  }

  Future<void> actualizarMovimientosHistorial(int idProducto) async {
    print(
      '🔄 [Provider] Iniciando actualización de movimientos historial para producto: $idProducto',
    );
    _movimientosHistorial.clear();

    // Asegurarnos de que tenemos los datos actualizados
    await getDocumentos(forceUpdate: true);

    print('🔍 [Provider] Filtrando movimientos para el producto $idProducto');
    print(
      '📅 [Provider] Rango de fechas actual: ${_filtros.rangoFechas?.start} - ${_filtros.rangoFechas?.end}',
    );
    print(
      '🏪 [Provider] Localidades seleccionadas: ${_filtros.localidadesSeleccionadas}',
    );

    final Set<int> movimientosProcesados = {};
    final List<MovimientoHistorial> tempMovimientosHistorial = [];

    for (var doc in _documentosFiltrados) {
      for (var movimiento in doc.movimientos) {
        if (movimiento.idProducto == idProducto &&
            !movimientosProcesados.contains(movimiento.idMovimiento)) {
          tempMovimientosHistorial.add(
            MovimientoHistorial.fromMovimiento(movimiento, doc),
          );
          movimientosProcesados.add(movimiento.idMovimiento);
        }
      }
    }

    _movimientosHistorial = tempMovimientosHistorial;

    print('📊 [Provider] Movimientos encontrados: ${_movimientosHistorial.length}');
    print(
      '📊 [Provider] Movimientos únicos procesados: ${movimientosProcesados.length}',
    );

    _movimientosHistorial.sort(
      (a, b) => b.documento.fecha.compareTo(a.documento.fecha),
    );

    actualizarEstado();
    print('✅ [Provider] Actualización de movimientos historial completada');
  }

  void _mostrarError(String mensaje) {
    _errorMessage = mensaje;
    actualizarEstado();
  }

  void actualizarEstado() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }
}
