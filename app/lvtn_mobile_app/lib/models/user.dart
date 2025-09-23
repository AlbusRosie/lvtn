class User {
  final int id;
  final int roleId;
  final int? branchId;
  final String username;
  final String email;
  final String name;
  final String? address;
  final String? phone;
  final bool favorite;
  final String? avatar;
  final String status;
  final DateTime createdAt;

  User({
    required this.id,
    required this.roleId,
    this.branchId,
    required this.username,
    required this.email,
    required this.name,
    this.address,
    this.phone,
    required this.favorite,
    this.avatar,
    required this.status,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    print('User.fromJson: Parsing user data: $json');
    return User(
      id: json['id'] ?? 0,
      roleId: json['role_id'] ?? 0,
      branchId: json['branch_id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      address: json['address'],
      phone: json['phone'],
      favorite: json['favorite'] == 1 || json['favorite'] == true,
      avatar: json['avatar'],
      status: json['status'] ?? 'active', // Default value if null
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(), // Default to now if null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role_id': roleId,
      'branch_id': branchId,
      'username': username,
      'email': email,
      'name': name,
      'address': address,
      'phone': phone,
      'favorite': favorite ? 1 : 0,
      'avatar': avatar,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get roleName {
    switch (roleId) {
      case 1: return 'Admin';
      case 2: return 'Manager';
      case 3: return 'Staff';
      case 4: return 'Customer';
      default: return 'Unknown';
    }
  }

  bool get isAdmin => roleId == 1;
  bool get isManager => roleId == 2;
  bool get isStaff => roleId == 3;
  bool get isCustomer => roleId == 4;
}
