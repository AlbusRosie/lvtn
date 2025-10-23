import 'package:flutter/material.dart';

class Reservation {
  final int id;
  final int userId;
  final int branchId;
  final int tableId;
  final DateTime reservationDate;
  final TimeOfDay reservationTime;
  final int guestCount;
  final String status;
  final String? specialRequests;
  final DateTime createdAt;
  final String? branchName;
  final String? tableNumber;

  Reservation({
    required this.id,
    required this.userId,
    required this.branchId,
    required this.tableId,
    required this.reservationDate,
    required this.reservationTime,
    required this.guestCount,
    required this.status,
    this.specialRequests,
    required this.createdAt,
    this.branchName,
    this.tableNumber,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    // Parse time from string format "HH:MM"
    final timeString = json['reservation_time'] as String;
    final timeParts = timeString.split(':');
    final time = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    return Reservation(
      id: json['id'],
      userId: json['user_id'],
      branchId: json['branch_id'],
      tableId: json['table_id'],
      reservationDate: DateTime.parse(json['reservation_date']),
      reservationTime: time,
      guestCount: json['guest_count'],
      status: json['status'],
      specialRequests: json['special_requests'],
      createdAt: DateTime.parse(json['created_at']),
      branchName: json['branch_name'],
      tableNumber: json['table_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'branch_id': branchId,
      'table_id': tableId,
      'reservation_date': reservationDate.toIso8601String().split('T')[0],
      'reservation_time': '${reservationTime.hour.toString().padLeft(2, '0')}:${reservationTime.minute.toString().padLeft(2, '0')}',
      'guest_count': guestCount,
      'status': status,
      'special_requests': specialRequests,
      'created_at': createdAt.toIso8601String(),
      'branch_name': branchName,
      'table_number': tableNumber,
    };
  }
}
