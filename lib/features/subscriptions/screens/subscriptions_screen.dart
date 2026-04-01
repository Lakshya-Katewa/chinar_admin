// subscription_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/subscription.dart';
import '../../../core/providers/subscription_provider.dart';
import '../widgets/add_subscription_dialog.dart';

class SubscriptionsScreen extends ConsumerStatefulWidget {
  final SubscriptionFilter? initialFilter;

  const SubscriptionsScreen({super.key, this.initialFilter});

  @override
  ConsumerState<SubscriptionsScreen> createState() =>
      _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  late SubscriptionFilter _currentFilter;

  @override
  void initState() {
    super.initState();
    _currentFilter =
        widget.initialFilter ?? SubscriptionFilter(status: SubscriptionStatus.active);
  }

  int _calculateTotalDeliveries(Subscription subscription) {
    if (subscription.endDate == null) {
      return 0; // Can't calculate for open-ended subscriptions
    }

    final duration =
        subscription.endDate!.difference(subscription.startDate).inDays + 1;
    if (duration <= 0) return 0;

    switch (subscription.type) {
      case SubscriptionType.monthly:
        return (duration / 30).ceil();
      case SubscriptionType.weekly:
        return (duration / 7).ceil();
      case SubscriptionType.alternateDay:
        return (duration / 2).ceil();
    }
  }

  // REFINED: This logic now serves as the single source of truth for determining status in the UI.
  SubscriptionStatus _getActualStatus(Subscription subscription) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Rule 1: If the end date has passed, the subscription is expired, regardless of its stored status.
    if (subscription.endDate != null) {
      final endDate = DateTime(
        subscription.endDate!.year,
        subscription.endDate!.month,
        subscription.endDate!.day,
      );
      if (today.isAfter(endDate)) {
        return SubscriptionStatus.expired;
      }
    }

