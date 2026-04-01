import 'package:cloud_firestore/cloud_firestore.dart';
import 'order.dart' as myOrder; // Import the Order model for the calculation method
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
  });

  factory DeliveryPerson.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DeliveryPerson(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      assignedAreas: (data['assignedAreas'] as List<dynamic>?)
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
      paymentHistory: (data['paymentHistory'] as List<dynamic>?)
              ?.map((e) => PaymentRecord.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
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
    };
  }

  // --- NEW EARNINGS CALCULATION LOGIC ---
  double calculateEarnings(List<myOrder.Order> deliveredOrders) {
    double totalEarnings = 0.0;

    // Loop through each delivered order
    for (final order in deliveredOrders) {
      double totalQuantityInOrder = 0;
      // Loop through each item in the order to sum up the quantities
      for (final item in order.items) {
        totalQuantityInOrder += item.quantity;
      }
      // Calculate earnings for this order and add to the total
      totalEarnings += (totalQuantityInOrder * ratePerUnitQuantity) +
          (totalQuantityInOrder * bonusPerUnitQuantity);
    }
    return totalEarnings;
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
