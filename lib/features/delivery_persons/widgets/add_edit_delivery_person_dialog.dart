import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/delivery_person.dart';
import '../../../core/providers/delivery_person_provider.dart';

class AddEditDeliveryPersonDialog extends ConsumerStatefulWidget {
  final DeliveryPerson? person;

  const AddEditDeliveryPersonDialog({super.key, this.person});

  @override
  ConsumerState<AddEditDeliveryPersonDialog> createState() => _AddEditDeliveryPersonDialogState();
}

class _AddEditDeliveryPersonDialogState extends ConsumerState<AddEditDeliveryPersonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _assignedAreaController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.person != null) {
      _nameController.text = widget.person!.name;
      _phoneController.text = widget.person!.phone;
      _emailController.text = widget.person!.email;
      _codeController.text = widget.person!.code;
      _assignedAreaController.text = widget.person!.assignedArea;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    _assignedAreaController.dispose();
    super.dispose();
  }

  Future<void> _saveDeliveryPerson() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final person = DeliveryPerson(
        id: widget.person?.id ?? const Uuid().v4(),
        name: _nameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        code: _codeController.text,
        assignedArea: _assignedAreaController.text,
        isActive: widget.person?.isActive ?? true,
        createdAt: widget.person?.createdAt ?? DateTime.now(),
      );

      if (widget.person == null) {
        await ref.read(deliveryPersonNotifierProvider).addDeliveryPerson(person);
      } else {
        await ref.read(deliveryPersonNotifierProvider).updateDeliveryPerson(person);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.person == null 
                  ? 'Delivery person added successfully' 
                  : 'Delivery person updated successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving delivery person: $e')),
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
      title: Text(widget.person == null ? 'Add Delivery Person' : 'Edit Delivery Person'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Delivery Person Code',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., DP001',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter delivery person code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _assignedAreaController,
                  decoration: const InputDecoration(
                    labelText: 'Assigned Area',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., DELHI-NORTH',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter assigned area';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveDeliveryPerson,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.person == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}
