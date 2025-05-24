import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardData = ref.watch(dashboardDataProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: dashboardData.when(
          data: (data) => _buildDashboard(data),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error: $error'),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(Map<String, dynamic> data) {
    final forecast = data['tomorrowForecast'] as Map<String, dynamic>;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard - ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Today's Stats
          const Text(
            'Today\'s Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Today\'s Deliveries',
                  data['todayDeliveries'].toString(),
                  Icons.local_shipping,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Active Subscriptions',
                  data['activeSubscriptions'].toString(),
                  Icons.subscriptions,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            'Today\'s Revenue',
            '₹${data['todayRevenue'].toStringAsFixed(2)}',
            Icons.currency_rupee,
            Colors.orange,
          ),
          
          const SizedBox(height: 32),
          
          // Tomorrow's Forecast
          const Text(
            'Tomorrow\'s Delivery Forecast',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildForecastCard(
                  'Milk',
                  '${forecast['milk'].toStringAsFixed(1)} L',
                  Icons.local_drink,
                  Colors.blue.shade100,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildForecastCard(
                  'Paneer',
                  '${forecast['paneer'].toStringAsFixed(1)} Kg',
                  Icons.food_bank,
                  Colors.yellow.shade100,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildForecastCard(
                  'Cheese',
                  '${forecast['cheese'].toStringAsFixed(1)} Kg',
                  Icons.cake,
                  Colors.orange.shade100,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastCard(String title, String value, IconData icon, Color backgroundColor) {
    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
