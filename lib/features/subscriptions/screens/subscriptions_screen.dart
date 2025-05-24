import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/subscription.dart';
import '../../../core/providers/subscription_provider.dart';
import '../widgets/add_subscription_dialog.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(subscriptionsProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subscriptions',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddSubscriptionDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Subscription'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: subscriptionsAsync.when(
                data: (subscriptions) => _buildSubscriptionsList(context, ref, subscriptions),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Error: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionsList(BuildContext context, WidgetRef ref, List<Subscription> subscriptions) {
    if (subscriptions.isEmpty) {
      return const Center(
        child: Text('No subscriptions found'),
      );
    }

    return ListView.builder(
      itemCount: subscriptions.length,
      itemBuilder: (context, index) {
        final subscription = subscriptions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text('${subscription.customerName} - ${subscription.productName}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Phone: ${subscription.customerPhone}'),
                Text('Type: ${_getSubscriptionTypeText(subscription.type)}'),
                Text('Quantity: ${subscription.quantity}'),
                Text('Start Date: ${DateFormat('MMM dd, yyyy').format(subscription.startDate)}'),
                if (subscription.endDate != null)
                  Text('End Date: ${DateFormat('MMM dd, yyyy').format(subscription.endDate!)}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Chip(
                  label: Text(
                    subscription.isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: subscription.isActive ? Colors.green : Colors.grey,
                ),
              ],
            ),
            onTap: () => _showSubscriptionDetails(context, ref, subscription),
          ),
        );
      },
    );
  }

  String _getSubscriptionTypeText(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.monthly:
        return 'Monthly';
      case SubscriptionType.weekly:
        return 'Weekly';
      case SubscriptionType.alternateDay:
        return 'Alternate Day';
    }
  }

  void _showAddSubscriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddSubscriptionDialog(),
    );
  }

  void _showSubscriptionDetails(BuildContext context, WidgetRef ref, Subscription subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Subscription #${subscription.id.substring(0, 8)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${subscription.customerName}'),
            Text('Phone: ${subscription.customerPhone}'),
            Text('Email: ${subscription.customerEmail}'),
            Text('Product: ${subscription.productName}'),
            Text('Type: ${_getSubscriptionTypeText(subscription.type)}'),
            Text('Quantity: ${subscription.quantity}'),
            Text('Price per Unit: ₹${subscription.pricePerUnit}'),
            Text('Area: ${subscription.areaCode}'),
            Text('Address: ${subscription.address}'),
            Text('Start Date: ${DateFormat('MMM dd, yyyy').format(subscription.startDate)}'),
            if (subscription.endDate != null)
              Text('End Date: ${DateFormat('MMM dd, yyyy').format(subscription.endDate!)}'),
            Text('Status: ${subscription.isActive ? 'Active' : 'Inactive'}'),
            const SizedBox(height: 16),
            if (subscription.isActive)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _toggleSubscriptionStatus(context, ref, subscription),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Deactivate Subscription'),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _toggleSubscriptionStatus(context, ref, subscription),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Activate Subscription'),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSubscriptionStatus(BuildContext context, WidgetRef ref, Subscription subscription) async {
    try {
      final updatedSubscription = Subscription(
        id: subscription.id,
        customerName: subscription.customerName,
        customerPhone: subscription.customerPhone,
        customerEmail: subscription.customerEmail,
        productId: subscription.productId,
        productName: subscription.productName,
        type: subscription.type,
        startDate: subscription.startDate,
        endDate: subscription.endDate,
        isActive: !subscription.isActive,
        quantity: subscription.quantity,
        pricePerUnit: subscription.pricePerUnit,
        areaCode: subscription.areaCode,
        address: subscription.address,
      );

      await ref.read(subscriptionNotifierProvider).updateSubscription(updatedSubscription);
      
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              subscription.isActive 
                  ? 'Subscription deactivated successfully'
                  : 'Subscription activated successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating subscription: $e')),
        );
      }
    }
  }
}
