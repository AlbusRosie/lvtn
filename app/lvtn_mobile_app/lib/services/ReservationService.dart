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
      final uri = Uri.parse('$_baseUrl/reservations/table/$tableId/schedule')
          .replace(queryParameters: {
        'start_date': startDate,
        'end_date': endDate,
      });
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('ReservationService.getTableSchedule: tableId=$tableId, startDate=$startDate, endDate=$endDate');
      print('ReservationService.getTableSchedule: statusCode=${response.statusCode}');
      print('ReservationService.getTableSchedule: response=${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        List<dynamic>? reservations;
        if (data is Map) {
          if (data['data'] != null && data['data'] is Map) {
            reservations = data['data']['reservations'];
          } else if (data['reservations'] != null) {
            reservations = data['reservations'];
          } else if (data['data'] is List) {
            reservations = data['data'];
          }
        }
        
        final result = List<Map<String, dynamic>>.from(
          reservations is List ? reservations : []
        );
        print('ReservationService.getTableSchedule: found ${result.length} items (reservations/schedules/orders)');
        if (result.isNotEmpty) {
          print('ReservationService.getTableSchedule: first item keys=${result[0].keys.toList()}');
        }
        return result;
      } else {
        print('ReservationService.getTableSchedule: Error status ${response.statusCode}, body=${response.body}');
        return [];
      }
    } catch (e) {
      print('ReservationService.getTableSchedule: Exception $e');
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
    String? token,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final requestBody = {
        'user_id': userId,
        'branch_id': branchId,
        'table_id': tableId,
        'reservation_date': reservationDate,
        'reservation_time': reservationTime,
        'guest_count': guestCount,
        'special_requests': specialRequests,
      };
      
      print('ReservationService.createReservation: Request body: $requestBody');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/reservations'),
        headers: headers,
        body: json.encode(requestBody),
      );

      print('ReservationService.createReservation: Status code: ${response.statusCode}');
      print('ReservationService.createReservation: Response body: ${response.body}');

      print('ReservationService.createReservation: Response status: ${response.statusCode}');
      print('ReservationService.createReservation: Response body: ${response.body}');
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        print('ReservationService.createReservation: Parsed data: $data');
        
        // API trả về { status: 'success', data: {...reservation...}, message: '...' }
        if (data is Map) {
          if (data['data'] != null) {
            // data['data'] chính là reservation object
            final reservation = Map<String, dynamic>.from(data['data']);
            print('ReservationService.createReservation: ✅ Reservation parsed: $reservation');
            if (reservation['id'] == null) {
              print('ReservationService.createReservation: ⚠️ Reservation không có ID!');
              throw Exception('Reservation được tạo nhưng không có ID');
            }
            return reservation;
          } else if (data['reservation'] != null) {
            final reservation = Map<String, dynamic>.from(data['reservation']);
            print('ReservationService.createReservation: ✅ Reservation parsed (alt path): $reservation');
            return reservation;
          }
        }
        print('ReservationService.createReservation: ⚠️ Unexpected response structure: $data');
        throw Exception('Unexpected response structure from server');
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? errorData['error'] ?? 'Failed to create reservation';
        print('ReservationService.createReservation: ❌ Error - $errorMessage');
        print('ReservationService.createReservation: Error data: $errorData');
        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      print('ReservationService.createReservation: ❌ Exception - $e');
      print('ReservationService.createReservation: Stack trace: $stackTrace');
      rethrow;
    }
  }

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

  static Future<List<Map<String, dynamic>>> getOverdueReservations({
    int minutes = 30,
    String? token,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/reservations/overdue?minutes=$minutes'),
        headers: headers,
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

  static Future<List<Map<String, dynamic>>> getReservationsNeedingWarning({
    String? token,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/reservations/warning'),
        headers: headers,
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
}
