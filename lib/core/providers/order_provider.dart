import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../services/firebase_service.dart';

final ordersProvider = StreamProvider.family<List<Order>, OrderFilter>((ref, filter) {
  // Pass the filter object directly
  return FirebaseService.getOrders(filter: filter);
});

final orderNotifierProvider = Provider<OrderNotifier>((ref) {
  return OrderNotifier();
});

class OrderNotifier {
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await FirebaseService.updateOrderStatus(orderId, status);
  }
}

class OrderFilter {
  // CHANGED: From String? areaCode to List<String>? assignedAreas
  final List<String>? assignedAreas;
  final DateTime? startDate;
  final DateTime? endDate;
  final OrderStatus? status;

  OrderFilter({this.assignedAreas, this.startDate, this.endDate, this.status});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderFilter &&
          runtimeType == other.runtimeType &&
          // Note: Deep equality for lists is complex, but for Riverpod this is often sufficient.
          assignedAreas == other.assignedAreas &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          status == other.status;

  @override
  int get hashCode =>
      assignedAreas.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      status.hashCode;
}