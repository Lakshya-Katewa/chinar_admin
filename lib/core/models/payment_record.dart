import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class PaymentRecord {
  final String id;
  final double amount;
  final DateTime paymentDate;

  const PaymentRecord({
    required this.id,
    required this.amount,
    required this.paymentDate,
  });

  factory PaymentRecord.fromMap(Map<String, dynamic> map) {
    return PaymentRecord(
      id: map['id'] as String? ?? '',
      amount: (map['amount'] as num? ?? 0).toDouble(),
      paymentDate: (map['paymentDate'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'paymentDate': Timestamp.fromDate(paymentDate),
    };
  }
}
