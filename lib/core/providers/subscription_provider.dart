import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription.dart';
import '../services/firebase_service.dart';

final subscriptionsProvider = StreamProvider<List<Subscription>>((ref) {
  return FirebaseService.getSubscriptions();
});

final subscriptionNotifierProvider = Provider<SubscriptionNotifier>((ref) {
  return SubscriptionNotifier();
});

class SubscriptionNotifier {
  Future<void> addSubscription(Subscription subscription) async {
    await FirebaseService.addSubscription(subscription);
  }

  Future<void> updateSubscription(Subscription subscription) async {
    await FirebaseService.updateSubscription(subscription);
  }
}
