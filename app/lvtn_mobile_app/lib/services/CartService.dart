import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/cart.dart';
import '../models/product_option.dart';
import '../services/StorageService.dart';

class CartService {
  static const String _storageKey = 'cart_session_id';


  static Future<String?> _getSessionId() async {
    final storage = StorageService();
    final sessionId = await storage.getString(_storageKey);
    return sessionId;
  }


  static Future<void> _setSessionId(String sessionId) async {
    final storage = StorageService();
    await storage.setString(_storageKey, sessionId);
  }


  static String _generateSessionId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }


  static Future<Cart> addToCart({
    required String token,
    required int branchId,
    required int productId,
    int quantity = 1,
    String orderType = 'dine_in',
    String? sessionId,
    List<SelectedOption>? selectedOptions,
    String? specialInstructions,
  }) async {
    try {
      final storedSessionId = await _getSessionId();
      final currentSessionId = sessionId ?? storedSessionId ?? _generateSessionId();
      
      if (storedSessionId == null) {
        await _setSessionId(currentSessionId);
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.addToCart(branchId)}'),
        headers: ApiConstants.authHeaders(token),
        body: jsonEncode({
          'product_id': productId,
          'quantity': quantity,
          'order_type': orderType,
          'session_id': currentSessionId,
          'selected_options': selectedOptions?.map((o) => o.toJson()).toList() ?? [],
          'special_instructions': specialInstructions,
        }),
      );


      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final cart = Cart.fromJson(data['data']);
        
        await _setSessionId(cart.sessionId);
        
        return cart;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to add item to cart');
      }
    } catch (e) {
      throw Exception('Error adding item to cart: $e');
    }
  }


  static Future<Cart?> getUserCart({
    required String token,
    required int branchId,
    String? sessionId,
  }) async {
    try {
      final storedSessionId = await _getSessionId();
      String? currentSessionId = sessionId ?? storedSessionId;


      if (currentSessionId == null) {
        final newSessionId = _generateSessionId();
        await _setSessionId(newSessionId);
        currentSessionId = newSessionId;
      }

      final url = '${ApiConstants.baseUrl}${ApiConstants.getUserCart(branchId)}?session_id=$currentSessionId';

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConstants.authHeaders(token),
      );


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] == null) {
          return null;
        }
        return Cart.fromJson(data['data']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to get user cart');
      }
    } catch (e) {
      throw Exception('Error getting user cart: $e');
    }
  }


  static Future<Cart> getCart({
    required String token,
    required int cartId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getCart(cartId)}'),
        headers: ApiConstants.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Cart.fromJson(data['data']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to get cart');
      }
    } catch (e) {
      throw Exception('Error getting cart: $e');
    }
  }


  static Future<Cart> updateCartItemQuantity({
    required String token,
    required int cartId,
    required int productId,
    required int quantity,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateCartItemQuantity(cartId, productId)}'),
        headers: ApiConstants.authHeaders(token),
        body: jsonEncode({'quantity': quantity}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Cart.fromJson(data['data']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to update cart item quantity');
      }
    } catch (e) {
      throw Exception('Error updating cart item quantity: $e');
    }
  }


  static Future<Cart> removeFromCart({
    required String token,
    required int cartId,
    required int productId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.removeFromCart(cartId, productId)}'),
        headers: ApiConstants.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Cart.fromJson(data['data']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to remove item from cart');
      }
    } catch (e) {
      throw Exception('Error removing item from cart: $e');
    }
  }


  static Future<Cart> reserveTable({
    required String token,
    required int cartId,
    required int tableId,
    required String reservationDate,
    required String reservationTime,
    required int guestCount,
    String? note,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reserveTable(cartId)}'),
        headers: ApiConstants.authHeaders(token),
        body: jsonEncode({
          'table_id': tableId,
          'reservation_date': reservationDate,
          'reservation_time': reservationTime,
          'guest_count': guestCount,
          if (note != null && note.isNotEmpty) 'note': note,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Cart.fromJson(data['data']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to reserve table');
      }
    } catch (e) {
      throw Exception('Error reserving table: $e');
    }
  }


  static Future<Cart> cancelTableReservation({
    required String token,
    required int cartId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cancelReservation(cartId)}'),
        headers: ApiConstants.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Cart.fromJson(data['data']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to cancel table reservation');
      }
    } catch (e) {
      throw Exception('Error canceling table reservation: $e');
    }
  }


  static Future<Map<String, dynamic>> checkout({
    required String token,
    required int cartId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.checkout(cartId)}'),
        headers: ApiConstants.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to checkout cart');
      }
    } catch (e) {
      throw Exception('Error checking out cart: $e');
    }
  }


  static Future<void> clearCart({
    required String token,
    required int cartId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.clearCart(cartId)}'),
        headers: ApiConstants.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final storage = StorageService();
        await storage.remove(_storageKey);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to clear cart');
      }
    } catch (e) {
      throw Exception('Error clearing cart: $e');
    }
  }


  static Future<Cart> updateCartItemOptions({
    required String token,
    required int cartId,
    required int productId,
    required List<SelectedOption> selectedOptions,
    String? specialInstructions,
  }) async {
    try {

      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/cart/$cartId/items/$productId/options'),
        headers: ApiConstants.authHeaders(token),
        body: jsonEncode({
          'selected_options': selectedOptions.map((o) => o.toJson()).toList(),
          if (specialInstructions != null) 'special_instructions': specialInstructions,
        }),
      );


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final cart = Cart.fromJson(data['data']);
        return cart;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to update cart item options');
      }
    } catch (e) {
      throw Exception('Error updating cart item options: $e');
    }
  }


  static Future<void> clearSession() async {
    final storage = StorageService();
    await storage.remove(_storageKey);
  }
}
