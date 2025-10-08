import '../config/env.dart';

class ApiConstants {
  static String get baseUrl => Environment.baseUrl;
  // Base origin for static files (e.g., images)
  static String get fileBaseUrl {
    final url = Environment.baseUrl;
    if (url.endsWith('/api')) {
      return url.substring(0, url.length - 4);
    }
    return url;
  }
  
  static const String login = '/users/login/customer';
  static const String register = '/users/register';
  static const String users = '/users';
  
  static const String branches = '/branches';
  static const String activeBranches = '/branches/active';
  
  static const String products = '/products';
  static const String categories = '/categories';
  
  static const String tables = '/tables';
  static const String floors = '/floors';
  
  static const String provinces = '/provinces';
  static const String districts = '/districts';
  
  // Cart API endpoints
  static const String cart = '/cart';
  static String addToCart(int branchId) => '/cart/branches/$branchId/add-item';
  static String getUserCart(int branchId) => '/cart/branches/$branchId/user-cart';
  static String getCart(int cartId) => '/cart/$cartId';
  static String updateCartItemQuantity(int cartId, int productId) => '/cart/$cartId/items/$productId/quantity';
  static String removeFromCart(int cartId, int productId) => '/cart/$cartId/items/$productId';
  static String reserveTable(int cartId) => '/cart/$cartId/reserve-table';
  static String cancelReservation(int cartId) => '/cart/$cartId/cancel-reservation';
  static String checkout(int cartId) => '/cart/$cartId/checkout';
  static String clearCart(int cartId) => '/cart/$cartId/clear';
  
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
  };
  
  static Map<String, String> authHeaders(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
}
