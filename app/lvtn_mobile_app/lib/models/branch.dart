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
  final String? openingHours;
  final String? description;
  final DateTime createdAt;

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
    this.description,
    required this.createdAt,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    print('Branch.fromJson: Parsing branch data: $json');
    return Branch(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      provinceId: json['province_id'],
      districtId: json['district_id'],
      addressDetail: json['address_detail'],
      phone: json['phone'] ?? '',
      email: json['email'],
      managerId: json['manager_id'],
      status: json['status'] ?? 'active',
      openingHours: json['opening_hours'],
      description: json['description'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
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
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isActive => status == 'active';
  String get fullAddress => '$addressDetail, District $districtId, Province $provinceId';
}
