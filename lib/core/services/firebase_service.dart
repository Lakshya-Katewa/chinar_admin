import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as storage;
import '../models/area.dart';
import '../models/banner.dart';
import '../models/customer.dart';
import '../models/delivery_person.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/subscription.dart';
import '../providers/order_provider.dart';
import '../providers/subscription_provider.dart';

class FirebaseService {
  static final firestore.FirebaseFirestore _firestore =
      firestore.FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final storage.FirebaseStorage _storage =
      storage.FirebaseStorage.instance;

  // --- NEW: DAILY SETTLEMENT FOR STALE ORDERS (REQ 2) ---
  static Future<void> runDailySettlement() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    try {
      final staleOrdersSnapshot =
          await _firestore
              .collection('orders')
              .where(
                'deliveryDate',
                isLessThan: firestore.Timestamp.fromDate(todayStart),
              )
              .get();

      if (staleOrdersSnapshot.docs.isEmpty) return;

      final batch = _firestore.batch();

      for (var doc in staleOrdersSnapshot.docs) {
        final order = Order.fromFirestore(doc);

        if (order.status == OrderStatus.pending ||
            order.status == OrderStatus.confirmed ||
            order.status == OrderStatus.preparing ||
            order.status == OrderStatus.outForDelivery) {
          batch.update(doc.reference, {
            'status': OrderStatus.cancelled.name,
            'updatedAt': firestore.Timestamp.now(),
            'notes': 'Auto-cancelled: Not delivered on scheduled date.',
          });

          if (order.paymentMethod == 'wallet' ||
              order.paymentMethod == 'razorpay') {
            final customerRef = _firestore
                .collection('customers')
                .doc(order.customerId);
            batch.update(customerRef, {
              'walletBalance': firestore.FieldValue.increment(
                order.totalAmount,
              ),
              'updatedAt': firestore.Timestamp.now(),
            });

            final transactionRef = _firestore.collection('transactions').doc();
            batch.set(transactionRef, {
              'customerId': order.customerId,
              'amount': order.totalAmount,
              'type': 'credit',
              'description':
                  'Auto-Refund for un-delivered order #${order.id.substring(0, 8)}',
              'orderId': order.id,
              'paymentMethod': 'refund',
              'createdAt': firestore.Timestamp.now(),
            });
          }
        }
      }

      await batch.commit();
      print("Daily settlement completed successfully.");
    } catch (e) {
      print("Error running daily settlement: $e");
      throw Exception('Failed to run daily settlement: $e');
    }
  }

  static Stream<List<DeliveryPerson>> getDeliveryPersons() {
    return _firestore
        .collection('delivery_boys')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => DeliveryPerson.fromFirestore(doc))
                  .toList(),
        );
  }

  static Future<void> addDeliveryPerson(DeliveryPerson person) async {
    await _firestore
        .collection('delivery_boys')
        .doc(person.id)
        .set(person.toFirestore());
  }

  static Future<void> updateDeliveryPerson(DeliveryPerson person) async {
    await _firestore
        .collection('delivery_boys')
        .doc(person.id)
        .update(person.toFirestore());
  }

  static Future<String> uploadProductImage({
    required File file,
    required String productId,
  }) async {
    try {
      final ref = _storage.ref('product_images/$productId');
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  static Future<String> uploadBannerImage({
    required File file,
    required String bannerId,
  }) async {
    try {
      final ref = _storage.ref('banner_images/$bannerId');
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Error uploading banner image: $e');
    }
  }

  static Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static User? get currentUser => _auth.currentUser;

  static Stream<List<Banner>> getBanners() {
    return _firestore
        .collection('banners')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Banner.fromFirestore(doc)).toList(),
        );
  }

  static Future<void> addBanner(Banner banner) async {
    // FIX: Using .set() ensures the Firestore ID matches the Image ID
    await _firestore
        .collection('banners')
        .doc(banner.id)
        .set(banner.toFirestore());
  }

  static Future<void> updateBanner(Banner banner) async {
    await _firestore
        .collection('banners')
        .doc(banner.id)
        .update(banner.toFirestore());
  }

  static Future<void> deleteBanner(String bannerId) async {
    try {
      final ref = _storage.ref('banner_images/$bannerId');
      await ref.delete();
    } catch (e) {
      print("Failed to delete banner image: $e");
    }
    await _firestore.collection('banners').doc(bannerId).delete();
  }

  static Stream<List<Product>> getProducts() {
    return _firestore
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList(),
        );
  }

  static Future<void> addProduct(Product product) async {
    await _firestore.collection('products').add(product.toFirestore());
  }

  static Future<void> updateProduct(Product product) async {
    await _firestore
        .collection('products')
        .doc(product.id)
        .update(product.toFirestore());
  }

  static Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }

  static Stream<List<Order>> getOrders({required OrderFilter filter}) {
    firestore.Query query = _firestore
        .collection('orders')
        .orderBy('orderDate', descending: true);

    if (filter.assignedAreas != null && filter.assignedAreas!.isNotEmpty) {
      query = query.where(
        'deliveryAddress.pinCode',
        whereIn: filter.assignedAreas,
      );
    }

    if (filter.startDate != null) {
      query = query.where(
        'orderDate',
        isGreaterThanOrEqualTo: firestore.Timestamp.fromDate(filter.startDate!),
      );
    }
    if (filter.endDate != null) {
      query = query.where(
        'orderDate',
        isLessThanOrEqualTo: firestore.Timestamp.fromDate(filter.endDate!),
      );
    }
    if (filter.status != null) {
      query = query.where('status', isEqualTo: filter.status!.name);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList(),
    );
  }

  static Stream<List<Order>> getDeliveredOrdersForPersonSince({
    required String personId,
    DateTime? lastPaymentDate,
  }) {
    firestore.Query query = _firestore
        .collection('orders')
        .where('status', isEqualTo: OrderStatus.delivered.name)
        .where('deliveryPersonId', isEqualTo: personId);

    if (lastPaymentDate != null) {
      query = query.where(
        'deliveryDate',
        isGreaterThan: firestore.Timestamp.fromDate(lastPaymentDate),
      );
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList(),
    );
  }

  static Future<void> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': status.name,
      if (status == OrderStatus.delivered)
        'deliveryDate': firestore.Timestamp.now(),
    });
  }

  static Stream<List<Subscription>> getSubscriptions({
    required SubscriptionFilter filter,
  }) {
    firestore.Query query = _firestore
        .collection('subscriptions')
        .orderBy('createdAt', descending: true);

    if (filter.status != null) {
      query = query.where('status', isEqualTo: filter.status!.name);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Subscription.fromFirestore(doc)).toList(),
    );
  }

  static Future<void> addSubscription(Subscription subscription) async {
    await _firestore
        .collection('subscriptions')
        .add(subscription.toFirestore());
  }

  static Future<void> updateSubscription(Subscription subscription) async {
    await _firestore
        .collection('subscriptions')
        .doc(subscription.id)
        .update(subscription.toFirestore());
  }

  static Stream<List<Area>> getAreas() {
    return _firestore
        .collection('areas')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Area.fromFirestore(doc)).toList(),
        );
  }

  static Future<void> addArea(Area area) async {
    await _firestore.collection('areas').add(area.toFirestore());
  }

  static Future<void> deleteArea(String areaId) async {
    await _firestore.collection('areas').doc(areaId).delete();
  }

  static Stream<List<Customer>> getCustomers() {
    return _firestore
        .collection('customers')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Customer.fromFirestore(doc)).toList(),
        );
  }

  static Future<void> updateCustomer(Customer customer) async {
    await _firestore
        .collection('customers')
        .doc(customer.id)
        .update(customer.toFirestore());
  }

  static Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      final tomorrow = todayStart.add(const Duration(days: 1));
      final tomorrowEnd = tomorrow.add(const Duration(days: 1));

      final todayDeliveries =
          await _firestore
              .collection('orders')
              .where(
                'deliveryDate',
                isGreaterThanOrEqualTo: firestore.Timestamp.fromDate(
                  todayStart,
                ),
              )
              .where(
                'deliveryDate',
                isLessThan: firestore.Timestamp.fromDate(todayEnd),
              )
              .get();

      final tomorrowDeliveries =
          await _firestore
              .collection('orders')
              .where(
                'deliveryDate',
                isGreaterThanOrEqualTo: firestore.Timestamp.fromDate(tomorrow),
              )
              .where(
                'deliveryDate',
                isLessThan: firestore.Timestamp.fromDate(tomorrowEnd),
              )
              .get();

      final allSubscriptions =
          await _firestore.collection('subscriptions').get();

      int activeSubscriptionCount = 0;
      List<Subscription> validActiveSubscriptions = [];

      for (var doc in allSubscriptions.docs) {
        try {
          final subscription = Subscription.fromFirestore(doc);
          if (subscription.status == SubscriptionStatus.active &&
              _isSubscriptionActiveToday(subscription, today)) {
            activeSubscriptionCount++;
            validActiveSubscriptions.add(subscription);
          }
        } catch (e) {
          continue;
        }
      }

      double todayRevenue = 0;
      for (var doc in todayDeliveries.docs) {
        try {
          final order = Order.fromFirestore(doc);
          if (order.status == OrderStatus.delivered) {
            double orderTotal = 0;
            for (var item in order.items) {
              orderTotal += item.price * item.quantity;
            }
            todayRevenue += orderTotal;
          }
        } catch (e) {
          continue;
        }
      }

      final Map<String, double> tomorrowForecast = {};

      void addToForecast(String productName, double quantity) {
        tomorrowForecast[productName] =
            (tomorrowForecast[productName] ?? 0) + quantity;
      }

      for (var subscription in validActiveSubscriptions) {
        try {
          if (_shouldDeliverOnDate(subscription, tomorrow)) {
            addToForecast(subscription.productName, subscription.quantity);
          }
        } catch (e) {
          continue;
        }
      }

      for (var doc in tomorrowDeliveries.docs) {
        try {
          final order = Order.fromFirestore(doc);
          for (var item in order.items) {
            addToForecast(item.productName, item.quantity.toDouble());
          }
        } catch (e) {
          continue;
        }
      }

      return {
        'todayDeliveries': todayDeliveries.size,
        'activeSubscriptions': activeSubscriptionCount,
        'todayRevenue': todayRevenue,
        'tomorrowForecast': tomorrowForecast,
      };
    } catch (e) {
      throw Exception('Failed to get dashboard data: $e');
    }
  }

  // --- REQ 3: UPDATED SUBSCRIPTION LOGIC ---
  static bool _isSubscriptionActiveToday(
    Subscription subscription,
    DateTime today,
  ) {
    if (subscription.status != SubscriptionStatus.active) return false;

    final todayDate = DateTime(today.year, today.month, today.day);
    final startDate = DateTime(
      subscription.startDate.year,
      subscription.startDate.month,
      subscription.startDate.day,
    );

    if (todayDate.isBefore(startDate)) return false;

    int targetDeliveries = 0;
    switch (subscription.type) {
      case SubscriptionType.monthly:
        targetDeliveries = 30;
        break;
      case SubscriptionType.weekly:
        targetDeliveries = 7;
        break;
      case SubscriptionType.alternateDay:
        targetDeliveries = 15;
        break;
      default:
        targetDeliveries = 30;
    }

    return subscription.deliveredCount < targetDeliveries;
  }

  static bool _shouldDeliverOnDate(Subscription subscription, DateTime date) {
    if (!_isSubscriptionActiveToday(subscription, date)) {
      return false;
    }

    final daysSinceStart = date.difference(subscription.startDate).inDays;

    switch (subscription.type) {
      case SubscriptionType.monthly:
      case SubscriptionType.weekly:
        return true;
      case SubscriptionType.alternateDay:
        return daysSinceStart % 2 == 0;
      default:
        return true;
    }
  }
}
