import 'dart:async';
import 'dart:io';

import 'package:easy_bo_mobile_app/config/supabase_config.dart';
import 'package:easy_bo_mobile_app/models/mensaje.dart' show Mensaje, TipoMensaje;
import 'package:easy_bo_mobile_app/models/precio.dart';
import 'package:easy_bo_mobile_app/models/producto.dart';
import 'package:easy_bo_mobile_app/models/stock.dart';
import 'package:easy_bo_mobile_app/presentation/providers/tiendas_provider.dart';
import 'package:easy_bo_mobile_app/services/local_storage_service.dart';
import 'package:easy_bo_mobile_app/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

class Filtros {
  bool? conStock;
  bool soloActivos = true;
  String search = '';

  Filtros({this.conStock});
}

class ProductosProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService(
    SupabaseConfig.client,
  );
  final LocalStorageService _localStorageService = LocalStorageService();

  bool _isDisposed = false;
  Future? _pendingRequest;

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

  Mensaje? _message;
  bool _cargando = false;

  void _mostrarMensaje(Mensaje mensaje) {
    _message = mensaje;
    actualizarEstado();
  }

  void clearMensaje() {
    _message = Mensaje();
    actualizarEstado();
  }

  Mensaje? get message => _message;
  bool get cargando => _cargando;

  final List<Producto> productos = [];
  final List<Producto> productosFiltrados = [];
  final List<Producto> productosVentas = [];

  final TiendasProvider tiendasProvider;

  ProductosProvider(this.tiendasProvider) {
    getProductos(forceUpdate: false);
  }

  Filtros filtros = Filtros();

  void setSearch(String search) {
    filtros.search = search;
    filterProducts();
    actualizarEstado();
  }

  void setSoloActivos(bool soloActivos) {
    filtros.soloActivos = soloActivos;
    filterProducts();
    actualizarEstado();
  }

  void setConStock(bool? conStock) {
    filtros.conStock = conStock;
    filterProducts();
    actualizarEstado();
  }

  Future<void> getProductos({bool forceUpdate = false}) async {
    cancelPendingRequest();
    final completer = Completer();
    _pendingRequest = completer.future;
    try {
      _message = Mensaje();
      _cargando = true;
      actualizarEstado();
      if (!forceUpdate) {
        final productosLocales = await _localStorageService.getProductos();
        if (productosLocales.isNotEmpty) {
          final preciosLocales = await _localStorageService.getPrecios();
          final stocksLocales = await _localStorageService.getStocks();

          if (preciosLocales.isNotEmpty && stocksLocales.isNotEmpty) {
            this.productos.addAll(
              enrichProducts(productosLocales, stocksLocales, preciosLocales),
            );
            filterProducts();
            return;
          }
        }
      }

      final productos = await _supabaseService.getProductos();
      final precios = await _supabaseService.getPrecios();
      final stocks = await _supabaseService.getStocks();
      this.productos.clear();

      this.productos.addAll(enrichProducts(productos, stocks, precios));

      unawaited(updateProductos(productos));
      unawaited(updatePrecios(precios));
      unawaited(updateStocks(stocks));

      filterProducts();
      _mostrarMensaje(
        Mensaje(
          mensaje: 'Productos actualizados',
          tipoMensaje: TipoMensaje.succes,
        ),
      );
    } on SocketException catch (_) {
      _mostrarMensaje(
        Mensaje(
          mensaje: 'Sin conexión - Mostrando datos locales',
          tipoMensaje: TipoMensaje.error,
        ),
      );
    } on PostgrestException catch (e) {
      _mostrarMensaje(
        Mensaje(
          mensaje: 'Error en Supabase: ${e.message}',
          tipoMensaje: TipoMensaje.error,
        ),
      );
    } finally {
      _cargando = false;
      if (!completer.isCompleted) completer.complete();
      actualizarEstado();
    }
  }

  void actualizarEstado() {
    if (!_isDisposed) notifyListeners();
  }

  Future<void> updateProductos(List<Producto> productos) async {
    _localStorageService.saveProductos(productos);
  }

  Future<void> updatePrecios(List<Precio> precios) async {
    _localStorageService.savePrecios(precios);
  }

  Future<void> updateStocks(List<Stock> stocks) async {
    _localStorageService.saveStocks(stocks);
  }

  List<Producto> enrichProducts(
    List<Producto> productos,
    List<Stock> stocks,
    List<Precio> precios,
  ) {
    for (Producto p in productos) {
      for (Stock s in stocks) {
        if (p.idProducto == s.idProducto && !p.stocks.contains(s)) {
          p.stocks.add(s);
        }
      }
      for (Precio pr in precios) {
        if (p.idProducto == pr.idProducto && !p.precios.contains(pr)) {
          p.precios.add(pr);
        }
      }
    }
    return productos;
  }

  void filterProducts() {
    if (filtros.search.isNotEmpty) {
      final productosFiltrados =
          productos
              .where(
                (p) =>
                    p.descripcion.toLowerCase().contains(
                      filtros.search.toLowerCase(),
                    ) ||
                    (p.codigo != null &&
                        p.codigo!.toLowerCase().contains(
                          filtros.search.toLowerCase(),
                        )),
              )
              .toList();
      this.productosFiltrados.clear();
      this.productosFiltrados.addAll(productosFiltrados);
    } else {
      productosFiltrados.clear();
      productosFiltrados.addAll(productos);
    }

    if (filtros.soloActivos) {
      final productosFiltrados =
          this.productosFiltrados
              .where((p) => p.activo == filtros.soloActivos)
              .toList();
      this.productosFiltrados.clear();
      this.productosFiltrados.addAll(productosFiltrados);
    }

    if (filtros.conStock != null) {
      if (filtros.conStock == true) {
        List<int> localidadesSeleccionadas =
            tiendasProvider.localidadesSeleccionadas
                .map((e) => e.idLocalidad)
                .toList();
        final productosFiltrados =
            this.productosFiltrados
                .where(
                  (p) =>
                      p.stocks.isNotEmpty &&
                      p.stocks.any(
                        (s) =>
                            localidadesSeleccionadas.contains(s.idLocalidad) &&
                            s.stock > 0,
                      ),
                )
                .toList();
        this.productosFiltrados.clear();
        this.productosFiltrados.addAll(productosFiltrados);
      } else {
        final productosFiltrados =
            this.productosFiltrados
                .where(
                  (p) => p.stocks.isEmpty || p.stocks.every( (s) => s.stock <= 0 ))
                .toList();
        this.productosFiltrados.clear();
        this.productosFiltrados.addAll(productosFiltrados);
      }
    }

    productosFiltrados.sort((a, b) => a.descripcion.compareTo(b.descripcion));
  }

  // En productos_provider.dart
  void getProductosByIDS(List<int> ids) async {
    if (productos.isEmpty) {
      await getProductos();
    }

    final nuevosProductos =
        productos.where((p) => ids.contains(p.idProducto)).toList();

    productosVentas.clear();
    productosVentas.addAll(nuevosProductos);
    actualizarEstado();
  }

  // Método para comparar stocks entre localidades
  List<Producto> compararStocksEntreLocalidades(int localidad1, int localidad2) {
    return productos.where((producto) {
      final stock1 = producto.stocks.firstWhere(
        (s) => s.idLocalidad == localidad1,
        orElse: () => Stock(
          idLocalidad: localidad1,
          idProducto: producto.idProducto,
          stock: 0,
          idStock: 0,
        ),
      );
      
      final stock2 = producto.stocks.firstWhere(
        (s) => s.idLocalidad == localidad2,
        orElse: () => Stock(
          idLocalidad: localidad2,
          idProducto: producto.idProducto,
          stock: 0,
          idStock: 0,
        ),
      );

      // Retorna true si hay stock en la primera localidad pero no en la segunda
      return stock1.stock > 0 && stock2.stock == 0;
    }).toList();
  }
}
