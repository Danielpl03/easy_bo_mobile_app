import 'package:easy_bo_mobile_app/models/tienda.dart';
import 'package:easy_bo_mobile_app/models/localidad.dart';
import 'package:easy_bo_mobile_app/presentation/providers/tiendas_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showMultiSelectDialog(
    BuildContext context,
    TiendasProvider tiendasProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.store, color: Colors.blue),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      "Seleccionar Tiendas y Localidades",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.clip
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tiendas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...tiendasProvider.tiendas.map((tienda) {
                      return _buildStoreItem(tienda, tiendasProvider, setDialogState);
                    }),
                    const SizedBox(height: 16),
                    const Text(
                      'Localidades',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...tiendasProvider.localidades
                        .where((localidad) => tiendasProvider.tiendasSeleccionadas
                            .any((tienda) => tienda.idTienda == localidad.idTienda))
                        .map((localidad) {
                      return _buildLocalidadItem(localidad, tiendasProvider, setDialogState);
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Aplicar',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStoreItem(Tienda tienda, TiendasProvider provider, StateSetter setDialogState) {
    return ListTile(
      leading: Icon(Icons.storefront, color: Colors.grey[700]),
      title: Text(tienda.nombre, style: const TextStyle(fontSize: 16)),
      trailing: Checkbox(
        value: provider.tiendasSeleccionadas.contains(tienda),
        onChanged: (value) {
          provider.seleccionarTienda(tienda);
          setDialogState(() {});
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      onTap: () {
        provider.seleccionarTienda(tienda);
        setDialogState(() {});
      },
    );
  }

  Widget _buildLocalidadItem(Localidad localidad, TiendasProvider provider, StateSetter setDialogState) {
    return ListTile(
      leading: Icon(Icons.location_on, color: Colors.grey[700]),
      title: Text(localidad.localidad, style: const TextStyle(fontSize: 16)),
      subtitle: Text(
        provider.tiendas
            .firstWhere((t) => t.idTienda == localidad.idTienda)
            .nombre,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: Checkbox(
        value: provider.localidadesSeleccionadas.contains(localidad),
        onChanged: (value) {
          provider.seleccionarLocalidad(localidad);
          setDialogState(() {});
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      onTap: () {
        provider.seleccionarLocalidad(localidad);
        setDialogState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tiendasProvider = context.watch<TiendasProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.apps_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text('Easy BO', style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              context.watch<ThemeProvider>().isDarkMode 
                ? Icons.light_mode 
                : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: () {
              context.read<ThemeProvider>().toggleTheme();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text(
              'M&L SOLUCIONES',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
        backgroundColor: theme.primaryColor,
        elevation: 3,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStoreSelectorCard(context, tiendasProvider),
            const SizedBox(height: 24),
            _buildNavigationButton(
              context: context,
              icon: Icons.inventory_2,
              label: 'Gestión de Productos',
              route: '/productos',
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 16),
            _buildNavigationButton(
              context: context,
              icon: Icons.receipt_long,
              label: 'Historial de Ventas',
              route: '/ventas',
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            _buildNavigationButton(
              context: context,
              icon: Icons.shopping_cart,
              label: 'Gestión de pedidos',
              route: '/pedidos',
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreSelectorCard(
    BuildContext context,
    TiendasProvider provider,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, size: 22, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Tiendas y Localidades Activas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (provider.tiendasSeleccionadas.isEmpty) _buildEmptyState(),
            if (provider.tiendasSeleccionadas.isNotEmpty) ...[
              const Text(
                'Tiendas:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: provider.tiendasSeleccionadas.map((tienda) {
                  return InputChip(
                    label: Text(tienda.nombre),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => provider.seleccionarTienda(tienda),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    labelStyle: const TextStyle(color: Colors.blue),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Localidades:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: provider.localidadesSeleccionadas.map((localidad) {
                  final tienda = provider.tiendas.firstWhere(
                    (t) => t.idTienda == localidad.idTienda,
                  );
                  return InputChip(
                    label: Text('${localidad.localidad} (${tienda.nombre})'),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => provider.seleccionarLocalidad(localidad),
                    backgroundColor: Colors.green.withOpacity(0.1),
                    labelStyle: const TextStyle(color: Colors.green),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_business, size: 20),
              label: const Text('Administrar Tiendas y Localidades'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.withOpacity(0.1),
                foregroundColor: Colors.blue,
              ),
              onPressed: () => _showMultiSelectDialog(context, provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          'No hay tiendas seleccionadas',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildNavigationButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
    required Color color,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(width: 16),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 18, color: color),
          ],
        ),
      ),
    );
  }
}
