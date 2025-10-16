import 'package:easy_bo_mobile_app/presentation/providers/monedas_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/tiendas_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/flujo_caja_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ResumenTiendas extends StatelessWidget {
  final MonedasProvider monedasProvider;
  const ResumenTiendas({super.key, required this.monedasProvider});

  static const Map<bool, IconData> iconosMetodosPago = {
    true: Icons.attach_money,
    false: Icons.account_balance,
  };

  @override
  Widget build(BuildContext context) {
    final flujoCajaProvider = context.watch<FlujoCajaProvider>();
    final tiendasProvider = context.watch<TiendasProvider>();

    final resumenFlujos = flujoCajaProvider.resumenFlujos;

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text(
          //   'Resumen por Tienda',
          //   style: theme.textTheme.titleMedium?.copyWith(
          //     fontWeight: FontWeight.bold,
          //   ),
          // ),
          // const SizedBox(height: 8),
          // Wrap(
          //   spacing: 12,
          //   runSpacing: 8,
          //   children: resumenVentas.entries.map((entry) {
          //     return Chip(
          //       backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          //       label: Row(
          //         mainAxisSize: MainAxisSize.min,
          //         children: [
          //           Text(
          //             '${entry.key}:',
          //             style: TextStyle(
          //               color: theme.colorScheme.primary,
          //             ),
          //           ),
          //           const SizedBox(width: 6),
          //           Text(
          //             '\$${NumberFormat('#,##0.00', 'es_MX').format(entry.value)}',
          //             style: TextStyle(
          //               fontWeight: FontWeight.bold,
          //               color: theme.colorScheme.primary,
          //             ),
          //           ),
          //         ],
          //       ),
          //     );
          //   }).toList(),
          // ),
          // const SizedBox(height: 16),
          Text(
            'Resumen de Ingresos',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (flujoCajaProvider.cargando) const CircularProgressIndicator(),
          if (resumenFlujos.isEmpty && !flujoCajaProvider.cargando)
            const Text('No hay ingresos para las fechas seleccionadas.'),
          ...resumenFlujos.entries.map((entryLocalidad) {
            final idLocalidad = entryLocalidad.key;
            final resumenMetodoPago = entryLocalidad.value;
            final totalLocalidad = resumenMetodoPago.values.fold<num>(
              0,
              (a, b) => a + b.importe,
            );
            String nombreLocalidad =
                tiendasProvider.getLocalidad(idLocalidad).localidad;
            final tienda = tiendasProvider.getTiendaByLocalidad(idLocalidad);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tienda.nombre}: $nombreLocalidad',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Total: \$${NumberFormat('#,##0.00', 'es_MX').format(totalLocalidad)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children:
                          resumenMetodoPago.entries.map((entryMetodo) {
                            final idMetodo = entryMetodo.key;
                            final pago = entryMetodo.value.formaPago;
                            final moneda = monedasProvider.getMoneda(pago.idMoneda);
                            final importe = entryMetodo.value.importe;
                            final monto = entryMetodo.value.monto;
                            final nombreMetodo =
                                pago.idPago > 0 ? pago.tipoPago : "Desconocido";
                            final icono =
                                iconosMetodosPago[pago.efectivo] ??
                                Icons.payment;
                            final color =
                                Colors.primaries[idMetodo %
                                    Colors.primaries.length];

                            return Chip(
                              avatar: Icon(icono, color: color),
                              label: monto == importe ? 
                              Text(
                                '$nombreMetodo: \$${NumberFormat('#,##0.00', 'es_MX').format(importe)}',
                                style: TextStyle(color: color),
                              ) :
                              Text(
                                '$nombreMetodo:\n ${NumberFormat('#,##0.00', 'es_MX').format(monto)} ${moneda.siglas}: \$${NumberFormat('#,##0.00', 'es_MX').format(importe)}',
                                style: TextStyle(color: color),
                                maxLines: 2,
                              ),
                              backgroundColor: color.withOpacity(0.1),
                              shape: StadiumBorder(
                                side: BorderSide(color: color),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
