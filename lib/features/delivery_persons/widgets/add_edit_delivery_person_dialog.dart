import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/area.dart';
import '../../../core/models/delivery_person.dart';
import '../../../core/providers/area_provider.dart';
import '../../../core/providers/delivery_person_provider.dart';

class AddEditDeliveryPersonDialog extends ConsumerStatefulWidget {
  final DeliveryPerson? person;

  const AddEditDeliveryPersonDialog({super.key, this.person});

  @override
  ConsumerState<AddEditDeliveryPersonDialog> createState() =>
      _AddEditDeliveryPersonDialogState();
}

class _AddEditDeliveryPersonDialogState
    extends ConsumerState<AddEditDeliveryPersonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ratePerUnitController = TextEditingController();
  final _bonusPerUnitController = TextEditingController();

  List<Area> _selectedAreas = [];

  bool _isActive = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.person != null) {
      _nameController.text = widget.person!.name;
      _phoneController.text = widget.person!.phone;
      _emailController.text = widget.person!.email;
      _passwordController.text = widget.person!.password;
      _isActive = widget.person!.isActive;
      _ratePerUnitController.text = widget.person!.ratePerUnitQuantity
          .toString();
      _bonusPerUnitController.text = widget.person!.bonusPerUnitQuantity
          .toString();
    } else {
      _ratePerUnitController.text = '2';
      _bonusPerUnitController.text = '0';
    }
  }

  void _initializeSelectedAreas(List<Area> allAreas) {
    if (widget.person != null && !_initialized) {
      _selectedAreas = allAreas
          .where((area) => widget.person!.assignedAreas.contains(area.areaCode))
          .toList();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ratePerUnitController.dispose();
    _bonusPerUnitController.dispose();
    super.dispose();
  }

  Future<void> _saveDeliveryPerson() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one assigned area.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final person = DeliveryPerson(
        id: widget.person?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        assignedAreas: _selectedAreas.map((area) => area.areaCode).toList(),
        isActive: _isActive,
        createdAt: widget.person?.createdAt ?? now,
        updatedAt: widget.person != null ? now : null,
        ratePerUnitQuantity: double.parse(_ratePerUnitController.text.trim()),
        bonusPerUnitQuantity: double.parse(_bonusPerUnitController.text.trim()),
      );

      final notifier = ref.read(deliveryPersonNotifierProvider.notifier);

      if (widget.person == null) {
        await notifier.addDeliveryPerson(person);
      } else {
        await notifier.updateDeliveryPerson(person);
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
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving delivery person: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAreaSelectionDialog(List<Area> allAreas) async {
    final currentlySelected = List<Area>.from(_selectedAreas);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Assigned Areas'),
              content: SizedBox(
                width: 300,
                child: allAreas.isEmpty
                    ? const Center(
                        child: Text('No areas found. Please add areas first.'),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: allAreas.length,
                        itemBuilder: (context, index) {
                          final area = allAreas[index];
                          final isSelected = currentlySelected.any(
                            (a) => a.id == area.id,
                          );
                          return CheckboxListTile(
                            title: Text(area.name),
                            subtitle: Text(area.areaCode),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                if (value == true) {
                                  currentlySelected.add(area);
                                } else {
                                  currentlySelected.removeWhere(
                                    (a) => a.id == area.id,
                                  );
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedAreas = currentlySelected;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final areasAsync = ref.watch(areasProvider);

    if (areasAsync is AsyncData<List<Area>>) {
      _initializeSelectedAreas(areasAsync.value!);
    }

    return Dialog(
      child: Container(
        width: double.infinity, // FIX: Changed from 450 to make it responsive
        constraints: const BoxConstraints(maxHeight: 700),
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
                  Icon(
                    widget.person == null ? Icons.person_add : Icons.person,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  // FIX: Wrapped the title in Expanded to prevent overflow
                  Expanded(
                    child: Text(
                      widget.person == null
                          ? 'Add Delivery Person'
                          : 'Edit Delivery Person',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) => value?.trim().isEmpty == true
                              ? 'Please enter full name'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value?.trim().isEmpty == true)
                              return 'Please enter phone number';
                            if (value!.trim().length < 10)
                              return 'Please enter a valid phone number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email Address *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value?.trim().isEmpty == true)
                              return 'Please enter email address';
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value!.trim())) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Login Password *',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            helperText:
                                'Password for delivery person app login',
                          ),
                          validator: (value) {
                            if (value?.trim().isEmpty == true)
                              return 'Please enter password';
                            if (value!.trim().length < 6)
                              return 'Password must be at least 6 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assigned Areas *',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 8),
                              if (_selectedAreas.isEmpty)
                                const Text('No areas selected.')
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _selectedAreas
                                      .map(
                                        (area) => Chip(label: Text(area.name)),
                                      )
                                      .toList(),
                                ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: areasAsync.when(
                                  data: (areas) => ElevatedButton.icon(
                                    onPressed: () =>
                                        _showAreaSelectionDialog(areas),
                                    icon: const Icon(Icons.map),
                                    label: const Text('Select Areas'),
                                  ),
                                  loading: () => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  error: (e, s) =>
                                      const Text('Could not load areas'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _ratePerUnitController,
                          decoration: const InputDecoration(
                            labelText: 'Rate Per Unit (₹) *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.currency_rupee),
                            helperText:
                                'Amount paid per unit quantity (e.g., per Liter/Kg)',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.trim().isEmpty == true)
                              return 'Please enter payment amount';
                            final amount = double.tryParse(value!.trim());
                            if (amount == null || amount < 0)
                              return 'Please enter a valid amount';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _bonusPerUnitController,
                          decoration: const InputDecoration(
                            labelText: 'Bonus Per Unit (₹)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.star),
                            helperText: 'Optional bonus per unit quantity',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.trim().isNotEmpty == true) {
                              final amount = double.tryParse(value!.trim());
                              if (amount == null || amount < 0)
                                return 'Please enter a valid bonus amount';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Switch(
                              value: _isActive,
                              onChanged: (value) =>
                                  setState(() => _isActive = value),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _isActive ? Colors.green : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              // FIX: Wrapped bottom buttons in Expanded to prevent overflow and adjust spacing
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancel', maxLines: 1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveDeliveryPerson,
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              widget.person == null
                                  ? 'Add Person'
                                  : 'Update Person',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
