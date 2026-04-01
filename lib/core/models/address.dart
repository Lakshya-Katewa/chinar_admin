class DetailedAddress {
  final String houseNumber;
  final String street;
  final String city;
  final String landmark;
  final String pinCode;
  final double latitude;
  final double longitude;
  final String fullAddress;
  final String? instructions;

  DetailedAddress({
    required this.houseNumber,
    required this.street,
    required this.city,
    required this.landmark,
    required this.pinCode,
    required this.latitude,
    required this.longitude,
    required this.fullAddress,
    this.instructions,
  });

  factory DetailedAddress.fromMap(Map<String, dynamic> map) {
    return DetailedAddress(
      houseNumber: map['houseNumber']?.toString() ?? '',
      street: map['street']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      landmark: map['landmark']?.toString() ?? '',
      pinCode: map['pinCode']?.toString() ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      fullAddress: map['fullAddress']?.toString() ?? '',
      instructions: map['instructions']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'houseNumber': houseNumber,
      'street': street,
      'city': city,
      'landmark': landmark,
      'pinCode': pinCode,
      'latitude': latitude,
      'longitude': longitude,
      'fullAddress': fullAddress,
      'instructions': instructions,
    };
  }

  @override
  String toString() {
    return fullAddress.isNotEmpty ? fullAddress : '$houseNumber, $street, $city';
  }
}
