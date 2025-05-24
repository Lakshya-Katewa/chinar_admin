import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chinar Dairy Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF2E7D32)),
              child: Text(
                'Chinar Dairy\nAdmin Panel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.dashboard,
              title: 'Dashboard',
              route: '/dashboard',
            ),
            _buildDrawerItem(
              context,
              icon: Icons.inventory,
              title: 'Products',
              route: '/products',
            ),
            _buildDrawerItem(
              context,
              icon: Icons.shopping_cart,
              title: 'Orders',
              route: '/orders',
            ),
            _buildDrawerItem(
              context,
              icon: Icons.subscriptions,
              title: 'Subscriptions',
              route: '/subscriptions',
            ),
            _buildDrawerItem(
              context,
              icon: Icons.delivery_dining,
              title: 'Delivery Persons',
              route: '/delivery-persons',
            ),
            _buildDrawerItem(
              context,
              icon: Icons.location_on,
              title: 'Areas',
              route: '/areas',
            ),
            _buildDrawerItem(
              context,
              icon: Icons.people,
              title: 'Customers',
              route: '/customers',
            ),
          ],
        ),
      ),
      body: child,
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    final isSelected = currentRoute == route;

    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFF2E7D32) : null),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF2E7D32) : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      selected: isSelected,
      onTap: () {
        Navigator.pop(context);
        context.go(route);
      },
    );
  }
}
