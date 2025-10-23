import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ReservationService {
  static String get _baseUrl => ApiConstants.baseUrl;


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
        return [];
      }
    } catch (e) {
      return [];
    }
  }


  static Future<List<Map<String, dynamic>>> getReservationsByDateRange({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final url = '$_baseUrl/reservations?start_date=$startDate&end_date=$endDate';
      
      final response = await http.get(
        Uri.parse(url),
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
        return [];
      }
    } catch (e) {
      return [];
    }
  }


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
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Quick Reservation - Backend will auto-assign suitable table
  Future<Map<String, dynamic>?> createQuickReservation({
    required String token,
    required int branchId,
    required String reservationDate,
    required String reservationTime,
    required int guestCount,
    String? specialRequests,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reservations/quick'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'branch_id': branchId,
          'reservation_date': reservationDate,
          'reservation_time': reservationTime,
          'guest_count': guestCount,
          'special_requests': specialRequests,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data'] ?? data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to create reservation');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }


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
      

      final reservationHour = int.parse(reservationTime!.split(':')[0]);
      final slotStartHour = int.parse(startTime.split(':')[0]);
      final slotEndHour = int.parse(endTime.split(':')[0]);
      

      return reservationHour >= slotStartHour && reservationHour < slotEndHour;
    });
  }


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


  static List<Map<String, dynamic>> mergeTimeSlots({
    required List<String> timeSlots,
    required List<Map<String, dynamic>> reservations,
    required String date,
  }) {
    final mergedSlots = <Map<String, dynamic>>[];
    

    final slotStatuses = <String, String>{};
    for (final timeSlot in timeSlots) {
      final isReserved = isSlotReserved(
        reservations: reservations,
        date: date,
        timeSlot: timeSlot,
      );
      slotStatuses[timeSlot] = isReserved ? 'reserved' : 'available';
    }
    

    for (int i = 0; i < timeSlots.length; i++) {
      final timeSlot = timeSlots[i];
      final status = slotStatuses[timeSlot]!;
      final startTime = timeSlot.split('-')[0];
      final endTime = timeSlot.split('-')[1];
      
      if (status == 'available') {

        if (mergedSlots.isNotEmpty && 
            mergedSlots.last['status'] == 'available' &&
            mergedSlots.last['end'] == startTime) {

          mergedSlots.last['end'] = endTime;
          mergedSlots.last['time'] = '${mergedSlots.last['start']}-$endTime';
        } else {

          mergedSlots.add({
            'time': timeSlot,
            'status': status,
            'start': startTime,
            'end': endTime,
            'date': date,
          });
        }
      } else {

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
