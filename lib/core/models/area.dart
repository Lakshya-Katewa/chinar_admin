import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

class Area {
  final String id;
  final String name;
  final String areaCode;
  final DateTime createdAt;

  Area({
    required this.id,
    required this.name,
    required this.areaCode,
    required this.createdAt,
  });

  factory Area.fromFirestore(firestore.DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Area(
      id: doc.id,
      name: data['name'] ?? '',
      areaCode: data['areaCode'] ?? '',
      createdAt: (data['createdAt'] as firestore.Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'areaCode': areaCode,
      'createdAt': firestore.Timestamp.fromDate(createdAt),
    };
  }
}
