import 'package:easy_bo_mobile_app/presentation/screens/pedidos_screen.dart';
import 'package:easy_bo_mobile_app/presentation/screens/productos_screen.dart';
import 'package:easy_bo_mobile_app/presentation/screens/ventas_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_bo_mobile_app/presentation/screens/home_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/productos',
      builder: (context, state) => const ProductosScreen(),
    ),
    // GoRoute(
    //   path: '/tiendas',
    //   builder: (context, state) => const TiendasScreen(),
    // ),
    GoRoute(path: '/ventas', builder: (context, state) => const VentasScreen()),
    GoRoute(
      path: '/pedidos',
      builder: (context, state) => const PedidosScreen(),
    ),
  ],
);
