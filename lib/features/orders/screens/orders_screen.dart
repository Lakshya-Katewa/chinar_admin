import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/order.dart';
import '../../../core/providers/order_provider.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String? _selectedAreaCode;
  DateTime? _startDate;
  DateTime? _endDate;
  
  late OrderFilter _currentFilter;

  @override
  void initState() {
    super.initState();
    _currentFilter = OrderFilter();
  }

  void _updateFilter() {
    setState(() {
      _currentFilter = OrderFilter(
        areaCode: _selectedAreaCode,
        startDate: _startDate,
        endDate: _endDate,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider(_currentFilter));

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Orders',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFilters(),
            const SizedBox(height: 16),
            Expanded(
              child: ordersAsync.when(
                data: (orders) => _buildOrdersList(orders),
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

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Area Code',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., DELHI-NORTH',
                    ),
                    onChanged: (value) {
                      _selectedAreaCode = value.isEmpty ? null : value;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                        });
                      }
                    },
                    controller: TextEditingController(
                      text: _startDate != null 
                          ? DateFormat('yyyy-MM-dd').format(_startDate!)
                          : '',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                      }
                    },
                    controller: TextEditingController(
                      text: _endDate != null 
                          ? DateFormat('yyyy-MM-dd').format(_endDate!)
                          : '',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _updateFilter,
                  child: const Text('Apply Filters'),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedAreaCode = null;
                      _startDate = null;
                      _endDate = null;
                      _currentFilter = OrderFilter();
                    });
                  },
                  child: const Text('Clear Filters'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<Order> orders) {
    if (orders.isEmpty) {
      return const Center(
        child: Text('No orders found'),
      );
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text('${order.customerName} - ${order.productName}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Phone: ${order.customerPhone}'),
                Text('Area: ${order.areaCode}'),
                Text('Quantity: ${order.quantity}'),
                Text('Amount: ₹${order.totalAmount}'),
                Text('Date: ${DateFormat('MMM dd, yyyy').format(order.orderDate)}'),
              ],
            ),
            trailing: _buildStatusChip(order.status),
            onTap: () => _showOrderDetails(order),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        text = 'Delivered';
        break;
      case OrderStatus.canceled:
        color = Colors.red;
        text = 'Canceled';
        break;
    }

    return Chip(
      label: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  void _showOrderDetails(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order #${order.id.substring(0, 8)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${order.customerName}'),
            Text('Phone: ${order.customerPhone}'),
            Text('Product: ${order.productName}'),
            Text('Quantity: ${order.quantity}'),
            Text('Amount: ₹${order.totalAmount}'),
            Text('Area: ${order.areaCode}'),
            Text('Address: ${order.address}'),
            Text('Order Date: ${DateFormat('MMM dd, yyyy HH:mm').format(order.orderDate)}'),
            if (order.deliveryDate != null)
              Text('Delivery Date: ${DateFormat('MMM dd, yyyy HH:mm').format(order.deliveryDate!)}'),
            const SizedBox(height: 16),
            const Text('Update Status:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: order.status == OrderStatus.pending
                        ? () => _updateOrderStatus(order.id, OrderStatus.delivered)
                        : null,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Mark Delivered'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: order.status == OrderStatus.pending
                        ? () => _updateOrderStatus(order.id, OrderStatus.canceled)
                        : null,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Cancel Order'),
                  ),
                ),
              ],
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

  Future<void> _updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await ref.read(orderNotifierProvider).updateOrderStatus(orderId, status);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order status updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating order status: $e')),
        );
      }
    }
  }
}
