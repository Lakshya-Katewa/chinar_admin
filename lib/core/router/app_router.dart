import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/products/screens/products_screen.dart';
import '../../features/orders/screens/orders_screen.dart';
import '../../features/subscriptions/screens/subscriptions_screen.dart';
import '../../features/delivery_persons/screens/delivery_persons_screen.dart';
import '../../features/areas/screens/areas_screen.dart';
import '../../features/customers/screens/customers_screen.dart';
import '../../shared/widgets/main_layout.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.uri.toString() == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/dashboard';

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/products',
            builder: (context, state) => const ProductsScreen(),
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) => const OrdersScreen(),
          ),
          GoRoute(
            path: '/subscriptions',
            builder: (context, state) => const SubscriptionsScreen(),
          ),
          GoRoute(
            path: '/delivery-persons',
            builder: (context, state) => const DeliveryPersonsScreen(),
          ),
          GoRoute(
            path: '/areas',
            builder: (context, state) => const AreasScreen(),
          ),
          GoRoute(
            path: '/customers',
            builder: (context, state) => const CustomersScreen(),
          ),
        ],
      ),
    ],
  );
});
