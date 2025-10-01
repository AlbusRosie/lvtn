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
  final String? categoryName;
  
  // Branch-specific data
  final double? branchPrice;
  final bool? branchAvailable;
  final String? branchStatus;

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
    this.categoryName,
    this.branchPrice,
    this.branchAvailable,
    this.branchStatus,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      categoryId: json['category_id'],
      name: json['name'],
      basePrice: (json['base_price'] ?? json['display_price']).toDouble(),
      description: json['description'],
      image: json['image'],
      isGlobalAvailable: json['is_global_available'] == 1,
      status: json['status'] ?? json['global_status'],
      createdAt: DateTime.parse(json['created_at']),
      categoryName: json['category_name'],
      branchPrice: json['branch_price']?.toDouble(),
      branchAvailable: json['branch_available'] == 1,
      branchStatus: json['branch_status'],
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
      'category_name': categoryName,
      'branch_price': branchPrice,
      'branch_available': (branchAvailable ?? false) ? 1 : 0,
      'branch_status': branchStatus,
    };
  }
}
