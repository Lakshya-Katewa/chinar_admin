import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/delivery_person.dart';
import '../../../core/models/payment_record.dart';
import '../../../core/providers/delivery_person_provider.dart';
import '../widgets/add_edit_delivery_person_dialog.dart';

class DeliveryPersonsScreen extends ConsumerWidget {
  const DeliveryPersonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveryPersonsAsync = ref.watch(deliveryPersonsProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Delivery Personnel',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (MediaQuery.of(context).size.width < 400) {
                      return IconButton.filled(
                        onPressed: () => _showAddDeliveryPersonDialog(context),
                        icon: const Icon(Icons.add),
                        tooltip: 'Add Delivery Person',
                      );
                    } else if (MediaQuery.of(context).size.width < 600) {
                      return ElevatedButton.icon(
                        onPressed: () => _showAddDeliveryPersonDialog(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Person'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      );
                    } else {
                      return ElevatedButton.icon(
                        onPressed: () => _showAddDeliveryPersonDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Delivery Person'),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: deliveryPersonsAsync.when(
                data: (deliveryPersons) =>
                    _buildDeliveryPersonsList(context, ref, deliveryPersons),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading delivery personnel',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.refresh(deliveryPersonsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryPersonsList(BuildContext context, WidgetRef ref,
      List<DeliveryPerson> deliveryPersons) {
    if (deliveryPersons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delivery_dining,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No delivery personnel found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first delivery person to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return _buildGridView(context, ref, deliveryPersons);
        } else {
          return _buildListView(context, ref, deliveryPersons);
        }
      },
    );
  }

  Widget _buildGridView(BuildContext context, WidgetRef ref,
      List<DeliveryPerson> deliveryPersons) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: deliveryPersons.length,
      itemBuilder: (context, index) {
        final person = deliveryPersons[index];
        return _buildDeliveryPersonCard(context, ref, person);
      },
    );
  }

  Widget _buildListView(BuildContext context, WidgetRef ref,
      List<DeliveryPerson> deliveryPersons) {
    return ListView.builder(
      itemCount: deliveryPersons.length,
      itemBuilder: (context, index) {
        final person = deliveryPersons[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildDeliveryPersonCard(context, ref, person),
        );
      },
    );
  }

  Widget _buildDeliveryPersonCard(
      BuildContext context, WidgetRef ref, DeliveryPerson person) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showDeliveryPersonDetails(context, ref, person),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: person.isActive
                        ? Colors.green.shade100
                        : Colors.grey.shade100,
                    child: Icon(
                      Icons.person,
                      size: 16,
                      color: person.isActive
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: person.isActive ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      person.isActive ? 'Active' : 'Inactive',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _buildInfoRow(Icons.phone, person.phone),
              const SizedBox(height: 2),
              _buildInfoRow(Icons.email, person.email),
              const SizedBox(height: 2),
              _buildInfoRow(Icons.location_on, person.assignedAreas.join(', ')),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    flex: 2,
                    child: Text(
                      'Added: ${DateFormat('MMM dd, yyyy').format(person.createdAt)}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Flexible(
                    flex: 1,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () =>
                              _showEditDeliveryPersonDialog(context, person),
                          icon: const Icon(Icons.edit, size: 14),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 20, minHeight: 20),
                        ),
                        IconButton(
                          onPressed: () =>
                              _togglePersonStatus(context, ref, person),
                          icon: Icon(
                            person.isActive ? Icons.pause : Icons.play_arrow,
                            size: 14,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 20, minHeight: 20),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 11,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showAddDeliveryPersonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddEditDeliveryPersonDialog(),
    );
  }

  void _showEditDeliveryPersonDialog(
      BuildContext context, DeliveryPerson person) {
    showDialog(
      context: context,
      builder: (context) => AddEditDeliveryPersonDialog(person: person),
    );
  }

  void _showDeliveryPersonDetails(
      BuildContext context, WidgetRef ref, DeliveryPerson person) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 400,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        person.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                        overflow: TextOverflow.ellipsis,
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
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Consumer(
                    builder: (context, ref, child) {
                      final earningsAsync = ref.watch(earningsProvider(person));
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow('Phone', person.phone),
                            _buildDetailRow('Email', person.email),
                            _buildDetailRow(
                                'Assigned Area', person.assignedAreas.join(', ')),
                            _buildDetailRow(
                                'Status', person.isActive ? 'Active' : 'Inactive'),
                            _buildDetailRow('Added',
                                DateFormat('MMM dd, yyyy').format(person.createdAt)),
                            if (person.updatedAt != null)
                              _buildDetailRow(
                                  'Updated',
                                  DateFormat('MMM dd, yyyy')
                                      .format(person.updatedAt!)),
                            const Divider(height: 24),
                            earningsAsync.when(
                              data: (earnings) => Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('Current Unpaid Earnings',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall),
                                  Text(
                                    '₹${earnings.toStringAsFixed(2)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: earnings > 0
                                        ? () => _handlePayment(context, ref,
                                            person, earnings)
                                        : null,
                                    icon: const Icon(Icons.payment),
                                    label: const Text('Mark as Paid'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              loading: () => const Center(
                                  child: CircularProgressIndicator()),
                              error: (e, s) =>
                                  Text('Error calculating earnings: $e'),
                            ),
                            const Divider(height: 24),
                            Text('Payment History',
                                style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            if (person.paymentHistory == null ||
                                person.paymentHistory.isEmpty)
                              const Center(
                                child: Text(
                                  'No payments recorded.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: person.paymentHistory.length,
                                separatorBuilder: (_, __) => const Divider(),
                                itemBuilder: (context, index) {
                                  final payment = person.paymentHistory.reversed
                                      .toList()[index];
                                  return ListTile(
                                    title: Text(
                                        '₹${payment.amount.toStringAsFixed(2)}'),
                                    subtitle: Text(
                                        'Paid on ${DateFormat.yMMMd().add_jm().format(payment.paymentDate)}'),
                                    dense: true,
                                  );
                                },
                              ),
                          ],
                        ),
                      );
                    },
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
      padding: const EdgeInsets.only(bottom: 10),
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
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePayment(BuildContext context, WidgetRef ref,
      DeliveryPerson person, double earnings) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text(
            'You are about to record a payment of ₹${earnings.toStringAsFixed(2)} to ${person.name}. This action will reset their current earnings and cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm & Pay'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final now = DateTime.now();
      final newPayment = PaymentRecord(
        id: const Uuid().v4(),
        amount: earnings,
        paymentDate: now,
      );

      final updatedPerson = person.copyWith(
        lastPaymentDate: now,
        paymentHistory: [...(person.paymentHistory ?? []), newPayment],
        updatedAt: now,
      );

      try {
        await ref
            .read(deliveryPersonNotifierProvider.notifier)
            .updateDeliveryPerson(updatedPerson);
        if (context.mounted) {
          Navigator.pop(context); // Close the details dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment recorded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to record payment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _togglePersonStatus(
      BuildContext context, WidgetRef ref, DeliveryPerson person) async {
    try {
      final updatedPerson = person.copyWith(
        isActive: !person.isActive,
        updatedAt: DateTime.now(),
      );

      await ref
          .read(deliveryPersonNotifierProvider.notifier)
          .updateDeliveryPerson(updatedPerson);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Delivery person ${updatedPerson.isActive ? 'activated' : 'deactivated'} successfully',
            ),
            backgroundColor:
                updatedPerson.isActive ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating delivery person: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

