import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/customer.dart';
import '../../../core/providers/customer_provider.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customers',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: customersAsync.when(
                data: (customers) => _buildCustomersList(customers),
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

  Widget _buildCustomersList(List<Customer> customers) {
    if (customers.isEmpty) {
      return const Center(
        child: Text('No customers found'),
      );
    }

    // Calculate total wallet balance
    final totalWalletBalance = customers.fold<double>(
      0.0,
      (sum, customer) => sum + customer.walletBalance,
    );

    return Column(
      children: [
        Card(
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Total Wallet Balance: ₹${totalWalletBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF2E7D32),
                    child: Text(
                      customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(customer.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Phone: ${customer.phone}'),
                      Text('Email: ${customer.email}'),
                      Text('Area: ${customer.areaCode}'),
                      Text('Joined: ${DateFormat('MMM dd, yyyy').format(customer.createdAt)}'),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${customer.walletBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: customer.walletBalance > 0 ? Colors.green : Colors.grey,
                        ),
                      ),
                      const Text(
                        'Wallet Balance',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  onTap: () => _showCustomerDetails(context, customer),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCustomerDetails(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Customer Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${customer.name}'),
            Text('Phone: ${customer.phone}'),
            Text('Email: ${customer.email}'),
            Text('Area Code: ${customer.areaCode}'),
            Text('Address: ${customer.address}'),
            Text('Wallet Balance: ₹${customer.walletBalance.toStringAsFixed(2)}'),
            Text('Member Since: ${DateFormat('MMM dd, yyyy').format(customer.createdAt)}'),
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
}
