class User {
  final int id;
  final String username;
  final String email;
  final String name;
  final String? address;
  final String? phone;
  final bool favorite;
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
    required this.favorite,
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
    bool? favorite,
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
      favorite: favorite ?? this.favorite,
      avatar: avatar ?? this.avatar,
      roleId: roleId ?? this.roleId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      address: json['address'],
      phone: json['phone'],
      favorite: json['favorite'] == 1 || json['favorite'] == true,
      avatar: json['avatar'],
      roleId: json['role_id'] ?? 4,
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'name': name,
      'address': address,
      'phone': phone,
      'favorite': favorite ? 1 : 0,
      'avatar': avatar,
      'role_id': roleId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
