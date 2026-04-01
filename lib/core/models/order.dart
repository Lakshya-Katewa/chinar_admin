import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'address.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  cancelled,
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final String unit;
  final String? imageUrl;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.unit,
    this.imageUrl,
  });

  double get totalPrice => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'unit': unit,
      'imageUrl': imageUrl,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: (map['quantity'] ?? 0).toInt(),
      price: (map['price'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? '',
      imageUrl: map['imageUrl'],
    );
  }
}

class Order {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final DetailedAddress deliveryAddress;
  final DateTime orderDate;
  final DateTime deliveryDate;
  final String? notes;
  final String? paymentMethod;
  final String? paymentId;
  final String? deliverySlot;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.deliveryAddress,
    required this.orderDate,
    required this.deliveryDate,
    this.notes,
    this.paymentMethod,
    this.paymentId,
    this.deliverySlot,
    required this.createdAt,
  });

  String get areaCode => deliveryAddress.pinCode; // For compatibility with existing code

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status.toString().split('.').last,
      'deliveryAddress': deliveryAddress.toMap(),
      'orderDate': firestore.Timestamp.fromDate(orderDate),
      'deliveryDate': firestore.Timestamp.fromDate(deliveryDate),
      'notes': notes,
      'paymentMethod': paymentMethod,
      'paymentId': paymentId,
      'deliverySlot': deliverySlot,
      'createdAt': firestore.Timestamp.fromDate(createdAt),
    };
  }

  factory Order.fromFirestore(firestore.DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      
      // Parse delivery address with fallback values
      DetailedAddress deliveryAddress;
      try {
        final addressData = data['deliveryAddress'] as Map<String, dynamic>? ?? {};
        deliveryAddress = DetailedAddress.fromMap(addressData);
      } catch (e) {
        // Create a fallback address
        deliveryAddress = DetailedAddress(
          houseNumber: '',
          street: '',
          city: '',
          landmark: '',
          pinCode: '',
          latitude: 0.0,
          longitude: 0.0,
          fullAddress: 'Address not available',
          instructions: null,
        );
      }
      
      // Parse items with error handling
      List<OrderItem> items = [];
      try {
        final itemsData = data['items'] as List<dynamic>? ?? [];
        items = itemsData
            .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        items = [];
      }
      
      return Order(
        id: doc.id,
        customerId: data['customerId']?.toString() ?? '',
        customerName: data['customerName']?.toString() ?? '',
        customerPhone: data['customerPhone']?.toString() ?? '',
        items: items,
        totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
        status: _parseOrderStatus(data['status']?.toString()),
        deliveryAddress: deliveryAddress,
        orderDate: (data['orderDate'] as firestore.Timestamp?)?.toDate() ?? DateTime.now(),
        deliveryDate: (data['deliveryDate'] as firestore.Timestamp?)?.toDate() ?? DateTime.now(),
        notes: data['notes']?.toString(),
        paymentMethod: data['paymentMethod']?.toString(),
        paymentId: data['paymentId']?.toString(),
        deliverySlot: data['deliverySlot']?.toString(),
        createdAt: (data['createdAt'] as firestore.Timestamp?)?.toDate() ?? DateTime.now(),
      );
      
    } catch (e) {
      rethrow;
    }
  }

  static OrderStatus _parseOrderStatus(String? status) {
    switch (status) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'outForDelivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}
