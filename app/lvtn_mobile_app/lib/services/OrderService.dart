import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/order.dart';
import '../models/reservation.dart';
import '../constants/api_constants.dart';

class OrderService {
  final Dio _dio = Dio();

  OrderService() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.connectTimeout = Duration(seconds: 10);
    _dio.options.receiveTimeout = Duration(seconds: 10);
  }

  Future<List<Order>> getUserOrders(int userId) async {
    try {
      final response = await _dio.get(
        ApiConstants.orders,
        queryParameters: {
          'user_id': userId,
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final List<dynamic> ordersData = response.data['data'];
        return ordersData.map((json) => Order.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load orders: ${response.data['message']}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Server error: ${e.response?.data['message'] ?? e.message}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<List<Reservation>> getUserReservations(int userId) async {
    try {
      final response = await _dio.get(
        ApiConstants.reservations,
        queryParameters: {
          'user_id': userId,
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        // ReservationRouter returns { "data": { "reservations": [...] } }
        final Map<String, dynamic> data = response.data['data'];
        final List<dynamic> reservationsData = data['reservations'];
        return reservationsData.map((json) => Reservation.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load reservations: ${response.data['message']}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Server error: ${e.response?.data['message'] ?? e.message}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<Order> getOrderById(int orderId) async {
    try {
      final response = await _dio.get('${ApiConstants.orders}/$orderId');

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return Order.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to load order: ${response.data['message']}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Server error: ${e.response?.data['message'] ?? e.message}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<Order> getOrderWithDetails(int orderId) async {
    try {
      final response = await _dio.get('${ApiConstants.orders}/$orderId/details');

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return Order.fromJson(response.data['data']);
      } else {
        // Fallback to basic order if details endpoint doesn't exist
        return await getOrderById(orderId);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Fallback to basic order if details endpoint doesn't exist
        return await getOrderById(orderId);
      } else if (e.response != null) {
        throw Exception('Server error: ${e.response?.data['message'] ?? e.message}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<Reservation> getReservationById(int reservationId) async {
    try {
      final response = await _dio.get('${ApiConstants.reservations}/$reservationId');

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return Reservation.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to load reservation: ${response.data['message']}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Server error: ${e.response?.data['message'] ?? e.message}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<bool> cancelOrder(int orderId) async {
    try {
      final response = await _dio.put('${ApiConstants.orders}/$orderId', data: {
        'status': 'cancelled',
      });

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return true;
      } else {
        throw Exception('Failed to cancel order: ${response.data['message']}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Server error: ${e.response?.data['message'] ?? e.message}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<bool> cancelReservation(int reservationId) async {
    try {
      final response = await _dio.put('${ApiConstants.reservations}/$reservationId', data: {
        'status': 'cancelled',
      });

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return true;
      } else {
        throw Exception('Failed to cancel reservation: ${response.data['message']}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Server error: ${e.response?.data['message'] ?? e.message}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<List<Order>> getOrdersByBranch(int branchId) async {
    try {
      final response = await _dio.get(
        ApiConstants.orders,
        queryParameters: {
          'branch_id': branchId,
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final List<dynamic> ordersData = response.data['data'];
        return ordersData.map((json) => Order.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load orders: ${response.data['message']}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Server error: ${e.response?.data['message'] ?? e.message}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<List<Reservation>> getReservationsByBranch(int branchId) async {
    try {
      final response = await _dio.get(
        ApiConstants.reservations,
        queryParameters: {
          'branch_id': branchId,
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        // ReservationRouter returns { "data": { "reservations": [...] } }
        final Map<String, dynamic> data = response.data['data'];
        final List<dynamic> reservationsData = data['reservations'];
        return reservationsData.map((json) => Reservation.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load reservations: ${response.data['message']}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Server error: ${e.response?.data['message'] ?? e.message}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
