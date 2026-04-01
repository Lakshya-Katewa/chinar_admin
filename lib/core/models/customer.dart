import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'address.dart';

class Customer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final DetailedAddress address;
  final String areaCode;
  final double walletBalance;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String referralCode;
  final String? referredBy;
  final bool hasUsedReferral;
  final bool referralRewardClaimed;
  final int successfulReferrals;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.areaCode,
    required this.walletBalance,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.referralCode,
    this.referredBy,
    required this.hasUsedReferral,
    required this.referralRewardClaimed,
    required this.successfulReferrals,
  });

  factory Customer.fromFirestore(firestore.DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Customer(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      address: DetailedAddress.fromMap(data['address'] ?? {}),
      areaCode: data['areaCode'] ?? '',
      walletBalance: (data['walletBalance'] ?? 0.0).toDouble(),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as firestore.Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as firestore.Timestamp).toDate(),
      referralCode: data['referralCode'] ?? '',
      referredBy: data['referredBy'],
      hasUsedReferral: data['hasUsedReferral'] ?? false,
      referralRewardClaimed: data['referralRewardClaimed'] ?? false,
      successfulReferrals: data['successfulReferrals'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address.toMap(),
      'areaCode': areaCode,
      'walletBalance': walletBalance,
      'isActive': isActive,
      'createdAt': firestore.Timestamp.fromDate(createdAt),
      'updatedAt': firestore.Timestamp.fromDate(updatedAt),
      'referralCode': referralCode,
      'referredBy': referredBy,
      'hasUsedReferral': hasUsedReferral,
      'referralRewardClaimed': referralRewardClaimed,
      'successfulReferrals': successfulReferrals,
    };
  }

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    DetailedAddress? address,
    String? areaCode,
    double? walletBalance,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? referralCode,
    String? referredBy,
    bool? hasUsedReferral,
    bool? referralRewardClaimed,
    int? successfulReferrals,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      areaCode: areaCode ?? this.areaCode,
      walletBalance: walletBalance ?? this.walletBalance,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      hasUsedReferral: hasUsedReferral ?? this.hasUsedReferral,
      referralRewardClaimed:
          referralRewardClaimed ?? this.referralRewardClaimed,
      successfulReferrals: successfulReferrals ?? this.successfulReferrals,
    );
  }
}
