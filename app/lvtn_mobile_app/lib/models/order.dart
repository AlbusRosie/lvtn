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
  final int? tableIdDisplay;
  final int? itemsCount;
  final List<OrderDetail>? items;
  final String? customerName;
  final String? customerPhone;
  final String? tableName;

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
    this.tableIdDisplay,
    this.itemsCount,
    this.items,
    this.customerName,
    this.customerPhone,
    this.tableName,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // table_id có thể đến từ reservation join trong API response
    // Nếu không có, sẽ là null
    final tableId = json['table_id'] ?? json['reservation']?['table_id'];
    return Order(
      id: json['id'],
      userId: json['user_id'],
      branchId: json['branch_id'],
      tableId: tableId,
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
      tableIdDisplay: tableId,
      itemsCount: json['items_count'],
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => OrderDetail.fromJson(item))
          .toList(),
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      tableName: json['table_name'],
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
      'table_id': tableIdDisplay,
      'items_count': itemsCount,
      'items': items?.map((item) => item.toJson()).toList(),
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'table_name': tableName,
    };
  }
}
