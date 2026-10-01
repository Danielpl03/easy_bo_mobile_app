import 'dart:async';
import 'dart:io';

import 'package:easy_bo_mobile_app/config/supabase_config.dart';
import 'package:easy_bo_mobile_app/models/documento.dart';
import 'package:easy_bo_mobile_app/models/movimiento.dart';
import 'package:easy_bo_mobile_app/models/movimiento_historial.dart';
import 'package:easy_bo_mobile_app/models/cliente.dart';
import 'package:easy_bo_mobile_app/models/proveedor.dart';
import 'package:easy_bo_mobile_app/presentation/providers/tiendas_provider.dart';
import 'package:easy_bo_mobile_app/services/local_storage_service.dart';
import 'package:easy_bo_mobile_app/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Filtros {
  DateTimeRange? rangoFechas;
  List<int> localidadesSeleccionadas = [];
  String? tipoDocumento; // Nuevo: filtro por tipo de documento
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
  List<Cliente> _clientes = [];
  List<Proveedor> _proveedores = [];

  bool get cargando => _cargando;
  String? get errorMessage => _errorMessage;
  List<Documento> get documentos => _documentos;
  List<Documento> get documentosFiltrados => _documentosFiltrados;
  List<MovimientoHistorial> get movimientosHistorial => _movimientosHistorial;
  List<Cliente> get clientes => _clientes;
  List<Proveedor> get proveedores => _proveedores;

  DocumentosProvider(this.tiendasProvider) {
    _inicializarFiltros();
    _cargarClientesYProveedores();
    // unawaited(getDocumentos());
  }

  Future<void> _cargarClientesYProveedores() async {
    try {
      _clientes = await _localStorageService.getClientes();
      _proveedores = await _localStorageService.getProveedores();
      print('📋 [Provider] Clientes cargados: ${_clientes.length}');
      print('📋 [Provider] Proveedores cargados: ${_proveedores.length}');

      // Si no hay datos locales, intentar cargar desde Supabase
      if (_clientes.isEmpty || _proveedores.isEmpty) {
        await _sincronizarClientesYProveedores();
      }
    } catch (e) {
      print('⚠️ [Provider] Error al cargar clientes/proveedores: $e');
      // Intentar cargar desde Supabase si falla la carga local
      try {
        await _sincronizarClientesYProveedores();
      } catch (e2) {
        print('⚠️ [Provider] Error al sincronizar clientes/proveedores: $e2');
      }
    }
  }

  Future<void> _sincronizarClientesYProveedores() async {
    try {
      print(
        '🔄 [Provider] Sincronizando clientes y proveedores desde Supabase...',
      );
      final clientesRemotos = await _supabaseService.getClientes();
      final proveedoresRemotos = await _supabaseService.getProveedores();

      await _localStorageService.saveClientes(clientesRemotos);
      await _localStorageService.saveProveedores(proveedoresRemotos);

      _clientes = clientesRemotos;
      _proveedores = proveedoresRemotos;

      print('✅ [Provider] Clientes sincronizados: ${_clientes.length}');
      print('✅ [Provider] Proveedores sincronizados: ${_proveedores.length}');
    } catch (e) {
      print('❌ [Provider] Error al sincronizar clientes/proveedores: $e');
      rethrow;
    }
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

    // Filtrar inmediatamente con el nuevo rango
    filtrarDocumentos();
    actualizarEstado();

    // Luego actualizar datos si es necesario
    await getDocumentos(forceUpdate: true);
  }

  void setTipoDocumento(String? tipo) {
    _filtros.tipoDocumento = tipo;
    filtrarDocumentos();
    actualizarEstado();
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

      if (rangosFaltantes.isNotEmpty) {
        await actualizarDesdeRemoto(rangosFaltantes);
      }

      // Cargar datos locales una sola vez
      print('📥 [Provider] Cargando datos locales...');
      await cargarDesdeLocal();
      // Asegurar que clientes y proveedores estén cargados
      if (_clientes.isEmpty || _proveedores.isEmpty) {
        await _cargarClientesYProveedores();
      }
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

    _documentos = _enriquecerDocumentos(documentosLocales, movimientosLocales);
  }

  Future<void> actualizarDesdeRemoto(List<DateTime> rangosFaltantes) async {
    // Obtener los rangos de fechas que faltan
    List<Documento> documentosRemotos = [];
    List<Movimiento> movimientosRemotos = [];
    DateTime now = DateTime.now();

    // Obtener documentos solo para los rangos faltantes
    for (var primerDiaMes in rangosFaltantes) {
      final anio = primerDiaMes.year;
      final mes = primerDiaMes.month;
      final esMesActual = anio == now.year && mes == now.month;

      DateTimeRange range;
      DateTime fechaGuardar;

      if (esMesActual) {
        // Para el mes actual, verificar si hay datos parciales
        final ultimaFechaDescargada =
            await _localStorageService.getUltimaFechaMesActual();

        DateTime fechaInicio;
        if (ultimaFechaDescargada != null) {
          // Hay datos parciales, descargar desde el día siguiente a la última fecha
          // Usar add para manejar correctamente el desbordamiento de días
          fechaInicio = DateTime(
            ultimaFechaDescargada.year,
            ultimaFechaDescargada.month,
            ultimaFechaDescargada.day,
          ).add(const Duration(days: 1));
          print(
            '📅 [Provider] Mes actual con datos parciales. Última fecha: $ultimaFechaDescargada, Descargando desde: $fechaInicio',
          );
        } else {
          // No hay datos, descargar desde el inicio del mes
          fechaInicio = DateTime(anio, mes, 1);
          print(
            '📅 [Provider] Mes actual sin datos. Descargando desde inicio: $fechaInicio',
          );
        }

        range = DateTimeRange(start: fechaInicio, end: now);
        // Para el mes actual, guardar la última fecha descargada (hoy)
        fechaGuardar = DateTime(now.year, now.month, now.day);
      } else {
        // Para meses pasados, descargar el mes completo
        DateTime start = DateTime(anio, mes, 1);
        DateTime end = DateTime(start.year, start.month + 1, 0, 23, 59, 59);
        range = DateTimeRange(start: start, end: end);
        // Para meses completos, guardar el primer día del mes
        fechaGuardar = DateTime(anio, mes, 1);
        print('📅 [Provider] Descargando mes completo: ${start} - ${end}');
      }

      final docs = await _supabaseService.getDocumentos(
        start: range.start,
        end: range.end,
      );
      print(
        '📥 [Provider] Documentos obtenidos para este rango: ${docs.length}',
      );
      documentosRemotos.addAll(docs);

      // Guardar la fecha correspondiente para este mes
      await _localStorageService.guardarFechaParaMes(anio, mes, fechaGuardar);
      print('💾 [Provider] Fecha guardada para mes $anio-$mes: $fechaGuardar');
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

      print('💾 [Provider] Guardando datos en local...');
      await _guardarEnLocal(documentosRemotos, movimientosRemotos);
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
      doc.movimientos.clear();
      if (movimientosPorDocumento.containsKey(doc.idDocumento)) {
        doc.movimientos.addAll(movimientosPorDocumento[doc.idDocumento]!);
      }
    }
    return documentos;
  }

  void filtrarDocumentos() {
    print('🔍 Iniciando filtrado de documentos');
    print('📊 Total documentos antes de filtrar: ${_documentos.length}');

    _documentosFiltrados =
        _documentos.where((doc) {
          // Filtro por fecha - ES CRÍTICO
          if (_filtros.rangoFechas != null) {
            final fechaDoc = DateTime(
              doc.fecha.year,
              doc.fecha.month,
              doc.fecha.day,
            );
            final fechaInicio = DateTime(
              _filtros.rangoFechas!.start.year,
              _filtros.rangoFechas!.start.month,
              _filtros.rangoFechas!.start.day,
            );
            final fechaFin = DateTime(
              _filtros.rangoFechas!.end.year,
              _filtros.rangoFechas!.end.month,
              _filtros.rangoFechas!.end.day,
            );

            final enRango =
                fechaDoc.isAtSameMomentAs(fechaInicio) ||
                fechaDoc.isAtSameMomentAs(fechaFin) ||
                (fechaDoc.isAfter(fechaInicio) && fechaDoc.isBefore(fechaFin));

            if (!enRango) {
              print('❌ Documento fuera de rango: ${doc.fecha} - ${doc.tipo}');
              return false;
            }
          }

          // Filtro por tipo de documento
          if (_filtros.tipoDocumento != null &&
              _filtros.tipoDocumento!.isNotEmpty) {
            if (doc.tipo != _filtros.tipoDocumento) {
              return false;
            }
          }

          // Filtro por localidades
          if (_filtros.localidadesSeleccionadas.isNotEmpty) {
            final cumpleFiltro =
                _filtros.localidadesSeleccionadas.contains(doc.idLocalidad) ||
                (doc.idLocalidadDestino != null &&
                    _filtros.localidadesSeleccionadas.contains(
                      doc.idLocalidadDestino,
                    )) ||
                doc.tipo == 'CREADO' ||
                doc.tipo == 'MODIFICADO';
            if (!cumpleFiltro) {
              return false;
            }
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

    print(
      '📊 [Provider] Movimientos encontrados: ${_movimientosHistorial.length}',
    );
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

  // Métodos adicionales para la pantalla
  List<String> getTiposDocumentoUnicos() {
    final tipos = _documentos.map((doc) => doc.tipo).toSet().toList();
    tipos.sort();
    return tipos;
  }

  void limpiarFiltros() {
    _filtros.localidadesSeleccionadas.clear();
    _filtros.tipoDocumento = null;
    _inicializarFiltros();
    filtrarDocumentos();
    actualizarEstado();
  }

  // Métodos helper para obtener cliente y proveedor por ID
  // Si no se encuentra localmente, intenta obtenerlo desde Supabase
  Future<Cliente?> getClientePorId(int? idCliente) async {
    if (idCliente == null) return null;

    try {
      // Buscar primero en la lista local
      try {
        final clienteLocal = _clientes.firstWhere(
          (c) => c.idCliente == idCliente,
        );
        return clienteLocal;
      } catch (e) {
        // No se encontró localmente, continuar para buscar en Supabase
      }

      // Si no se encontró localmente, intentar obtenerlo desde Supabase
      print(
        '🔍 [Provider] Cliente $idCliente no encontrado localmente, buscando en Supabase...',
      );
      final clienteRemoto = await _supabaseService.getClientePorId(idCliente);

      if (clienteRemoto != null) {
        // Guardar el nuevo cliente en almacenamiento local
        _clientes.add(clienteRemoto);
        await _localStorageService.saveClientes(_clientes);
        print(
          '✅ [Provider] Cliente $idCliente obtenido y guardado desde Supabase',
        );
        return clienteRemoto;
      }

      print('⚠️ [Provider] Cliente $idCliente no encontrado en Supabase');
      return null;
    } catch (e) {
      print('❌ [Provider] Error al obtener cliente $idCliente: $e');
      return null;
    }
  }

  Future<Proveedor?> getProveedorPorId(int? idProveedor) async {
    if (idProveedor == null) return null;

    try {
      // Buscar primero en la lista local
      try {
        final proveedorLocal = _proveedores.firstWhere(
          (p) => p.idProveedor == idProveedor,
        );
        return proveedorLocal;
      } catch (e) {
        // No se encontró localmente, continuar para buscar en Supabase
      }

      // Si no se encontró localmente, intentar obtenerlo desde Supabase
      print(
        '🔍 [Provider] Proveedor $idProveedor no encontrado localmente, buscando en Supabase...',
      );
      final proveedorRemoto = await _supabaseService.getProveedorPorId(
        idProveedor,
      );

      if (proveedorRemoto != null) {
        // Guardar el nuevo proveedor en almacenamiento local
        _proveedores.add(proveedorRemoto);
        await _localStorageService.saveProveedores(_proveedores);
        print(
          '✅ [Provider] Proveedor $idProveedor obtenido y guardado desde Supabase',
        );
        return proveedorRemoto;
      }

      print('⚠️ [Provider] Proveedor $idProveedor no encontrado en Supabase');
      return null;
    } catch (e) {
      print('❌ [Provider] Error al obtener proveedor $idProveedor: $e');
      return null;
    }
  }
}
