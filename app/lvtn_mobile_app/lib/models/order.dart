class Order {
  final int id;
  final int userId;
  final int branchId;
  final int? tableId;
  final String orderType;
  final double total;
  final String status;
  final String paymentStatus;
  final String? paymentMethod;
  final String? deliveryAddress;
  final String? deliveryPhone;
  final String? notes;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.userId,
    required this.branchId,
    this.tableId,
    required this.orderType,
    required this.total,
    required this.status,
    required this.paymentStatus,
    this.paymentMethod,
    this.deliveryAddress,
    this.deliveryPhone,
    this.notes,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      branchId: json['branch_id'],
      tableId: json['table_id'],
      orderType: json['order_type'],
      total: json['total'].toDouble(),
      status: json['status'],
      paymentStatus: json['payment_status'],
      paymentMethod: json['payment_method'],
      deliveryAddress: json['delivery_address'],
      deliveryPhone: json['delivery_phone'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'branch_id': branchId,
      'table_id': tableId,
      'order_type': orderType,
      'total': total,
      'status': status,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'delivery_address': deliveryAddress,
      'delivery_phone': deliveryPhone,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
