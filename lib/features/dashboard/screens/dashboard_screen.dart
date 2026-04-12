import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/subscription.dart';
import '../../../core/providers/dashboard_provider.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/services/firebase_service.dart';
import '../../subscriptions/screens/subscriptions_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isSettling = false;

  Future<void> _runSettlement() async {
    setState(() => _isSettling = true);
    try {
      await FirebaseService.runDailySettlement();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Daily settlement complete! Stale orders cancelled & refunded.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(dashboardDataProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to run settlement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSettling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardData = ref.watch(dashboardDataProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: dashboardData.when(
          data: (data) => _buildDashboard(context, data),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, Map<String, dynamic> data) {
    final forecast = data['tomorrowForecast'] as Map<String, dynamic>;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- FIX: Wrapped the title in Expanded to prevent overflow ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Dashboard - ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isSettling ? null : _runSettlement,
                icon:
                    _isSettling
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Icon(Icons.autorenew),
                label: const Text('Settle Stale Orders'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
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
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (context) => SubscriptionsScreen(
                              initialFilter: SubscriptionFilter(
                                status: SubscriptionStatus.active,
                              ),
                            ),
                      ),
                    );
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
              children:
                  forecast.entries.map((entry) {
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
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastCard(
    String title,
    String value,
    IconData icon,
    Color backgroundColor,
  ) {
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
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
