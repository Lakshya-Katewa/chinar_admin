import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

enum OrderStatus { pending, delivered, canceled }

class Order {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String productId;
  final String productName;
  final double quantity;
  final double totalAmount;
  final String areaCode;
  final String address;
  final OrderStatus status;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final String? deliveryPersonId;

  Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.totalAmount,
    required this.areaCode,
    required this.address,
    required this.status,
    required this.orderDate,
    this.deliveryDate,
    this.deliveryPersonId,
  });

  factory Order.fromFirestore(firestore.DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Order(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      quantity: (data['quantity'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      areaCode: data['areaCode'] ?? '',
      address: data['address'] ?? '',
      status: OrderStatus.values[data['status'] ?? 0],
      orderDate: (data['orderDate'] as firestore.Timestamp).toDate(),
      deliveryDate:
          data['deliveryDate'] != null
              ? (data['deliveryDate'] as firestore.Timestamp).toDate()
              : null,
      deliveryPersonId: data['deliveryPersonId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'totalAmount': totalAmount,
      'areaCode': areaCode,
      'address': address,
      'status': status.index,
      'orderDate': firestore.Timestamp.fromDate(orderDate),
      'deliveryDate':
          deliveryDate != null
              ? firestore.Timestamp.fromDate(deliveryDate!)
              : null,
      'deliveryPersonId': deliveryPersonId,
    };
  }
}
