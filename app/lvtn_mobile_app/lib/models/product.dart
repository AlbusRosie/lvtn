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

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      categoryId: json['category_id'],
      name: json['name'],
      basePrice: double.parse(json['base_price'].toString()),
      description: json['description'],
      image: json['image'],
      isGlobalAvailable: json['is_global_available'] == 1 || json['is_global_available'] == true,
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
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

  bool get isActive => status == 'active';
  String get formattedPrice => '${basePrice.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  )} VNĐ';
}

class BranchProduct {
  final int id;
  final int branchId;
  final int productId;
  final double price;
  final bool isAvailable;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  BranchProduct({
    required this.id,
    required this.branchId,
    required this.productId,
    required this.price,
    required this.isAvailable,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BranchProduct.fromJson(Map<String, dynamic> json) {
    return BranchProduct(
      id: json['id'],
      branchId: json['branch_id'],
      productId: json['product_id'],
      price: double.parse(json['price'].toString()),
      isAvailable: json['is_available'] == 1 || json['is_available'] == true,
      status: json['status'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  bool get isAvailableForOrder => isAvailable && status == 'available';
  String get formattedPrice => '${price.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  )} VNĐ';
}
