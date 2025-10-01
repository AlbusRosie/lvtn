import 'dart:io';

class ApiConstants {
  static String get baseUrl {
    if (Platform.isAndroid) {
      //IP LAN máy chạy backend
      return 'http://192.168.1.22:3000/api';
    }
    if (Platform.isIOS) {
      return 'http://127.0.0.1:3000/api';
    }
    return 'http://127.0.0.1:3000/api';
  }
  
  static const String login = '/users/login';
  static const String register = '/users/register';
  static const String users = '/users';
  
  static const String branches = '/branches';
  static const String activeBranches = '/branches/active';
  
  static const String products = '/products';
  static const String categories = '/categories';
  
  static const String tables = '/tables';
  static const String floors = '/floors';
  
  static const String provinces = '/provinces';
  static const String districts = '/provinces';
  
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
  };
  
  static Map<String, String> authHeaders(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
}
