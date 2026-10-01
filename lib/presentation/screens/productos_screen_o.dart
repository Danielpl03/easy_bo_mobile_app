import 'package:easy_bo_mobile_app/config/supabase_config.dart';
import 'package:easy_bo_mobile_app/models/detalle_pedido.dart';
import 'package:easy_bo_mobile_app/models/mensaje.dart' show TipoMensaje;
import 'package:easy_bo_mobile_app/models/precio.dart';
import 'package:easy_bo_mobile_app/models/producto.dart';
import 'package:easy_bo_mobile_app/models/producto_imagen.dart';
import 'package:easy_bo_mobile_app/models/producto_proveedor.dart';
import 'package:easy_bo_mobile_app/models/proveedor.dart';
import 'package:easy_bo_mobile_app/models/stock.dart';
import 'package:easy_bo_mobile_app/models/pedido.dart';
import 'package:easy_bo_mobile_app/models/tienda.dart';
import 'package:easy_bo_mobile_app/presentation/providers/documentos_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/monedas_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/pedidos_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/productos_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/tiendas_provider.dart';
import 'package:easy_bo_mobile_app/presentation/widgets/estado_carga.dart';
import 'package:easy_bo_mobile_app/services/image_service.dart';
import 'package:easy_bo_mobile_app/services/local_storage_service.dart';
import 'package:easy_bo_mobile_app/services/share_service.dart';
import 'package:easy_bo_mobile_app/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ProductosScreen extends StatelessWidget {
  const ProductosScreen({super.key});

  void _mostrarDialogoDetalles(BuildContext context, Producto producto) {
    final monedasProvider = context.read<MonedasProvider>();
    final tiendasProvider = context.read<TiendasProvider>();
    final theme = Theme.of(context);
    final imageService = ImageService();
    final shareService = ShareService();
    final localStorageService = LocalStorageService();

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _cargarCostosProveedores(
                    producto,
                    localStorageService,
                  ),
                  builder: (context, snapshot) {
                    final costosProveedores = snapshot.data ?? [];
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ProductoImagenesGaleria(
                          producto: producto,
                          imageService: imageService,
                        ),
                        const SizedBox(height: 20),

                        // Información del producto
                        Text(
                          producto.descripcion,
                          style: theme.textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Código: ${producto.codigo ?? 'N/A'}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Costo: ${producto.costo ?? 'N/A'}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Costos por proveedor
                        if (costosProveedores.isNotEmpty) ...[
                          Text(
                            'Costos por Proveedor:',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children:
                                costosProveedores.map((item) {
                                  final proveedor =
                                      item['proveedor'] as Proveedor;
                                  final ultimoCosto =
                                      item['ultimoCosto'] as num;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.blue.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      '${proveedor.nombre}: ${NumberFormat('#,##0.00', 'es_MX').format(ultimoCosto)}',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 16),
                        ],

                        //Precios
                        if (producto.precios.isNotEmpty) ...[
                          Text('Precios:', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children:
                                monedasProvider.monedas.map((moneda) {
                                  final precioBase = producto.precios
                                      .firstWhere(
                                        (pr) => pr.idMoneda == 1,
                                        orElse:
                                            () => Precio(
                                              idPrecio: 0,
                                              idProducto: producto.idProducto,
                                              idMoneda: 0,
                                              precio: 0,
                                            ),
                                      );
                                  final precio = producto.precios.firstWhere(
                                    (s) => s.idMoneda == moneda.idMoneda,
                                    orElse:
                                        () => Precio(
                                          idPrecio: 0,
                                          idProducto: producto.idProducto,
                                          idMoneda: moneda.idMoneda,
                                          precio:
                                              (precioBase.precio /
                                                  moneda.tazaCambio),
                                        ),
                                  );
                                  final color =
                                      Colors.primaries[moneda.idMoneda %
                                          Colors.accents.length];
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: color),
                                    ),
                                    child: Text(
                                      '${moneda.siglas} ${NumberFormat('#,##0.00', 'es_MX').format(precio.precio)}',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Stock total
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Stock Total: ${producto.stocks.fold<num>(0, (sum, stock) => sum + stock.stock)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Stocks por localidad
                        if (producto.stocks.fold<num>(
                              0,
                              (sum, stock) => sum + stock.stock,
                            ) >
                            0) ...[
                          Text(
                            'Stocks por Localidad:',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children:
                                tiendasProvider.localidades.map((localidad) {
                                  producto.stocks.sort(
                                    (a, b) => a.stock.compareTo(b.stock),
                                  );
                                  final stock = producto.stocks.firstWhere(
                                    (s) =>
                                        s.idLocalidad == localidad.idLocalidad,
                                    orElse:
                                        () => Stock(
                                          idLocalidad: localidad.idLocalidad,
                                          idProducto: producto.idProducto,
                                          stock: 0,
                                          idStock: 0,
                                        ),
                                  );
                                  return stock.stock > 0
                                      ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              stock.stock > 0
                                                  ? Colors.green.withOpacity(
                                                    0.1,
                                                  )
                                                  : Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color:
                                                stock.stock > 0
                                                    ? Colors.green.withOpacity(
                                                      0.3,
                                                    )
                                                    : Colors.red.withOpacity(
                                                      0.3,
                                                    ),
                                          ),
                                        ),
                                        child: Text(
                                          '${localidad.localidad} (${localidad.idLocalidad}): ${stock.stock}',
                                          style: TextStyle(
                                            color:
                                                stock.stock > 0
                                                    ? Colors.green[700]
                                                    : Colors.red[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      )
                                      : SizedBox();
                                }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Botones de acción
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _mostrarDialogoAgregarAlPedido(
                                    context,
                                    producto,
                                  );
                                },
                                icon: const Icon(Icons.add_shopping_cart),
                                label: const Text('Agregar al pedido'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  context.push(
                                    '/producto-historial',
                                    extra: producto,
                                  );
                                },
                                icon: const Icon(Icons.history),
                                label: const Text('Ver historial'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed:
                                () => shareService.shareProduct(
                                  producto,
                                  context,
                                  monedasProvider.monedaSeleccionada!,
                                ),
                            icon: const Icon(Icons.share),
                            label: const Text('Compartir producto'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
    );
  }

  Future<List<Map<String, dynamic>>> _cargarCostosProveedores(
    Producto producto,
    LocalStorageService localStorageService,
  ) async {
    try {
      // Intentar cargar desde almacenamiento local
      List<ProductoProveedor> productosProveedores =
          await localStorageService.getProductosProveedores();
      List<Proveedor> proveedores = await localStorageService.getProveedores();

      // Si no hay datos locales, intentar cargar desde Supabase
      if (productosProveedores.isEmpty || proveedores.isEmpty) {
        try {
          final supabaseService = SupabaseService(SupabaseConfig.client);
          final productosProveedoresRemotos =
              await supabaseService.getProductosProveedores();
          final proveedoresRemotos = await supabaseService.getProveedores();
          // Guardar en almacenamiento local
          await localStorageService.saveProductosProveedores(
            productosProveedoresRemotos,
          );
          await localStorageService.saveProveedores(proveedoresRemotos);

          productosProveedores = productosProveedoresRemotos;
          proveedores = proveedoresRemotos;
        } catch (e) {
          print('⚠️ [ProductosScreen] Error al sincronizar desde Supabase: $e');
          // Continuar con datos locales aunque estén vacíos
        }
      }

      // Filtrar relaciones del producto actual
      final relacionesProducto =
          productosProveedores
              .where((pp) => pp.idProducto == producto.idProducto)
              .toList();

      // Crear lista con información de proveedor y costo
      final costosProveedores = <Map<String, dynamic>>[];
      for (final relacion in relacionesProducto) {
        try {
          final proveedor = proveedores.firstWhere(
            (p) => p.idProveedor == relacion.idProveedor,
            orElse: () {
              return Proveedor(
                idProveedor: relacion.idProveedor,
                nombre: 'Proveedor ${relacion.idProveedor}',
              );
            },
          );

          costosProveedores.add({
            'proveedor': proveedor,
            'ultimoCosto': relacion.ultimoCosto,
          });
        } catch (e) {
          print('❌ [ProductosScreen] Error al procesar relación: $e');
        }
      }

      return costosProveedores;
    } catch (e, stackTrace) {
      print('❌ [ProductosScreen] Error al cargar costos por proveedor: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  void _mostrarDialogoAgregarAlPedido(BuildContext context, Producto producto) {
    final pedidosProvider = context.read<PedidosProvider>();
    final tiendasProvider = context.read<TiendasProvider>();
    final documentosProvider = context.read<DocumentosProvider>();

    // Asegurar que los pedidos estén cargados
    if (pedidosProvider.pedidos.isEmpty) {
      pedidosProvider.cargarPedidos();
    }

    final textController = TextEditingController(text: '1');
    Pedido? pedidoSeleccionado;
    bool crearNuevoPedido = false;
    Tienda? tiendaSeleccionada;
    Proveedor? proveedorSeleccionado;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              // Obtener últimos pedidos (últimos 10)
              final pedidosRecientes =
                  pedidosProvider.pedidos.take(10).toList();

              return AlertDialog(
                title: Text('Agregar ${producto.descripcion}'),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 500),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Código: ${producto.codigo ?? 'N/A'}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 20),

                          // Campo de cantidad
                          TextFormField(
                            controller: textController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Cantidad a pedir',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Opción: Seleccionar pedido existente o crear nuevo
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment<bool>(
                                value: false,
                                label: Text('Pedido existente'),
                                icon: Icon(Icons.list),
                              ),
                              ButtonSegment<bool>(
                                value: true,
                                label: Text('Nuevo pedido'),
                                icon: Icon(Icons.add),
                              ),
                            ],
                            selected: {crearNuevoPedido},
                            onSelectionChanged: (Set<bool> newSelection) {
                              setState(() {
                                crearNuevoPedido = newSelection.first;
                                if (crearNuevoPedido) {
                                  pedidoSeleccionado = null;
                                } else {
                                  tiendaSeleccionada = null;
                                  proveedorSeleccionado = null;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 20),

                          // Mostrar lista de pedidos recientes o formulario de nuevo pedido
                          if (!crearNuevoPedido) ...[
                            Text(
                              'Seleccione un pedido:',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 12),
                            if (pedidosRecientes.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'No hay pedidos recientes',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            else
                              Container(
                                constraints: const BoxConstraints(
                                  maxHeight: 200,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: pedidosRecientes.length,
                                  itemBuilder: (context, index) {
                                    final pedido = pedidosRecientes[index];
                                    final tienda = tiendasProvider.tiendas
                                        .firstWhere(
                                          (t) => t.idTienda == pedido.idTienda,
                                          orElse:
                                              () => Tienda(
                                                idTienda: pedido.idTienda,
                                                nombre:
                                                    'Tienda ${pedido.idTienda}',
                                              ),
                                        );

                                    Proveedor? proveedor;
                                    if (pedido.idProveedor != null) {
                                      try {
                                        proveedor = documentosProvider
                                            .proveedores
                                            .firstWhere(
                                              (p) =>
                                                  p.idProveedor ==
                                                  pedido.idProveedor,
                                            );
                                      } catch (e) {
                                        // Proveedor no encontrado
                                      }
                                    }

                                    final isSelected =
                                        pedidoSeleccionado?.idPedido ==
                                        pedido.idPedido;

                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          pedidoSeleccionado = pedido;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color:
                                              isSelected
                                                  ? Colors.blue.withOpacity(0.1)
                                                  : Colors.transparent,
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey.shade200,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  isSelected
                                                      ? Icons
                                                          .radio_button_checked
                                                      : Icons
                                                          .radio_button_unchecked,
                                                  color:
                                                      isSelected
                                                          ? Colors.blue
                                                          : Colors.grey,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Pedido #${pedido.idPedido}',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          isSelected
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                  .normal,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Tienda: ${tienda.nombre}',
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                            ),
                                            if (proveedor != null)
                                              Text(
                                                'Proveedor: ${proveedor.nombre}',
                                                style:
                                                    Theme.of(
                                                      context,
                                                    ).textTheme.bodySmall,
                                              ),
                                            Text(
                                              'Fecha: ${DateFormat('dd/MM/yyyy').format(pedido.fecha)}',
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                            ),
                                            Text(
                                              'Estado: ${pedido.estado}',
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ] else ...[
                            // Formulario para nuevo pedido
                            Text(
                              'Crear nuevo pedido:',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 12),

                            // Selector de tienda
                            DropdownButtonFormField<Tienda>(
                              decoration: const InputDecoration(
                                labelText: 'Seleccionar tienda',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.store),
                              ),
                              value: tiendaSeleccionada,
                              items:
                                  tiendasProvider.tiendas.map((tienda) {
                                    return DropdownMenuItem<Tienda>(
                                      value: tienda,
                                      child: Text(tienda.nombre),
                                    );
                                  }).toList(),
                              onChanged: (Tienda? nuevaTienda) {
                                setState(() {
                                  tiendaSeleccionada = nuevaTienda;
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            // Selector de proveedor
                            DropdownButtonFormField<Proveedor>(
                              decoration: const InputDecoration(
                                labelText: 'Seleccionar proveedor (opcional)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.local_shipping),
                              ),
                              value: proveedorSeleccionado,
                              items: [
                                const DropdownMenuItem<Proveedor>(
                                  value: null,
                                  child: Text('Sin proveedor'),
                                ),
                                ...documentosProvider.proveedores.map((
                                  proveedor,
                                ) {
                                  return DropdownMenuItem<Proveedor>(
                                    value: proveedor,
                                    child: Text(proveedor.nombre),
                                  );
                                }),
                              ],
                              onChanged: (Proveedor? nuevoProveedor) {
                                setState(() {
                                  proveedorSeleccionado = nuevoProveedor;
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
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
                      if (cantidad <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ingrese una cantidad válida'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      Pedido? pedidoFinal;

                      if (!crearNuevoPedido) {
                        // Agregar a pedido existente
                        if (pedidoSeleccionado == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Seleccione un pedido'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        pedidoFinal = pedidoSeleccionado;
                      } else {
                        // Crear nuevo pedido
                        if (tiendaSeleccionada == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Seleccione una tienda'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        pedidosProvider.crearNuevoPedido(
                          tiendaSeleccionada!.idTienda,
                          idProveedor: proveedorSeleccionado?.idProveedor,
                        );
                        pedidoFinal = pedidosProvider.pedidoActual;
                      }

                      if (pedidoFinal != null) {
                        // Cargar detalles del pedido si no están cargados
                        final pedidoIdFinal = pedidoFinal.idPedido;
                        if (pedidoFinal.detalles.isEmpty && pedidoIdFinal > 0) {
                          // Intentar cargar detalles del almacenamiento
                          pedidosProvider.cargarPedidos().then((_) {
                            final pedidoCompleto = pedidosProvider.pedidos
                                .firstWhere(
                                  (p) => p.idPedido == pedidoIdFinal,
                                  orElse: () => pedidoFinal!,
                                );
                            pedidosProvider.setPedidoActual(pedidoCompleto);
                          });
                        }

                        pedidosProvider.setPedidoActual(pedidoFinal);

                        final nuevoDetalle = DetallePedido(
                          idPedido: pedidoIdFinal,
                          idProducto: producto.idProducto,
                          cantidad: cantidad,
                        );

                        pedidosProvider.agregarDetallePedido(
                          nuevoDetalle,
                          true,
                        );

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              crearNuevoPedido
                                  ? 'Producto agregado al nuevo pedido'
                                  : 'Producto agregado al pedido #$pedidoIdFinal',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    child: const Text('Agregar'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _showFilterDialog(
    BuildContext context,
    ProductosProvider productosProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          scrollable: true,
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              final theme = Theme.of(context);
              return Padding(
                padding: const EdgeInsets.all(2.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,

                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filtros de Productos',
                          style: theme.textTheme.titleLarge,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 22),
                          color: theme.colorScheme.onSurface,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(height: 1, color: theme.colorScheme.onSurface),
                    const SizedBox(height: 20),

                    // Opción: Solo activos
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outline),
                      ),
                      child: SwitchListTile.adaptive(
                        title: Text(
                          'Mostrar solo productos activos',
                          style: theme.textTheme.bodyMedium,
                        ),
                        value: productosProvider.filtros.soloActivos,
                        // activeColor: Colors.blue,
                        activeTrackColor: theme.colorScheme.primaryContainer,
                        onChanged: (value) {
                          productosProvider.setSoloActivos(value);
                          setState(() {});
                        },
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Filtro por stock
                    Text(
                      'Filtrar por stock',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),

                    // Opciones de filtro de stock
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outline),
                      ),
                      child: Column(
                        children: [
                          // Opción: Todos
                          RadioListTile<bool?>(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 5,
                            ),
                            title: Text(
                              'Todos los productos',
                              style: theme.textTheme.bodyMedium,
                            ),
                            value: null,
                            groupValue:
                                productosProvider.filtros.filtroPersonalizado
                                    ? false
                                    : productosProvider.filtros.conStock,
                            onChanged: (value) {
                              productosProvider.setFiltroPersonalizado(false);
                              productosProvider.setConStock(null);
                              setState(() {});
                            },
                            dense: true,
                            activeColor: theme.colorScheme.primary,
                          ),

                          Divider(
                            height: 1,
                            color: theme.colorScheme.outline,
                            indent: 16,
                            endIndent: 16,
                          ),

                          // Opción: Con stock
                          RadioListTile<bool?>(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 5,
                            ),
                            title: Text(
                              'Con stock disponible',
                              style: theme.textTheme.bodyMedium,
                            ),
                            value: true,
                            groupValue:
                                productosProvider.filtros.filtroPersonalizado
                                    ? null
                                    : productosProvider.filtros.conStock,
                            onChanged: (value) {
                              productosProvider.setFiltroPersonalizado(false);
                              productosProvider.setConStock(true);
                              setState(() {});
                            },
                            dense: true,
                            activeColor: theme.colorScheme.primary,
                          ),

                          Divider(
                            height: 1,
                            color: theme.colorScheme.outline,
                            indent: 16,
                            endIndent: 16,
                          ),

                          // Opción: Sin stock
                          RadioListTile<bool?>(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 5,
                            ),
                            title: Text(
                              'Sin stock disponible',
                              style: theme.textTheme.bodyMedium,
                            ),
                            value: false,
                            groupValue:
                                productosProvider.filtros.filtroPersonalizado
                                    ? null
                                    : productosProvider.filtros.conStock,
                            onChanged: (value) {
                              productosProvider.setFiltroPersonalizado(false);
                              productosProvider.setConStock(false);
                              setState(() {});
                            },
                            dense: true,
                            activeColor: theme.colorScheme.primary,
                          ),

                          Divider(
                            height: 1,
                            color: theme.colorScheme.outline,
                            indent: 16,
                            endIndent: 16,
                          ),

                          // Opción: Personalizado
                          RadioListTile<bool?>(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 5,
                            ),
                            title: Text(
                              'Filtro personalizado',
                              style: theme.textTheme.bodyMedium,
                            ),
                            value: null,
                            groupValue:
                                productosProvider.filtros.filtroPersonalizado
                                    ? null
                                    : false,
                            onChanged: (value) {
                              productosProvider.setFiltroPersonalizado(true);
                              setState(() {});
                            },
                            dense: true,
                            activeColor: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),

                    // Sección de filtro personalizado (solo visible si está seleccionado)
                    if (productosProvider.filtros.filtroPersonalizado) ...[
                      const SizedBox(height: 20),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.outline),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Configurar filtro personalizado',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),

                            // Selector de comparación
                            Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ChoiceChip(
                                      label: Text('Mayor que'),
                                      selected:
                                          productosProvider.filtros.mayorQue,
                                      onSelected: (selected) {
                                        if (selected) {
                                          productosProvider
                                              .setComparacionPersonalizada(
                                                true,
                                              );
                                          setState(() {});
                                        }
                                      },
                                      selectedColor: theme.colorScheme.primary,
                                      backgroundColor:
                                          theme.colorScheme.surface,
                                      labelStyle: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color:
                                                productosProvider
                                                        .filtros
                                                        .mayorQue
                                                    ? theme
                                                        .colorScheme
                                                        .onSurface
                                                    : theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                  Expanded(
                                    child: ChoiceChip(
                                      label: Text('Menor que'),
                                      selected:
                                          !productosProvider.filtros.mayorQue,
                                      onSelected: (selected) {
                                        if (selected) {
                                          productosProvider
                                              .setComparacionPersonalizada(
                                                false,
                                              );
                                          setState(() {});
                                        }
                                      },
                                      selectedColor: theme.colorScheme.primary,
                                      backgroundColor:
                                          theme.colorScheme.surface,
                                      labelStyle: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color:
                                                !productosProvider
                                                        .filtros
                                                        .mayorQue
                                                    ? theme
                                                        .colorScheme
                                                        .onSurface
                                                    : theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Campo de cantidad
                            TextField(
                              decoration: InputDecoration(
                                label: Text('Cantidad de stock'),
                                hintText: 'Ej: 10, 25, 50',
                                hintStyle: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: Icon(
                                  Icons.inventory,
                                  size: theme.textTheme.bodySmall?.fontSize,
                                  color: theme.colorScheme.onSurface,
                                ),
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                final cantidad = int.tryParse(value);
                                productosProvider.setCantidadPersonalizada(
                                  cantidad,
                                );
                              },
                            ),

                            const SizedBox(height: 8),

                            // Indicador de estado
                            if (productosProvider
                                    .filtros
                                    .cantidadPersonalizada !=
                                null)
                              Text(
                                'Mostrando productos con stock ${productosProvider.filtros.mayorQue ? '>' : '<'} ${productosProvider.filtros.cantidadPersonalizada}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Botón para aplicar filtros
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Aplicar Filtros',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _mostrarDialogoComparacion(BuildContext context) {
    final tiendasProvider = context.read<TiendasProvider>();
    final productosProvider = context.read<ProductosProvider>();
    int? localidad1;
    int? localidad2;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Comparar Stocks',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Primera Localidad',
                          border: OutlineInputBorder(),
                        ),
                        value: localidad1,
                        items:
                            tiendasProvider.localidadesSeleccionadas.map((l) {
                              return DropdownMenuItem(
                                value: l.idLocalidad,
                                child: Text(
                                  '${l.localidad} (${l.idLocalidad})',
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() => localidad1 = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Segunda Localidad',
                          border: OutlineInputBorder(),
                        ),
                        value: localidad2,
                        items:
                            tiendasProvider.localidadesSeleccionadas.map((l) {
                              return DropdownMenuItem(
                                value: l.idLocalidad,
                                child: Text(
                                  '${l.localidad} (${l.idLocalidad})',
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() => localidad2 = value);
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed:
                                localidad1 != null && localidad2 != null
                                    ? () {
                                      final productosDiferentes =
                                          productosProvider
                                              .compararStocksEntreLocalidades(
                                                localidad1!,
                                                localidad2!,
                                              );
                                      Navigator.pop(context);
                                      _mostrarResultadosComparacion(
                                        context,
                                        productosDiferentes,
                                        localidad1!,
                                        localidad2!,
                                      );
                                    }
                                    : null,
                            child: const Text('Comparar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  void _mostrarResultadosComparacion(
    BuildContext context,
    List<Producto> productos,
    int localidad1,
    int localidad2,
  ) {
    final tiendasProvider = context.read<TiendasProvider>();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Productos en ${tiendasProvider.localidadesSeleccionadas.firstWhere((l) => l.idLocalidad == localidad1).localidad} que no están en ${tiendasProvider.localidadesSeleccionadas.firstWhere((l) => l.idLocalidad == localidad2).localidad}',
              style: const TextStyle(fontSize: 16),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.7,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: productos.length,
                itemBuilder: (context, index) {
                  final producto = productos[index];
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

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            producto.descripcion,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Código: ${producto.codigo ?? 'N/A'}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Chip(
                                label: Text('$localidad1: ${stock1.stock}'),
                                backgroundColor:
                                    stock1.stock > 0
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text('$localidad2: ${stock2.stock}'),
                                backgroundColor:
                                    stock2.stock > 0
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productosProvider = context.watch<ProductosProvider>();
    final localidadesSeleccionadas =
        context.watch<TiendasProvider>().localidadesSeleccionadas;
    final monedasProvider = context.watch<MonedasProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        backgroundColor: theme.colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            onPressed: () => _mostrarDialogoComparacion(context),
          ),
          IconButton(
            icon: Badge(
              isLabelVisible:
                  productosProvider.filtros.soloActivos ||
                  productosProvider.filtros.conStock != null ||
                  productosProvider.filtros.filtroPersonalizado ||
                  productosProvider.filtros.tieneFiltrosCatalogo,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () {
              _showFilterDialog(context, productosProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.replay_sharp),
            onPressed: () async {
              await productosProvider.getCatalogos(forceUpdate: true);
              await productosProvider.getProductos(forceUpdate: true);
            },
          ),
        ],
      ),
      body: Consumer<ProductosProvider>(
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
          return Column(
            children: [
              estadoCargaP(productosProvider),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SearchBar(productosProvider: productosProvider),
              ),
              FiltrosCatalogo(productosProvider: productosProvider),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Mostrando ${productosProvider.productosFiltrados.length} productos',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (productosProvider.filtros.tieneFiltrosCatalogo)
                      TextButton.icon(
                        onPressed: productosProvider.limpiarFiltrosCatalogo,
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Limpiar'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: productosProvider.productosFiltrados.length,
                  itemBuilder: (context, index) {
                    final producto =
                        productosProvider.productosFiltrados[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        title: Text(
                          producto.descripcion.toUpperCase(),
                          style: theme.textTheme.titleMedium,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Código: ${producto.codigo ?? 'N/A'}',
                              style: theme.textTheme.bodySmall,
                            ),
                            if (producto.stocks.isNotEmpty)
                              Consumer(
                                builder: (context, ref, child) {
                                  return Wrap(
                                    spacing: 8,
                                    children:
                                        localidadesSeleccionadas.map((
                                          localidad,
                                        ) {
                                          final stock = producto.stocks
                                              .firstWhere(
                                                (s) =>
                                                    s.idLocalidad ==
                                                    localidad.idLocalidad,
                                                orElse:
                                                    () => Stock(
                                                      idLocalidad:
                                                          localidad.idLocalidad,
                                                      idProducto:
                                                          producto.idProducto,
                                                      stock: 0,
                                                      idStock: 0,
                                                    ),
                                              );

                                          return Chip(
                                            label: Text(
                                              '${localidad.idLocalidad}: ${stock.stock}',
                                              style: TextStyle(
                                                color:
                                                    stock.stock > 0
                                                        ? Colors.green
                                                        : Colors.red,
                                              ),
                                            ),
                                            backgroundColor:
                                                stock.stock > 0
                                                    ? Colors.green.withOpacity(
                                                      0.1,
                                                    )
                                                    : Colors.red.withOpacity(
                                                      0.1,
                                                    ),
                                          );
                                        }).toList(),
                                  );
                                },
                              ),
                          ],
                        ),
                        trailing:
                            monedasProvider.monedaSeleccionada == null
                                ? const Text('Seleccione una moneda')
                                : Consumer(
                                  builder: (context, ref, child) {
                                    final precio = producto.precios.firstWhere(
                                      (p) =>
                                          p.idMoneda ==
                                          monedasProvider
                                              .monedaSeleccionada!
                                              .idMoneda,
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
                                    String precioFormateado = NumberFormat(
                                      '#,##0.00',
                                      'en_EN',
                                    ).format(precio.precio);
                                    return Text(
                                      precio.precio > 0
                                          ? '${monedasProvider.monedaSeleccionada!.siglas} $precioFormateado'
                                          : 'No disponible',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                          ),
                                    );
                                  },
                                ),
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(
                              text: producto.fullDescripction(precio: 1),
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Info de producto copiado al portapapeles',
                              ),
                            ),
                          );
                        },
                        onLongPress:
                            () => _mostrarDialogoDetalles(context, producto),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class FiltrosCatalogo extends StatelessWidget {
  const FiltrosCatalogo({super.key, required this.productosProvider});

  final ProductosProvider productosProvider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final departamentos = productosProvider.departamentos;
    final categorias = productosProvider.categoriasVisibles;
    final idDepartamento = productosProvider.filtros.idDepartamento;
    final idCategoria = productosProvider.filtros.idCategoria;

    if (productosProvider.cargandoCatalogos) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: LinearProgressIndicator(),
      );
    }

    if (departamentos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'No hay departamentos disponibles',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Departamento',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: departamentos.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return FilterChip(
                  label: const Text('Todos'),
                  selected: idDepartamento == null,
                  onSelected: (_) => productosProvider.setDepartamento(null),
                  showCheckmark: false,
                );
              }
              final departamento = departamentos[index - 1];
              final selected = idDepartamento == departamento.idDepartamento;
              return FilterChip(
                label: Text(departamento.nombre),
                selected: selected,
                onSelected:
                    (_) => productosProvider.setDepartamento(
                      selected ? null : departamento.idDepartamento,
                    ),
                showCheckmark: false,
              );
            },
          ),
        ),
        if (idDepartamento != null && categorias.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Categoría',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categorias.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return FilterChip(
                    label: const Text('Todas'),
                    selected: idCategoria == null,
                    onSelected: (_) => productosProvider.setCategoria(null),
                    showCheckmark: false,
                  );
                }
                final categoria = categorias[index - 1];
                final selected = idCategoria == categoria.idCategoria;
                return FilterChip(
                  label: Text(categoria.nombre),
                  selected: selected,
                  onSelected:
                      (_) => productosProvider.setCategoria(
                        selected ? null : categoria.idCategoria,
                      ),
                  showCheckmark: false,
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ProductoImagenesGaleria extends StatefulWidget {
  const _ProductoImagenesGaleria({
    required this.producto,
    required this.imageService,
  });

  final Producto producto;
  final ImageService imageService;

  @override
  State<_ProductoImagenesGaleria> createState() =>
      _ProductoImagenesGaleriaState();
}

class _ProductoImagenesGaleriaState extends State<_ProductoImagenesGaleria> {
  late PageController _pageController;
  int _indiceSeleccionado = 0;
  bool _procesando = false;

  List<ProductoImagen> get _imagenes {
    final imgs = List<ProductoImagen>.from(widget.producto.imagenes);
    imgs.sort((a, b) {
      if (a.principal != b.principal) return a.principal ? -1 : 1;
      return a.idRelacion.compareTo(b.idRelacion);
    });
    return imgs;
  }

  @override
  void initState() {
    super.initState();
    _indiceSeleccionado = _indiceInicial();
    _pageController = PageController(initialPage: _indiceSeleccionado);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _indiceInicial() {
    final imgs = _imagenes;
    if (imgs.isEmpty) return 0;
    final idx = imgs.indexWhere((i) => i.principal);
    return idx >= 0 ? idx : 0;
  }

  ProductoImagen? get _imagenActual {
    final imgs = _imagenes;
    if (imgs.isEmpty || _indiceSeleccionado >= imgs.length) return null;
    return imgs[_indiceSeleccionado];
  }

  void _seleccionarIndice(int indice) {
    if (indice == _indiceSeleccionado) return;
    setState(() => _indiceSeleccionado = indice);
    _pageController.animateToPage(
      indice,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _ejecutar(Future<void> Function() accion) async {
    if (_procesando) return;
    setState(() => _procesando = true);
    final idRelacionActual = _imagenActual?.idRelacion;
    try {
      await accion();
      if (mounted) {
        final imgs = _imagenes;
        if (imgs.isEmpty) {
          _indiceSeleccionado = 0;
        } else if (idRelacionActual != null) {
          final nuevoIdx = imgs.indexWhere(
            (i) => i.idRelacion == idRelacionActual,
          );
          _indiceSeleccionado = nuevoIdx >= 0 ? nuevoIdx : 0;
          _pageController.jumpToPage(_indiceSeleccionado);
        } else {
          _indiceSeleccionado = _indiceSeleccionado.clamp(0, imgs.length - 1);
          _pageController.jumpToPage(_indiceSeleccionado);
        }
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _confirmarEliminar(ProductoImagen imagen) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Eliminar imagen'),
            content: const Text('¿Desea eliminar esta imagen del producto?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
    if (confirmar != true || !mounted) return;

    await _ejecutar(() async {
      await widget.imageService.deleteProductImage(widget.producto, imagen);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imagenes = _imagenes;
    final imagenActual = _imagenActual;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: SizedBox(
                height: 220,
                width: double.infinity,
                child:
                    imagenes.isEmpty
                        ? widget.imageService.getProductImage(widget.producto)
                        : PageView.builder(
                          controller: _pageController,
                          itemCount: imagenes.length,
                          onPageChanged:
                              (i) => setState(() => _indiceSeleccionado = i),
                          itemBuilder:
                              (_, i) => widget.imageService.getProductImage(
                                widget.producto,
                                imagen: imagenes[i],
                              ),
                        ),
              ),
            ),
            if (_procesando)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            if (imagenes.length > 1)
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_indiceSeleccionado + 1} / ${imagenes.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Column(
                children: [
                  _botonAccion(
                    icon: Icons.camera_alt,
                    color: theme.colorScheme.primary,
                    tooltip: 'Agregar imagen',
                    onPressed:
                        () => _ejecutar(
                          () => widget.imageService.uploadProductImage(
                            widget.producto,
                            context,
                          ),
                        ),
                  ),
                  const SizedBox(height: 8),
                  _botonAccion(
                    icon: Icons.refresh,
                    color: theme.colorScheme.tertiary,
                    tooltip: 'Recargar imagen',
                    onPressed:
                        imagenActual == null
                            ? null
                            : () => _ejecutar(() async {
                              await widget.imageService.clearImageCache(
                                widget.imageService.getProductImageUrl(
                                  widget.producto,
                                  imagen: imagenActual,
                                ),
                              );
                              setState(() {});
                            }),
                  ),
                  const SizedBox(height: 8),
                  _botonAccion(
                    icon: Icons.download,
                    color: Colors.green,
                    tooltip: 'Descargar imagen',
                    onPressed:
                        imagenActual == null
                            ? null
                            : () => widget.imageService.downloadProductImage(
                              widget.producto,
                              context,
                              imagen: imagenActual,
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (imagenes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Imágenes (${imagenes.length})',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: imagenes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final imagen = imagenes[index];
                final seleccionada = index == _indiceSeleccionado;
                return GestureDetector(
                  onTap: () => _seleccionarIndice(index),
                  child: Stack(
                    children: [
                      Container(
                        width: 88,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                seleccionada
                                    ? theme.colorScheme.primary
                                    : Colors.grey.shade300,
                            width: seleccionada ? 2.5 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: widget.imageService.getProductImage(
                            widget.producto,
                            imagen: imagen,
                            height: 88,
                            width: 88,
                          ),
                        ),
                      ),
                      if (imagen.principal)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!imagen.principal)
                              _miniBoton(
                                icon: Icons.star_outline,
                                color: Colors.amber.shade800,
                                onTap:
                                    () => _ejecutar(
                                      () => widget.imageService
                                          .setImagenPrincipal(
                                            widget.producto,
                                            imagen,
                                          ),
                                    ),
                              ),
                            _miniBoton(
                              icon: Icons.delete_outline,
                              color: Colors.red.shade700,
                              onTap: () => _confirmarEliminar(imagen),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (imagenActual != null && !imagenActual.principal)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed:
                    () => _ejecutar(
                      () => widget.imageService.setImagenPrincipal(
                        widget.producto,
                        imagenActual,
                      ),
                    ),
                icon: const Icon(Icons.star),
                label: const Text('Marcar imagen actual como principal'),
              ),
            ),
        ],
      ],
    );
  }

  Widget _botonAccion({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomRight: Radius.circular(15),
        ),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        tooltip: tooltip,
        onPressed: _procesando ? null : onPressed,
      ),
    );
  }

  Widget _miniBoton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.92),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: _procesando ? null : onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

class SearchBar extends StatefulWidget {
  const SearchBar({super.key, required this.productosProvider});

  final ProductosProvider productosProvider;

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final TextEditingController textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: textController,
      onTapOutside: (event) {
        widget.productosProvider.setSearch(textController.value.text);
      },
      decoration: InputDecoration(
        hintText: 'Buscar productos...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon:
            textController.value.text.isNotEmpty
                ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    textController.clear();
                    widget.productosProvider.setSearch('');
                  },
                )
                : null,
      ),
      onFieldSubmitted: (value) {
        widget.productosProvider.setSearch(value);
      },
    );
  }
}
