import '../config/env.dart';
class Product {
  final int id;
  final int categoryId;
  final String name;
  final double basePrice;
  final String? description;
  final String? image;
  final bool isGlobalAvailable;
  final String status;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.basePrice,
    this.description,
    this.image,
    required this.isGlobalAvailable,
    required this.status,
    required this.createdAt,
  });

  static double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      return double.tryParse(price) ?? 0.0;
    }
    return 0.0;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      categoryId: json['category_id'],
      name: json['name'],
      basePrice: _parsePrice(json['base_price']),
      description: json['description'],
      image: json['image'],
      isGlobalAvailable: json['is_global_available'] == 1,
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'base_price': basePrice,
      'description': description,
      'image': image,
      'is_global_available': isGlobalAvailable ? 1 : 0,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedPrice {
    return '${basePrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')} đ';
  }

  String get imageUrl {
    if (image == null || image!.isEmpty) {
      return '${Environment.baseUrl.replaceAll('/api', '')}/public/images/blank-profile-picture.jpg';
    }
    if (image!.startsWith('http')) {
      return image!;
    }
    if (image!.startsWith('/public')) {
      return '${Environment.baseUrl.replaceAll('/api', '')}$image';
    }
    return '${Environment.baseUrl.replaceAll('/api', '')}/public/uploads/$image';
  }

  Product copyWith({
    int? id,
    int? categoryId,
    String? name,
    double? basePrice,
    String? description,
    String? image,
    bool? isGlobalAvailable,
    String? status,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      basePrice: basePrice ?? this.basePrice,
      description: description ?? this.description,
      image: image ?? this.image,
      isGlobalAvailable: isGlobalAvailable ?? this.isGlobalAvailable,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Product{id: $id, name: $name, price: $basePrice}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
