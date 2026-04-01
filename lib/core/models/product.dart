import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

enum ProductUnit { liter, kg, piece }
enum ProductType { oneTimeOnly, general, subscription }
enum ProductCategory { milk, paneer, cheese }

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final ProductUnit unit;
  final ProductCategory category;
  final String? imageUrl;
  final bool isActive;
  final ProductType type;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.unit,
    required this.category,
    this.imageUrl,
    required this.isActive,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
  });

  String get unitText {
    switch (unit) {
      case ProductUnit.liter:
        return 'L';
      case ProductUnit.kg:
        return 'kg';
      case ProductUnit.piece:
        return 'piece';
    }
  }

  String get categoryText {
    switch (category) {
      case ProductCategory.milk:
        return 'Milk';
      case ProductCategory.paneer:
        return 'Paneer';
      case ProductCategory.cheese:
        return 'Cheese';
    }
  }

  bool get canSubscribe => type == ProductType.subscription;
  bool get isOneTimeOnly => type == ProductType.oneTimeOnly;

  factory Product.fromFirestore(firestore.DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      unit: _parseUnit(data['unit']),
      category: _parseCategory(data['category']),
      imageUrl: data['imageUrl'],
      isActive: true,
      type: _parseProductType(data['type']),
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as firestore.Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as firestore.Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  static ProductUnit _parseUnit(dynamic unitValue) {
    if (unitValue is int) {
      switch (unitValue) {
        case 0: return ProductUnit.liter;
        case 1: return ProductUnit.kg;
        case 2: return ProductUnit.piece;
        default: return ProductUnit.liter;
      }
    }
    return ProductUnit.liter;
  }

  static ProductCategory _parseCategory(dynamic categoryValue) {
    if (categoryValue is int) {
      switch (categoryValue) {
        case 0: return ProductCategory.milk;
        case 1: return ProductCategory.paneer;
        case 2: return ProductCategory.cheese;
        default: return ProductCategory.milk;
      }
    }
    // Handle string values for backward compatibility
    if (categoryValue is String) {
      switch (categoryValue.toLowerCase()) {
        case 'milk': return ProductCategory.milk;
        case 'paneer': return ProductCategory.paneer;
        case 'cheese': return ProductCategory.cheese;
        default: return ProductCategory.milk;
      }
    }
    return ProductCategory.milk;
  }

  static ProductType _parseProductType(dynamic typeValue) {
    if (typeValue is int) {
      switch (typeValue) {
        case 0: return ProductType.oneTimeOnly;
        case 1: return ProductType.general;
        case 2: return ProductType.subscription;
        default: return ProductType.general;
      }
    }
    return ProductType.general;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'unit': unit.index,
      'type': type.index,
      'category': category.index,
      'imageUrl': imageUrl,
      'createdAt': firestore.Timestamp.fromDate(createdAt),
      'updatedAt': firestore.Timestamp.fromDate(updatedAt),
    };
  }
}
