import 'package:easy_bo_mobile_app/models/detalle_pedido.dart';
import 'package:easy_bo_mobile_app/models/mensaje.dart' show TipoMensaje;
import 'package:easy_bo_mobile_app/models/precio.dart';
import 'package:easy_bo_mobile_app/models/producto.dart';
import 'package:easy_bo_mobile_app/models/stock.dart';
import 'package:easy_bo_mobile_app/presentation/providers/monedas_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/pedidos_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/productos_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/tiendas_provider.dart';
import 'package:easy_bo_mobile_app/presentation/widgets/estado_carga.dart';
import 'package:easy_bo_mobile_app/services/image_service.dart';
import 'package:easy_bo_mobile_app/services/share_service.dart';
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

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            scrollable: true,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Imagen del producto con botón de cámara
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: imageService.getProductImage(producto),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomRight: Radius.circular(15),
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                              ),
                              onPressed: () async {
                                try {
                                  await imageService.uploadProductImage(
                                    producto,
                                    context,
                                  );
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    _mostrarDialogoDetalles(
                                      context,
                                      producto,
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(e.toString()),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                          const SizedBox(
                            height: 8,
                          ), // Espacio entre los botones
                          Container(
                            decoration: BoxDecoration(
                              color:
                                  theme
                                      .colorScheme
                                      .tertiary, // Nuevo color para recargar
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomRight: Radius.circular(15),
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.white,
                              ),
                              onPressed: () async {
                                // Forzar recarga de la imagen limpiando la caché
                                await imageService.clearImageCache(
                                  imageService.getProductImageUrl(producto),
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  _mostrarDialogoDetalles(context, producto);
                                }
                              },
                            ),
                          ),
                          const SizedBox(
                            height: 8,
                          ), // Espacio entre los botones
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.green, // Color para descargar
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomRight: Radius.circular(15),
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.download,
                                color: Colors.white,
                              ),
                              onPressed: () async {
                                await imageService.downloadProductImage(
                                  producto,
                                  context,
                                );
                                if (context.mounted) {
                                  Navigator.pop(
                                    context,
                                  ); // Cerrar el diálogo después de descargar
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
            
                //Precios
                Text('Precios:', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children:
                      monedasProvider.monedas.map((moneda) {
                        final precioBase = producto.precios.firstWhere(
                          (pr) => pr.idMoneda == 1,
                        );
                        final precio = producto.precios.firstWhere(
                          (s) => s.idMoneda == moneda.idMoneda,
                          orElse:
                              () => Precio(
                                idPrecio: 0,
                                idProducto: producto.idProducto,
                                idMoneda: moneda.idMoneda,
                                precio:
                                    (precioBase.precio / moneda.tazaCambio),
                              ),
                        );
                        final color = Colors.primaries[moneda.idMoneda % Colors.accents.length];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: color
                                ),
                              ),
                          child: Text(
                            '${moneda.siglas} ${NumberFormat('#,##0.00', 'es_MX').format(precio.precio)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                ),
            
                // Precio
                // if (monedasProvider.monedaSeleccionada != null) ...[
                //   Center(
                //     child: Text(
                //       'Precio: ${monedasProvider.monedaSeleccionada!.siglas} ${NumberFormat('#,##0.00', 'es_MX').format(producto.precios.firstWhere((p) => p.idMoneda == monedasProvider.monedaSeleccionada!.idMoneda, orElse: () => Precio(idPrecio: 0, idProducto: producto.idProducto, idMoneda: monedasProvider.monedaSeleccionada!.idMoneda, precio: 0)).precio)}',
                //       style: theme.textTheme.titleMedium?.copyWith(
                //         color: theme.colorScheme.primary,
                //         fontWeight: FontWeight.bold,
                //       ),
                //     ),
                //   ),
                // ],
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
                      'Stock Total: ${producto.stocks.fold<int>(0, (sum, stock) => sum + stock.stock)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
            
                // Stocks por localidad
                if (producto.stocks.fold<int>(0, (sum, stock) => sum + stock.stock) > 0) ...[
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
                          (s) => s.idLocalidad == localidad.idLocalidad,
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
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      stock.stock > 0
                                          ? Colors.green.withOpacity(0.3)
                                          : Colors.red.withOpacity(0.3),
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
                          _mostrarDialogoAgregarAlPedido(context, producto);
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
            ),
          ),
    );
  }

  void _mostrarDialogoAgregarAlPedido(BuildContext context, Producto producto) {
    final pedidosProvider = context.read<PedidosProvider>();
    final tiendasProvider = context.read<TiendasProvider>();
    final cantidadActual =
        pedidosProvider.pedidoActual?.detalles
            .firstWhere(
              (d) => d.idProducto == producto.idProducto,
              orElse:
                  () => DetallePedido(
                    idPedido: -1,
                    idProducto: producto.idProducto,
                    cantidad: 0,
                  ),
            )
            .cantidad;

    final textController = TextEditingController(
      text: cantidadActual.toString(),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Agregar ${producto.descripcion}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Código: ${producto.codigo ?? 'N/A'}'),
                const SizedBox(height: 20),
                TextFormField(
                  controller: textController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad a pedir',
                    border: OutlineInputBorder(),
                  ),
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
                  final cantidad = int.tryParse(textController.text) ?? 0;
                  if (cantidad > 0) {
                    if (pedidosProvider.pedidoActual == null) {
                      if (tiendasProvider.tiendasSeleccionadas.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Seleccione al menos una tienda'),
                          ),
                        );
                        return;
                      }
                      pedidosProvider.crearNuevoPedido(
                        tiendasProvider.tiendasSeleccionadas.first.idTienda,
                      );
                    }

                    final nuevoDetalle = DetallePedido(
                      idPedido: pedidosProvider.pedidoActual!.idPedido,
                      idProducto: producto.idProducto,
                      cantidad: cantidad,
                    );

                    pedidosProvider.agregarDetallePedido(nuevoDetalle, true);
                  }
                  Navigator.pop(context);
                },
                child: const Text('Agregar'),
              ),
            ],
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
                              title: const Text('Solo activos'),
                              value: productosProvider.filtros.soloActivos,
                              onChanged: (value) {
                                productosProvider.setSoloActivos(value);
                                setState(() {});
                              },
                            ),
                            const SizedBox(height: 8),
                            SegmentedButton<bool?>(
                              segments: const [
                                ButtonSegment<bool?>(
                                  value: null,
                                  label: Text('Todos'),
                                ),
                                ButtonSegment<bool?>(
                                  value: true,
                                  label: Text('Con stock'),
                                ),
                                ButtonSegment<bool?>(
                                  value: false,
                                  label: Text('Sin stock'),
                                ),
                              ],
                              selected: {productosProvider.filtros.conStock},
                              onSelectionChanged: (Set<bool?> newSelection) {
                                productosProvider.setConStock(
                                  newSelection.first,
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
                  productosProvider.filtros.conStock != null,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () {
              _showFilterDialog(context, productosProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.replay_sharp),
            onPressed: () {
              productosProvider.getProductos(forceUpdate: true);
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
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4.0,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Mostrando ${productosProvider.productosFiltrados.length} productos',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
