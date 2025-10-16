import 'package:easy_bo_mobile_app/models/localidad.dart';
import 'package:easy_bo_mobile_app/models/movimiento_historial.dart';
import 'package:easy_bo_mobile_app/models/producto.dart';
import 'package:easy_bo_mobile_app/presentation/providers/documentos_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/flujo_caja_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/monedas_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/tiendas_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:easy_bo_mobile_app/services/image_service.dart';

class ProductoHistorialScreen extends StatefulWidget {
  final Producto producto;

  const ProductoHistorialScreen({super.key, required this.producto});

  @override
  State<ProductoHistorialScreen> createState() =>
      _ProductoHistorialScreenState();
}

class _ProductoHistorialScreenState extends State<ProductoHistorialScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<DocumentosProvider>().actualizarMovimientosHistorial(
        widget.producto.idProducto,
      );
    });
  }

  void _mostrarFiltros(BuildContext context) {
    final documentosProvider = context.read<DocumentosProvider>();
    final tiendasProvider = context.read<TiendasProvider>();
    final theme = Theme.of(context);

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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Filtros', style: theme.textTheme.titleLarge),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Rango de fechas',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final DateTimeRange? rango =
                              await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2024),
                                lastDate: DateTime.now(),
                                initialDateRange:
                                    documentosProvider.filtros.rangoFechas,
                              );
                          if (rango != null) {
                            documentosProvider.setRangoFechas(rango);
                            setState(() {});
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                documentosProvider.filtros.rangoFechas != null
                                    ? '${DateFormat('dd/MM/yyyy').format(documentosProvider.filtros.rangoFechas!.start)} - ${DateFormat('dd/MM/yyyy').format(documentosProvider.filtros.rangoFechas!.end)}'
                                    : 'Seleccionar fechas',
                              ),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Localidades', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children:
                            tiendasProvider.localidades.map((localidad) {
                              final isSelected = documentosProvider
                                  .filtros
                                  .localidadesSeleccionadas
                                  .contains(localidad.idLocalidad);
                              return FilterChip(
                                label: Text(
                                  "${localidad.idLocalidad}: ${localidad.localidad}",
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  final nuevasLocalidades = List<int>.from(
                                    documentosProvider
                                        .filtros
                                        .localidadesSeleccionadas,
                                  );
                                  if (selected) {
                                    nuevasLocalidades.add(
                                      localidad.idLocalidad,
                                    );
                                  } else {
                                    nuevasLocalidades.remove(
                                      localidad.idLocalidad,
                                    );
                                  }
                                  documentosProvider
                                      .setLocalidadesSeleccionadas(
                                        nuevasLocalidades,
                                      );
                                  setState(() {});
                                },
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              documentosProvider.setRangoFechas(null);
                              documentosProvider.setLocalidadesSeleccionadas(
                                [],
                              );
                              documentosProvider.actualizarMovimientosHistorial(
                                widget.producto.idProducto,
                              );
                            },
                            child: const Text('Limpiar filtros'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(context);
                              documentosProvider.actualizarMovimientosHistorial(
                                widget.producto.idProducto,
                              );
                            },
                            child: const Text('Aplicar'),
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

  @override
  Widget build(BuildContext context) {
    final documentosProvider = context.watch<DocumentosProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de ${widget.producto.descripcion}'),
        backgroundColor: theme.colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible:
                  documentosProvider.filtros.rangoFechas != null ||
                  documentosProvider
                      .filtros
                      .localidadesSeleccionadas
                      .isNotEmpty,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () => _mostrarFiltros(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProductoInfo(context),
          if (documentosProvider.cargando)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (documentosProvider.movimientosHistorial.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No hay movimientos registrados\npara este producto',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: documentosProvider.movimientosHistorial.length,
                itemBuilder: (context, index) {
                  final movimientoHistorial =
                      documentosProvider.movimientosHistorial[index];

                  return _buildMovimientoItem(movimientoHistorial, theme);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductoInfo(BuildContext context) {
    final theme = Theme.of(context);
    final imageService = ImageService();

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: imageService.getProductImage(widget.producto),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.producto.descripcion,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Código: ${widget.producto.codigo ?? 'N/A'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovimientoItem(MovimientoHistorial movimiento, ThemeData theme) {
    final esEntrada =
        movimiento.documento.tipo == 'ENTRADA' ||
        movimiento.documento.tipo == 'POSITIVO';
    final esCreacion = movimiento.documento.tipo == 'CREADO';
    final esModificacion = movimiento.documento.tipo == 'MODIFICADO';
    final esTraslado = movimiento.documento.tipo == 'TRASLADO';
    final _ = !esEntrada && !esCreacion && !esModificacion && !esTraslado;
    final pago = context.read<FlujoCajaProvider>().getPago(
      movimiento.idPago ?? 1,
    );
    final moneda = context.read<MonedasProvider>().getMoneda(pago.idMoneda);

    int? localidadDestino = movimiento.documento.idLocalidadDestino;

    final tiendasProvider = context.read<TiendasProvider>();
    final localidad = tiendasProvider.localidades.firstWhere(
      (l) => l.idLocalidad == movimiento.documento.idLocalidad,
      orElse:
          () => Localidad(
            idLocalidad: 0,
            localidad: 'Desconocida',
            idTienda: 0,
            tipo: '',
          ),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat(
                        'dd/MM/yyyy hh:mm a',
                      ).format(movimiento.documento.fecha),
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      esCreacion || esModificacion
                          ? ''
                          : '${localidad.localidad} (${localidad.idLocalidad})',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      movimiento.documento.tipo,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getColorForTipoDocumento(
                          movimiento.documento.tipo,
                          theme,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        esTraslado
                            ? '${movimiento.documento.idLocalidad} -> ${localidadDestino ?? movimiento.documento.razon}'
                            : movimiento.documento.razon,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (esCreacion)
                        Text(
                          'Producto creado',
                          style: theme.textTheme.bodyLarge,
                        )
                      else ...[
                        Row(
                          children: [
                            if (esModificacion)
                              Text('Precio anterior:')
                            else ...[
                              Icon(
                                esEntrada
                                    ? Icons.add_circle
                                    : Icons.remove_circle,
                                color: esEntrada ? Colors.green : Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${movimiento.cantidad} ${(movimiento.cantidad == 1) ? 'unidad' : 'unidades'}',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: esEntrada ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${moneda.siglas}: \$${NumberFormat('#,##0.00', 'es_MX').format(movimiento.precioProducto)}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (movimiento.descuento != null &&
                            movimiento.descuento! > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Descuento: -\$${NumberFormat('#,##0.00', 'es_MX').format(movimiento.descuento!)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (esCreacion) ...[
                      Text(
                        'Precio:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${NumberFormat('#,##0.00', 'es_MX').format(movimiento.importe ?? 0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ] else if (esModificacion) ...[
                      Text(
                        'Precio nuevo:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${NumberFormat('#,##0.00', 'es_MX').format(movimiento.importe ?? 0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ] else ...[
                      Text(
                        '\$${NumberFormat('#,##0.00', 'es_MX').format(movimiento.importe ?? 0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Stock: ${movimiento.saldoProducto ?? 'N/A'}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForTipoDocumento(String tipo, ThemeData theme) {
    switch (tipo) {
      case 'ENTRADA':
      case 'POSITIVO':
        return Colors.green;
      case 'CREADO':
        return Colors.blue;
      case 'MODIFICADO':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }
}
