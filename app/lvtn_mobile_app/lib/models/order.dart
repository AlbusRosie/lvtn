import 'order_detail.dart';

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
  final String? branchName;
  final String? branchImage;
  final String? tableNumber;
  final int? itemsCount;
  final List<OrderDetail>? items;

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
    this.branchName,
    this.branchImage,
    this.tableNumber,
    this.itemsCount,
    this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      branchId: json['branch_id'],
      tableId: json['table_id'],
      orderType: json['order_type'],
      total: double.parse(json['total'].toString()),
      status: json['status'],
      paymentStatus: json['payment_status'],
      paymentMethod: json['payment_method'],
      deliveryAddress: json['delivery_address'],
      deliveryPhone: json['delivery_phone'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      branchName: json['branch_name'],
      branchImage: json['branch_image'],
      tableNumber: json['table_number'],
      itemsCount: json['items_count'],
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => OrderDetail.fromJson(item))
          .toList(),
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
      'branch_name': branchName,
      'branch_image': branchImage,
      'table_number': tableNumber,
      'items_count': itemsCount,
      'items': items?.map((item) => item.toJson()).toList(),
    };
  }
}
