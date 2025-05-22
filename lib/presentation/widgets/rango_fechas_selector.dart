import 'package:easy_bo_mobile_app/presentation/providers/documentos_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class RangoFechasSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final documentosProvider = context.watch<DocumentosProvider>();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              documentosProvider.filtros.rangoFechas != null
                  ? _formatearRango(documentosProvider.filtros.rangoFechas!)
                  : 'Seleccionar fechas',
              style: TextStyle(fontSize: 14),
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_calendar),
            onPressed: () => _mostrarSelectorFechas(context),
          ),
        ],
      ),
    );
  }

  String _formatearRango(DateTimeRange rango) {
    return '${DateFormat('dd/MM/yy').format(rango.start)} - ${DateFormat('dd/MM/yy').format(rango.end)}';
  }

  Future<void> _mostrarSelectorFechas(BuildContext context) async {
    final documentosProvider = context.read<DocumentosProvider>();
    final DateTimeRange? nuevoRango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(DateTime.now().year+1),
      initialDateRange: documentosProvider.filtros.rangoFechas,
    );

    if (nuevoRango != null) {
      await documentosProvider.setRangoFechas(nuevoRango);
    }
  }
}