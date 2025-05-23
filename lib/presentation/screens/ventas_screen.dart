import 'package:easy_bo_mobile_app/models/documento.dart';
import 'package:easy_bo_mobile_app/models/movimiento.dart';
import 'package:easy_bo_mobile_app/models/producto.dart';
import 'package:easy_bo_mobile_app/presentation/providers/documentos_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/productos_provider.dart';
import 'package:easy_bo_mobile_app/presentation/widgets/estado_carga.dart';
import 'package:easy_bo_mobile_app/presentation/widgets/ordenamiento_movimientos_menu.dart';
import 'package:easy_bo_mobile_app/presentation/widgets/ordenamiento_ventas_menu.dart';
import 'package:easy_bo_mobile_app/presentation/widgets/rango_fechas_selector.dart';
import 'package:easy_bo_mobile_app/presentation/widgets/resumen_tiendas.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

extension CancelFutureExtension on Future {
  void ignore() {
    catchError((_) {});
  }
}

class _VentasScreenState extends State<VentasScreen> {
  @override
  void dispose() {
    // context.read<DocumentosProvider>().cancelPendingRequest();
    super.dispose();
  }

  // @override
  // void initState() {
  //   super.initState();
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     context.read<DocumentosProvider>().cargarDocumentos();
  //   });
  // }

  void showFilterDialog(
    BuildContext context,
    DocumentosProvider documentosProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filtros',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SwitchListTile(
                              title: const Text('Incluir cancelados'),
                              value: documentosProvider.filtros.includeCanceled,
                              onChanged: (value) {
                                documentosProvider.setIncludeCanceled(
                                  include: value,
                                );
                                setState(() {});
                              },
                            ),
                          ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          OrdenamientoVentasMenu(),
          // Botón de filtros
          // IconButton(
          //   icon: Badge(
          //     isLabelVisible: false,
          //     child: const Icon(Icons.filter_list),
          //   ),
          //   onPressed: () {
          //     showFilterDialog(context, documentosProvider);
          //   },
          // ),
          // IconButton(
          //   icon: const Icon(Icons.add),
          //   onPressed: () {
          //     // TODO: Navegar a pantalla de creación
          //   },
          // ),
          // IconButton(
          //   icon: const Icon(Icons.replay_sharp),
          //   onPressed: () {
          //     productosProvider.getProductos(true);
          //   },
          // ),
        ],
      ),
      body: Consumer<DocumentosProvider>(
        builder: (context, provider, _) {
          if (provider.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.errorMessage!),
                  backgroundColor: Colors.red,
                ),
              );
              provider.clearError();
            });
          }
          return RefreshIndicator(
            onRefresh: () => provider.getDocumentos(tipo: 'VENTA'),
            child: Column(
              children: [
                estadoCargaV(provider),
                RangoFechasSelector(),
                ResumenTiendas(),
                Expanded(child: _buildListaDocumentos()),
              ],
            ),
          );
        },
      ),
    );
  }
}



Widget _buildMovementsList(
  Documento documento,
  ThemeData theme,
  BuildContext context,
) {
  final productos = context.read<ProductosProvider>().productos;
  return Consumer<DocumentosProvider>(
    builder: (context, provider, _) {
      final movimientosOrdenados = provider.movimientosOrdenados(documento);

      //     return AnimatedList(
      //       // duration: Duration(milliseconds: 300),
      //       itemBuilder: (context, index, animation) {
      //         final movimiento = movimientosOrdenados[index];
      //         final producto = productos.firstWhere(
      //           (p) => p.idProducto == movimiento.idProducto,
      //           orElse:
      //               () => Producto(
      //                 idProducto: 0,
      //                 descripcion: 'Producto no disponible',
      //                 idDepartamento: 0,
      //                 ipv: false,
      //                 activo: false,
      //                 combo: false,
      //                 web: false,
      //               ),
      //         );
      //         return SizeTransition(
      //           sizeFactor: animation,
      //           child: _buildMovimientoItem(movimiento, producto),
      //         );
      //       },
      //     );
      //   },
      // );

      return Column(
        children:
            movimientosOrdenados.map((movimiento) {
              final producto = productos.firstWhere(
                (p) => p.idProducto == movimiento.idProducto,
                orElse:
                    () => Producto(
                      idProducto: 0,
                      descripcion: 'Producto no disponible',
                      idDepartamento: 0,
                      ipv: false,
                      activo: false,
                      combo: false,
                      web: false,
                    ),
              );
              return _buildMovimientoItem(movimiento, producto);
            }).toList(),
      );
    },
  );

  // return Column(
  //   children: [
  //     const Divider(),
  //     ...documento.movimientos.map((movimiento) {
  //       final producto = productosProvider.productosVentas.firstWhere(
  //         (p) => p.idProducto == movimiento.idProducto,
  //         orElse:
  //             () => Producto(
  //               idProducto: 0,
  //               descripcion: 'Producto no disponible',
  //               idDepartamento: 0,
  //               ipv: false,
  //               activo: false,
  //               combo: false,
  //               web: false,
  //             ),
  //       );
  //       return _buildMovimientoItem(movimiento, producto);

  // return Padding(
  //   padding: const EdgeInsets.symmetric(vertical: 8),
  //   child: Row(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       // Ícono de producto
  //       Icon(
  //         Icons.shopping_bag_outlined,
  //         size: 20,
  //         color: theme.colorScheme.onSurface.withOpacity(0.6),
  //       ),
  //       const SizedBox(width: 12),

  //       // Detalles del producto
  //       Expanded(
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               producto.descripcion.toUpperCase(),
  //               style: theme.textTheme.bodyMedium?.copyWith(
  //                 fontWeight: FontWeight.w500,
  //               ),
  //             ),
  //             const SizedBox(height: 2),
  //             Text(
  //               'Código: ${producto.codigo ?? 'N/A'}',
  //               style: theme.textTheme.bodySmall,
  //             ),
  //           ],
  //         ),
  //       ),

  //       // Detalles del movimiento
  //       Column(
  //         crossAxisAlignment: CrossAxisAlignment.end,
  //         children: [
  //           Text(
  //             '${movimiento.cantidad} x \$${movimiento.precioProducto.toStringAsFixed(2)}',
  //             style: theme.textTheme.bodyMedium,
  //           ),
  //           const SizedBox(height: 4),
  //           Text(
  //             '\$${(movimiento.cantidad * movimiento.precioProducto).toStringAsFixed(2)}',
  //             style: theme.textTheme.bodyMedium?.copyWith(
  //               color: theme.colorScheme.primary,
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ],
  //   ),
  // );
}