    // Rule 2: If not expired by date, the status stored in Firestore is authoritative.
    // For example, if it was manually cancelled, it should remain cancelled.
    return subscription.status;
  }

  @override
  Widget build(BuildContext context) {
    // CHANGED: Watch the provider that fetches ALL subscriptions.
    final subscriptionsAsync = ref.watch(allSubscriptionsProvider);

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
            _buildFilterChips(),
            const SizedBox(height: 16),
            Expanded(
              child: subscriptionsAsync.when(
                // CHANGED: Apply client-side filtering here.
                data: (allSubscriptions) {
                  // Filter the fetched list based on the true, calculated status.
                  final filteredSubscriptions = allSubscriptions.where((sub) {
                    final actualStatus = _getActualStatus(sub);
                    return actualStatus == _currentFilter.status;
                  }).toList();

                  // Sort for a consistent order.
                  filteredSubscriptions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  
                  return _buildSubscriptionsList(
                      context, ref, filteredSubscriptions);
                },
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

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: SubscriptionStatus.values.map((status) {
          final isSelected = _currentFilter.status == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(
                  status.name[0].toUpperCase() + status.name.substring(1)),
              selectedColor: _getStatusColor(status).withOpacity(0.2),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _currentFilter = SubscriptionFilter(status: status);
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubscriptionsList(
      BuildContext context, WidgetRef ref, List<Subscription> subscriptions) {
    if (subscriptions.isEmpty) {
      return const Center(
        child: Text('No subscriptions found with the selected filter.'),
      );
    }

    return ListView.builder(
      itemCount: subscriptions.length,
      itemBuilder: (context, index) {
        final subscription = subscriptions[index];
        final actualStatus = _getActualStatus(subscription);
        final totalDeliveries = _calculateTotalDeliveries(subscription);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 12,
              height: 40,
              decoration: BoxDecoration(
                color: _getStatusColor(actualStatus),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            title: Text(
              subscription.customerName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subscription.productName,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(actualStatus).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(actualStatus),
                        style: TextStyle(
                          color: _getStatusColor(actualStatus),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₹${subscription.pricePerUnit} × ${subscription.quantity}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (totalDeliveries > 0 &&
                    actualStatus == SubscriptionStatus.active) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: subscription.deliveredCount / totalDeliveries,
                    backgroundColor: Colors.grey.shade300,
                    color: _getStatusColor(actualStatus),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${subscription.deliveredCount} of $totalDeliveries deliveries completed',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ]
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () =>
                      _showEditSubscriptionDialog(context, subscription),
                  icon: const Icon(Icons.edit, size: 20),
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: () =>
                      _showSubscriptionDetails(context, ref, subscription),
                  icon: const Icon(Icons.info_outline, size: 20),
                  tooltip: 'Details',
                ),
              ],
            ),
            onTap: () => _showSubscriptionDetails(context, ref, subscription),
          ),
        );
      },
    );
  }

  String _getStatusText(SubscriptionStatus status) {
    return status.name[0].toUpperCase() + status.name.substring(1);
  }

  Color _getStatusColor(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return Colors.green;
      case SubscriptionStatus.paused:
        return Colors.orange;
      case SubscriptionStatus.cancelled:
        return Colors.red;
      case SubscriptionStatus.expired:
        return Colors.grey;
    }
  }

  void _showAddSubscriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddEditSubscriptionDialog(),
    );
  }

  void _showEditSubscriptionDialog(
      BuildContext context, Subscription subscription) {
    showDialog(
      context: context,
      builder: (context) => AddEditSubscriptionDialog(subscription: subscription),
    );
  }

  void _showSubscriptionDetails(
      BuildContext context, WidgetRef ref, Subscription subscription) {
    final actualStatus = _getActualStatus(subscription);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.subscriptions,
                        color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Subscription Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Customer', subscription.customerName),
                      _buildDetailRow('Product', subscription.productName),
                      _buildDetailRow('Type', subscription.type.name),
                      _buildDetailRow('Quantity', subscription.quantity.toString()),
                      _buildDetailRow('Price', '₹${subscription.pricePerUnit}'),
                      _buildDetailRow('Start Date',
                          DateFormat('MMM dd, yyyy').format(subscription.startDate)),
                      if (subscription.endDate != null)
                        _buildDetailRow('End Date',
                            DateFormat('MMM dd, yyyy').format(subscription.endDate!)),
                      _buildDetailRow('Status', _getStatusText(actualStatus)),
                      const SizedBox(height: 16),
                      if (actualStatus == SubscriptionStatus.active) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _updateSubscriptionStatus(context, ref,
                                subscription, SubscriptionStatus.paused),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange),
                            icon: const Icon(Icons.pause),
                            label: const Text('Pause'),
                          ),
                        ),
                      ] else if (actualStatus == SubscriptionStatus.paused) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _updateSubscriptionStatus(context, ref,
                                subscription, SubscriptionStatus.active),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Resume'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSubscriptionStatus(
      BuildContext context,
      WidgetRef ref,
      Subscription subscription,
      SubscriptionStatus newStatus) async {
    try {
      // Create a new subscription object, ensuring all fields are carried over.
      final updatedSubscription = Subscription(
        id: subscription.id,
        customerId: subscription.customerId,
        customerName: subscription.customerName,
        customerPhone: subscription.customerPhone,
        customerEmail: subscription.customerEmail,
        productId: subscription.productId,
        productName: subscription.productName,
        type: subscription.type,
        startDate: subscription.startDate,
        endDate: subscription.endDate,
        isActive: newStatus == SubscriptionStatus.active, // Also update isActive
        quantity: subscription.quantity,
        pricePerUnit: subscription.pricePerUnit,
        totalAmount: subscription.totalAmount,
        areaCode: subscription.areaCode,
        address: subscription.address,
        createdAt: subscription.createdAt,
        deliveredCount: subscription.deliveredCount,
        imageUrl: subscription.imageUrl,
        status: newStatus, // Apply the new status
      );

      await ref
          .read(subscriptionNotifierProvider)
          .updateSubscription(updatedSubscription);

      if (context.mounted) {
        Navigator.pop(context); // Close the details dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Subscription ${_getStatusText(newStatus).toLowerCase()} successfully'),
            backgroundColor: _getStatusColor(newStatus),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating subscription: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
