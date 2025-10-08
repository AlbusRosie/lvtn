import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ReservationService {
  static String get _baseUrl => ApiConstants.baseUrl;

  // Lấy lịch đặt bàn theo bàn và ngày
  static Future<List<Map<String, dynamic>>> getTableSchedule({
    required int tableId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/reservations/table/$tableId/schedule'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final reservations = (data is Map && data['data'] != null)
            ? data['data']['reservations']
            : data['reservations'];
        return List<Map<String, dynamic>>.from(reservations ?? []);
      } else {
        print('❌ Error fetching table schedule: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Exception fetching table schedule: $e');
      return [];
    }
  }

  // Lấy tất cả reservations trong khoảng thời gian
  static Future<List<Map<String, dynamic>>> getReservationsByDateRange({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final url = '$_baseUrl/reservations?start_date=$startDate&end_date=$endDate';
      print('🔍 Debug - API URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('🔍 Debug - Response status: ${response.statusCode}');
      print('🔍 Debug - Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final reservations = (data is Map && data['data'] != null)
            ? data['data']['reservations']
            : data['reservations'];
        return List<Map<String, dynamic>>.from(reservations ?? []);
      } else {
        print('❌ Error fetching reservations: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Exception fetching reservations: $e');
      return [];
    }
  }

  // Tạo reservation mới
  static Future<Map<String, dynamic>?> createReservation({
    required int userId,
    required int branchId,
    required int tableId,
    required String reservationDate,
    required String reservationTime,
    required int guestCount,
    String? specialRequests,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reservations'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': userId,
          'branch_id': branchId,
          'table_id': tableId,
          'reservation_date': reservationDate,
          'reservation_time': reservationTime,
          'guest_count': guestCount,
          'special_requests': specialRequests,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['reservation'];
      } else {
        print('❌ Error creating reservation: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Exception creating reservation: $e');
      return null;
    }
  }

  // Kiểm tra xem slot có bận không
  static bool isSlotReserved({
    required List<Map<String, dynamic>> reservations,
    required String date,
    required String timeSlot,
  }) {
    final startTime = timeSlot.split('-')[0];
    final endTime = timeSlot.split('-')[1];
    
    return reservations.any((reservation) {
      final reservationDate = reservation['reservation_date']?.toString();
      final reservationTime = reservation['reservation_time']?.toString();
      final status = reservation['status']?.toString();
      
      // Extract date part from reservation_date (handle both "2025-10-09" and "2025-10-09T17:00:00.000Z" formats)
      String reservationDateOnly;
      if (reservationDate != null) {
        if (reservationDate.contains('T')) {
          reservationDateOnly = reservationDate.split('T')[0];
        } else {
          reservationDateOnly = reservationDate;
        }
      } else {
        reservationDateOnly = '';
      }
      
      if (reservationDateOnly != date || status == 'cancelled') {
        return false;
      }
      
      // Parse reservation time (HH:MM:SS format)
      final reservationHour = int.parse(reservationTime!.split(':')[0]);
      final slotStartHour = int.parse(startTime.split(':')[0]);
      final slotEndHour = int.parse(endTime.split(':')[0]);
      
      // Check if reservation time overlaps with slot
      return reservationHour >= slotStartHour && reservationHour < slotEndHour;
    });
  }

  // Tạo time slots từ 7h đến 22h
  static List<String> generateTimeSlots() {
    final slots = <String>[];
    for (int hour = 7; hour < 22; hour += 2) {
      final startHour = hour;
      final endHour = hour + 2;
      final timeSlot = '${startHour.toString().padLeft(2,'0')}:00-${endHour.toString().padLeft(2,'0')}:00';
      slots.add(timeSlot);
    }
    return slots;
  }

  // Merge consecutive available slots (only merge available, not reserved)
  static List<Map<String, dynamic>> mergeTimeSlots({
    required List<String> timeSlots,
    required List<Map<String, dynamic>> reservations,
    required String date,
  }) {
    final mergedSlots = <Map<String, dynamic>>[];
    
    // Check status for each slot
    final slotStatuses = <String, String>{};
    for (final timeSlot in timeSlots) {
      final isReserved = isSlotReserved(
        reservations: reservations,
        date: date,
        timeSlot: timeSlot,
      );
      slotStatuses[timeSlot] = isReserved ? 'reserved' : 'available';
    }
    
    // Process each slot individually
    for (int i = 0; i < timeSlots.length; i++) {
      final timeSlot = timeSlots[i];
      final status = slotStatuses[timeSlot]!;
      final startTime = timeSlot.split('-')[0];
      final endTime = timeSlot.split('-')[1];
      
      if (status == 'available') {
        // For available slots, try to merge with previous available slot
        if (mergedSlots.isNotEmpty && 
            mergedSlots.last['status'] == 'available' &&
            mergedSlots.last['end'] == startTime) {
          // Merge with previous available slot
          mergedSlots.last['end'] = endTime;
          mergedSlots.last['time'] = '${mergedSlots.last['start']}-$endTime';
        } else {
          // Add new available slot
          mergedSlots.add({
            'time': timeSlot,
            'status': status,
            'start': startTime,
            'end': endTime,
            'date': date,
          });
        }
      } else {
        // For reserved slots, always add individually (no merging)
        mergedSlots.add({
          'time': timeSlot,
          'status': status,
          'start': startTime,
          'end': endTime,
          'date': date,
        });
      }
    }
    
    return mergedSlots;
  }
}
