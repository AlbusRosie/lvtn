class Branch {
  final int id;
  final String name;
  final String? addressDetail;
  final String phone;
  final String? email;
  final int? managerId;
  final String status;
  final int? openingHours;
  final int? closeHours;
  final String? description;
  final String? image;
  final double? latitude;
  final double? longitude;
  /// Khoảng cách (km) từ vị trí người dùng, trả về bởi API /branches/nearby
  final double? distanceKm;
  final DateTime createdAt;

  String get address => addressDetail ?? 'Địa chỉ không xác định';

  Branch({
    required this.id,
    required this.name,
    this.addressDetail,
    required this.phone,
    this.email,
    this.managerId,
    required this.status,
    this.openingHours,
    this.closeHours,
    this.description,
    this.image,
    this.latitude,
    this.longitude,
    this.distanceKm,
    required this.createdAt,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'],
      name: json['name'].toString(),
      addressDetail: json['address_detail'],
      phone: json['phone'],
      email: json['email'],
      managerId: json['manager_id'],
      status: json['status'].toString(),
      openingHours: json['opening_hours'],
      closeHours: json['close_hours'],
      description: json['description'],
      image: json['image'],
      latitude: json['latitude'] != null ? double.parse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.parse(json['longitude'].toString()) : null,
      distanceKm: json['distance_km'] != null ? double.parse(json['distance_km'].toString()) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address_detail': addressDetail,
      'phone': phone,
      'email': email,
      'manager_id': managerId,
      'status': status,
      'opening_hours': openingHours,
      'close_hours': closeHours,
      'description': description,
      'image': image,
      'latitude': latitude,
      'longitude': longitude,
      'distance_km': distanceKm,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
