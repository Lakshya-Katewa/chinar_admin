import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/subscription.dart';
import '../../../core/providers/subscription_provider.dart';

class AddEditSubscriptionDialog extends ConsumerStatefulWidget {
  final Subscription? subscription;

  const AddEditSubscriptionDialog({super.key, this.subscription});

  @override
  ConsumerState<AddEditSubscriptionDialog> createState() => _AddEditSubscriptionDialogState();
}

class _AddEditSubscriptionDialogState extends ConsumerState<AddEditSubscriptionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _productNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  
  SubscriptionType _selectedType = SubscriptionType.monthly;
  SubscriptionStatus _selectedStatus = SubscriptionStatus.active;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.subscription != null) {
      _customerNameController.text = widget.subscription!.customerName;
      _productNameController.text = widget.subscription!.productName;
      _quantityController.text = widget.subscription!.quantity.toString();
      _priceController.text = widget.subscription!.pricePerUnit.toString();
      _selectedType = widget.subscription!.type;
      _selectedStatus = widget.subscription!.status ?? SubscriptionStatus.active;
      _startDate = widget.subscription!.startDate;
      _endDate = widget.subscription!.endDate;
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _productNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveSubscription() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final quantity = double.parse(_quantityController.text);
      final pricePerUnit = double.parse(_priceController.text);

      final subscription = Subscription(
        id: widget.subscription?.id ?? const Uuid().v4(),
        customerName: _customerNameController.text.trim(),
        customerPhone: widget.subscription?.customerPhone ?? '',
        customerEmail: widget.subscription?.customerEmail ?? '',
        productId: widget.subscription?.productId ?? const Uuid().v4(),
        productName: _productNameController.text.trim(),
        type: _selectedType,
        startDate: _startDate,
        endDate: _endDate,
        status: _selectedStatus,
        quantity: quantity,
        pricePerUnit: pricePerUnit,
        totalAmount: quantity * pricePerUnit,
        areaCode: widget.subscription?.areaCode ?? '',
        address: widget.subscription?.address ?? '', customerId: '', isActive: true, createdAt: DateTime.now()
      );

      if (widget.subscription == null) {
        await ref.read(subscriptionNotifierProvider).addSubscription(subscription);
      } else {
        await ref.read(subscriptionNotifierProvider).updateSubscription(subscription);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.subscription == null ? 'Subscription added successfully' : 'Subscription updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving subscription: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 450,
        constraints: const BoxConstraints(maxHeight: 550),
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
                  Icon(widget.subscription == null ? Icons.add : Icons.edit, 
                       color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    widget.subscription == null ? 'Add Subscription' : 'Edit Subscription',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const Spacer(),
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
                          controller: _customerNameController,
                          decoration: const InputDecoration(
                            labelText: 'Customer Name *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) => value?.isEmpty == true ? 'Please enter customer name' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _productNameController,
                          decoration: const InputDecoration(
                            labelText: 'Product Name *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.shopping_bag),
                          ),
                          validator: (value) => value?.isEmpty == true ? 'Please enter product name' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _quantityController,
                                decoration: const InputDecoration(
                                  labelText: 'Quantity *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.numbers),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value?.isEmpty == true) return 'Please enter quantity';
                                  if (double.tryParse(value!) == null) return 'Invalid quantity';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _priceController,
                                decoration: const InputDecoration(
                                  labelText: 'Price (₹) *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.currency_rupee),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value?.isEmpty == true) return 'Please enter price';
                                  if (double.tryParse(value!) == null) return 'Invalid price';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<SubscriptionType>(
                          value: _selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Subscription Type *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.repeat),
                          ),
                          items: SubscriptionType.values.map((type) {
                            String text = switch (type) {
                              SubscriptionType.monthly => 'Monthly',
                              SubscriptionType.weekly => 'Weekly',
                              SubscriptionType.alternateDay => 'Alternate Day',
                            };
                            return DropdownMenuItem(value: type, child: Text(text));
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedType = value!),
                        ),
                        if (widget.subscription != null) ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<SubscriptionStatus>(
                            value: _selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'Status *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.info),
                            ),
                            items: SubscriptionStatus.values.map((status) {
                              String text = switch (status) {
                                SubscriptionStatus.active => 'Active',
                                SubscriptionStatus.paused => 'Paused',
                                SubscriptionStatus.cancelled => 'Cancelled',
                                SubscriptionStatus.expired => 'Expired',
                              };
                              return DropdownMenuItem(value: status, child: Text(text));
                            }).toList(),
                            onChanged: (value) => setState(() => _selectedStatus = value!),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Start Date *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                readOnly: true,
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _startDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (date != null) setState(() => _startDate = date);
                                },
                                controller: TextEditingController(
                                  text: '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'End Date',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.event),
                                ),
                                readOnly: true,
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
                                    firstDate: _startDate,
                                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                                  );
                                  if (date != null) setState(() => _endDate = date);
                                },
                                controller: TextEditingController(
                                  text: _endDate != null ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}' : '',
                                ),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveSubscription,
                    child: _isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(widget.subscription == null ? 'Add Subscription' : 'Update Subscription'),
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
