import 'dart:async'; // Added for FutureOr
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/delivery_person.dart';
import '../models/order.dart';
import '../services/firebase_service.dart';

// Stream provider for delivery persons
final deliveryPersonsProvider = StreamProvider<List<DeliveryPerson>>((ref) {
  return FirebaseService.getDeliveryPersons();
});

// Provider to calculate earnings for a specific delivery person
// UPDATED: Now uses a Record to force cache invalidation when lastPaymentDate changes
final earningsProvider = StreamProvider.family<
  double,
  ({DeliveryPerson person, DateTime? lastPaymentDate})
>((ref, arg) {
  final ordersStream = FirebaseService.getDeliveredOrdersForPersonSince(
    personId: arg.person.id,
    lastPaymentDate: arg.lastPaymentDate,
  );

  return ordersStream.map((orders) {
    if (orders.isEmpty) {
      return 0.0;
    }
    return arg.person.calculateEarnings(orders);
  });
});

// Upgraded to AsyncNotifier (Modern Riverpod 2.x+)
class DeliveryPersonNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {} // Required initialization

  Future<void> addDeliveryPerson(DeliveryPerson person) async {
    state = const AsyncLoading();
    try {
      await FirebaseService.addDeliveryPerson(person);
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }

  Future<void> updateDeliveryPerson(DeliveryPerson person) async {
    state = const AsyncLoading();
    try {
      await FirebaseService.updateDeliveryPerson(person);
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }
}

// Upgraded to AsyncNotifierProvider
final deliveryPersonNotifierProvider =
    AsyncNotifierProvider<DeliveryPersonNotifier, void>(() {
      return DeliveryPersonNotifier();
    });
