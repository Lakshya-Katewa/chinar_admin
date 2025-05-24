import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/subscription.dart';
import '../models/delivery_person.dart';
import '../models/area.dart';
import '../models/customer.dart';

class FirebaseService {
  static final firestore.FirebaseFirestore _firestore =
      firestore.FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Auth
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

  // Products
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

  // Orders
  static Stream<List<Order>> getOrders({
    String? areaCode,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    firestore.Query query = _firestore
        .collection('orders')
        .orderBy('orderDate', descending: true);

    if (areaCode != null && areaCode.isNotEmpty) {
      query = query.where('areaCode', isEqualTo: areaCode);
    }

    if (startDate != null) {
      query = query.where(
        'orderDate',
        isGreaterThanOrEqualTo: firestore.Timestamp.fromDate(startDate),
      );
    }

    if (endDate != null) {
      query = query.where(
        'orderDate',
        isLessThanOrEqualTo: firestore.Timestamp.fromDate(endDate),
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
      'status': status.index,
      if (status == OrderStatus.delivered)
        'deliveryDate': firestore.Timestamp.now(),
    });
  }

  // Subscriptions
  static Stream<List<Subscription>> getSubscriptions() {
    return _firestore
        .collection('subscriptions')
        .orderBy('startDate', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Subscription.fromFirestore(doc))
                  .toList(),
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

  // Delivery Persons
  static Stream<List<DeliveryPerson>> getDeliveryPersons() {
    return _firestore
        .collection('delivery_persons')
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
    await _firestore.collection('delivery_persons').add(person.toFirestore());
  }

  static Future<void> updateDeliveryPerson(DeliveryPerson person) async {
    await _firestore
        .collection('delivery_persons')
        .doc(person.id)
        .update(person.toFirestore());
  }

  // Areas
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

  // Customers
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

  // Dashboard Analytics
  static Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      final tomorrow = todayStart.add(const Duration(days: 1));
      final tomorrowEnd = tomorrow.add(const Duration(days: 1));

      // Today's deliveries
      final todayDeliveries =
          await _firestore
              .collection('orders')
              .where(
                'orderDate',
                isGreaterThanOrEqualTo: firestore.Timestamp.fromDate(
                  todayStart,
                ),
              )
              .where(
                'orderDate',
                isLessThan: firestore.Timestamp.fromDate(todayEnd),
              )
              .get();

      // Active subscriptions
      final activeSubscriptions =
          await _firestore
              .collection('subscriptions')
              .where('isActive', isEqualTo: true)
              .get();

      // Today's revenue
      double todayRevenue = 0;
      for (var doc in todayDeliveries.docs) {
        final order = Order.fromFirestore(doc);
        if (order.status == OrderStatus.delivered) {
          todayRevenue += order.totalAmount;
        }
      }

      // Tomorrow's forecast (simplified - based on active subscriptions)
      double milkLiters = 0;
      double paneerKg = 0;
      double cheeseKg = 0;

      for (var doc in activeSubscriptions.docs) {
        final subscription = Subscription.fromFirestore(doc);
        if (subscription.productName.toLowerCase().contains('milk')) {
          milkLiters += subscription.quantity;
        } else if (subscription.productName.toLowerCase().contains('paneer')) {
          paneerKg += subscription.quantity / 1000; // Convert grams to kg
        } else if (subscription.productName.toLowerCase().contains('cheese')) {
          cheeseKg += subscription.quantity / 1000; // Convert grams to kg
        }
      }

      return {
        'todayDeliveries': todayDeliveries.size,
        'activeSubscriptions': activeSubscriptions.size,
        'todayRevenue': todayRevenue,
        'tomorrowForecast': {
          'milk': milkLiters,
          'paneer': paneerKg,
          'cheese': cheeseKg,
        },
      };
    } catch (e) {
      throw Exception('Failed to get dashboard data: $e');
    }
  }
}
