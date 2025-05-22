// ignore_for_file: avoid_print

import 'package:easy_bo_mobile_app/models/detalle_pedido.dart';
import 'package:easy_bo_mobile_app/models/documento.dart';
import 'package:easy_bo_mobile_app/models/movimiento.dart';
import 'package:easy_bo_mobile_app/models/pago.dart';
import 'package:easy_bo_mobile_app/models/pedido.dart';
import 'package:easy_bo_mobile_app/models/tienda.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/producto.dart';
import '../models/stock.dart';
import '../models/precio.dart';
import '../models/moneda.dart';
import '../models/localidad.dart';

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

      // Limpiar todas las cajas
      // await _clearAllBoxes();

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
      _lastSyncBox = await Hive.openBox(_lastSyncBoxName);

      _isInitialized = true;
      print('Cajas de Hive abiertas correctamente');
    } catch (e) {
      print('Error al abrir las cajas de Hive: $e');
      _isInitialized = false;
      rethrow;
    } finally {
      _initFuture = null;
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
    } catch (e) {
      print('Error al cerrar las cajas: $e');
    }
  }

  Future<void> _clearAllBoxes() async {
    try {
      await Hive.deleteBoxFromDisk(_productosBoxName);
      await Hive.deleteBoxFromDisk(_stocksBoxName);
      await Hive.deleteBoxFromDisk(_preciosBoxName);
      await Hive.deleteBoxFromDisk(_monedasBoxName);
      await Hive.deleteBoxFromDisk(_localidadesBoxName);
      await Hive.deleteBoxFromDisk(_lastSyncBoxName);
    } catch (e) {
      print('Error al limpiar las cajas: $e');
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
    print('Obteniendo documentos del almacenamiento local...');
    final documentos = _documentosBoxInstance.values.toList();
    print(
      'documentos obtenidas del almacenamiento local: ${documentos.length}',
    );
    return documentos;
  }

  Future<void> saveDocumentos(List<Documento> documentos) async {
    await _ensureInitialized();
    print('Guardando ${documentos.length} documentos en el almacenamiento local...');
    
    // Obtener los IDs de los documentos a actualizar
    final idsDocumentos = documentos.map((d) => d.idDocumento).toSet();
    
    // Eliminar solo los documentos que se van a actualizar
    for (var key in _documentosBoxInstance.keys) {
      final doc = _documentosBoxInstance.get(key);
      if (doc != null && idsDocumentos.contains(doc.idDocumento)) {
        await _documentosBoxInstance.delete(key);
      }
    }
    
    // Guardar los nuevos documentos
    await _documentosBoxInstance.addAll(documentos);
    await _updateLastSync('documentos');
    print('documentos guardadas correctamente en el almacenamiento local');
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
    print('Guardando ${movimientos.length} movimientos en el almacenamiento local...');
    
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
  final detalles =  _detallesPedidoBoxInstance.toMap();
  detalles.removeWhere( (key,value) => value.idPedido != idPedido );
  return detalles;
}

Future<List<DetallePedido>> getListDetallesPedido(int idPedido) async {
  await _ensureInitialized();
  final detalles =  _detallesPedidoBoxInstance.toMap();
  detalles.removeWhere( (key,value) => value.idPedido != idPedido );
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
}
