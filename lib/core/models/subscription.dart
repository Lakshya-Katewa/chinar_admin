// subscription.dart
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

enum SubscriptionType { monthly, weekly, alternateDay }
enum SubscriptionStatus { active, paused, cancelled, expired }

class Subscription {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String productId;
  final String productName;
  final SubscriptionType type;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final double quantity;
  final double pricePerUnit;
  final double totalAmount;
  final String areaCode;
  final String address;
  final SubscriptionStatus status;
  final String? imageUrl;
  final int deliveredCount; // ADDED
  final DateTime createdAt;

  Subscription({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.productId,
    required this.productName,
    required this.type,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalAmount,
    required this.areaCode,
    required this.address,
    required this.status,
    this.imageUrl,
    this.deliveredCount = 0, // ADDED
    required this.createdAt,
  });

  factory Subscription.fromFirestore(firestore.DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Subscription(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      type: SubscriptionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => SubscriptionType.monthly,
      ),
      startDate: (data['startDate'] as firestore.Timestamp).toDate(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as firestore.Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      quantity: (data['quantity'] ?? 0.0).toDouble(),
      pricePerUnit: (data['pricePerUnit'] ?? 0.0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      areaCode: data['areaCode'] ?? '',
      address: data['address'] ?? '',
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => SubscriptionStatus.active,
      ),
      imageUrl: data['imageUrl'],
      deliveredCount: data['deliveredCount'] ?? 0, // ADDED
      createdAt: (data['createdAt'] as firestore.Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'productId': productId,
      'productName': productName,
      'type': type.name,
      'startDate': firestore.Timestamp.fromDate(startDate),
      'endDate': endDate != null ? firestore.Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
      'quantity': quantity,
      'pricePerUnit': pricePerUnit,
      'totalAmount': totalAmount,
      'areaCode': areaCode,
      'address': address,
      'status': status.name,
      'imageUrl': imageUrl,
      'deliveredCount': deliveredCount, // ADDED
      'createdAt': firestore.Timestamp.fromDate(createdAt),
    };
  }
}