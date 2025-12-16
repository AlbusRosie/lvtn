import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/order.dart';
import '../models/reservation.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';

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
        return await getOrderById(orderId);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
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

  Future<bool> cancelOrder(int orderId, {required String token}) async {
    try {
      final url = '${ApiConstants.orders}/$orderId/cancel';
      print('[OrderService] 🚫 Cancelling order: orderId=$orderId, url=$url');
      
      final response = await _dio.put(
        url,
        options: Options(
          headers: ApiConstants.authHeaders(token),
        ),
      );

      print('[OrderService] ✅ Response status: ${response.statusCode}');
      print('[OrderService] ✅ Response data: ${response.data}');

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return true;
      } else {
        throw Exception('Failed to cancel order: ${response.data['message'] ?? 'Unknown error'}');
      }
    } on DioException catch (e) {
      print('[OrderService] ❌ DioException: ${e.type}');
      print('[OrderService] ❌ Response: ${e.response?.data}');
      print('[OrderService] ❌ Status code: ${e.response?.statusCode}');
      
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          final errorMessage = errorData['message'] ?? 
                              errorData['error'] ?? 
                              'Failed to cancel order';
          throw Exception(errorMessage);
        } else {
          throw Exception('Server error: ${e.response?.statusCode}');
        }
      } else {
        throw Exception('Network error: ${e.message ?? 'Unknown network error'}');
      }
    } catch (e) {
      print('[OrderService] ❌ Exception: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Unexpected error: $e');
    }
  }

  Future<bool> cancelReservation(int reservationId, {required String token}) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.reservations}/$reservationId',
        data: {
          'status': 'cancelled',
        },
        options: Options(
          headers: ApiConstants.authHeaders(token),
        ),
      );

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

  Future<List<Order>> getDeliveryOrders({required String token, String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) {
        queryParams['status'] = status;
      }
      
      final response = await _dio.get(
        '/delivery/orders',
        queryParameters: queryParams.isEmpty ? null : queryParams,
        options: Options(
          headers: ApiConstants.authHeaders(token),
        ),
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final List<dynamic> ordersData = response.data['data'] ?? [];
        return ordersData.map((json) => Order.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load delivery orders: ${response.data['message']}');
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

  Future<bool> updateOrderStatus({
    required int orderId,
    required String status,
    required String token,
  }) async {
    try {
      final response = await _dio.put(
        '/delivery/orders/$orderId/status',
        data: {
          'status': status,
        },
        options: Options(
          headers: ApiConstants.authHeaders(token),
        ),
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return true;
      } else {
        throw Exception('Failed to update order status: ${response.data['message']}');
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
