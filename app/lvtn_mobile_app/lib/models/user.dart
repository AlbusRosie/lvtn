class User {
  final int id;
  final String username;
  final String email;
  final String name;
  final String? address;
  final String? phone;
  final String? avatar;
  final int roleId;
  final String status;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.name,
    this.address,
    this.phone,
    this.avatar,
    required this.roleId,
    required this.status,
    required this.createdAt,
  });

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? name,
    String? address,
    String? phone,
    String? avatar,
    int? roleId,
    String? status,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      roleId: roleId ?? this.roleId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      DateTime? createdAt;
      if (json['created_at'] != null) {
        try {
          if (json['created_at'] is String) {
            createdAt = DateTime.parse(json['created_at']);
          } else if (json['created_at'] is int) {
            createdAt = DateTime.fromMillisecondsSinceEpoch(json['created_at']);
          }
        } catch (e) {
          print('User.fromJson: Lỗi parse created_at: $e, value: ${json['created_at']}');
          createdAt = DateTime.now();
        }
      }
      createdAt ??= DateTime.now();
      
      return User(
        id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
        username: json['username']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        address: json['address']?.toString(),
        phone: json['phone']?.toString(),
        avatar: json['avatar']?.toString(),
        roleId: json['role_id'] is int ? json['role_id'] : (int.tryParse(json['role_id']?.toString() ?? '4') ?? 4),
        status: json['status']?.toString() ?? 'active',
        createdAt: createdAt,
      );
    } catch (e) {
      print('User.fromJson: Lỗi khi parse user: $e');
      print('User.fromJson: JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'name': name,
      'address': address,
      'phone': phone,
      'avatar': avatar,
      'role_id': roleId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
