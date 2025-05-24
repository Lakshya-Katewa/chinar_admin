import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/area.dart';
import '../../../core/providers/area_provider.dart';

class AddAreaDialog extends ConsumerStatefulWidget {
  const AddAreaDialog({super.key});

  @override
  ConsumerState<AddAreaDialog> createState() => _AddAreaDialogState();
}

class _AddAreaDialogState extends ConsumerState<AddAreaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _areaCodeController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _areaCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveArea() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final area = Area(
        id: const Uuid().v4(),
        name: _nameController.text,
        areaCode: _areaCodeController.text.toUpperCase(),
        createdAt: DateTime.now(),
      );

      await ref.read(areaNotifierProvider).addArea(area);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Area added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding area: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Area'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Area Name',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Delhi North',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter area name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _areaCodeController,
                decoration: const InputDecoration(
                  labelText: 'Area Code',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., DELHI-NORTH',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter area code';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveArea,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Area'),
        ),
      ],
    );
  }
}
