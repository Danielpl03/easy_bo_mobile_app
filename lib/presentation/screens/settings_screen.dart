import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/theme_provider.dart';
import 'package:easy_bo_mobile_app/config/app_config.dart';
import '../providers/productos_provider.dart';
import '../../services/image_service.dart';
import 'package:easy_bo_mobile_app/services/json_import_service.dart';
import 'package:easy_bo_mobile_app/services/supabase_service.dart'; // Reintroducir SupabaseService
import 'package:supabase_flutter/supabase_flutter.dart'; // Reintroducir Supabase
import 'package:go_router/go_router.dart';
import 'package:easy_bo_mobile_app/presentation/providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  Future<void> _showPrecacheDialog(BuildContext context) async {
    final productosProvider = context.read<ProductosProvider>();
    final imageService = ImageService();
    final totalImages = productosProvider.productos.length;
    int loadedImages = 0;
    int failedImages = 0;
    bool isPrecaching = true;
    bool cancelRequested = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          Future<void> precache() async {
            for (final producto in productosProvider.productos) {
              if (!isPrecaching || cancelRequested) break;
              try {
                final ok = await imageService.precacheProductImage(context, producto);
                if (ok) {
                  loadedImages++;
                } else {
                  failedImages++;
                }
              } catch (e) {
                failedImages++;
              }
              setState(() {});
              await Future.delayed(const Duration(milliseconds: 50));
            }
            isPrecaching = false;
            setState(() {});
          }

          // Lanzar la precarga solo una vez
          if (isPrecaching && loadedImages == 0 && failedImages == 0) {
            Future.microtask(precache);
          }

          return AlertDialog(
            title: const Text('Precargando imágenes'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: totalImages > 0 ? (loadedImages + failedImages) / totalImages : 0,
                ),
                const SizedBox(height: 16),
                Text('Progreso: ${loadedImages + failedImages}/$totalImages'),
                const SizedBox(height: 8),
                Text('Éxitos: $loadedImages'),
                const SizedBox(height: 8),
                Text('Fallos: $failedImages'),
                if (!isPrecaching)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      cancelRequested
                        ? 'Precarga cancelada. $loadedImages éxitos, $failedImages fallos.'
                        : 'Precarga finalizada. $loadedImages éxitos, $failedImages fallos.',
                      style: TextStyle(
                        color: failedImages == 0 ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              if (isPrecaching)
                TextButton(
                  onPressed: () {
                    cancelRequested = true;
                    isPrecaching = false;
                    setState(() {});
                  },
                  child: const Text('Cancelar'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(isPrecaching ? 'Cerrar' : 'Aceptar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAboutDialog(BuildContext context) async {
    try {
      final version = await AppConfig.appVersion;
      final buildNumber = await AppConfig.buildNumber;

      if (!context.mounted) return;

      showAboutDialog(
        context: context,
        applicationName: AppConfig.appName,
        applicationVersion: version,
        applicationIcon: const Icon(Icons.apps_rounded, size: 50),
        children: [
          Text(AppConfig.appDescription),
          const SizedBox(height: 8),
          Text('Desarrollado por ${AppConfig.developer}'),
          const SizedBox(height: 8),
          Text('Versión $version+$buildNumber'),
        ],
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al obtener la información de la aplicación'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        backgroundColor: theme.primaryColor,
      ),
      body: ListView(
        children: [
                            // Sección de cuenta
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      print('[SettingsScreen] Renderizando sección de cuenta...');
                      if (authProvider.currentUser != null) {
                        print('[SettingsScreen] Usuario: ${authProvider.currentUser!.nombreCompleto}');
                        return Column(
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.primaryColor.withOpacity(0.1),
                                child: Icon(
                                  Icons.person,
                                  color: theme.primaryColor,
                                ),
                              ),
                              title: Text(authProvider.currentUser!.nombreCompleto),
                              subtitle: Text(authProvider.currentUser!.email ?? 'Sin email'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.go('/perfil'),
                            ),
                            const Divider(),
                          ],
                        );
                      }
                      print('[SettingsScreen] No hay usuario autenticado');
                      return const SizedBox.shrink();
                    },
                  ),
          
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Modo Oscuro'),
            trailing: Switch(
              value: context.watch<ThemeProvider>().isDarkMode,
              onChanged: (value) {
                context.read<ThemeProvider>().toggleTheme();
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Precargar imágenes'),
            onTap: () {
              _showPrecacheDialog(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.clear_all),
            title: const Text('Borrar caché de imágenes'),
            subtitle: const Text('Liberar espacio de almacenamiento'),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Borrar caché'),
                  content: const Text(
                    '¿Estás seguro de que quieres borrar toda la caché de imágenes? '
                    'Esto liberará espacio de almacenamiento pero las imágenes se volverán a descargar cuando las necesites.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Borrar'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                try {
                  final imageService = ImageService();
                  await imageService.clearAllImageCache();
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Caché de imágenes borrada exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al borrar la caché: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Importar y sincronizar JSON'),
            onTap: () async {
              print('[SettingsScreen] Botón "Importar y sincronizar JSON" presionado.');
              final jsonService = JsonImportService();
              final supabaseService = SupabaseService(Supabase.instance.client); // Instanciar SupabaseService
              try {
                print('[SettingsScreen] Intentando seleccionar archivo JSON...');
                final jsonString = await jsonService.pickJsonFile();
                if (jsonString == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No se seleccionó ningún archivo')),
                  );
                  print('[SettingsScreen] No se seleccionó ningún archivo JSON. Operación cancelada.');
                  return;
                }
                print('[SettingsScreen] Archivo JSON seleccionado. Analizando documentos...');
                final documentosConFlujos = await jsonService.parseDocumentosConFlujosFromJson(jsonString);
                
                print('[SettingsScreen] Iniciando sincronización de documentos con Supabase...');
                await supabaseService.upsertDocumentosConFlujos(documentosConFlujos); // Llamar al nuevo método en SupabaseService
                print('[SettingsScreen] Sincronización de ventas exitosa.');

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('¡Sincronización de ventas exitosa!')),
                );
              } catch (e) {
                print('[SettingsScreen] Error crítico al sincronizar el JSON de ventas: $e'); // Mantener para depuración si es necesario
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al sincronizar el JSON de ventas: $e'), backgroundColor: Colors.red),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Acerca de'),
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }
}

