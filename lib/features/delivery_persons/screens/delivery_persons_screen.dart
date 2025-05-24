import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/delivery_person.dart';
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
                const Text(
                  'Delivery Persons',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddDeliveryPersonDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Delivery Person'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: deliveryPersonsAsync.when(
                data: (deliveryPersons) => _buildDeliveryPersonsList(context, ref, deliveryPersons),
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

  Widget _buildDeliveryPersonsList(BuildContext context, WidgetRef ref, List<DeliveryPerson> deliveryPersons) {
    if (deliveryPersons.isEmpty) {
      return const Center(
        child: Text('No delivery persons found'),
      );
    }

    return ListView.builder(
      itemCount: deliveryPersons.length,
      itemBuilder: (context, index) {
        final person = deliveryPersons[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: person.isActive ? Colors.green : Colors.grey,
              child: Text(
                person.name.isNotEmpty ? person.name[0].toUpperCase() : 'D',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(person.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Phone: ${person.phone}'),
                Text('Code: ${person.code}'),
                Text('Area: ${person.assignedArea}'),
                Text('Joined: ${DateFormat('MMM dd, yyyy').format(person.createdAt)}'),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: const Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_status',
                  child: Row(
                    children: [
                      Icon(person.isActive ? Icons.block : Icons.check_circle),
                      const SizedBox(width: 8),
                      Text(person.isActive ? 'Deactivate' : 'Activate'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditDeliveryPersonDialog(context, person);
                } else if (value == 'toggle_status') {
                  _togglePersonStatus(context, ref, person);
                }
              },
            ),
          ),
        );
      },
    );
  }

  void _showAddDeliveryPersonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddEditDeliveryPersonDialog(),
    );
  }

  void _showEditDeliveryPersonDialog(BuildContext context, DeliveryPerson person) {
    showDialog(
      context: context,
      builder: (context) => AddEditDeliveryPersonDialog(person: person),
    );
  }

  Future<void> _togglePersonStatus(BuildContext context, WidgetRef ref, DeliveryPerson person) async {
    try {
      final updatedPerson = DeliveryPerson(
        id: person.id,
        name: person.name,
        phone: person.phone,
        email: person.email,
        code: person.code,
        assignedArea: person.assignedArea,
        isActive: !person.isActive,
        createdAt: person.createdAt,
      );

      await ref.read(deliveryPersonNotifierProvider).updateDeliveryPerson(updatedPerson);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              person.isActive 
                  ? 'Delivery person deactivated successfully'
                  : 'Delivery person activated successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating delivery person: $e')),
        );
      }
    }
  }
}
