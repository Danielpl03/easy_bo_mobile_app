import 'dart:async';
import 'dart:io';

import 'package:easy_bo_mobile_app/config/supabase_config.dart';
import 'package:easy_bo_mobile_app/models/categoria.dart';
import 'package:easy_bo_mobile_app/models/departamento.dart';
import 'package:easy_bo_mobile_app/models/mensaje.dart'
    show Mensaje, TipoMensaje;
import 'package:easy_bo_mobile_app/models/precio.dart';
import 'package:easy_bo_mobile_app/models/producto.dart';
import 'package:easy_bo_mobile_app/models/producto_imagen.dart';
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
  int? idDepartamento;
  int? idCategoria;
  // Nuevos campos para filtro personalizado
  bool filtroPersonalizado = false;
  int? cantidadPersonalizada;
  bool mayorQue = true; // true: mayor que, false: menor que

  Filtros({this.conStock});

  bool get tieneFiltrosCatalogo =>
      idDepartamento != null || idCategoria != null;
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
  bool _cargandoCatalogos = false;

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
  bool get cargandoCatalogos => _cargandoCatalogos;

  final List<Producto> productos = [];
  final List<Producto> productosFiltrados = [];
  final List<Producto> productosVentas = [];
  final List<Departamento> departamentos = [];
  final List<Categoria> categorias = [];

  final TiendasProvider tiendasProvider;

  ProductosProvider(this.tiendasProvider) {
    getProductos(forceUpdate: false);
  }

  List<Categoria> get categoriasVisibles {
    if (filtros.idDepartamento == null) return categorias;
    return categorias
        .where((c) => c.idDepartamento == filtros.idDepartamento)
        .toList();
  }

  String? nombreDepartamentoSeleccionado() {
    if (filtros.idDepartamento == null) return null;
    return departamentos
        .where((d) => d.idDepartamento == filtros.idDepartamento)
        .map((d) => d.nombre)
        .firstOrNull;
  }

  String? nombreCategoriaSeleccionada() {
    if (filtros.idCategoria == null) return null;
    return categorias
        .where((c) => c.idCategoria == filtros.idCategoria)
        .map((c) => c.nombre)
        .firstOrNull;
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

  void setFiltroPersonalizado(bool activado) {
    filtros.filtroPersonalizado = activado;
    if (activado) {
      filtros.conStock = null; // Desactiva otros filtros de stock
    }
    filterProducts();
    actualizarEstado();
  }

  void setCantidadPersonalizada(int? cantidad) {
    filtros.cantidadPersonalizada = cantidad;
    filterProducts();
    actualizarEstado();
  }

  void setComparacionPersonalizada(bool mayorQue) {
    filtros.mayorQue = mayorQue;
    filterProducts();
    actualizarEstado();
  }

  void setDepartamento(int? idDepartamento) {
    filtros.idDepartamento = idDepartamento;
    if (idDepartamento == null) {
      filtros.idCategoria = null;
    } else if (filtros.idCategoria != null) {
      final categoriaValida = categorias.any(
        (c) =>
            c.idCategoria == filtros.idCategoria &&
            c.idDepartamento == idDepartamento,
      );
      if (!categoriaValida) filtros.idCategoria = null;
    }
    filterProducts();
    actualizarEstado();
  }

  void setCategoria(int? idCategoria) {
    filtros.idCategoria = idCategoria;
    if (idCategoria != null) {
      final categoria = categorias.firstWhere(
        (c) => c.idCategoria == idCategoria,
      );
      filtros.idDepartamento = categoria.idDepartamento;
    }
    filterProducts();
    actualizarEstado();
  }

  void limpiarFiltrosCatalogo() {
    filtros.idDepartamento = null;
    filtros.idCategoria = null;
    filterProducts();
    actualizarEstado();
  }

  void _aplicarCatalogos(List<Departamento> deptos, List<Categoria> cats) {
    departamentos
      ..clear()
      ..addAll(
        deptos.where((d) => d.web).toList()
          ..sort((a, b) => a.orden.compareTo(b.orden)),
      );
    categorias
      ..clear()
      ..addAll(cats.where((c) => c.web));
  }

  Future<void> getCatalogos({bool forceUpdate = false}) async {
    if (_cargandoCatalogos) return;
    _cargandoCatalogos = true;
    try {
      if (!forceUpdate) {
        final departamentosLocales =
            await _localStorageService.getDepartamentos();
        final categoriasLocales = await _localStorageService.getCategorias();
        if (departamentosLocales.isNotEmpty) {
          _aplicarCatalogos(departamentosLocales, categoriasLocales);
          if (departamentos.isNotEmpty && categorias.isNotEmpty) {
            actualizarEstado();
            return;
          }
        }
      }

      final departamentosRemotos = await _supabaseService.getDepartamentos();
      final categoriasRemotas = await _supabaseService.getCategorias();

      _aplicarCatalogos(departamentosRemotos, categoriasRemotas);

      if (departamentosRemotos.isNotEmpty) {
        unawaited(
          _localStorageService.saveDepartamentos(departamentosRemotos),
        );
      }
      if (categoriasRemotas.isNotEmpty) {
        unawaited(_localStorageService.saveCategorias(categoriasRemotas));
      }

      actualizarEstado();
    } on SocketException catch (_) {
      print('Sin conexión al cargar catálogos');
    } on PostgrestException catch (e) {
      print('Error Supabase al cargar catálogos: ${e.message}');
    } catch (e) {
      print('Error al cargar catálogos: $e');
    } finally {
      _cargandoCatalogos = false;
      actualizarEstado();
    }
  }

  Future<void> getProductos({bool forceUpdate = false}) async {
    cancelPendingRequest();
    final completer = Completer();
    _pendingRequest = completer.future;
    try {
      _message = Mensaje();
      _cargando = true;
      actualizarEstado();

      await getCatalogos(forceUpdate: forceUpdate);

      if (!forceUpdate) {
        final productosLocales = await _localStorageService.getProductos();
        if (productosLocales.isNotEmpty) {
          final preciosLocales = await _localStorageService.getPrecios();
          final stocksLocales = await _localStorageService.getStocks();
          final imagenesLocales =
              await _localStorageService.getProductosImagenes();

          if (preciosLocales.isNotEmpty) {
            this.productos.clear();
            this.productos.addAll(
              enrichProducts(
                productosLocales,
                stocksLocales,
                preciosLocales,
                imagenesLocales,
              ),
            );
            filterProducts();
            return;
          }
        }
      }

      final productosRemotos = await _supabaseService.getProductos();
      final precios = await _supabaseService.getPrecios();
      final stocks = await _supabaseService.getStocks();
      final imagenes = await _supabaseService.getProductosImagenes();
      this.productos.clear();

      this.productos.addAll(
        enrichProducts(productosRemotos, stocks, precios, imagenes),
      );

      unawaited(updateProductos(productosRemotos));
      unawaited(updatePrecios(precios));
      unawaited(updateStocks(stocks));
      unawaited(updateProductosImagenes(imagenes));

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
    } on Exception catch (e) {
      _mostrarMensaje(
        Mensaje(
          mensaje: 'Error: ${e.toString()}',
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

  Future<void> updateProductosImagenes(List<ProductoImagen> imagenes) async {
    _localStorageService.saveProductosImagenes(imagenes);
  }

  List<Producto> enrichProducts(
    List<Producto> productos,
    List<Stock> stocks,
    List<Precio> precios,
    List<ProductoImagen> imagenes,
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
      for (ProductoImagen img in imagenes) {
        if (p.idProducto == img.idProducto &&
            !p.imagenes.any((i) => i.idRelacion == img.idRelacion)) {
          p.imagenes.add(img);
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

    if (filtros.idDepartamento != null) {
      final productosFiltrados =
          this.productosFiltrados
              .where((p) => p.idDepartamento == filtros.idDepartamento)
              .toList();
      this.productosFiltrados.clear();
      this.productosFiltrados.addAll(productosFiltrados);
    }

    if (filtros.idCategoria != null) {
      final productosFiltrados =
          this.productosFiltrados
              .where((p) => p.idCategoria == filtros.idCategoria)
              .toList();
      this.productosFiltrados.clear();
      this.productosFiltrados.addAll(productosFiltrados);
    }

    if (filtros.conStock != null || filtros.filtroPersonalizado) {
      if (filtros.filtroPersonalizado &&
          filtros.cantidadPersonalizada != null) {
        List<int> localidadesSeleccionadas =
            tiendasProvider.localidadesSeleccionadas
                .map((e) => e.idLocalidad)
                .toList();
        final productosFiltrados =
            this.productosFiltrados
                .where(
                  (p) =>
                      p.stocks.isNotEmpty &&
                      p.stocks.any((s) {
                        if (!localidadesSeleccionadas.contains(s.idLocalidad)) {
                          return false;
                        }
                        if (filtros.mayorQue) {
                          return s.stock > filtros.cantidadPersonalizada!;
                        } else {
                          return s.stock < filtros.cantidadPersonalizada!;
                        }
                      }),
                )
                .toList();
        this.productosFiltrados.clear();
        this.productosFiltrados.addAll(productosFiltrados);
      } else if (filtros.conStock == true) {
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
      } else if (filtros.conStock == false) {
        final productosFiltrados =
            this.productosFiltrados
                .where(
                  (p) =>
                      p.stocks.isEmpty || p.stocks.every((s) => s.stock <= 0),
                )
                .toList();
        this.productosFiltrados.clear();
        this.productosFiltrados.addAll(productosFiltrados);
      }
    }

    productosFiltrados.sort((a, b) => a.descripcion.compareTo(b.descripcion));
  }

  Producto? getProducto(int id) {
    return productos.where((p) => p.idProducto == id).firstOrNull;
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

  Future<String?> crearProducto({
    required String descripcion,
    String? codigo,
    required int idDepartamento,
    required bool ipv,
    int? idCategoria,
    required bool activo,
    String? barcode,
    num? costo,
    required bool combo,
    required bool web,
    int? idMonedaCosto,
    required Map<int, double> preciosPorMoneda,
  }) async {
    try {
      final producto = await _supabaseService.insertProducto(
        descripcion: descripcion.trim(),
        codigo: codigo?.trim().isEmpty == true ? null : codigo?.trim(),
        idDepartamento: idDepartamento,
        ipv: ipv,
        idCategoria: idCategoria,
        activo: activo,
        barcode: barcode?.trim().isEmpty == true ? null : barcode?.trim(),
        costo: costo,
        combo: combo,
        web: web,
        idMonedaCosto: idMonedaCosto,
      );

      final preciosGuardados = await _guardarPreciosProducto(
        producto.idProducto,
        preciosPorMoneda,
      );
      producto.precios.addAll(preciosGuardados);

      productos.add(producto);
      await updateProductos(List.from(productos));
      filterProducts();
      actualizarEstado();
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    } on SocketException {
      return 'Sin conexión a internet';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> editarProducto({
    required Producto productoOriginal,
    required String descripcion,
    String? codigo,
    required int idDepartamento,
    required bool ipv,
    int? idCategoria,
    required bool activo,
    String? barcode,
    num? costo,
    required bool combo,
    required bool web,
    int? idMonedaCosto,
    required Map<int, double> preciosPorMoneda,
  }) async {
    try {
      final productoActualizado = Producto(
        idProducto: productoOriginal.idProducto,
        descripcion: descripcion.trim(),
        codigo: codigo?.trim().isEmpty == true ? null : codigo?.trim(),
        idDepartamento: idDepartamento,
        ipv: ipv,
        idCategoria: idCategoria,
        activo: activo,
        barcode: barcode?.trim().isEmpty == true ? null : barcode?.trim(),
        costo: costo,
        combo: combo,
        web: web,
        idMonedaCosto: idMonedaCosto,
      );

      await _supabaseService.updateProducto(productoActualizado);

      final preciosGuardados = await _guardarPreciosProducto(
        productoActualizado.idProducto,
        preciosPorMoneda,
      );

      productoActualizado.stocks.addAll(productoOriginal.stocks);
      productoActualizado.imagenes.addAll(productoOriginal.imagenes);
      productoActualizado.precios.addAll(preciosGuardados);

      final idx = productos.indexWhere(
        (p) => p.idProducto == productoActualizado.idProducto,
      );
      if (idx >= 0) {
        productos[idx] = productoActualizado;
      }

      await updateProductos(List.from(productos));
      filterProducts();
      actualizarEstado();
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    } on SocketException {
      return 'Sin conexión a internet';
    } catch (e) {
      return e.toString();
    }
  }

  Future<List<Precio>> _guardarPreciosProducto(
    int idProducto,
    Map<int, double> preciosPorMoneda,
  ) async {
    final preciosExistentes = await _localStorageService.getPrecios();
    final preciosProducto =
        preciosExistentes
            .where((p) => p.idProducto == idProducto)
            .toList();

    final preciosAEnviar = <Precio>[];
    for (final entry in preciosPorMoneda.entries) {
      if (entry.value <= 0) continue;
      final existente = preciosProducto.firstWhere(
        (p) => p.idMoneda == entry.key,
        orElse:
            () => Precio(
              idPrecio: 0,
              idProducto: idProducto,
              idMoneda: entry.key,
              precio: 0,
            ),
      );
      preciosAEnviar.add(
        Precio(
          idPrecio: existente.idPrecio,
          idProducto: idProducto,
          idMoneda: entry.key,
          precio: entry.value,
        ),
      );
    }

    if (preciosAEnviar.isEmpty) return [];

    final preciosGuardados = await _supabaseService.upsertPrecios(preciosAEnviar);

    for (final precio in preciosGuardados) {
      final idx = preciosExistentes.indexWhere(
        (p) => p.idProducto == precio.idProducto && p.idMoneda == precio.idMoneda,
      );
      if (idx >= 0) {
        preciosExistentes[idx] = precio;
      } else {
        preciosExistentes.add(precio);
      }
    }
    await _localStorageService.savePrecios(preciosExistentes);

    return preciosGuardados;
  }

  // Método para comparar stocks entre localidades
  List<Producto> compararStocksEntreLocalidades(
    int localidad1,
    int localidad2,
  ) {
    return productos.where((producto) {
      final stock1 = producto.stocks.firstWhere(
        (s) => s.idLocalidad == localidad1,
        orElse:
            () => Stock(
              idLocalidad: localidad1,
              idProducto: producto.idProducto,
              stock: 0,
              idStock: 0,
            ),
      );

      final stock2 = producto.stocks.firstWhere(
        (s) => s.idLocalidad == localidad2,
        orElse:
            () => Stock(
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
