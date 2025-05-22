import 'package:easy_bo_mobile_app/models/documento.dart';
import 'package:easy_bo_mobile_app/presentation/providers/documentos_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrdenamientoMovimientosMenu extends StatelessWidget {
  final Documento documento;
  
  const OrdenamientoMovimientosMenu({super.key, required this.documento});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentosProvider>();
    final ordenActual = provider.getOrdenMov(documento.idDocumento) ?? OrdenMovimientos.alfabetico;

    return PopupMenuButton<OrdenMovimientos>(
      icon: Icon(Icons.sort, size: 18),
      onSelected: (orden) => provider.cambiarOrdenMovimientos(documento.idDocumento, orden),
      itemBuilder: (context) => [
        _buildItem(OrdenMovimientos.alfabetico, 'Nombre', Icons.sort_by_alpha, ordenActual),
        _buildItem(OrdenMovimientos.importe, 'Importe', Icons.money, ordenActual),
        _buildItem(OrdenMovimientos.cantidad, 'Cantidad', Icons.format_list_numbered, ordenActual),
      ],
    );
  }

  PopupMenuItem<OrdenMovimientos> _buildItem(
    OrdenMovimientos orden, 
    String texto, 
    IconData icono,
    OrdenMovimientos actual
  ) {
    return PopupMenuItem(
      value: orden,
      child: Row(
        children: [
          Icon(
            icono,
            color: orden == actual ? Colors.blue : Colors.grey,
            size: 20,
          ),
          SizedBox(width: 8),
          Text(
            texto,
            style: TextStyle(
              color: orden == actual ? Colors.blue : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}