import 'package:easy_bo_mobile_app/config/app_router.dart';
import 'package:easy_bo_mobile_app/config/supabase_config.dart';
import 'package:easy_bo_mobile_app/models/detalle_pedido.dart';
import 'package:easy_bo_mobile_app/models/documento.dart';
import 'package:easy_bo_mobile_app/models/localidad.dart';
import 'package:easy_bo_mobile_app/models/moneda.dart';
import 'package:easy_bo_mobile_app/models/movimiento.dart';
import 'package:easy_bo_mobile_app/models/pago.dart';
import 'package:easy_bo_mobile_app/models/pedido.dart';
import 'package:easy_bo_mobile_app/models/precio.dart';
import 'package:easy_bo_mobile_app/models/producto.dart';
import 'package:easy_bo_mobile_app/models/stock.dart';
import 'package:easy_bo_mobile_app/models/tienda.dart';
import 'package:easy_bo_mobile_app/presentation/providers/documentos_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/monedas_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/pedidos_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/productos_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/theme_provider.dart';
import 'package:easy_bo_mobile_app/services/local_storage_service.dart';
import 'package:easy_bo_mobile_app/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'presentation/providers/tiendas_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);

    // Registrar adaptadores
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TiendaAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(LocalidadAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(MonedaAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(PagoAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(ProductoAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(PrecioAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(StockAdapter());
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(DocumentoAdapter());
    if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(MovimientoAdapter());
    if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(PedidoAdapter());
    if (!Hive.isAdapterRegistered(10))Hive.registerAdapter(DetallePedidoAdapter());

    final localStorage = LocalStorageService();
    await localStorage.init();

    await SupabaseConfig.initialize();
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
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            routerConfig: router,
            title: 'Easy BO',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
