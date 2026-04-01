// subscription_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription.dart';
import '../services/firebase_service.dart';

// This provider is still useful for other parts of the app (like a dashboard)
// that may need a simple, pre-filtered list.
final subscriptionsProvider =
    StreamProvider.family<List<Subscription>, SubscriptionFilter>((ref, filter) {
  return FirebaseService.getSubscriptions(filter: filter);
});

// ADDED: A new provider to fetch all subscriptions for client-side filtering.
// This is more robust for the main subscription screen where the "actual" status
// can depend on the current date, not just the status stored in the database.
final allSubscriptionsProvider = StreamProvider<List<Subscription>>((ref) {
  // Pass an empty filter to fetch all documents.
  return FirebaseService.getSubscriptions(filter: SubscriptionFilter());
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

// This class remains unchanged.
class SubscriptionFilter {
  final SubscriptionStatus? status;

  SubscriptionFilter({this.status});

  // Override == and hashCode for Riverpod caching
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionFilter &&
          runtimeType == other.runtimeType &&
          status == other.status;

  @override
  int get hashCode => status.hashCode;
}
