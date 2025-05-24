import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

class DeliveryPerson {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String code;
  final String assignedArea;
  final bool isActive;
  final DateTime createdAt;

  DeliveryPerson({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.code,
    required this.assignedArea,
    required this.isActive,
    required this.createdAt,
  });

  factory DeliveryPerson.fromFirestore(firestore.DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DeliveryPerson(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      code: data['code'] ?? '',
      assignedArea: data['assignedArea'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as firestore.Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'code': code,
      'assignedArea': assignedArea,
      'isActive': isActive,
      'createdAt': firestore.Timestamp.fromDate(createdAt),
    };
  }
}
