class Category {
  final int id;
  final String name;
  final String? description;
  final String? image;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.image,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'].toString(),
      description: json['description'],
      image: json['image'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
