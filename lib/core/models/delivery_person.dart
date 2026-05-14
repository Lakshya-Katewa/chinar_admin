import 'package:cloud_firestore/cloud_firestore.dart';
import 'order.dart' as myOrder;
import 'payment_record.dart';

class DeliveryPerson {
  final String id;
  final String name;
  final String phone;
  final String email;
  final List<String> assignedAreas;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double ratePerUnitQuantity;
  final double bonusPerUnitQuantity;
  final String password;
  final DateTime? lastPaymentDate;
  final List<PaymentRecord> paymentHistory;

  // NEW: Added earnings tracking fields
  final double unpaidEarnings;
  final double totalEarnings;

  const DeliveryPerson({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.assignedAreas,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    required this.ratePerUnitQuantity,
    this.bonusPerUnitQuantity = 0.0,
    required this.password,
    this.lastPaymentDate,
    this.paymentHistory = const [],
    this.unpaidEarnings = 0.0, // Default to 0.0
    this.totalEarnings = 0.0, // Default to 0.0
  });

  factory DeliveryPerson.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DeliveryPerson(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      assignedAreas:
          (data['assignedAreas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      ratePerUnitQuantity:
          (data['ratePerUnitQuantity'] ?? data['paymentPerDelivery'] ?? 0.0)
              .toDouble(),
      bonusPerUnitQuantity:
          (data['bonusPerUnitQuantity'] ?? data['bonusPerDelivery'] ?? 0.0)
              .toDouble(),
      password: data['password']?.toString() ?? '',
      lastPaymentDate: (data['lastPaymentDate'] as Timestamp?)?.toDate(),
      paymentHistory:
          (data['paymentHistory'] as List<dynamic>?)
              ?.map((e) => PaymentRecord.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      // NEW: Extract from Firestore
      unpaidEarnings: (data['unpaidEarnings'] ?? 0.0).toDouble(),
      totalEarnings: (data['totalEarnings'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'assignedAreas': assignedAreas,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      'ratePerUnitQuantity': ratePerUnitQuantity,
      'bonusPerUnitQuantity': bonusPerUnitQuantity,
      'password': password,
      if (lastPaymentDate != null)
        'lastPaymentDate': Timestamp.fromDate(lastPaymentDate!),
      'paymentHistory': paymentHistory.map((e) => e.toMap()).toList(),
      // NEW: Save back to Firestore
      'unpaidEarnings': unpaidEarnings,
      'totalEarnings': totalEarnings,
    };
  }

  double calculateEarnings(List<myOrder.Order> deliveredOrders) {
    double calculatedEarnings = 0.0;

    for (final order in deliveredOrders) {
      double totalQuantityInOrder = 0;
      for (final item in order.items) {
        totalQuantityInOrder += item.quantity;
      }
      calculatedEarnings +=
          (totalQuantityInOrder * ratePerUnitQuantity) +
          (totalQuantityInOrder * bonusPerUnitQuantity);
    }
    return calculatedEarnings;
  }

  DeliveryPerson copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    List<String>? assignedAreas,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? ratePerUnitQuantity,
    double? bonusPerUnitQuantity,
    String? password,
    DateTime? lastPaymentDate,
    List<PaymentRecord>? paymentHistory,
    double? unpaidEarnings,
    double? totalEarnings,
  }) {
    return DeliveryPerson(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      assignedAreas: assignedAreas ?? this.assignedAreas,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ratePerUnitQuantity: ratePerUnitQuantity ?? this.ratePerUnitQuantity,
      bonusPerUnitQuantity: bonusPerUnitQuantity ?? this.bonusPerUnitQuantity,
      password: password ?? this.password,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      paymentHistory: paymentHistory ?? this.paymentHistory,
      unpaidEarnings: unpaidEarnings ?? this.unpaidEarnings,
      totalEarnings: totalEarnings ?? this.totalEarnings,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeliveryPerson && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
