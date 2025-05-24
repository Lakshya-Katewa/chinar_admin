import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

enum ProductType { buyOnce, subscription, both }

enum ProductUnit { liters, grams }

class Product {
  final String id;
  final String name;
  final double price;
  final String description;
  final ProductUnit unit;
  final double quantity;
  final ProductType type;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.unit,
    required this.quantity,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromFirestore(firestore.DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      unit: ProductUnit.values[data['unit'] ?? 0],
      quantity: (data['quantity'] ?? 0).toDouble(),
      type: ProductType.values[data['type'] ?? 0],
      createdAt: (data['createdAt'] as firestore.Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as firestore.Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'description': description,
      'unit': unit.index,
      'quantity': quantity,
      'type': type.index,
      'createdAt': firestore.Timestamp.fromDate(createdAt),
      'updatedAt': firestore.Timestamp.fromDate(updatedAt),
    };
  }

  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? description,
    ProductUnit? unit,
    double? quantity,
    ProductType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
