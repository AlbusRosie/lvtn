class OrderItem {
  final int id;
  final int orderId;
  final int productId;
  final int quantity;
  final double price;
  final String? specialInstructions;
  final String? productName;
  final String? productImage;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.price,
    this.specialInstructions,
    this.productName,
    this.productImage,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      orderId: json['order_id'],
      productId: json['product_id'],
      quantity: json['quantity'],
      price: json['price'].toDouble(),
      specialInstructions: json['special_instructions'],
      productName: json['product_name'],
      productImage: json['product_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'price': price,
      'special_instructions': specialInstructions,
      'product_name': productName,
      'product_image': productImage,
    };
  }
}