// void _handleExpansion(
//   bool expanded,
//   Documento documento,
//   BuildContext context,
// ) {
//   if (expanded) {
//     final ids = documento.movimientos.map((m) => m.idProducto).toSet().toList();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<ProductosProvider>().getProductosByIDS(ids);
//     });
//   }
// }

class _DocumentoTile extends StatelessWidget {
  final Documento documento;

  const _DocumentoTile({required this.documento});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        title: Row(
          children: [
            Text(
              DateFormat('h:mm').format(documento.fecha),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            if (documento.cancelado)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.cancel, color: theme.colorScheme.error, size: 18),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OrdenamientoMovimientosMenu(documento: documento),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '\$${NumberFormat('#,##0.00', 'es_MX').format(documento.importe)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: documento.cancelado ? theme.colorScheme.error : theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (documento.descuento != null && documento.descuento! > 0)
                  Text(
                    'Descuento: \$${NumberFormat('#,##0.00', 'es_MX').format(documento.descuento)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          ],
        ),
        children: [_buildMovementsList(documento, theme, context)],
      ),
    );
  }
}

class _GrupoDocumentosTile extends StatefulWidget {
  final GrupoDocumentos grupo;

  const _GrupoDocumentosTile({required this.grupo});

  @override
  __GrupoDocumentosTileState createState() => __GrupoDocumentosTileState();
}

class __GrupoDocumentosTileState extends State<_GrupoDocumentosTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        title: _buildHeader(),
        trailing: _buildTotal(),
        onExpansionChanged: (expanded) => setState(() => _expanded = expanded),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.grupo.documentos.length,
              itemBuilder: (context, index) {
                final documento = widget.grupo.documentos[index];
                return _DocumentoTile(documento: documento);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.store, color: theme.colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.grupo.nombreTienda,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              DateFormat('dd/MM/yyyy').format(widget.grupo.fecha),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotal() {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '\$${NumberFormat('#,##0.00', 'es_MX').format(widget.grupo.total)}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: _expanded ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${widget.grupo.documentos.length} ventas',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

Widget _buildMovimientoItem(Movimiento movimiento, Producto producto) {
  return Builder(
    builder: (context) {
      final theme = Theme.of(context);
      return ListTile(
        leading: Icon(Icons.shopping_basket, color: theme.colorScheme.primary),
        title: Text(
          producto.descripcion,
          style: theme.textTheme.bodyMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Código: ${producto.codigo ?? 'N/A'}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${movimiento.cantidad} x \$${NumberFormat('#,##0.00', 'es_MX').format(movimiento.precioProducto)}',
              style: theme.textTheme.bodySmall,
            ),
            if (movimiento.descuento != null && movimiento.descuento! > 0)
              Text(
                '-\$${NumberFormat('#,##0.00', 'es_MX').format(movimiento.descuento!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.end,
              ),
            Text(
              '\$${NumberFormat('#,##0.00', 'es_MX').format(movimiento.importe ?? 0)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildListaDocumentos() {
  return Consumer<DocumentosProvider>(
    builder: (context, provider, _) {
      if (provider.documentos.isEmpty) {
        return Center(child: CircularProgressIndicator());
      }

      return ListView.builder(
        itemCount: provider.documentosAgrupados.length,
        itemBuilder:
            (context, index) => _GrupoDocumentosTile(
              grupo: provider.documentosAgrupados[index],
            ),
      );
    },
  );
}
