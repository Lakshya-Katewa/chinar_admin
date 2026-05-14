import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ADDED: For fetching transactions directly
import '../../../core/models/customer.dart';
import '../../../core/providers/customer_provider.dart';
import '../../../core/services/firebase_service.dart';

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
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: customersAsync.when(
                data: (customers) => _buildCustomersList(context, customers),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomersList(BuildContext context, List<Customer> customers) {
    if (customers.isEmpty) {
      return const Center(child: Text('No customers found'));
    }

    // Calculate total wallet balance
    final totalWalletBalance = customers.fold<double>(
      0.0,
      (sum, customer) => sum + customer.walletBalance,
    );

    // Filter active customers
    final activeCustomers = customers.where((c) => c.isActive).length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${totalWalletBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Text('Total Wallet Balance'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.people, color: Colors.blue),
                      const SizedBox(height: 8),
                      Text(
                        '$activeCustomers',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Text('Active Customers'),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
                    backgroundColor:
                        customer.isActive
                            ? const Color(0xFF2E7D32)
                            : Colors.grey,
                    child: Text(
                      customer.name.isNotEmpty
                          ? customer.name[0].toUpperCase()
                          : 'C',
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
                      Text('Referrals: ${customer.successfulReferrals}'),
                      Text(
                        'Joined: ${DateFormat('MMM dd, yyyy').format(customer.createdAt)}',
                      ),
                      if (!customer.isActive)
                        const Text(
                          'BLOCKED',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  // ADDED: Modified trailing to include both Balance and History button
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${customer.walletBalance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  customer.walletBalance > 0
                                      ? Colors.green
                                      : Colors.grey,
                            ),
                          ),
                          const Text(
                            'Wallet Balance',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.history, color: Colors.blue),
                          tooltip: 'View Transaction History',
                          onPressed:
                              () => _showTransactionHistory(context, customer),
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _showCustomerEditDialog(context, customer),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ADDED: New method to show the transaction history dialog
  void _showTransactionHistory(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${customer.name}\'s Transactions'),
          content: SizedBox(
            width: double.maxFinite,
            height:
                MediaQuery.of(context).size.height *
                0.6, // 60% of screen height
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('transactions')
                      .where('customerId', isEqualTo: customer.id)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No transactions found for this customer.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final transactions = snapshot.data!.docs;
                return ListView.separated(
                  itemCount: transactions.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final data =
                        transactions[index].data() as Map<String, dynamic>;
                    final amount = (data['amount'] ?? 0.0).toDouble();
                    final type =
                        data['type'] ?? 'unknown'; // 'credit' or 'debit'
                    final desc = data['description'] ?? 'No description';
                    final date =
                        (data['createdAt'] as Timestamp?)?.toDate() ??
                        DateTime.now();

                    final isCredit = type == 'credit';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor:
                            isCredit
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                        child: Icon(
                          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isCredit ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(desc, style: const TextStyle(fontSize: 14)),
                      subtitle: Text(
                        DateFormat('MMM dd, yyyy • hh:mm a').format(date),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        '${isCredit ? '+' : '-'}₹${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isCredit ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showCustomerEditDialog(BuildContext context, Customer customer) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: customer.name);
    final phoneController = TextEditingController(text: customer.phone);
    final emailController = TextEditingController(text: customer.email);
    final areaCodeController = TextEditingController(text: customer.areaCode);
    final walletBalanceController = TextEditingController(
      text: customer.walletBalance.toString(),
    );

    bool isActive = customer.isActive; // Initial state

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          // To manage the state of the switch
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Customer'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator:
                            (value) =>
                                value!.isEmpty ? 'Please enter a name' : null,
                      ),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: 'Phone'),
                        validator:
                            (value) =>
                                value!.isEmpty
                                    ? 'Please enter a phone number'
                                    : null,
                      ),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator:
                            (value) =>
                                value!.isEmpty ? 'Please enter an email' : null,
                      ),
                      TextFormField(
                        controller: areaCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Area Code',
                        ),
                        validator:
                            (value) =>
                                value!.isEmpty
                                    ? 'Please enter an area code'
                                    : null,
                      ),
                      TextFormField(
                        controller: walletBalanceController,
                        decoration: const InputDecoration(
                          labelText: 'Wallet Balance',
                        ),
                        keyboardType: TextInputType.number,
                        validator:
                            (value) =>
                                value!.isEmpty
                                    ? 'Please enter a balance'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Active Status'),
                        subtitle: Text(
                          isActive
                              ? 'Customer is Active'
                              : 'Customer is Blocked',
                        ),
                        value: isActive,
                        onChanged: (bool value) {
                          setState(() {
                            // This setState is from StatefulBuilder
                            isActive = value;
                          });
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
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final updatedCustomer = customer.copyWith(
                        name: nameController.text,
                        phone: phoneController.text,
                        email: emailController.text,
                        areaCode: areaCodeController.text,
                        walletBalance:
                            double.tryParse(walletBalanceController.text) ??
                            customer.walletBalance,
                        isActive: isActive,
                        updatedAt: DateTime.now(), // Update the timestamp
                      );

                      try {
                        await FirebaseService.updateCustomer(updatedCustomer);
                        Navigator.pop(context); // Close dialog on success
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Customer updated successfully!'),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update customer: $e'),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
