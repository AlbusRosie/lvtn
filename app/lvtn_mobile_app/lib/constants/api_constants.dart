class ApiConstants {
  // Base URL - thay đổi theo môi trường
  // static const String baseUrl = 'http://localhost:3000/api'; // Cho web
  // static const String baseUrl = 'http://10.0.2.2:3000/api'; // Cho Android emulator
  static const String baseUrl = 'http://192.168.1.61:3000/api'; // Cho device thật
  
  // Endpoints
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
  
  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
  };
  
  static Map<String, String> authHeaders(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
}
