import 'package:cloud_firestore/cloud_firestore.dart';

class Banner {
  final String? id;
  final String imageUrl;
  final bool isActive;
  final String title;
  final String subtitle;
  final String actionType; // 'category', 'product', 'none'
  final String target;     // Category name or Product ID
  final Timestamp createdAt;

  Banner({
    this.id,
    required this.imageUrl,
    required this.isActive,
    required this.title,
    required this.subtitle,
    required this.actionType,
    required this.target,
    required this.createdAt,
  });

  factory Banner.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Banner(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      isActive: data['isActive'] ?? false,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      actionType: data['actionType'] ?? 'none',
      target: data['target'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'imageUrl': imageUrl,
      'isActive': isActive,
      'title': title,
      'subtitle': subtitle,
      'actionType': actionType,
      'target': target,
      'createdAt': createdAt,
    };
  }
}
