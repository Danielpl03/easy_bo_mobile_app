import 'package:easy_bo_mobile_app/presentation/providers/auth_provider.dart';
import 'package:easy_bo_mobile_app/presentation/screens/catalogos_screen.dart';
import 'package:easy_bo_mobile_app/presentation/screens/historial_documentos_screen.dart';
import 'package:easy_bo_mobile_app/presentation/screens/pedidos_screen.dart';
import 'package:easy_bo_mobile_app/presentation/screens/productos_screen.dart';
import 'package:easy_bo_mobile_app/presentation/screens/producto_historial_screen.dart';
import 'package:easy_bo_mobile_app/presentation/screens/proveedores_screen.dart';
import 'package:easy_bo_mobile_app/presentation/screens/ventas_screen.dart';
import 'package:easy_bo_mobile_app/presentation/screens/settings_screen.dart';
import 'package:easy_bo_mobile_app/presentation/screens/login_screen.dart';
import 'package:easy_bo_mobile_app/presentation/screens/profile_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_bo_mobile_app/presentation/screens/home_screen.dart';

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authProvider, // Escuchar cambios en AuthProvider
    redirect: (context, state) {
      print('🛣️ [AppRouter] Redirección solicitada');
      print('🛣️ [AppRouter] Ruta actual: ${state.matchedLocation}');
      print('🛣️ [AppRouter] AuthProvider loading: ${authProvider.isLoading}');
      print(
        '🛣️ [AppRouter] AuthProvider authenticated: ${authProvider.isAuthenticated}',
      );
      print(
        '🛣️ [AppRouter] AuthProvider currentUser: ${authProvider.currentUser}',
      );

      // Si está cargando, no redirigir
      if (authProvider.isLoading) {
        print('🛣️ [AppRouter] ⏳ Está cargando, no redirigir');
        return null;
      }

      // Si no está autenticado y no está en la pantalla de login, redirigir a login
      if (!authProvider.isAuthenticated && state.matchedLocation != '/login') {
        print('🛣️ [AppRouter] 🔒 No autenticado, redirigiendo a /login');
        return '/login';
      }

      // Si está autenticado y está en la pantalla de login, redirigir a home
      if (authProvider.isAuthenticated && state.matchedLocation == '/login') {
        print('🛣️ [AppRouter] ✅ Autenticado en login, redirigiendo a /');
        return '/';
      }

      print('🛣️ [AppRouter] ✅ No redirección necesaria');
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/productos',
        builder: (context, state) => const ProductosScreen(),
      ),
      GoRoute(
        path: '/producto-historial',
        builder:
            (context, state) =>
                ProductoHistorialScreen(producto: state.extra as dynamic),
      ),
      // GoRoute(
      //   path: '/tiendas',
      //   builder: (context, state) => const TiendasScreen(),
      // ),
      GoRoute(
        path: '/ventas',
        builder: (context, state) => const VentasScreen(),
      ),
      GoRoute(
        path: '/pedidos',
        builder: (context, state) => const PedidosScreen(),
      ),
      GoRoute(
        path: '/documentos',
        builder: (context, state) => const HistorialDocumentosScreen(),
      ),
      GoRoute(
        path: '/proveedores',
        builder: (context, state) => const ProveedoresScreen(),
      ),
      GoRoute(path: '/ajustes', builder: (context, state) => SettingsScreen()),
      GoRoute(
        path: '/perfil',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(path: '/catalogos', builder: (_, __) => const CatalogosScreen()),
    ],
  );
}
