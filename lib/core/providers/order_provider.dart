import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../services/firebase_service.dart';

final ordersProvider = StreamProvider.family<List<Order>, OrderFilter>((ref, filter) {
  return FirebaseService.getOrders(
    areaCode: filter.areaCode,
    startDate: filter.startDate,
    endDate: filter.endDate,
  );
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
  final String? areaCode;
  final DateTime? startDate;
  final DateTime? endDate;

  OrderFilter({this.areaCode, this.startDate, this.endDate});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderFilter &&
          runtimeType == other.runtimeType &&
          areaCode == other.areaCode &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => areaCode.hashCode ^ startDate.hashCode ^ endDate.hashCode;
}
