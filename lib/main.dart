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
import 'presentation/screens/company_selection_screen.dart';

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

    // Verificar si hay una clave de configuración guardada
    final hasConfigKey = await SupabaseConfig.hasConfigKey();

    if (!hasConfigKey) {
      // Si no hay clave guardada, mostrar la pantalla de selección
      // sin inicializar Supabase todavía
      runApp(const CompanySelectionApp());
    } else {
      // Si hay clave guardada, inicializar normalmente
      await SupabaseConfig.initialize();

      // Inicializar package_info_plus
      await PackageInfo.fromPlatform();

      runApp(const MyApp());
    }
  } catch (e) {
    print('Error en main: $e');
    // En caso de error, mostrar la app con pantalla de selección
    runApp(const CompanySelectionApp());
  }
}

/// App temporal para mostrar la pantalla de selección de empresa
/// Esta app se muestra cuando no hay una clave de configuración guardada
class CompanySelectionApp extends StatefulWidget {
  const CompanySelectionApp({super.key});

  @override
  State<CompanySelectionApp> createState() => _CompanySelectionAppState();
}

class _CompanySelectionAppState extends State<CompanySelectionApp> {
  Widget? _mainApp;

  void _onCompanySelected() {
    setState(() {
      _mainApp = const MyApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_mainApp != null) {
      return _mainApp!;
    }

    return MaterialApp(
      title: 'Easy BO - Configuración',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: CompanySelectionScreen(onCompanySelected: _onCompanySelected),
      debugShowCheckedModeBanner: false,
    );
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
                  productosProvider ?? ProductosProvider(tiendasProvider),
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
