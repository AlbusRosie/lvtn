class Province {
  final int id;
  final String name;
  final String code;
  final DateTime createdAt;

  Province({
    required this.id,
    required this.name,
    required this.code,
    required this.createdAt,
  });

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class District {
  final int id;
  final String name;
  final String code;
  final int provinceId;
  final DateTime createdAt;

  District({
    required this.id,
    required this.name,
    required this.code,
    required this.provinceId,
    required this.createdAt,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      provinceId: json['province_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'province_id': provinceId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
