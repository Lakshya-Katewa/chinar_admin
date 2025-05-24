import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/delivery_person.dart';
import '../services/firebase_service.dart';

final deliveryPersonsProvider = StreamProvider<List<DeliveryPerson>>((ref) {
  return FirebaseService.getDeliveryPersons();
});

final deliveryPersonNotifierProvider = Provider<DeliveryPersonNotifier>((ref) {
  return DeliveryPersonNotifier();
});

class DeliveryPersonNotifier {
  Future<void> addDeliveryPerson(DeliveryPerson person) async {
    await FirebaseService.addDeliveryPerson(person);
  }

  Future<void> updateDeliveryPerson(DeliveryPerson person) async {
    await FirebaseService.updateDeliveryPerson(person);
  }
}
