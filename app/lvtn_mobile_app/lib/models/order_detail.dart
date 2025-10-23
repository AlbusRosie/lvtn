class OrderDetail {
    final int id;
    final int orderId;
    final int productId;
    final int quantity;
    final double price;
    final String? productName;
    final String? productImage;
    final String? productDescription;
    final String? specialInstructions;

    OrderDetail({
        required this.id,
        required this.orderId,
        required this.productId,
        required this.quantity,
        required this.price,
        this.productName,
        this.productImage,
        this.productDescription,
        this.specialInstructions,
    });

    factory OrderDetail.fromJson(Map<String, dynamic> json) {
        return OrderDetail(
        id: json['id'],
        orderId: json['order_id'],
        productId: json['product_id'],
        quantity: json['quantity'],
        price: double.parse(json['price'].toString()),
        productName: json['product_name'],
        productImage: json['product_image'],
        productDescription: json['product_description'],
        specialInstructions: json['special_instructions'],
        );
    }

    Map<String, dynamic> toJson() {
        return {
        'id': id,
        'order_id': orderId,
        'product_id': productId,
        'quantity': quantity,
        'price': price,
        'product_name': productName,
        'product_image': productImage,
        'product_description': productDescription,
        'special_instructions': specialInstructions,
        };
    }
}
