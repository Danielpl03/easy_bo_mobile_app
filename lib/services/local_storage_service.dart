// ignore_for_file: avoid_print

import 'package:easy_bo_mobile_app/models/detalle_pedido.dart';
import 'package:easy_bo_mobile_app/models/documento.dart';
import 'package:easy_bo_mobile_app/models/movimiento.dart';
import 'package:easy_bo_mobile_app/models/pago.dart';
import 'package:easy_bo_mobile_app/models/pedido.dart';
import 'package:easy_bo_mobile_app/models/rango_fechas.dart';
import 'package:easy_bo_mobile_app/models/tienda.dart';
import 'package:easy_bo_mobile_app/models/usuario.dart';
import 'package:easy_bo_mobile_app/models/cliente.dart';
import 'package:easy_bo_mobile_app/models/proveedor.dart';
import 'package:easy_bo_mobile_app/models/producto_proveedor.dart';
import 'package:easy_bo_mobile_app/models/producto_imagen.dart';
import 'package:easy_bo_mobile_app/models/categoria.dart';
import 'package:easy_bo_mobile_app/models/departamento.dart';
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
  static const String _clientesBoxName = 'clientes';
  static const String _proveedoresBoxName = 'proveedores';
  static const String _productosProveedoresBoxName = 'productos_proveedores';
  static const String _productosImagenesBoxName = 'productos_imagenes';
  static const String _categoriasBoxName = 'categorias';
  static const String _departamentosBoxName = 'departamentos';

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
  Box<DateTime>? _rangosFechasBox;
  Box<FlujoCaja>? _flujosCajaBox;
  Box<Cliente>? _clientesBox;
  Box<Proveedor>? _proveedoresBox;
  Box<ProductoProveedor>? _productosProveedoresBox;
  Box<ProductoImagen>? _productosImagenesBox;
  Box<Categoria>? _categoriasBox;
  Box<Departamento>? _departamentosBox;
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
      if (!Hive.isAdapterRegistered(12))
        Hive.registerAdapter(FlujoCajaAdapter());
      if (!Hive.isAdapterRegistered(13)) Hive.registerAdapter(UsuarioAdapter());
      if (!Hive.isAdapterRegistered(14))
        Hive.registerAdapter(CategoriaAdapter());
      if (!Hive.isAdapterRegistered(15))
        Hive.registerAdapter(DepartamentoAdapter());
      if (!Hive.isAdapterRegistered(16))
        Hive.registerAdapter(ProveedorAdapter());
      if (!Hive.isAdapterRegistered(17)) Hive.registerAdapter(ClienteAdapter());
      if (!Hive.isAdapterRegistered(18))
        Hive.registerAdapter(ProductoProveedorAdapter());
      if (!Hive.isAdapterRegistered(19))
        Hive.registerAdapter(ProductoImagenAdapter());

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
      _rangosFechasBox = await Hive.openBox<DateTime>(_rangosFechasBoxName);
      _flujosCajaBox = await Hive.openBox<FlujoCaja>(_flujosCajaBoxName);
      _clientesBox = await Hive.openBox<Cliente>(_clientesBoxName);
      _proveedoresBox = await Hive.openBox<Proveedor>(_proveedoresBoxName);
      _productosProveedoresBox = await Hive.openBox<ProductoProveedor>(
        _productosProveedoresBoxName,
      );
      _productosImagenesBox = await Hive.openBox<ProductoImagen>(
        _productosImagenesBoxName,
      );
      _categoriasBox = await Hive.openBox<Categoria>(_categoriasBoxName);
      _departamentosBox = await Hive.openBox<Departamento>(
        _departamentosBoxName,
      );

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
      await _clientesBox?.close();
      await _proveedoresBox?.close();
      await _productosProveedoresBox?.close();
      await _productosImagenesBox?.close();
      await _categoriasBox?.close();
      await _departamentosBox?.close();

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
      _clientesBox = null;
      _proveedoresBox = null;
      _productosProveedoresBox = null;
      _productosImagenesBox = null;
      _categoriasBox = null;
      _departamentosBox = null;
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

  Box<DateTime> get _rangosFechasBoxInstance {
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

  Box<Cliente> get _clientesBoxInstance {
    if (!_isInitialized || _clientesBox == null) {
      throw Exception('LocalStorageService no inicializado');
    }
    return _clientesBox!;
  }

  Box<Proveedor> get _proveedoresBoxInstance {
    if (!_isInitialized || _proveedoresBox == null) {
      throw Exception('LocalStorageService no inicializado');
    }
    return _proveedoresBox!;
  }

  Box<ProductoProveedor> get _productosProveedoresBoxInstance {
    if (!_isInitialized || _productosProveedoresBox == null) {
      throw Exception('LocalStorageService no inicializado');
    }
    return _productosProveedoresBox!;
  }

  Box<ProductoImagen> get _productosImagenesBoxInstance {
    if (!_isInitialized || _productosImagenesBox == null) {
      throw Exception('LocalStorageService no inicializado');
    }
    return _productosImagenesBox!;
  }

  Box<Categoria> get _categoriasBoxInstance {
    if (!_isInitialized || _categoriasBox == null) {
      throw Exception('LocalStorageService no inicializado');
    }
    return _categoriasBox!;
  }

  Box<Departamento> get _departamentosBoxInstance {
    if (!_isInitialized || _departamentosBox == null) {
      throw Exception('LocalStorageService no inicializado');
    }
    return _departamentosBox!;
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
    print(
      '📥 [LocalStorage] Obteniendo movimientos del almacenamiento local...',
    );
    final movimientos = _movimientosBoxInstance.values.toList();

    // Contar movimientos con costo
    final movsConCosto =
        movimientos
            .where((m) => m.costoProducto != null && m.costoProducto! > 0)
            .length;
    print(
      '📥 [LocalStorage] Movimientos obtenidos del almacenamiento local: ${movimientos.length}',
    );
    print(
      '💰 [LocalStorage] Movimientos con costo desde local: $movsConCosto de ${movimientos.length}',
    );

    return movimientos;
  }

  Future<void> saveMovimientos(List<Movimiento> movimientos) async {
    await _ensureInitialized();
    print(
      '💾 [LocalStorage] Guardando ${movimientos.length} movimientos en el almacenamiento local...',
    );

    // Obtener los IDs de los documentos relacionados con los movimientos
    final idsDocumentos = movimientos.map((m) => m.idDocumento).toSet();

    // Eliminar solo los movimientos relacionados con los documentos actualizados
    int eliminados = 0;
    for (var key in _movimientosBoxInstance.keys) {
      final mov = _movimientosBoxInstance.get(key);
      if (mov != null && idsDocumentos.contains(mov.idDocumento)) {
        await _movimientosBoxInstance.delete(key);
        eliminados++;
      }
    }
    print('🗑️ [LocalStorage] Movimientos eliminados: $eliminados');

    // Guardar los nuevos movimientos
    await _movimientosBoxInstance.addAll(movimientos);

    await _updateLastSync('movimientos');
    print(
      '✅ [LocalStorage] Movimientos guardados correctamente en el almacenamiento local',
    );
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

  Future<List<DateTime>> getRangosFechas() async {
    await _ensureInitialized();
    final rangos = _rangosFechasBoxInstance.values.toList();
    print('📅 [LocalStorage] Rangos de fechas almacenados: ${rangos.length}');
    for (var rango in rangos) {
      print(rango);
    }
    return rangos;
  }

  /// Guarda o actualiza la fecha para un mes específico
  /// Para meses completos: guarda el primer día del mes (anio, mes, 1)
  /// Para mes actual parcial: guarda la última fecha descargada
  Future<void> guardarFechaParaMes(int anio, int mes, DateTime fecha) async {
    await _ensureInitialized();
    // Usar una clave única basada en anio-mes para evitar duplicados
    final clave = '${anio}_${mes}';

    // Eliminar fecha anterior si existe (usando la clave directamente)
    if (_rangosFechasBoxInstance.containsKey(clave)) {
      await _rangosFechasBoxInstance.delete(clave);
    } else {
      // Si no existe con la clave string, buscar por valores (compatibilidad con datos antiguos)
      final fechaAnterior = await _getFechaGuardadaParaMes(anio, mes);
      if (fechaAnterior != null) {
        // Buscar y eliminar la fecha anterior usando cualquier tipo de clave
        for (var key in _rangosFechasBoxInstance.keys) {
          final fechaGuardada = _rangosFechasBoxInstance.get(key);
          if (fechaGuardada != null &&
              fechaGuardada.year == anio &&
              fechaGuardada.month == mes) {
            await _rangosFechasBoxInstance.delete(key);
            break;
          }
        }
      }
    }

    // Guardar la nueva fecha
    await _rangosFechasBoxInstance.put(clave, fecha);
  }

  /// Agrega rangos de fechas (método legacy, mantener para compatibilidad)
  /// Ahora usa guardarFechaParaMes internamente
  Future<void> agregarRangoFechas(List<DateTime> fechas) async {
    await _ensureInitialized();
    // Este método ahora se usa principalmente para meses completos
    // donde cada DateTime representa el primer día del mes
    for (var fecha in fechas) {
      await guardarFechaParaMes(fecha.year, fecha.month, fecha);
    }
  }

  bool isAfterOrEqual(DateTime first, DateTime second) {
    return first.isAfter(second) || first.isAtSameMomentAs(second);
  }

  bool isBeforeOrEqual(DateTime first, DateTime second) {
    return first.isBefore(second) || first.isAtSameMomentAs(second);
  }

  /// Obtiene el primer día de cada mes contenido en el rango de fechas
  /// Para el mes actual, devuelve el primer día del mes (no la fecha actual)
  List<DateTime> _getMeses(DateTime fechaInicio, DateTime fechaFin) {
    List<DateTime> meses = [];
    DateTime fechaActual = DateTime(fechaInicio.year, fechaInicio.month, 1);
    DateTime fechaFinMes = DateTime(fechaFin.year, fechaFin.month, 1);

    // Agregar el primer mes
    meses.add(fechaActual);

    // Agregar meses intermedios
    while (fechaActual.isBefore(fechaFinMes)) {
      fechaActual = DateTime(fechaActual.year, fechaActual.month + 1, 1);
      meses.add(fechaActual);
    }

    return meses;
  }

  /// Obtiene la fecha guardada para un mes específico (anio-mes)
  /// Retorna null si el mes no está guardado
  /// Busca primero por la clave string, luego por valores (compatibilidad)
  Future<DateTime?> _getFechaGuardadaParaMes(int anio, int mes) async {
    await _ensureInitialized();
    final clave = '${anio}_${mes}';

    // Buscar primero por la clave string (método preferido)
    if (_rangosFechasBoxInstance.containsKey(clave)) {
      return _rangosFechasBoxInstance.get(clave);
    }

    // Buscar por valores (compatibilidad con datos antiguos)
    final rangosExistentes = await getRangosFechas();
    for (var fechaGuardada in rangosExistentes) {
      if (fechaGuardada.year == anio && fechaGuardada.month == mes) {
        return fechaGuardada;
      }
    }
    return null;
  }

  /// Obtiene la última fecha descargada del mes actual
  /// Retorna null si el mes actual no tiene datos descargados
  Future<DateTime?> getUltimaFechaMesActual() async {
    await _ensureInitialized();
    final ahora = DateTime.now();
    return await _getFechaGuardadaParaMes(ahora.year, ahora.month);
  }

  /// Verifica si un mes completo está descargado
  /// Un mes está completo si tiene guardado el primer día del mes
  bool _esMesCompleto(DateTime fechaGuardada, int anio, int mes) {
    return fechaGuardada.year == anio &&
        fechaGuardada.month == mes &&
        fechaGuardada.day == 1;
  }

  Future<List<DateTime>> getRangosFaltantes(
    DateTimeRange rangoSolicitado,
  ) async {
    await _ensureInitialized();
    final rangoMeses = _getMeses(rangoSolicitado.start, rangoSolicitado.end);
    List<DateTime> rangosFaltantes = [];
    final ahora = DateTime.now();

    for (var primerDiaMes in rangoMeses) {
      final anio = primerDiaMes.year;
      final mes = primerDiaMes.month;
      final esMesActual = anio == ahora.year && mes == ahora.month;

      final fechaGuardada = await _getFechaGuardadaParaMes(anio, mes);

      if (fechaGuardada == null) {
        // Mes no descargado, agregar a faltantes
        rangosFaltantes.add(primerDiaMes);
      } else if (esMesActual) {
        // Para el mes actual, verificar si necesita actualización
        // Si la fecha guardada es anterior a hoy, necesita actualización
        final fechaHoy = DateTime(ahora.year, ahora.month, ahora.day);
        final fechaGuardadaSinHora = DateTime(
          fechaGuardada.year,
          fechaGuardada.month,
          fechaGuardada.day,
        );

        if (fechaGuardadaSinHora.isBefore(fechaHoy)) {
          // Necesita actualización incremental
          rangosFaltantes.add(primerDiaMes);
        }
        // Si la fecha guardada es hoy o posterior, el mes está actualizado
      } else {
        // Para meses pasados, verificar si está completo
        if (!_esMesCompleto(fechaGuardada, anio, mes)) {
          // Mes parcial, necesita descarga completa
          rangosFaltantes.add(primerDiaMes);
        }
        // Si es completo (día 1), no necesita descarga
      }
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
    print(
      'Guardando ${flujos.length} flujos de caja en el almacenamiento local...',
    );
    await _flujosCajaBoxInstance.putAll({
      for (FlujoCaja fc in flujos) fc.idFlujo: fc,
    });
    await _updateLastSync('flujos_caja');
    print('Flujos de caja guardados correctamente.');
  }

  // Clientes
  Future<List<Cliente>> getClientes() async {
    await _ensureInitialized();
    print('Obteniendo clientes del almacenamiento local...');
    final clientes = _clientesBoxInstance.values.toList();
    print('Clientes obtenidos del almacenamiento local: ${clientes.length}');
    return clientes;
  }

  Future<void> saveClientes(List<Cliente> clientes) async {
    await _ensureInitialized();
    print(
      'Guardando ${clientes.length} clientes en el almacenamiento local...',
    );
    await _clientesBoxInstance.clear();
    await _clientesBoxInstance.addAll(clientes);
    await _updateLastSync('clientes');
    print('Clientes guardados correctamente en el almacenamiento local');
  }

  // Proveedores
  Future<List<Proveedor>> getProveedores() async {
    await _ensureInitialized();
    print('Obteniendo proveedores del almacenamiento local...');
    final proveedores = _proveedoresBoxInstance.values.toList();
    print(
      'Proveedores obtenidos del almacenamiento local: ${proveedores.length}',
    );
    return proveedores;
  }

  Future<void> saveProveedores(List<Proveedor> proveedores) async {
    await _ensureInitialized();
    print(
      'Guardando ${proveedores.length} proveedores en el almacenamiento local...',
    );
    await _proveedoresBoxInstance.clear();
    await _proveedoresBoxInstance.addAll(proveedores);
    await _updateLastSync('proveedores');
    print('Proveedores guardados correctamente en el almacenamiento local');
  }

  // Productos Proveedores
  Future<List<ProductoProveedor>> getProductosProveedores() async {
    await _ensureInitialized();
    print('Obteniendo productos proveedores del almacenamiento local...');
    final productosProveedores =
        _productosProveedoresBoxInstance.values.toList();
    print(
      'Productos proveedores obtenidos del almacenamiento local: ${productosProveedores.length}',
    );
    return productosProveedores;
  }

  Future<void> saveProductosProveedores(
    List<ProductoProveedor> productosProveedores, {
    bool removeOthers = true,
  }) async {
    await _ensureInitialized();
    print(
      'Guardando ${productosProveedores.length} productos proveedores en el almacenamiento local...',
    );
    if (removeOthers) {
      await _productosProveedoresBoxInstance.clear();
      await _productosProveedoresBoxInstance.putAll({
        for (ProductoProveedor pp in productosProveedores) pp.idRelacion: pp,
      });
    } else {
      for (ProductoProveedor pp in productosProveedores) {
        if (_productosProveedoresBoxInstance.containsKey(pp.idRelacion)) {
          _productosProveedoresBoxInstance.delete(pp.idRelacion);
        }
        await _productosProveedoresBoxInstance.put(pp.idRelacion, pp);
      }
    }
    await _updateLastSync('productos_proveedores');
    print(
      'Productos proveedores guardados correctamente en el almacenamiento local',
    );
  }

  // Productos Imagenes
  Future<List<ProductoImagen>> getProductosImagenes() async {
    await _ensureInitialized();
    print('Obteniendo productos imagenes del almacenamiento local...');
    final imagenes = _productosImagenesBoxInstance.values.toList();
    print(
      'Productos imagenes obtenidos del almacenamiento local: ${imagenes.length}',
    );
    return imagenes;
  }

  Future<void> saveProductosImagenes(
    List<ProductoImagen> imagenes, {
    bool removeOthers = true,
  }) async {
    await _ensureInitialized();
    print(
      'Guardando ${imagenes.length} productos imagenes en el almacenamiento local...',
    );
    if (removeOthers) {
      await _productosImagenesBoxInstance.clear();
      await _productosImagenesBoxInstance.putAll({
        for (ProductoImagen img in imagenes) img.idRelacion: img,
      });
    } else {
      for (ProductoImagen img in imagenes) {
        if (_productosImagenesBoxInstance.containsKey(img.idRelacion)) {
          _productosImagenesBoxInstance.delete(img.idRelacion);
        }
        await _productosImagenesBoxInstance.put(img.idRelacion, img);
      }
    }
    await _updateLastSync('productos_imagenes');
    print(
      'Productos imagenes guardados correctamente en el almacenamiento local',
    );
  }

  Future<void> deleteProductoImagenLocal(int idRelacion) async {
    await _ensureInitialized();
    await _productosImagenesBoxInstance.delete(idRelacion);
  }

  // Categorias
  Future<List<Categoria>> getCategorias() async {
    await _ensureInitialized();
    print('Obteniendo categorias del almacenamiento local...');
    final categorias = _categoriasBoxInstance.values.toList();
    print(
      'Categorias obtenidas del almacenamiento local: ${categorias.length}',
    );
    return categorias;
  }

  Future<void> saveCategorias(List<Categoria> categorias) async {
    await _ensureInitialized();
    print(
      'Guardando ${categorias.length} categorias en el almacenamiento local...',
    );
    await _categoriasBoxInstance.clear();
    await _categoriasBoxInstance.addAll(categorias);
    await _updateLastSync('categorias');
    print('Categorias guardadas correctamente en el almacenamiento local');
  }

  // Departamentos
  Future<List<Departamento>> getDepartamentos() async {
    await _ensureInitialized();
    print('Obteniendo departamentos del almacenamiento local...');
    final departamentos = _departamentosBoxInstance.values.toList();
    print(
      'Departamentos obtenidos del almacenamiento local: ${departamentos.length}',
    );
    return departamentos;
  }

  Future<void> saveDepartamentos(List<Departamento> departamentos) async {
    await _ensureInitialized();
    print(
      'Guardando ${departamentos.length} departamentos en el almacenamiento local...',
    );
    await _departamentosBoxInstance.clear();
    await _departamentosBoxInstance.addAll(departamentos);
    await _updateLastSync('departamentos');
    print('Departamentos guardados correctamente en el almacenamiento local');
  }
}
