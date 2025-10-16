import 'package:easy_bo_mobile_app/config/app_router.dart';
import 'package:easy_bo_mobile_app/config/supabase_config.dart';
import 'package:easy_bo_mobile_app/presentation/providers/flujo_caja_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/documentos_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/ventas_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/monedas_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/pedidos_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/productos_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/theme_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/auth_provider.dart';
import 'package:easy_bo_mobile_app/services/local_storage_service.dart';
import 'package:easy_bo_mobile_app/services/notificaciones_service.dart';
import 'package:easy_bo_mobile_app/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'presentation/providers/tiendas_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Inicializar Hive
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);

    // Inicializar notificaciones
    await NotificacionesService.initialize();

    final localStorage = LocalStorageService();
    await localStorage.init();

    await SupabaseConfig.initialize();

    // Inicializar package_info_plus
    await PackageInfo.fromPlatform();

    runApp(const MyApp());
  } catch (e) {
    print(e);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create:
              (_) => TiendasProvider(SupabaseService(SupabaseConfig.client)),
        ),
        ChangeNotifierProvider(
          create:
              (_) => MonedasProvider(SupabaseService(SupabaseConfig.client)),
        ),
        ChangeNotifierProxyProvider<TiendasProvider, ProductosProvider>(
          create:
              (_) => ProductosProvider(
                TiendasProvider(SupabaseService(SupabaseConfig.client)),
              ),
          update:
              (_, tiendasProvider, productosProvider) =>
                  ProductosProvider(tiendasProvider),
        ),
        ChangeNotifierProxyProvider<TiendasProvider, VentasProvider>(
          create:
              (_) => VentasProvider(
                TiendasProvider(SupabaseService(SupabaseConfig.client)),
                ProductosProvider(
                  TiendasProvider(SupabaseService(SupabaseConfig.client)),
                ),
              ),
          update:
              (_, tiendasProvider, productosProvider) => VentasProvider(
                tiendasProvider,
                ProductosProvider(
                  TiendasProvider(SupabaseService(SupabaseConfig.client)),
                ),
              ),
        ),
        ChangeNotifierProxyProvider<TiendasProvider, DocumentosProvider>(
          create:
              (_) => DocumentosProvider(
                TiendasProvider(SupabaseService(SupabaseConfig.client)),
              ),
          update:
              (_, tiendasProvider, documentosProvider) =>
                  DocumentosProvider(tiendasProvider),
        ),
        ChangeNotifierProvider(
          create: (_) => PedidosProvider()..cargarPedidos(),
        ),
        ChangeNotifierProvider(create: (_) => FlujoCajaProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final authProvider = Provider.of<AuthProvider>(context);
          final router = createRouter(authProvider);
          return MaterialApp.router(
            routerConfig: router,
            title: 'Easy BO',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
