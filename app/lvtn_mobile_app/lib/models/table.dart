class Table {
  final int id;
  final int branchId;
  final int floorId;
  final String tableNumber;
  final int capacity;
  final String status;
  final String? location;
  final int? positionX;
  final int? positionY;
  final DateTime createdAt;

  Table({
    required this.id,
    required this.branchId,
    required this.floorId,
    required this.tableNumber,
    required this.capacity,
    required this.status,
    this.location,
    this.positionX,
    this.positionY,
    required this.createdAt,
  });

  factory Table.fromJson(Map<String, dynamic> json) {
    return Table(
      id: json['id'],
      branchId: json['branch_id'],
      floorId: json['floor_id'],
      tableNumber: json['table_number'],
      capacity: json['capacity'],
      status: json['status'],
      location: json['location'],
      positionX: json['position_x'],
      positionY: json['position_y'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'branch_id': branchId,
      'floor_id': floorId,
      'table_number': tableNumber,
      'capacity': capacity,
      'status': status,
      'location': location,
      'position_x': positionX,
      'position_y': positionY,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
