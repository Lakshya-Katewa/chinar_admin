// dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/subscription.dart'; // ADDED for SubscriptionStatus
import '../../../core/providers/dashboard_provider.dart';
import '../../../core/providers/subscription_provider.dart'; // ADDED for SubscriptionFilter
import '../../subscriptions/screens/subscriptions_screen.dart'; // ADDED for navigation

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardData = ref.watch(dashboardDataProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: dashboardData.when(
          data: (data) => _buildDashboard(context, data), // Pass context for navigation
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error: $error'),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, Map<String, dynamic> data) {
    // The forecast is now a map of product names to quantities.
    final forecast = data['tomorrowForecast'] as Map<String, dynamic>;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard - ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          const Text(
            'Today\'s Overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
              // UPDATED: Made this card clickable
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => SubscriptionsScreen(
                        // Pre-filter the screen to show only active subscriptions
                        initialFilter:
                            SubscriptionFilter(status: SubscriptionStatus.active),
                      ),
                    ));
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: _buildStatCard(
                    'Active Subscriptions',
                    data['activeSubscriptions'].toString(),
                    Icons.subscriptions,
                    Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Today\'s Revenue',
            '₹${data['todayRevenue'].toStringAsFixed(2)}',
            Icons.currency_rupee,
            Colors.orange,
          ),
          const SizedBox(height: 32),
          const Text(
            'Tomorrow\'s Delivery Forecast',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // UPDATED: Dynamically generate forecast cards
          if (forecast.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Text('No deliveries scheduled for tomorrow.'),
              ),
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: forecast.entries.map((entry) {
                final productName = entry.key;
                final quantity = entry.value as double;
                return _buildForecastCard(
                  productName,
                  '${quantity.toStringAsFixed(1)} units',
                  Icons.inventory_2_outlined,
                  Colors.blue.shade50,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
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

  Widget _buildForecastCard(
      String title, String value, IconData icon, Color backgroundColor) {
    return Card(
      elevation: 0,
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              textAlign: TextAlign.center,
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