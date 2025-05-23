import 'package:easy_bo_mobile_app/presentation/providers/documentos_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

Widget ResumenTiendas() {
  return Consumer<DocumentosProvider>(
    builder: (context, provider, _) {
      final resumen = provider.resumenPorTienda;
      final theme = Theme.of(context);
      
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen por Tienda',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: resumen.entries.map((entry) {
                return Chip(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${entry.key}:',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '\$${NumberFormat('#,##0.00', 'es_MX').format(entry.value)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
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