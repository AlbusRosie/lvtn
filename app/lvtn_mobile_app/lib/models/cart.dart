class CartItem {
  final int id;
  final int cartId;
  final int productId;
  final int quantity;
  final double price;
  final String? specialInstructions;
  final String productName;
  final String? productImage;
  final String? productDescription;

  CartItem({
    required this.id,
    required this.cartId,
    required this.productId,
    required this.quantity,
    required this.price,
    this.specialInstructions,
    required this.productName,
    this.productImage,
    this.productDescription,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      cartId: json['cart_id'],
      productId: json['product_id'],
      quantity: json['quantity'],
      price: (json['price'] as num).toDouble(),
      specialInstructions: json['special_instructions'],
      productName: json['product_name'],
      productImage: json['product_image'],
      productDescription: json['product_description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cart_id': cartId,
      'product_id': productId,
      'quantity': quantity,
      'price': price,
      'special_instructions': specialInstructions,
      'product_name': productName,
      'product_image': productImage,
      'product_description': productDescription,
    };
  }

  CartItem copyWith({
    int? id,
    int? cartId,
    int? productId,
    int? quantity,
    double? price,
    String? specialInstructions,
    String? productName,
    String? productImage,
    String? productDescription,
  }) {
    return CartItem(
      id: id ?? this.id,
      cartId: cartId ?? this.cartId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      productDescription: productDescription ?? this.productDescription,
    );
  }
}

class Cart {
  final int id;
  final int userId;
  final int branchId;
  final String sessionId;
  final String orderType;
  final int? tableId;
  final String? reservationDate;
  final String? reservationTime;
  final int? guestCount;
  final String status;
  final DateTime expiresAt;
  final String? specialRequests;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? tableNumber;
  final int? tableCapacity;
  final String? branchName;
  final List<CartItem> items;
  final double total;

  Cart({
    required this.id,
    required this.userId,
    required this.branchId,
    required this.sessionId,
    required this.orderType,
    this.tableId,
    this.reservationDate,
    this.reservationTime,
    this.guestCount,
    required this.status,
    required this.expiresAt,
    this.specialRequests,
    required this.createdAt,
    required this.updatedAt,
    this.tableNumber,
    this.tableCapacity,
    this.branchName,
    required this.items,
    required this.total,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'],
      userId: json['user_id'],
      branchId: json['branch_id'],
      sessionId: json['session_id'],
      orderType: json['order_type'],
      tableId: json['table_id'],
      reservationDate: json['reservation_date'],
      reservationTime: json['reservation_time'],
      guestCount: json['guest_count'],
      status: json['status'],
      expiresAt: DateTime.parse(json['expires_at']),
      specialRequests: json['special_requests'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      tableNumber: json['table_number'],
      tableCapacity: json['capacity'],
      branchName: json['branch_name'],
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => CartItem.fromJson(item))
          .toList() ?? [],
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'branch_id': branchId,
      'session_id': sessionId,
      'order_type': orderType,
      'table_id': tableId,
      'reservation_date': reservationDate,
      'reservation_time': reservationTime,
      'guest_count': guestCount,
      'status': status,
      'expires_at': expiresAt.toIso8601String(),
      'special_requests': specialRequests,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'table_number': tableNumber,
      'capacity': tableCapacity,
      'branch_name': branchName,
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
    };
  }

  Cart copyWith({
    int? id,
    int? userId,
    int? branchId,
    String? sessionId,
    String? orderType,
    int? tableId,
    String? reservationDate,
    String? reservationTime,
    int? guestCount,
    String? status,
    DateTime? expiresAt,
    String? specialRequests,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? tableNumber,
    int? tableCapacity,
    String? branchName,
    List<CartItem>? items,
    double? total,
  }) {
    return Cart(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      branchId: branchId ?? this.branchId,
      sessionId: sessionId ?? this.sessionId,
      orderType: orderType ?? this.orderType,
      tableId: tableId ?? this.tableId,
      reservationDate: reservationDate ?? this.reservationDate,
      reservationTime: reservationTime ?? this.reservationTime,
      guestCount: guestCount ?? this.guestCount,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      specialRequests: specialRequests ?? this.specialRequests,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tableNumber: tableNumber ?? this.tableNumber,
      tableCapacity: tableCapacity ?? this.tableCapacity,
      branchName: branchName ?? this.branchName,
      items: items ?? this.items,
      total: total ?? this.total,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isEmpty => items.isEmpty;
  bool get hasTableReservation => tableId != null;
  bool get isDineIn => orderType == 'dine_in';
  bool get isTakeaway => orderType == 'takeaway';
  bool get isDelivery => orderType == 'delivery';
}
