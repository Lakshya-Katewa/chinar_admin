import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/delivery_person.dart';
import '../models/order.dart';
import '../services/firebase_service.dart';

// Stream provider for delivery persons
final deliveryPersonsProvider = StreamProvider<List<DeliveryPerson>>((ref) {
  return FirebaseService.getDeliveryPersons();
});

// New provider to calculate earnings for a specific delivery person
final earningsProvider =
    StreamProvider.family<double, DeliveryPerson>((ref, person) {
  // Get the stream of delivered orders for the person since their last payment
  final ordersStream = FirebaseService.getDeliveredOrdersForPersonSince(
    personId: person.id,
    lastPaymentDate: person.lastPaymentDate,
  );

  // When the stream emits new orders, calculate the total earnings
  return ordersStream.map((orders) {
    if (orders.isEmpty) {
      return 0.0;
    }
    return person.calculateEarnings(orders);
  });
});

// Notifier for delivery person operations
class DeliveryPersonNotifier extends StateNotifier<AsyncValue<void>> {
  DeliveryPersonNotifier() : super(const AsyncValue.data(null));

  Future<void> addDeliveryPerson(DeliveryPerson person) async {
    state = const AsyncValue.loading();
    try {
      await FirebaseService.addDeliveryPerson(person);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> updateDeliveryPerson(DeliveryPerson person) async {
    state = const AsyncValue.loading();
    try {
      await FirebaseService.updateDeliveryPerson(person);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final deliveryPersonNotifierProvider =
    StateNotifierProvider<DeliveryPersonNotifier, AsyncValue<void>>((ref) {
  return DeliveryPersonNotifier();
});
