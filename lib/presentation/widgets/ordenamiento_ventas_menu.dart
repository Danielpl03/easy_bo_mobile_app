import 'package:easy_bo_mobile_app/presentation/providers/documentos_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/tiendas_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrdenamientoVentasMenu extends StatelessWidget {
  const OrdenamientoVentasMenu({super.key});

  

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentosProvider>();

    IconData getIconoOrdenActual() {
    switch (provider.ordenVentas) {
      case OrdenVentas.fecha:
        return Icons.calendar_month;
      case OrdenVentas.tienda:
        return Icons.store;
      case OrdenVentas.importe:
        return Icons.attach_money;
    }
  }

    return PopupMenuButton<OrdenVentas>(
      icon: Icon(getIconoOrdenActual()),
      onSelected: (orden) => provider.cambiarOrdenVentas(orden),
      itemBuilder:
          (context) => [
            PopupMenuItem(
              value: OrdenVentas.fecha,
              child: Row(
                children: [
                  Icon(Icons.calendar_month, size: 20),
                  SizedBox(width: 8),
                  Text('Ordenar por fecha'),
                ],
              ),
            ),
            PopupMenuItem(
              value: OrdenVentas.tienda,
              child: Row(
                children: [
                  Icon(Icons.store, size: 20),
                  SizedBox(width: 8),
                  Text('Ordenar por tienda'),
                ],
              ),
            ),
            PopupMenuItem(
              value: OrdenVentas.importe,
              child: Row(
                children: [
                  Icon(Icons.attach_money, size: 20),
                  SizedBox(width: 8),
                  Text('Ordenar por importe'),
                ],
              ),
            ),
          ],
    );
  }
}
