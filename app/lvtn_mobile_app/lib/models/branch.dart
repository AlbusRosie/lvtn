class Branch {
  final int id;
  final String name;
  final int? provinceId;
  final int? districtId;
  final String? addressDetail;
  final String phone;
  final String? email;
  final int? managerId;
  final String status;
  final int? openingHours;
  final int? closeHours;
  final String? description;
  final String? image;
  final DateTime createdAt;

  String get address => addressDetail ?? 'Địa chỉ không xác định';

  Branch({
    required this.id,
    required this.name,
    this.provinceId,
    this.districtId,
    this.addressDetail,
    required this.phone,
    this.email,
    this.managerId,
    required this.status,
    this.openingHours,
    this.closeHours,
    this.description,
    this.image,
    required this.createdAt,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'],
      name: json['name'].toString(),
      provinceId: json['province_id'],
      districtId: json['district_id'],
      addressDetail: json['address_detail'],
      phone: json['phone'],
      email: json['email'],
      managerId: json['manager_id'],
      status: json['status'].toString(),
      openingHours: json['opening_hours'],
      closeHours: json['close_hours'],
      description: json['description'],
      image: json['image'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'province_id': provinceId,
      'district_id': districtId,
      'address_detail': addressDetail,
      'phone': phone,
      'email': email,
      'manager_id': managerId,
      'status': status,
      'opening_hours': openingHours,
      'close_hours': closeHours,
      'description': description,
      'image': image,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
