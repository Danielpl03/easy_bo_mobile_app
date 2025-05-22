// [file name]: editar_pedido_screen.dart
import 'package:easy_bo_mobile_app/models/detalle_pedido.dart';
import 'package:easy_bo_mobile_app/models/pedido.dart';
import 'package:easy_bo_mobile_app/models/producto.dart';
import 'package:easy_bo_mobile_app/models/tienda.dart' show Tienda;
import 'package:easy_bo_mobile_app/presentation/providers/pedidos_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/productos_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/tiendas_provider.dart';
import 'package:easy_bo_mobile_app/presentation/screens/crear_pedido_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:easy_bo_mobile_app/presentation/widgets/estado_pedido.dart'
    show getColorEstado, getIconEstado;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class EditarPedidoScreen extends StatefulWidget {
  final Pedido pedido;

  const EditarPedidoScreen({super.key, required this.pedido});

  @override
  State<EditarPedidoScreen> createState() => _EditarPedidoScreenState();
}

class _EditarPedidoScreenState extends State<EditarPedidoScreen> {
  final _observacionesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _observacionesController.text = widget.pedido.observaciones ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PedidosProvider>();
    Pedido pedido = provider.pedidoActual!;
    final tienda = context.read<TiendasProvider>().tiendas.firstWhere(
      (t) => t.idTienda == pedido.idTienda,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Pedido #${pedido.idPedido}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () => _copiarPedido(context, pedido, tienda),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _handleSave(context, pedido),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeaderInfo(pedido, tienda),
                  const Divider(),
                  _buildProductosSection(pedido),
                  const SizedBox(height: 24),
                  _buildObservacionesSection(),
                ],
              ),
            ),
          ),
          _buildResumenFooter(pedido),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 50),
        child: FloatingActionButton(
          onPressed: () => _navegarAProductos(context, pedido),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(Pedido pedido, Tienda tienda) {
    return Column(
      children: [
        Row(
          children: [
            _buildInfoChip(
              Icons.calendar_today,
              DateFormat('dd/MM/yyyy').format(pedido.fecha),
            ),
            const SizedBox(width: 8),
            _buildInfoChip(Icons.store, tienda.nombre),
          ],
        ),
        const SizedBox(height: 8),
        _buildEstadoChip(pedido.estado),
      ],
    );
  }

  Widget _buildProductosSection(Pedido pedido) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Productos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 12),
            ...pedido.detalles.map(
              (detalle) => _buildProductoItem(detalle, pedido, setState),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductoItem(
    DetallePedido detalle,
    Pedido pedido,
    StateSetter setState,
  ) {
    return Consumer<ProductosProvider>(
      builder: (context, productosProvider, _) {
        final producto = productosProvider.productos.firstWhere(
          (p) => p.idProducto == detalle.idProducto,
          orElse:
              () => Producto(
                idProducto: -1,
                descripcion: 'Producto no disponible',
                idDepartamento: 0,
                ipv: false,
                activo: false,
                combo: false,
                web: false,
              ),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.descripcion,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (producto.codigo != null)
                        Text(
                          producto.codigo!,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                _buildCantidadControls(detalle),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    _eliminarDetalle(detalle, pedido);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEstadoChip(String estado) {
    final colorEstado = getColorEstado(estado);
    return Chip(
      label: Text(
        estado,
        style: TextStyle(color: colorEstado, fontWeight: FontWeight.w500),
      ),
      backgroundColor: colorEstado.withOpacity(0.1),
      avatar: Icon(getIconEstado(estado), color: colorEstado, size: 16),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Chip(
      label: Text(text),
      avatar: Icon(icon, size: 16),
      backgroundColor: Colors.blue.withOpacity(0.1),
    );
  }

  Widget _buildObservacionesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Observaciones',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _observacionesController,
          decoration: const InputDecoration(
            hintText: 'Agregar observaciones al pedido...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  void _handleSave(BuildContext context, Pedido pedido) async {
    try {
      final provider = context.read<PedidosProvider>();
      final pedidoActualizado = pedido.copyWith(
        observaciones: _observacionesController.text,
        estado: 'MODIFICADO',
      );

      pedidoActualizado.detalles = pedido.detalles;

      // Si el pedido no se puede modificar, solo actualizamos las observaciones
      if (!provider.puedeModificarPedido(pedidoActualizado)) {
        await provider.actualizarObservaciones(_observacionesController.text);
      } else {
        provider.setPedidoActual(pedidoActualizado);
        await provider.guardarPedido();
      }

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar el pedido: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCantidadControls(DetallePedido detalle) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 20),
                onPressed: () {
                  if (detalle.cantidad > 1) {
                    detalle = _actualizarCantidad(
                      detalle,
                      detalle.cantidad - 1,
                    );
                    setState(() {});
                  }
                },
              ),
              Text(
                '${detalle.cantidad}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () {
                  detalle = _actualizarCantidad(detalle, detalle.cantidad + 1);
                  setState(() {});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResumenFooter(Pedido pedido) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Productos:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            '${pedido.detalles.length}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  DetallePedido _actualizarCantidad(DetallePedido detalle, int cantidad) {
    final provider = context.read<PedidosProvider>();
    final nuevoDetalle = DetallePedido(
      idPedido: provider.pedidoActual!.idPedido,
      idProducto: detalle.idProducto,
      cantidad: cantidad,
    );

    provider.agregarDetallePedido(nuevoDetalle, false);
    return nuevoDetalle;
  }

  void _copiarPedido(BuildContext context, Pedido pedido, Tienda tienda) async {
    final productosProvider = context.read<ProductosProvider>();
    final buffer = StringBuffer();

    // Encabezado
    buffer.writeln(
      'PEDIDO *${tienda.nombre.toUpperCase()} ${DateFormat('dd/MM/yyyy').format(pedido.fecha.add(const Duration(days: 1)))}:*',
    );

    // Productos
    for (var detalle in pedido.detalles) {
      final producto = productosProvider.productos.firstWhere(
        (p) => p.idProducto == detalle.idProducto,
        orElse:
            () => Producto(
              idProducto: -1,
              descripcion: 'Producto no disponible',
              idDepartamento: 0,
              ipv: false,
              activo: false,
              combo: false,
              web: false,
            ),
      );
      buffer.writeln(
        '- ${producto.fullDescripction(inversed: true)} -- ${detalle.cantidad}',
      );
    }
    buffer.writeln('');

    // Observaciones
    if (pedido.observaciones != null && pedido.observaciones!.isNotEmpty) {
      buffer.writeln('OBSERVACIONES:');
      buffer.writeln(pedido.observaciones);
    }

    final texto = buffer.toString();
    await Clipboard.setData(ClipboardData(text: texto));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contenido del pedido copiado al portapapeles'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _eliminarDetalle(DetallePedido detalle, Pedido pedido) {
    // final provider = context.read<PedidosProvider>();
    // provider.eliminarDetallePedido(detalle);
    pedido.detalles.removeWhere((d) => d.idProducto == detalle.idProducto);
  }

  void _navegarAProductos(BuildContext context, Pedido pedido) {
    final provider = context.read<PedidosProvider>();
    provider.setPedidoActual(pedido);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CrearPedidoScreen(idTienda: pedido.idTienda),
      ),
    );
  }
}
