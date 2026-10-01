import 'dart:async';

import 'package:easy_bo_mobile_app/config/supabase_config.dart';
import 'package:easy_bo_mobile_app/models/precio.dart';
import 'package:easy_bo_mobile_app/models/producto.dart';
import 'package:easy_bo_mobile_app/models/producto_proveedor.dart';
import 'package:easy_bo_mobile_app/models/proveedor.dart';
import 'package:easy_bo_mobile_app/presentation/providers/monedas_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/productos_provider.dart';
import 'package:easy_bo_mobile_app/services/local_storage_service.dart';
import 'package:easy_bo_mobile_app/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

enum OrdenamientoTipo { descripcion, stock }

enum OrdenamientoDireccion { ascendente, descendente }

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  final LocalStorageService _localStorageService = LocalStorageService();
  final SupabaseService _supabaseService = SupabaseService(
    SupabaseConfig.client,
  );

  List<Proveedor> _proveedores = [];
  Proveedor? _proveedorSeleccionado;
  List<Map<String, dynamic>> _productosProveedor = [];
  List<Map<String, dynamic>> _productosProveedorOriginal = [];
  bool _cargando = false;

  OrdenamientoTipo _ordenamientoTipo = OrdenamientoTipo.descripcion;
  OrdenamientoDireccion _ordenamientoDireccion =
      OrdenamientoDireccion.ascendente;

  @override
  void initState() {
    super.initState();
    _cargarProveedores();
  }

  Future<void> _cargarProveedores({bool forceUpdate = false}) async {
    setState(() => _cargando = true);
    try {
      // Intentar cargar desde almacenamiento local
      List<Proveedor> proveedores = await _localStorageService.getProveedores();

      // Si no hay datos locales, cargar desde Supabase
      if (proveedores.isEmpty || forceUpdate) {
        proveedores = await _supabaseService.getProveedores();
        await _localStorageService.saveProveedores(proveedores);
      }

      setState(() {
        _proveedores = proveedores;
        _cargando = false;
      });
    } catch (e) {
      print('Error al cargar proveedores: $e');
      setState(() => _cargando = false);
    }
  }

  void _aplicarOrdenamiento() {
    final listaOrdenada = List<Map<String, dynamic>>.from(
      _productosProveedorOriginal,
    );

    listaOrdenada.sort((a, b) {
      int comparacion = 0;

      if (_ordenamientoTipo == OrdenamientoTipo.descripcion) {
        final descA = (a['producto'] as Producto).descripcion.toLowerCase();
        final descB = (b['producto'] as Producto).descripcion.toLowerCase();
        comparacion = descA.compareTo(descB);
      } else if (_ordenamientoTipo == OrdenamientoTipo.stock) {
        final stockA = a['stockTotal'] as num;
        final stockB = b['stockTotal'] as num;
        comparacion = stockA.compareTo(stockB);
      }

      // Invertir si es descendente
      if (_ordenamientoDireccion == OrdenamientoDireccion.descendente) {
        comparacion = -comparacion;
      }

      return comparacion;
    });

    setState(() {
      _productosProveedor = listaOrdenada;
    });
  }

  Future<void> _cargarProductosProveedor(
    Proveedor? proveedor, {
    bool forceUpdate = false,
  }) async {
    setState(() {
      _proveedorSeleccionado = proveedor;
      _cargando = true;
      _productosProveedor = [];
    });

    try {
      // Cargar productos proveedores
      List<ProductoProveedor> productosProveedores =
          await _localStorageService.getProductosProveedores();

      if (productosProveedores.isEmpty) {
        productosProveedores = await _supabaseService.getProductosProveedores();
        unawaited(
          _localStorageService.saveProductosProveedores(productosProveedores),
        );
      } else if (forceUpdate) {
        if (proveedor != null) {
          productosProveedores = await _supabaseService
              .getProductosProveedoresByProveedor(proveedor.idProveedor);
          unawaited(
            _localStorageService.saveProductosProveedores(
              productosProveedores,
              removeOthers: false,
            ),
          );
        } else {
          productosProveedores =
              await _supabaseService.getProductosProveedores();
          unawaited(
            _localStorageService.saveProductosProveedores(productosProveedores),
          );
        }
      }

      // Filtrar relaciones del proveedor seleccionado
      List<ProductoProveedor> relacionesProveedor;
      if (proveedor != null) {
        relacionesProveedor =
            productosProveedores
                .where((pp) => pp.idProveedor == proveedor.idProveedor)
                .toList();
      } else {
        relacionesProveedor = [];
      }

      // Obtener productos del provider
      final productosProvider = context.read<ProductosProvider>();
      if (productosProvider.productos.isEmpty) {
        await productosProvider.getProductos();
      }

      // Crear lista con información completa
      final productosCompletos = <Map<String, dynamic>>[];
      for (final relacion in relacionesProveedor) {
        final producto = productosProvider.productos.firstWhere(
          (p) => p.idProducto == relacion.idProducto,
          orElse:
              () => Producto(
                idProducto: relacion.idProducto,
                descripcion: 'Producto ${relacion.idProducto}',
                idDepartamento: 0,
                ipv: false,
                activo: true,
                combo: false,
                web: false,
              ),
        );

        // Calcular stock total
        final stockTotal = producto.stocks.fold<num>(
          0,
          (sum, stock) => sum + stock.stock,
        );

        productosCompletos.add({
          'producto': producto,
          'relacion': relacion,
          'stockTotal': stockTotal,
        });
      }

      setState(() {
        _productosProveedorOriginal = productosCompletos;
        _productosProveedor = List.from(productosCompletos);
        _aplicarOrdenamiento();
        _cargando = false;
      });
    } catch (e) {
      print('Error al cargar productos del proveedor: $e');
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monedasProvider = context.watch<MonedasProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos por Proveedor'),
        backgroundColor: theme.colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Ordenar',
            onPressed: _mostrarDialogoOrdenamiento,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () {
              // Si hay un proveedor seleccionado, actualizar los productos del proveedor
              if (_proveedorSeleccionado != null) {
                _cargarProductosProveedor(
                  _proveedorSeleccionado!,
                  forceUpdate: true,
                );
              } else {
                // Si no hay un proveedor seleccionado, actualizar los proveedores
                _cargarProveedores(forceUpdate: true);
                _cargarProductosProveedor(null, forceUpdate: true);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Selector de proveedor
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<Proveedor>(
              decoration: InputDecoration(
                labelText: 'Seleccionar Proveedor',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.business),
              ),
              initialValue: _proveedorSeleccionado,
              items:
                  _proveedores.map((proveedor) {
                    return DropdownMenuItem(
                      value: proveedor,
                      child: Text(proveedor.nombre),
                    );
                  }).toList(),
              onChanged: (proveedor) {
                if (proveedor != null) {
                  _cargarProductosProveedor(proveedor);
                }
              },
            ),
          ),

          // Contador de productos y ordenamiento actual
          if (_proveedorSeleccionado != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mostrando ${_productosProveedor.length} productos',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_productosProveedor.isNotEmpty)
                    Chip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _ordenamientoTipo == OrdenamientoTipo.descripcion
                                ? Icons.text_fields
                                : Icons.inventory_2,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getOrdenamientoTexto(),
                            style: const TextStyle(fontSize: 12),
                          ),
                          Icon(
                            _ordenamientoDireccion ==
                                    OrdenamientoDireccion.ascendente
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 16,
                          ),
                        ],
                      ),
                      onDeleted: () {
                        setState(() {
                          _ordenamientoTipo = OrdenamientoTipo.descripcion;
                          _ordenamientoDireccion =
                              OrdenamientoDireccion.ascendente;
                        });
                        _aplicarOrdenamiento();
                      },
                    ),
                ],
              ),
            ),

          // Lista de productos
          Expanded(
            child:
                _cargando
                    ? const Center(child: CircularProgressIndicator())
                    : _proveedorSeleccionado == null
                    ? Center(
                      child: Text(
                        'Seleccione un proveedor para ver sus productos',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                    : _productosProveedor.isEmpty
                    ? Center(
                      child: Text(
                        'No hay productos asociados a este proveedor',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: _productosProveedor.length,
                      itemBuilder: (context, index) {
                        final item = _productosProveedor[index];
                        final producto = item['producto'] as Producto;
                        final relacion = item['relacion'] as ProductoProveedor;
                        final stockTotal = item['stockTotal'] as num;

                        // Obtener precio del producto
                        Precio? precio;
                        if (monedasProvider.monedaSeleccionada != null) {
                          precio = producto.precios.firstWhere(
                            (p) =>
                                p.idMoneda ==
                                monedasProvider.monedaSeleccionada!.idMoneda,
                            orElse:
                                () => Precio(
                                  idPrecio: 0,
                                  idProducto: producto.idProducto,
                                  idMoneda:
                                      monedasProvider
                                          .monedaSeleccionada!
                                          .idMoneda,
                                  precio: 0,
                                ),
                          );
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nombre del producto
                                Text(
                                  producto.descripcion.toUpperCase(),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // Código
                                if (producto.codigo != null)
                                  Text(
                                    'Código: ${producto.codigo}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),

                                const SizedBox(height: 12),

                                // Información en filas
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Precio
                                    Expanded(
                                      child: _buildInfoChip(
                                        context,
                                        'Precio',
                                        precio != null && precio.precio > 0
                                            ? '${monedasProvider.monedaSeleccionada!.siglas} ${NumberFormat('#,##0.00', 'es_MX').format(precio.precio)}'
                                            : 'N/A',
                                        Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Costo del producto
                                    Expanded(
                                      child: _buildInfoChip(
                                        context,
                                        'Costo Producto',
                                        producto.costo != null
                                            ? NumberFormat(
                                              '#,##0.00',
                                              'es_MX',
                                            ).format(producto.costo)
                                            : 'N/A',
                                        Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Costo del proveedor
                                    Expanded(
                                      child: _buildInfoChip(
                                        context,
                                        'Costo Proveedor',
                                        NumberFormat(
                                          '#,##0.00',
                                          'es_MX',
                                        ).format(relacion.ultimoCosto),
                                        Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Stock total
                                    Expanded(
                                      child: _buildInfoChip(
                                        context,
                                        'Stock Total',
                                        stockTotal.toStringAsFixed(0),
                                        stockTotal > 0
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getOrdenamientoTexto() {
    String tipo =
        _ordenamientoTipo == OrdenamientoTipo.descripcion
            ? 'Descripción'
            : 'Stock';
    return tipo;
  }

  void _mostrarDialogoOrdenamiento() {
    OrdenamientoTipo tipoTemp = _ordenamientoTipo;
    OrdenamientoDireccion direccionTemp = _ordenamientoDireccion;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.sort, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Ordenar Productos'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Ordenar por:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<OrdenamientoTipo>(
                    segments: const [
                      ButtonSegment<OrdenamientoTipo>(
                        value: OrdenamientoTipo.descripcion,
                        label: Text('Descripción'),
                        icon: Icon(Icons.text_fields, size: 18),
                      ),
                      ButtonSegment<OrdenamientoTipo>(
                        value: OrdenamientoTipo.stock,
                        label: Text('Stock'),
                        icon: Icon(Icons.inventory_2, size: 18),
                      ),
                    ],
                    selected: {tipoTemp},
                    onSelectionChanged: (Set<OrdenamientoTipo> newSelection) {
                      setDialogState(() {
                        tipoTemp = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Dirección:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<OrdenamientoDireccion>(
                    segments: const [
                      ButtonSegment<OrdenamientoDireccion>(
                        value: OrdenamientoDireccion.ascendente,
                        label: Text('Ascendente'),
                        icon: Icon(Icons.arrow_upward, size: 18),
                      ),
                      ButtonSegment<OrdenamientoDireccion>(
                        value: OrdenamientoDireccion.descendente,
                        label: Text('Descendente'),
                        icon: Icon(Icons.arrow_downward, size: 18),
                      ),
                    ],
                    selected: {direccionTemp},
                    onSelectionChanged: (
                      Set<OrdenamientoDireccion> newSelection,
                    ) {
                      setDialogState(() {
                        direccionTemp = newSelection.first;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _ordenamientoTipo = tipoTemp;
                      _ordenamientoDireccion = direccionTemp;
                    });
                    Navigator.pop(context);
                    _aplicarOrdenamiento();
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
