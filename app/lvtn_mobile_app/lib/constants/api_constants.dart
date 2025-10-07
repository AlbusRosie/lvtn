import '../config/env.dart';

class ApiConstants {
  static String get baseUrl => Environment.baseUrl;
  
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
  
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
  };
  
  static Map<String, String> authHeaders(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
}
