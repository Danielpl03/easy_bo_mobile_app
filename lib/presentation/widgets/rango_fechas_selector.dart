import 'package:easy_bo_mobile_app/presentation/providers/flujo_caja_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/ventas_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class RangoFechasSelector extends StatelessWidget {
  const RangoFechasSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final documentosProvider = context.watch<VentasProvider>();
    
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
    final documentosProvider = context.read<VentasProvider>();
    final flujoCajaProvider = context.read<FlujoCajaProvider>();
    final DateTimeRange? nuevoRango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(DateTime.now().year+1),
      initialDateRange: documentosProvider.filtros.rangoFechas,
    );


    if (nuevoRango != null) {
      DateTime end = nuevoRango.end;
      final rango = DateTimeRange(start: nuevoRango.start, end: DateTime(end.year, end.month, end.day, 23, 59, 59));
      await documentosProvider.setRangoFechas(rango);
      await flujoCajaProvider.setRangoFechas(rango);
    }
  }
}