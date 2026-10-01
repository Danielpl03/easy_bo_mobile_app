// [file name]: crear_pedido_screen.dart
import 'package:easy_bo_mobile_app/models/detalle_pedido.dart';
import 'package:easy_bo_mobile_app/models/producto.dart';
import 'package:easy_bo_mobile_app/models/producto_proveedor.dart';
import 'package:easy_bo_mobile_app/models/proveedor.dart';
import 'package:easy_bo_mobile_app/presentation/providers/documentos_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/pedidos_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/productos_provider.dart';
import 'package:easy_bo_mobile_app/services/local_storage_service.dart';
import 'package:easy_bo_mobile_app/services/supabase_service.dart';
import 'package:easy_bo_mobile_app/config/supabase_config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CrearPedidoScreen extends StatefulWidget {
  final int idTienda;

  const CrearPedidoScreen({super.key, required this.idTienda});

  @override
  State<CrearPedidoScreen> createState() => _CrearPedidoScreenState();
}

class _CrearPedidoScreenState extends State<CrearPedidoScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Proveedor? _proveedorSeleccionado;
  List<Producto> _productosSugeridos = [];
  final LocalStorageService _localStorageService = LocalStorageService();
  final SupabaseService _supabaseService = SupabaseService(SupabaseConfig.client);

  @override
  void initState() {
    super.initState();
    _cargarProveedorDelPedido();
  }

  Future<void> _cargarProveedorDelPedido() async {
    final pedidosProvider = context.read<PedidosProvider>();
    if (pedidosProvider.pedidoActual?.idProveedor != null) {
      final documentosProvider = context.read<DocumentosProvider>();
      try {
        final proveedor = documentosProvider.proveedores.firstWhere(
          (p) => p.idProveedor == pedidosProvider.pedidoActual!.idProveedor,
        );
        if (mounted) {
          setState(() {
            _proveedorSeleccionado = proveedor;
          });
          await _cargarProductosSugeridos(proveedor);
        }
      } catch (e) {
        // Proveedor no encontrado
      }
    }
  }

  Future<void> _cargarProductosSugeridos(Proveedor proveedor) async {
    try {
      // Cargar productos proveedores
      List<ProductoProveedor> productosProveedores =
          await _localStorageService.getProductosProveedores();
      
      if (productosProveedores.isEmpty) {
        productosProveedores = await _supabaseService.getProductosProveedores();
        await _localStorageService.saveProductosProveedores(productosProveedores);
      }

      // Filtrar relaciones del proveedor seleccionado
      final relacionesProveedor = productosProveedores
          .where((pp) => pp.idProveedor == proveedor.idProveedor)
          .toList();

      // Obtener productos del provider
      final productosProvider = context.read<ProductosProvider>();
      if (productosProvider.productos.isEmpty) {
        await productosProvider.getProductos();
      }

      // Crear lista con productos del proveedor y calcular stock total
      final productosCompletos = <Map<String, dynamic>>[];
      for (final relacion in relacionesProveedor) {
        try {
          final producto = productosProvider.productos.firstWhere(
            (p) => p.idProducto == relacion.idProducto,
          );

          // Calcular stock total
          final stockTotal = producto.stocks.fold<num>(
            0,
            (sum, stock) => sum + stock.stock,
          );

          productosCompletos.add({
            'producto': producto,
            'stockTotal': stockTotal,
          });
        } catch (e) {
          // Producto no encontrado, continuar
        }
      }

      // Ordenar por stock total de menor a mayor
      productosCompletos.sort((a, b) => 
        (a['stockTotal'] as num).compareTo(b['stockTotal'] as num)
      );

      if (mounted) {
        setState(() {
          _productosSugeridos = productosCompletos
              .map((item) => item['producto'] as Producto)
              .toList();
        });
      }
    } catch (e) {
      print('Error al cargar productos sugeridos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pedidosProvider = context.watch<PedidosProvider>();
    final productosProvider = context.watch<ProductosProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Pedido'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _guardarPedido(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProveedorSection(),
          _buildSearchBar(productosProvider),
          Expanded(
            child: _buildProductosList(productosProvider, pedidosProvider),
          ),
          _buildDetallesPedido(pedidosProvider),
        ],
      ),
    );
  }

  Widget _buildProveedorSection() {
    return Consumer<DocumentosProvider>(
      builder: (context, documentosProvider, _) {
        final proveedores = documentosProvider.proveedores;
        
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: DropdownButtonFormField<Proveedor>(
            value: _proveedorSeleccionado,
            decoration: const InputDecoration(
              labelText: 'Seleccionar proveedor',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.local_shipping),
            ),
            items: [
              const DropdownMenuItem<Proveedor>(
                value: null,
                child: Text('Sin proveedor'),
              ),
              ...proveedores.map((proveedor) {
                return DropdownMenuItem<Proveedor>(
                  value: proveedor,
                  child: Text(proveedor.nombre),
                );
              }),
            ],
            onChanged: (Proveedor? nuevoProveedor) async {
              setState(() {
                _proveedorSeleccionado = nuevoProveedor;
                _productosSugeridos = [];
              });
              
              // Actualizar el pedido con el nuevo proveedor
              final pedidosProvider = context.read<PedidosProvider>();
              if (pedidosProvider.pedidoActual != null) {
                pedidosProvider.setPedidoActual(
                  pedidosProvider.pedidoActual!.copyWith(
                    idProveedor: nuevoProveedor?.idProveedor,
                  ),
                );
              }
              
              // Cargar productos sugeridos si se seleccionó un proveedor
              if (nuevoProveedor != null) {
                await _cargarProductosSugeridos(nuevoProveedor);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(ProductosProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar productos...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              provider.setSearch('');
            },
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            provider.setSearch(value);
          });
        },
      ),
    );
  }

  Widget _buildProductosList(
    ProductosProvider productosProvider,
    PedidosProvider pedidosProvider,
  ) {
    List<Producto> productosFiltrados;

    // Si hay búsqueda manual, filtrar todos los productos
    if (_searchQuery.isNotEmpty) {
      productosFiltrados = productosProvider.productosFiltrados
          .where(
            (p) =>
                p.descripcion.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                (p.codigo != null &&
                    p.codigo!.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    )),
          )
          .toList();
    } 
    // Si hay proveedor seleccionado y no hay búsqueda, mostrar productos sugeridos
    else if (_proveedorSeleccionado != null && _productosSugeridos.isNotEmpty) {
      productosFiltrados = _productosSugeridos;
    }
    // Si no hay proveedor ni búsqueda, mostrar todos los productos filtrados
    else {
      productosFiltrados = productosProvider.productosFiltrados;
    }

    return ListView.builder(
      itemCount: productosFiltrados.length,
      itemBuilder: (context, index) {
        final producto = productosFiltrados[index];
        DetallePedido? detalle = pedidosProvider.pedidoActual?.detalles
            .firstWhere(
              (d) => d.idProducto == producto.idProducto,
              orElse:
                  () => DetallePedido(
                    idPedido: -1,
                    idProducto: producto.idProducto,
                    cantidad: 0,
                  ),
            );
        detalle ??= DetallePedido(
          idPedido: -1,
          idProducto: producto.idProducto,
          cantidad: 0,
        );

        return ListTile(
          title: Text(producto.descripcion),
          subtitle: Text(producto.codigo ?? 'Sin código'),
          trailing: _buildCantidadControls(detalle, pedidosProvider),
          onLongPress:
              () =>
                  _mostrarDialogoCantidad(context, producto, detalle!.cantidad),
        );
      },
    );
  }

  Widget _buildCantidadControls(
    DetallePedido detalle,
    PedidosProvider provider,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed:
              detalle.cantidad > 0
                  ? () => _actualizarCantidad(
                    detalle.idProducto,
                    detalle.cantidad - 1,
                  )
                  : null,
        ),
        Text('${detalle.cantidad}'),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed:
              () =>
                  _actualizarCantidad(detalle.idProducto, detalle.cantidad + 1),
        ),
      ],
    );
  }

  Widget _buildDetallesPedido(PedidosProvider provider) {
    return Card(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 200),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Resumen del Pedido',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${provider.pedidoActual?.detalles.where((d) => d.cantidad > 0).length ?? 0} productos',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: provider.pedidoActual?.detalles
                          .where((d) => d.cantidad > 0)
                          .map(
                            (detalle) {
                              final producto = context
                                  .read<ProductosProvider>()
                                  .productos
                                  .firstWhere(
                                    (p) => p.idProducto == detalle.idProducto,
                                  );

                              return ListTile(
                                title: Text(producto.fullDescripction(inversed: true)),
                                trailing: Text('${detalle.cantidad}'),
                                onTap: () => _mostrarDialogoCantidad(
                                  context,
                                  producto,
                                  detalle.cantidad,
                                ),
                              );
                            },
                          )
                          .toList() ??
                      [],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoCantidad(
    BuildContext context,
    Producto producto,
    num cantidadActual,
  ) {
    final textController = TextEditingController(
      text: cantidadActual.toString(),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Cantidad para ${producto.descripcion}'),
            content: TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  final cantidad = int.tryParse(textController.text) ?? 0;
                  _actualizarCantidad(producto.idProducto, cantidad);
                  Navigator.pop(context);
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }


  void _actualizarCantidad(int idProducto, num cantidad) {
    final provider = context.read<PedidosProvider>();
    final nuevoDetalle = DetallePedido(
      idPedido: provider.pedidoActual!.idPedido,
      idProducto: idProducto,
      cantidad: cantidad,
    );

    provider.agregarDetallePedido(nuevoDetalle, false);
  }

  Future<void> _guardarPedido(BuildContext context) async {
    try {
      final provider = context.read<PedidosProvider>();
      if (provider.pedidoActual?.detalles.isEmpty ?? true) {
        throw Exception('Agregue al menos un producto al pedido');
      }

      await provider.guardarPedido();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
