import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

enum SubscriptionType { monthly, weekly, alternateDay }

class Subscription {
  final String id;
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
  final String areaCode;
  final String address;

  Subscription({
    required this.id,
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
    required this.areaCode,
    required this.address,
  });

  factory Subscription.fromFirestore(firestore.DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Subscription(
      id: doc.id,
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      type: SubscriptionType.values[data['type'] ?? 0],
      startDate: (data['startDate'] as firestore.Timestamp).toDate(),
      endDate:
          data['endDate'] != null
              ? (data['endDate'] as firestore.Timestamp).toDate()
              : null,
      isActive: data['isActive'] ?? true,
      quantity: (data['quantity'] ?? 0).toDouble(),
      pricePerUnit: (data['pricePerUnit'] ?? 0).toDouble(),
      areaCode: data['areaCode'] ?? '',
      address: data['address'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'productId': productId,
      'productName': productName,
      'type': type.index,
      'startDate': firestore.Timestamp.fromDate(startDate),
      'endDate':
          endDate != null ? firestore.Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
      'quantity': quantity,
      'pricePerUnit': pricePerUnit,
      'areaCode': areaCode,
      'address': address,
    };
  }
}
