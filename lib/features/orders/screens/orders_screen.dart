import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/area.dart';
import '../../../core/models/order.dart';
import '../../../core/providers/area_provider.dart';
import '../../../core/providers/order_provider.dart';

// A more professional and modern take on the Orders Screen.
// Key Enhancements:
// 1.  **Material 3 Design:** Utilizes `Theme.of(context).colorScheme` and `textTheme` for a modern look.
// 2.  **Improved Layout & Spacing:** Better padding and use of widgets like `SizedBox` create a cleaner, less cluttered UI.
// 3.  **Refined Filter Section:** Filters are now more visually appealing with styled input fields and clearer buttons.
// 4.  **Redesigned Order Card:** The order card (`_OrderListItem`) has been completely redesigned for better readability and visual hierarchy.
// 5.  **Pull-to-Refresh:** `RefreshIndicator` is added for a familiar UX pattern to refresh the order list.
// 6.  **Enhanced Details Dialog:** The order details dialog is cleaner and uses `ListTile` for structured information.
// 7.  **Collapsible Filters:** The filter section is now collapsible to save screen space, toggled by an icon in the header.

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  Area? _selectedArea;
  DateTime? _startDate;
  DateTime? _endDate;
  OrderStatus? _selectedStatus;
  bool _isFilterExpanded = false; // State to control filter visibility

  late OrderFilter _currentFilter;

  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentFilter = OrderFilter();
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  void _updateFilter() {
    setState(() {
      _currentFilter = OrderFilter(
        assignedAreas:
            _selectedArea == null ? null : [_selectedArea!.areaCode],
        startDate: _startDate,
        endDate: _endDate,
        status: _selectedStatus,
      );
      _isFilterExpanded = false; // Collapse filters after applying
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedArea = null;
      _startDate = null;
      _endDate = null;
      _selectedStatus = null;

      _startDateController.clear();
      _endDateController.clear();

      _currentFilter = OrderFilter();
      _isFilterExpanded = false; // Collapse filters after clearing
    });
  }

  Future<void> _refreshOrders() async {
    // Invalidate the provider to force a refresh
    ref.invalidate(ordersProvider(_currentFilter));
    // We can also await the new future if we want to wait for the refresh to complete
    await ref.read(ordersProvider(_currentFilter).future);
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider(_currentFilter));
    final theme = Theme.of(context);

    return Scaffold(
      // Use a background color from the theme for a cohesive look.
      backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.4),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Use a SafeArea to avoid system UI intrusions at the top.
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                // Header with title and filter toggle button
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Manage Orders',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    IconButton(
                      icon: Icon(_isFilterExpanded
                          ? Icons.close
                          : Icons.filter_list_rounded),
                      tooltip: 'Show/Hide Filters',
                      onPressed: () {
                        setState(() {
                          _isFilterExpanded = !_isFilterExpanded;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Animated visibility for the filter section
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isFilterExpanded
                  ? _buildFilters()
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshOrders,
                child: ordersAsync.when(
                  data: (orders) => orders.isEmpty
                      ? const Center(
                          child: Text(
                              'No orders found with the selected filters.'),
                        )
                      : _buildOrdersList(orders),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text('Error: $error'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDER METHODS ---

  Widget _buildFilters() {
    final areasAsync = ref.watch(areasProvider);
    final theme = Theme.of(context);

    // Common InputDecoration for a consistent, modern look.
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: theme.colorScheme.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: theme.dividerColor.withOpacity(0.1))),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Status Filter
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 180),
            child: DropdownButtonFormField<OrderStatus?>(
              decoration: inputDecoration.copyWith(labelText: 'Status'),
              value: _selectedStatus,
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('All Statuses')),
                ...OrderStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.name[0].toUpperCase() +
                        status.name.substring(1)),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() => _selectedStatus = value);
              },
            ),
          ),
          // Area Filter
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 180),
            child: areasAsync.when(
              data: (areas) => DropdownButtonFormField<Area?>(
                decoration: inputDecoration.copyWith(labelText: 'Area'),
                value: _selectedArea,
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('All Areas')),
                  ...areas.map((area) {
                    return DropdownMenuItem(
                        value: area, child: Text(area.name));
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() => _selectedArea = value);
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => const Text('Could not load areas'),
            ),
          ),
          // Start Date Filter
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 180),
            child: TextFormField(
              controller: _startDateController,
              decoration: inputDecoration.copyWith(
                labelText: 'Start Date',
                suffixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() {
                    _startDate = date;
                    _startDateController.text =
                        DateFormat('yyyy-MM-dd').format(date);
                  });
                }
              },
            ),
          ),
          // End Date Filter
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 180),
            child: TextFormField(
              controller: _endDateController,
              decoration: inputDecoration.copyWith(
                labelText: 'End Date',
                suffixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? DateTime.now(),
                  firstDate: _startDate ?? DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() {
                    _endDate = date;
                    _endDateController.text =
                        DateFormat('yyyy-MM-dd').format(date);
                  });
                }
              },
            ),
          ),
          // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.icon(
                onPressed: _updateFilter,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Apply'),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Clear Filters',
                onPressed: _clearFilters,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<Order> orders) {
    // Use ListView.separated for automatically adding spacing between items.
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _OrderListItem(
          order: orders[index],
          onTap: () => _showOrderDetails(orders[index]),
        );
      },
    );
  }

  void _showOrderDetails(Order order) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Order #${order.id.substring(0, 8)}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _buildDetailTile(
                    Icons.person_outline, 'Customer', order.customerName),
                _buildDetailTile(
                    Icons.phone_outlined, 'Phone', order.customerPhone),
                _buildDetailTile(Icons.location_on_outlined, 'Address',
                    order.deliveryAddress.fullAddress),
                _buildDetailTile(
                    Icons.map_outlined, 'Area Code', order.areaCode),
                const Divider(height: 24),
                _buildDetailTile(
                    Icons.calendar_today_outlined,
                    'Order Date',
                    DateFormat('MMM dd, yyyy HH:mm').format(order.orderDate)),
                _buildDetailTile(
                    Icons.delivery_dining_outlined,
                    'Delivery Date',
                    DateFormat('MMM dd, yyyy').format(order.deliveryDate)),
                if (order.deliverySlot != null)
                  _buildDetailTile(
                      Icons.access_time_outlined, 'Slot', order.deliverySlot!),
                const Divider(height: 24),
                Text('Items:', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 4),
                      child: Text(
                          '• ${item.productName} (${item.quantity} ${item.unit}) @ ₹${item.price.toStringAsFixed(2)}'),
                    )),
                const Divider(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title:
                      Text('Total Amount', style: theme.textTheme.bodyLarge),
                  trailing: Text(
                    '₹${order.totalAmount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
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

  // Helper for the details dialog for consistent styling.
  Widget _buildDetailTile(IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style:
            TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

// --- CUSTOM WIDGETS ---

class _OrderListItem extends StatelessWidget {
  const _OrderListItem({
    required this.order,
    required this.onTap,
  });

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Customer Name, ID, and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.customerName,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${order.id.substring(0, 8)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(status: order.status),
                ],
              ),
              const Divider(height: 24),
              // Info Grid: Key details at a glance
              Row(
                children: [
                  _buildInfoColumn(
                    context,
                    icon: Icons.calendar_today_outlined,
                    title: 'Delivery On',
                    subtitle:
                        DateFormat('MMM dd, yyyy').format(order.deliveryDate),
                  ),
                  const SizedBox(width: 16),
                  _buildInfoColumn(
                    context,
                    icon: Icons.currency_rupee,
                    title: 'Total Amount',
                    subtitle: order.totalAmount.toStringAsFixed(2),
                    isAmount: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Address Row
              _buildInfoRow(
                context,
                icon: Icons.location_on_outlined,
                text:
                    '${order.deliveryAddress.pinCode} - ${order.deliveryAddress.fullAddress}',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for a column in the info grid
  Widget _buildInfoColumn(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    bool isAmount = false,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isAmount ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper for a simple info row (like address)
  Widget _buildInfoRow(BuildContext context,
      {required IconData icon, required String text}) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// A dedicated widget for the status chip for better code organization.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = _getStatusProperties(status, context);

    return Chip(
      label: Text(
        label,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  // Helper to get color and text based on status.
  (Color, String) _getStatusProperties(
      OrderStatus status, BuildContext context) {
    final theme = Theme.of(context);
    final String text =
        status.name[0].toUpperCase() + status.name.substring(1);
    final Color color;

    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange.shade600;
        break;
      case OrderStatus.confirmed:
        color = Colors.blue.shade600;
        break;
      case OrderStatus.preparing:
        color = Colors.purple.shade600;
        break;
      case OrderStatus.outForDelivery:
        color = Colors.teal.shade600;
        break;
      case OrderStatus.delivered:
        color = Colors.green.shade600;
        break;
      case OrderStatus.cancelled:
        color = theme.colorScheme.error;
        break;
    }
    return (color, text);
  }
}

