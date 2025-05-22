// [file name]: crear_pedido_screen.dart
import 'package:easy_bo_mobile_app/models/detalle_pedido.dart';
import 'package:easy_bo_mobile_app/models/producto.dart';
import 'package:easy_bo_mobile_app/presentation/providers/pedidos_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/productos_provider.dart';
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

  // @override
  // void initState() {
  //   super.initState();
  //   _initializePedido();
  // }

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
          _buildSearchBar(productosProvider),
          Expanded(
            child: _buildProductosList(productosProvider, pedidosProvider),
          ),
          _buildDetallesPedido(pedidosProvider),
        ],
      ),
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
    final productosFiltrados =
        productosProvider.productosFiltrados
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
    int cantidadActual,
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


  void _actualizarCantidad(int idProducto, int cantidad) {
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
