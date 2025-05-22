// [file name]: pedidos_screen.dart (Versión mejorada)
import 'package:easy_bo_mobile_app/models/mensaje.dart'
    show Mensaje, TipoMensaje;
import 'package:easy_bo_mobile_app/models/pedido.dart';
import 'package:easy_bo_mobile_app/presentation/providers/pedidos_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/tiendas_provider.dart';
import 'package:easy_bo_mobile_app/presentation/screens/crear_pedido_screen.dart';
import 'package:easy_bo_mobile_app/presentation/screens/editar_pedido_screen.dart';
import 'package:easy_bo_mobile_app/presentation/widgets/estado_pedido.dart' show getColorEstado, getIconEstado;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PedidosProvider>().cargarPedidos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tiendasProvider = context.read<TiendasProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Pedidos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _nuevoPedido(context),
          ),
        ],
      ),
      body: Consumer<PedidosProvider>(
        builder: (context, provider, _) {
          
          if (provider.message != null &&
              provider.message!.tipoMensaje != TipoMensaje.loading) {
          
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.message!.mensaje),
                  backgroundColor:
                      provider.message!.tipoMensaje == TipoMensaje.error
                          ? Colors.red
                          : Colors.green,
                ),
              );
              provider.clearMensaje();
            });
          }

          return ListView.builder(
            itemCount: provider.pedidos.length,
            itemBuilder: (context, index) {
              final pedido = provider.pedidos[index];
              return _buildPedidoItem(pedido, context);
            },
          );
        },
      ),
    );
  }

  

  // Widget _buildPedidoItem(Pedido pedido, BuildContext context) {
  //   return ListTile(
  //     title: Text('Pedido #${pedido.idPedido}'),
  //     subtitle: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(DateFormat('dd/MM/yyyy').format(pedido.fecha)),
  //         Text('${pedido.detalles.length} productos'),
  //         Text('Estado: ${pedido.estado}'),
  //       ],
  //     ),
  //     trailing: IconButton(
  //       icon: const Icon(Icons.edit),
  //       onPressed: () => _editarPedido(context, pedido),
  //     ),
  //   );
  // }

  void _nuevoPedido(BuildContext context) async {
    final tiendasProvider = context.read<TiendasProvider>();
    if (tiendasProvider.tiendasSeleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione al menos una tienda')),
      );
      return;
    }
    if (tiendasProvider.tiendasSeleccionadas.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione solo una tienda')),
      );
      return;
    }
    final idTienda = tiendasProvider.tiendasSeleccionadas.first.idTienda;

    if (context.read<PedidosProvider>().crearNuevoPedido(idTienda)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CrearPedidoScreen(idTienda: idTienda),
        ),
      );
    }
  }

  void _editarPedido(BuildContext context, Pedido pedido) {
    context.read<PedidosProvider>().cargarPedidoParaEdicion(pedido.idPedido);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditarPedidoScreen(pedido: pedido)),
    );
  }





  Widget _buildPedidoItem(Pedido pedido, BuildContext context) {
  final colorEstado = getColorEstado(pedido.estado);
  final tienda = context.read<TiendasProvider>().tiendas.firstWhere( (t) => t.idTienda == pedido.idTienda );
  
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    elevation: 2,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colorEstado.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          getIconEstado(pedido.estado),
          color: colorEstado,
          size: 24,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              'Pedido #${pedido.idPedido}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16
              ),
            ),
          ),
          Chip(
            label: Text(
              pedido.estado,
              style: TextStyle(
                color: colorEstado,
                fontWeight: FontWeight.w500
              ),
            ),
            backgroundColor: colorEstado.withOpacity(0.1),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            DateFormat('dd MMM yyyy - HH:mm').format(pedido.fecha),
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoItem(Icons.store, '${tienda.nombre}'),
              const SizedBox(width: 16),
              _buildInfoItem(Icons.shopping_basket, 
                '${pedido.detalles.length} Productos'),
            ],
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () => _showOptionsMenu(context, pedido),
      ),
    ),
  );
}

Widget _buildInfoItem(IconData icon, String text) {
  return Row(
    children: [
      Icon(icon, size: 16, color: Colors.grey),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(color: Colors.grey)),
    ],
  );
}

void _showOptionsMenu(BuildContext context, Pedido pedido) {
  showModalBottomSheet(
    context: context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.edit),
          title: const Text('Editar Pedido'),
          onTap: () {
            Navigator.pop(context);
            _editarPedido(context, pedido);
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete, color: Colors.red),
          title: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          onTap: () => _confirmarEliminacion(context, pedido),
        ),
      ],
    ),
  );
}



void _confirmarEliminacion(BuildContext context, Pedido pedido) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirmar eliminación'),
      content: Text('¿Está seguro que desea eliminar el pedido #${pedido.idPedido}?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            try {
              await context.read<PedidosProvider>().eliminarPedido(pedido);
              if (context.mounted) {
                Navigator.pop(context); // Cierra el diálogo
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pedido eliminado exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                Navigator.pop(context); // Cierra el diálogo
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al eliminar el pedido: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
}
}
