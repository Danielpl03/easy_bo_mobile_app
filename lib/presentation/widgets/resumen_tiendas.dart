import 'package:easy_bo_mobile_app/presentation/providers/documentos_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

Widget ResumenTiendas() {
  return Consumer<DocumentosProvider>(
    builder: (context, provider, _) {
      final resumen = provider.resumenPorTienda;
      
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen por Tienda',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: resumen.entries.map((entry) {
                return Chip(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${entry.key}:',
                          style: TextStyle(color: Colors.blue)),
                      SizedBox(width: 6),
                      Text(
                        '\$${NumberFormat('#,##0.00', 'es_MX').format(entry.value)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800]),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    },
  );
}