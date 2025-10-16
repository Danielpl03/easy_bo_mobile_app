// ignore_for_file: avoid_print

import 'package:easy_bo_mobile_app/models/detalle_pedido.dart';
import 'package:easy_bo_mobile_app/models/documento.dart';
import 'package:easy_bo_mobile_app/models/movimiento.dart';
import 'package:easy_bo_mobile_app/models/pago.dart';
import 'package:easy_bo_mobile_app/models/pedido.dart';
import 'package:easy_bo_mobile_app/models/rango_fechas.dart';
import 'package:easy_bo_mobile_app/models/tienda.dart';
import 'package:easy_bo_mobile_app/models/usuario.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/producto.dart';
import '../models/stock.dart';
import '../models/precio.dart';
import '../models/moneda.dart';
import '../models/localidad.dart';
import 'package:easy_bo_mobile_app/models/flujo_caja.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static const String _tiendasBoxName = 'tiendas';
  static const String _localidadesBoxName = 'localidades';
  static const String _monedasBoxName = 'monedas';
  static const String _pagosBoxName = 'pagos';
  static const String _productosBoxName = 'productos';
  static const String _stocksBoxName = 'stocks';
  static const String _preciosBoxName = 'precios';
  static const String _documentosBoxName = 'documentos';
  static const String _movimientosBoxName = 'movimientos';
  static const String _pedidosBoxName = 'pedidos';
  static const String _detallesPedidoBoxName = 'detalles_pedido';
  static const String _lastSyncBoxName = 'lastSync';
  static const String _rangosFechasBoxName = 'rangos_fechas';
  static const String _flujosCajaBoxName = 'flujos_caja';
  
  Box<Tienda>? _tiendasBox;
  Box<Localidad>? _localidadesBox;
  Box<Moneda>? _monedasBox;
  Box<Pago>? _pagosBox;
  Box<Producto>? _productosBox;
  Box<Stock>? _stocksBox;
  Box<Precio>? _preciosBox;
  Box<Documento>? _documentosBox;
  Box<Movimiento>? _movimientosBox;
  Box<Pedido>? _pedidosBox;
  Box<DetallePedido>? _detallesPedidoBox;
  Box<dynamic>? _lastSyncBox;
  Box<RangoFechas>? _rangosFechasBox;
  Box<FlujoCaja>? _flujosCajaBox;
  bool _isInitialized = false;
  Future<void>? _initFuture;

  Future<void> init() async {
    if (_isInitialized) {
      print('LocalStorageService ya está inicializado');
      return;
    }

    if (_initFuture != null) {
      print('Esperando a que se complete la inicialización en curso...');
      await _initFuture;
      return;
    }

    _initFuture = _initialize();
    await _initFuture;
  }

  Future<void> _initialize() async {
    print('Inicializando LocalStorageService...');
    try {
      // Cerrar todas las cajas si están abiertas
      await _closeAllBoxes();

      // Registrar adaptadores
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TiendaAdapter());
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(LocalidadAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(MonedaAdapter());
      if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(PagoAdapter());
      if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(ProductoAdapter());
      if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(PrecioAdapter());
      if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(StockAdapter());
      if (!Hive.isAdapterRegistered(7)) {
        Hive.registerAdapter(DocumentoAdapter());
      }
      if (!Hive.isAdapterRegistered(8)) {
        Hive.registerAdapter(MovimientoAdapter());
      }
      if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(PedidoAdapter());
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(DetallePedidoAdapter());
      }
      if (!Hive.isAdapterRegistered(11)) {
        Hive.registerAdapter(RangoFechasAdapter());
      }
      if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(FlujoCajaAdapter());
      if (!Hive.isAdapterRegistered(13)) Hive.registerAdapter(UsuarioAdapter());

      // Abrir las cajas de Hive
      _tiendasBox = await Hive.openBox<Tienda>(_tiendasBoxName);
      _localidadesBox = await Hive.openBox<Localidad>(_localidadesBoxName);
      _monedasBox = await Hive.openBox<Moneda>(_monedasBoxName);
      _pagosBox = await Hive.openBox<Pago>(_pagosBoxName);
      _productosBox = await Hive.openBox<Producto>(_productosBoxName);
      _stocksBox = await Hive.openBox<Stock>(_stocksBoxName);
      _preciosBox = await Hive.openBox<Precio>(_preciosBoxName);
      _documentosBox = await Hive.openBox<Documento>(_documentosBoxName);
      _movimientosBox = await Hive.openBox<Movimiento>(_movimientosBoxName);
      _pedidosBox = await Hive.openBox<Pedido>(_pedidosBoxName);
      _detallesPedidoBox = await Hive.openBox<DetallePedido>(
        _detallesPedidoBoxName,
      );
      _lastSyncBox = await Hive.openBox<dynamic>(_lastSyncBoxName);
      _rangosFechasBox = await Hive.openBox<RangoFechas>(_rangosFechasBoxName);
      _flujosCajaBox = await Hive.openBox<FlujoCaja>(_flujosCajaBoxName);

      _isInitialized = true;
      print('LocalStorageService inicializado correctamente');
    } catch (e) {
      print('Error al inicializar LocalStorageService: $e');
      rethrow;
    }
  }

  Future<void> _closeAllBoxes() async {
    try {
      await _tiendasBox?.close();
      await _localidadesBox?.close();
      await _monedasBox?.close();
      await _pagosBox?.close();
      await _productosBox?.close();
      await _stocksBox?.close();
      await _preciosBox?.close();
      await _documentosBox?.close();
      await _movimientosBox?.close();
      await _lastSyncBox?.close();
      await _rangosFechasBox?.close();
      await _flujosCajaBox?.close();

      _localidadesBox = null;
      _tiendasBox = null;
      _monedasBox = null;
      _pagosBox = null;
      _productosBox = null;
      _stocksBox = null;
      _preciosBox = null;
      _documentosBox = null;
      _movimientosBox = null;
      _lastSyncBox = null;
      _rangosFechasBox = null;
      _flujosCajaBox = null;
    } catch (e) {
      print('Error al cerrar las cajas: $e');
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }

  Box<Producto> get _productosBoxInstance {
    if (!_isInitialized || _productosBox == null) {
      throw Exception('LocalStorageService no inicializado');
    }
    return _productosBox!;
  }

  Box<Stock> get _stocksBoxInstance {
    if (!_isInitialized || _stocksBox == null) {
      throw Exception('LocalStorageService no inicializado');
    }
    return _stocksBox!;
  }

  Box<Precio> get _preciosBoxInstance {
    if (!_isInitialized || _preciosBox == null) {
      throw Exception('LocalStorageService no inicializado');
    }
    return _preciosBox!;
  }

  Box<Moneda> get _monedasBoxInstance {
    if (!_isInitialized || _monedasBox == null) {
      throw Exception('LocalStorageService no inicializado');
    }
    return _monedasBox!;
  }

  Box<Pago> get _pagosBoxInstance {
    if (!_isInitialized || _pagosBox == null) {
      throw Exception('LocalStorageService no inicializado');
    }
    return _pagosBox!;
  }

  Box<Localidad> get _localidadesBoxInstance {
    if (!_isInitialized || _localidadesBox == null) {
      throw Exception('LocalStorageService no inicializado');
    }
    return _localidadesBox!;
  }

  Box<Tienda> get _tiendasBoxInstance {
    if (!_isInitialized || _tiendasBox == null) {
      throw Exception('LocalStorageService no inicializado');
    }
    return _tiendasBox!;
  }

  Box<Documento> get _documentosBoxInstance {
    if (!_isInitialized || _documentosBox == null) {
      throw Exception('LocalStorageService no inicializado');
    }
    return _documentosBox!;
  }

  Box<Movimiento> get _movimientosBoxInstance {
    if (!_isInitialized || _movimientosBox == null) {
      throw Exception('LocalStorageService no inicializado');
    }
    return _movimientosBox!;
  }

  Box<Pedido> get _pedidosBoxInstance {
    if (!_isInitialized || _pedidosBox == null) {
      throw Exception('LocalStorageService no inicializado');
    }
    return _pedidosBox!;
  }

  Box<DetallePedido> get _detallesPedidoBoxInstance {
    if (!_isInitialized || _detallesPedidoBox == null) {
      throw Exception('LocalStorageService no inicializado');
    }
    return _detallesPedidoBox!;
  }

  Box<dynamic> get _lastSyncBoxInstance {
    if (!_isInitialized || _lastSyncBox == null) {
      throw Exception('LocalStorageService no inicializado');
    }
    return _lastSyncBox!;
  }

  Box<RangoFechas> get _rangosFechasBoxInstance {
    if (!_isInitialized || _rangosFechasBox == null) {
      throw Exception('LocalStorageService no inicializado');
    }
    return _rangosFechasBox!;
  }

  Box<FlujoCaja> get _flujosCajaBoxInstance {
    if (!_isInitialized || _flujosCajaBox == null) {
      throw Exception('LocalStorageService no inicializado');
    }
    return _flujosCajaBox!;
  }

  // Productos
  Future<List<Producto>> getProductos() async {
    await _ensureInitialized();
    print('Obteniendo productos del almacenamiento local...');
    final productos = _productosBoxInstance.values.toList();
    print('Productos obtenidos del almacenamiento local: ${productos.length}');
    return productos;
  }

  Future<void> saveProductos(List<Producto> productos) async {
    await _ensureInitialized();
    print(
      'Guardando ${productos.length} productos en el almacenamiento local...',
    );
    await _productosBoxInstance.clear();
    await _productosBoxInstance.addAll(productos);
    await _updateLastSync('productos');
    print('Productos guardados correctamente en el almacenamiento local');
  }

  // Stocks
  Future<List<Stock>> getStocks() async {
    await _ensureInitialized();
    print('Obteniendo stocks del almacenamiento local...');
    final stocks = _stocksBoxInstance.values.toList();
    print('Stocks obtenidos del almacenamiento local: ${stocks.length}');
    return stocks;
  }

  Future<void> saveStocks(List<Stock> stocks) async {
    await _ensureInitialized();
    print('Guardando ${stocks.length} stocks en el almacenamiento local...');
    await _stocksBoxInstance.clear();
    await _stocksBoxInstance.addAll(stocks);
    await _updateLastSync('stocks');
    print('Stocks guardados correctamente en el almacenamiento local');
  }

  // Precios
  Future<List<Precio>> getPrecios() async {
    await _ensureInitialized();
    print('Obteniendo precios del almacenamiento local...');
    final precios = _preciosBoxInstance.values.toList();
    print('Precios obtenidos del almacenamiento local: ${precios.length}');
    return precios;
  }

  Future<void> savePrecios(List<Precio> precios) async {
    await _ensureInitialized();
    print('Guardando ${precios.length} precios en el almacenamiento local...');
    await _preciosBoxInstance.clear();
    await _preciosBoxInstance.addAll(precios);
    await _updateLastSync('precios');
    print('Precios guardados correctamente en el almacenamiento local');
  }

  // Monedas
  Future<List<Moneda>> getMonedas() async {
    await _ensureInitialized();
    print('Obteniendo monedas del almacenamiento local...');
    final monedas = _monedasBoxInstance.values.toList();
    print('Monedas obtenidas del almacenamiento local: ${monedas.length}');
    return monedas;
  }

  Future<void> saveMonedas(List<Moneda> monedas) async {
    await _ensureInitialized();
    print('Guardando ${monedas.length} monedas en el almacenamiento local...');
    await _monedasBoxInstance.clear();
    await _monedasBoxInstance.addAll(monedas);
    await _updateLastSync('monedas');
    print('Monedas guardadas correctamente en el almacenamiento local');
  }

  // Pagos
  Future<List<Pago>> getPagos() async {
    await _ensureInitialized();
    print('Obteniendo pagos del almacenamiento local...');
    final pagos = _pagosBoxInstance.values.toList();
    print('pagos obtenidas del almacenamiento local: ${pagos.length}');
    return pagos;
  }

  Future<void> savePagos(List<Pago> pagos) async {
    await _ensureInitialized();
    print('Guardando ${pagos.length} pagos en el almacenamiento local...');
    await _pagosBoxInstance.clear();
    await _pagosBoxInstance.addAll(pagos);
    await _updateLastSync('pagos');
    print('pagos guardadas correctamente en el almacenamiento local');
  }

  // Documentos
  Future<List<Documento>> getDocumentos() async {
    await _ensureInitialized();
    print(
      '📥 [LocalStorage] Obteniendo documentos del almacenamiento local...',
    );
    final documentos = _documentosBoxInstance.values.toList();
    print('📥 [LocalStorage] Documentos obtenidos: ${documentos.length}');
    return documentos;
  }

  Future<void> saveDocumentos(List<Documento> documentos) async {
    await _ensureInitialized();
    print(
      '💾 [LocalStorage] Guardando ${documentos.length} documentos en local...',
    );

    // Obtener los IDs de los documentos a actualizar
    final idsDocumentos = documentos.map((d) => d.idDocumento).toSet();
    print(
      '📋 [LocalStorage] IDs de documentos a actualizar: ${idsDocumentos.length}',
    );

    // Eliminar solo los documentos que se van a actualizar
    int eliminados = 0;
    for (var key in _documentosBoxInstance.keys) {
      final doc = _documentosBoxInstance.get(key);
      if (doc != null && idsDocumentos.contains(doc.idDocumento)) {
        await _documentosBoxInstance.delete(key);
        eliminados++;
      }
    }
    print('🗑️ [LocalStorage] Documentos eliminados: $eliminados');

    // Guardar los nuevos documentos
    await _documentosBoxInstance.addAll(documentos);
    await _updateLastSync('documentos');
    print('✅ [LocalStorage] Documentos guardados correctamente');
  }

  // Movimientos
  Future<List<Movimiento>> getMovimientos() async {
    await _ensureInitialized();
    print('Obteniendo movimientos del almacenamiento local...');
    final movimientos = _movimientosBoxInstance.values.toList();
    print(
      'movimientos obtenidas del almacenamiento local: ${movimientos.length}',
    );
    return movimientos;
  }

  Future<void> saveMovimientos(List<Movimiento> movimientos) async {
    await _ensureInitialized();
    print(
      'Guardando ${movimientos.length} movimientos en el almacenamiento local...',
    );

    // Obtener los IDs de los documentos relacionados con los movimientos
    final idsDocumentos = movimientos.map((m) => m.idDocumento).toSet();

    // Eliminar solo los movimientos relacionados con los documentos actualizados
    for (var key in _movimientosBoxInstance.keys) {
      final mov = _movimientosBoxInstance.get(key);
      if (mov != null && idsDocumentos.contains(mov.idDocumento)) {
        await _movimientosBoxInstance.delete(key);
      }
    }

    // Guardar los nuevos movimientos
    await _movimientosBoxInstance.addAll(movimientos);
    await _updateLastSync('movimientos');
    print('movimientos guardadas correctamente en el almacenamiento local');
  }

  // Localidades
  Future<List<Localidad>> getLocalidades() async {
    await _ensureInitialized();
    print('Obteniendo localidades del almacenamiento local...');
    final localidades = _localidadesBoxInstance.values.toList();
    print(
      'Localidades obtenidas del almacenamiento local: ${localidades.length}',
    );
    return localidades;
  }

  Future<void> saveLocalidades(List<Localidad> localidades) async {
    await _ensureInitialized();
    print(
      'Guardando ${localidades.length} localidades en el almacenamiento local...',
    );
    await _localidadesBoxInstance.clear();
    await _localidadesBoxInstance.addAll(localidades);
    await _updateLastSync('localidades');
    print('Localidades guardadas correctamente en el almacenamiento local');
  }

  // Tiendas
  Future<List<Tienda>> getTiendas() async {
    await _ensureInitialized();
    print('Obteniendo tiendas del almacenamiento local...');
    final tiendas = _tiendasBoxInstance.values.toList();
    print('tiendas obtenidas del almacenamiento local: ${tiendas.length}');
    return tiendas;
  }

  Future<void> saveTiendas(List<Tienda> tiendas) async {
    await _ensureInitialized();
    print('Guardando ${tiendas.length} tiendas en el almacenamiento local...');
    await _tiendasBoxInstance.clear();
    await _tiendasBoxInstance.addAll(tiendas);
    await _localidadesBoxInstance.clear();
    await _updateLastSync('tiendas');
    await _removeLastSync('localidades');
    print('tiendas guardadas correctamente en el almacenamiento local');
  }

  Future<List<Pedido>> getPedidos() async {
    await _ensureInitialized();
    return _pedidosBoxInstance.values.toList();
  }

  Future<void> savePedido(Pedido pedido) async {
    await _ensureInitialized();
    await _pedidosBoxInstance.put(pedido.idPedido, pedido);
  }

  Future<void> saveDetallesPedido(List<DetallePedido> detalles) async {
    await _ensureInitialized();

    await _detallesPedidoBoxInstance.addAll(detalles);
  }

  Future<void> savePedidoCompleto(Pedido pedido) async {
    await _ensureInitialized();

    // Guardar pedido principal
    await _pedidosBoxInstance.put(pedido.idPedido, pedido);

    // Eliminar detalles existentes
    final detallesExistentes = await getDetallesPedido(pedido.idPedido);
    for (var key in detallesExistentes.keys) {
      await _detallesPedidoBoxInstance.delete(key);
    }

    // Guardar nuevos detalles
    await saveDetallesPedido(pedido.detalles);
  }

  // Future<Pedido> getPedidoCompleto(int idPedido) async {
  //   await _ensureInitialized();
  //   final pedido = _pedidosBoxInstance.get(idPedido);
  //   if (pedido == null) throw Exception('Pedido no encontrado');

  //   final detalles = await getDetallesPedido(idPedido);
  //   return pedido.copyWith(detalles: detalles);
  // }

  Future<Map<dynamic, DetallePedido>> getDetallesPedido(int idPedido) async {
    await _ensureInitialized();
    final detalles = _detallesPedidoBoxInstance.toMap();
    detalles.removeWhere((key, value) => value.idPedido != idPedido);
    return detalles;
  }

  Future<List<DetallePedido>> getListDetallesPedido(int idPedido) async {
    await _ensureInitialized();
    final detalles = _detallesPedidoBoxInstance.toMap();
    detalles.removeWhere((key, value) => value.idPedido != idPedido);
    final detallesL = detalles.values.toList();
    return detallesL;
  }

  Future<void> eliminarPedido(Pedido pedido) async {
    await _ensureInitialized();

    // Eliminar detalles primero
    final detalles = await getDetallesPedido(pedido.idPedido);
    for (var key in detalles.keys) {
      await _detallesPedidoBoxInstance.delete(key);
    }

    // Eliminar pedido
    await _pedidosBoxInstance.delete(pedido.idPedido);
  }

  Future<void> _updateLastSync(String entity) async {
    await _ensureInitialized();
    await _lastSyncBoxInstance.put(entity, DateTime.now().toIso8601String());
  }

  Future<void> _removeLastSync(String entity) async {
    await _ensureInitialized();
    await _lastSyncBoxInstance.delete(entity);
  }

  Future<DateTime?> getLastSync(String entity) async {
    await _ensureInitialized();
    final lastSync = _lastSyncBoxInstance.get(entity);
    return lastSync != null ? DateTime.parse(lastSync) : null;
  }

  Future<List<RangoFechas>> getRangosFechas() async {
    await _ensureInitialized();
    final rangos = _rangosFechasBoxInstance.values.toList();
    print('📅 [LocalStorage] Rangos de fechas almacenados: ${rangos.length}');
    for (var rango in rangos) {
      print('  - ${rango.inicio} a ${rango.fin}');
    }
    return rangos;
  }

  Future<void> agregarRangoFechas(RangoFechas nuevoRango) async {
    await _ensureInitialized();

    // Validar que el rango no sea futuro
    final ahora = DateTime.now();
    if (nuevoRango.inicio.isAfter(ahora)) {
      print(
        '⚠️ [LocalStorage] Intento de agregar rango futuro: ${nuevoRango.inicio}',
      );
      return;
    }

    // Convertir el nuevo rango a un rango de mes completo
    final rangoMesCompleto = _getPrimerYUltimoDiaDelMes(nuevoRango.inicio);

    // Ajustar el fin del mes si se extiende más allá del día actual
    DateTime finMesAjustado = rangoMesCompleto.end;
    if (finMesAjustado.isAfter(ahora)) {
      finMesAjustado = DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);
    }

    var rangoAjustado = RangoFechas(
      inicio: rangoMesCompleto.start,
      fin: finMesAjustado,
    );

    print(
      '📅 [LocalStorage] Intentando agregar/unir rango: ${rangoAjustado.inicio} - ${rangoAjustado.fin}',
    );

    final rangosExistentes = await getRangosFechas();
    bool cubierto = false;
    for (var rangoGuardado in rangosExistentes) {
      if (isBeforeOrEqual(rangoAjustado.inicio, rangoGuardado.inicio) &&
          isAfterOrEqual(rangoAjustado.fin, rangoGuardado.fin)) {
        cubierto = true;
        print(
          'ℹ️ [LocalStorage] Rango ${rangoAjustado.inicio} - ${rangoAjustado.fin} ya cubierto por ${rangoGuardado.inicio} - ${rangoGuardado.fin}',
        );
        break;
      }
    }

    if (!cubierto) {
      await _rangosFechasBoxInstance.add(rangoAjustado);
      print('➕ [LocalStorage] Rango agregado: ${rangoAjustado.inicio} - ${rangoAjustado.fin}');
    } else {
      print('✅ [LocalStorage] Rango ya existente o cubierto, no se agregó');
    }
    print('✅ [LocalStorage] Rangos actualizados correctamente');
  }

  bool isAfterOrEqual(DateTime first, DateTime second) {
    return first.isAfter(second) || first.isAtSameMomentAs(second);
  }

  bool isBeforeOrEqual(DateTime first, DateTime second) {
    return first.isBefore(second) || first.isAtSameMomentAs(second);
  }

  DateTimeRange _getPrimerYUltimoDiaDelMes(DateTime fecha) {
    final primerDiaMes = DateTime(fecha.year, fecha.month, 1);
    final ultimoDiaMes = DateTime(
      fecha.year,
      fecha.month + 1,
      0,
      23,
      59,
      59,
    );
    return DateTimeRange(start: primerDiaMes, end: ultimoDiaMes);
  }

  Future<List<DateTimeRange>> getRangosFaltantes(
    DateTimeRange rangoSolicitado,
  ) async {
    await _ensureInitialized();

    final ahora = DateTime.now();
    if (rangoSolicitado.start.isAfter(ahora)) {
      print('⚠️ [LocalStorage] Intento de obtener rangos futuros');
      return [];
    }

    final rangosAlmacenados = await getRangosFechas();
    List<DateTimeRange> rangosFaltantes = [];

    // Iterar por cada mes en el rango solicitado
    DateTime fechaActual = DateTime(
      rangoSolicitado.start.year,
      rangoSolicitado.start.month,
      1,
    );

    while (isBeforeOrEqual(fechaActual, rangoSolicitado.end)) {
      final rangoMes = _getPrimerYUltimoDiaDelMes(fechaActual);

      // Ajustar el fin del mes si se extiende más allá del rango solicitado o del día actual
      DateTime finMesAjustado = rangoMes.end;
      if (finMesAjustado.isAfter(ahora)) {
        finMesAjustado = DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);
      }

      final rangoMesAjustado = DateTimeRange(
        start: rangoMes.start,
        end: finMesAjustado,
      );

      bool cubierto = false;
      for (var rangoGuardado in rangosAlmacenados) {
        // Verificar si el rango guardado cubre completamente el mes ajustado
        if (isBeforeOrEqual(rangoMesAjustado.start, rangoGuardado.inicio) &&
            isAfterOrEqual(rangoMesAjustado.end, rangoGuardado.fin)) {
          cubierto = true;
          break;
        }
      }

      if (!cubierto) {
        rangosFaltantes.add(rangoMesAjustado);
      }

      // Avanzar al siguiente mes
      fechaActual = DateTime(fechaActual.year, fechaActual.month + 1, 1);
    }

    print('📊 [LocalStorage] Total rangos faltantes: ${rangosFaltantes.length}');
    for (var rango in rangosFaltantes) {
      print('  - Faltante: ${rango.start} a ${rango.end}');
    }
    return rangosFaltantes;
  }

  // Flujos de Caja
  Future<List<FlujoCaja>> getFlujosCaja() async {
    await _ensureInitialized();
    print('Obteniendo flujos de caja del almacenamiento local...');
    final flujos = _flujosCajaBoxInstance.values.toList();
    print('Flujos de caja obtenidos:  ${flujos.length}');
    return flujos;
  }

  Future<void> saveFlujosCaja(List<FlujoCaja> flujos) async {
    await _ensureInitialized();
    print('Guardando ${flujos.length} flujos de caja en el almacenamiento local...');
    await _flujosCajaBoxInstance.clear();
    await _flujosCajaBoxInstance.addAll(flujos);
    await _updateLastSync('flujos_caja');
    print('Flujos de caja guardados correctamente.');
  }
}
