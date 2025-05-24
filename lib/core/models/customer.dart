import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

class Customer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String areaCode;
  final double walletBalance;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.areaCode,
    required this.walletBalance,
    required this.createdAt,
  });

  factory Customer.fromFirestore(firestore.DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Customer(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      address: data['address'] ?? '',
      areaCode: data['areaCode'] ?? '',
      walletBalance: (data['walletBalance'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as firestore.Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'areaCode': areaCode,
      'walletBalance': walletBalance,
      'createdAt': firestore.Timestamp.fromDate(createdAt),
    };
  }
}
