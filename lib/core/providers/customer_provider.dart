import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import '../services/firebase_service.dart';

final customersProvider = StreamProvider<List<Customer>>((ref) {
  return FirebaseService.getCustomers();
});
