import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/area.dart';
import '../../../core/providers/area_provider.dart';
import '../widgets/add_area_dialog.dart';

class AreasScreen extends ConsumerWidget {
  const AreasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areasAsync = ref.watch(areasProvider);

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
                  'Areas',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddAreaDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Area'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: areasAsync.when(
                data: (areas) => _buildAreasList(context, ref, areas),
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

  Widget _buildAreasList(BuildContext context, WidgetRef ref, List<Area> areas) {
    if (areas.isEmpty) {
      return const Center(
        child: Text('No areas found'),
      );
    }

    return ListView.builder(
      itemCount: areas.length,
      itemBuilder: (context, index) {
        final area = areas[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF2E7D32),
              child: Icon(Icons.location_on, color: Colors.white),
            ),
            title: Text(area.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Area Code: ${area.areaCode}'),
                Text('Created: ${DateFormat('MMM dd, yyyy').format(area.createdAt)}'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(context, ref, area),
            ),
          ),
        );
      },
    );
  }

  void _showAddAreaDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddAreaDialog(),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, Area area) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Area'),
        content: Text('Are you sure you want to delete "${area.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(areaNotifierProvider).deleteArea(area.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Area deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting area: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
