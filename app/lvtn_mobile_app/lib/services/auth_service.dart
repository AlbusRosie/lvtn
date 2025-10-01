import 'dart:convert';
import '../models/user.dart';
import '../constants/app_constants.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  String? _token;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _currentUser != null;

  Future<User> login(String username, String password) async {
    try {
      final response = await ApiService().post(ApiConstants.login, {
        'username': username,
        'password': password,
      });

      print('Login response: $response'); // Debug log
      
      _token = response['token'];
      _currentUser = User.fromJson(response['user']);
      
      // Save to storage
      await StorageService().setString(AppConstants.authTokenKey, _token!);
      await StorageService().setString(AppConstants.userDataKey, 
        jsonEncode(_currentUser!.toJson()));
      
      // Set token for API calls
      ApiService().setAuthToken(_token!);
      
      return _currentUser!;
    } catch (error) {
      print('Login error: $error'); // Debug log
      throw Exception('Đăng nhập thất bại: ${error.toString()}');
    }
  }

  Future<User> register({
    required String username,
    required String password,
    required String email,
    required String name,
    String? phone,
    String? address,
  }) async {
    try {
      final response = await ApiService().post(ApiConstants.register, {
        'username': username,
        'password': password,
        'email': email,
        'name': name,
        'phone': phone,
        'address': address,
        'role_id': AppConstants.customerRole, // Always customer for mobile app
      });

      print('Register response: $response'); // Debug log
      
      // Register only returns user, no token
      // User needs to login after registration to get token
      _currentUser = User.fromJson(response['data']['user']);
      
      // Auto-login after successful registration
      return await login(username, password);
    } catch (error) {
      throw Exception('Đăng ký thất bại: ${error.toString()}');
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _token = null;
    
    // Clear storage
    await StorageService().remove(AppConstants.authTokenKey);
    await StorageService().remove(AppConstants.userDataKey);
    
    // Clear API token
    ApiService().clearAuthToken();
  }

  Future<bool> tryAutoLogin() async {
    try {
      final token = await StorageService().getString(AppConstants.authTokenKey);
      final userData = await StorageService().getString(AppConstants.userDataKey);
      
      if (token != null && userData != null) {
        _token = token;
        _currentUser = User.fromJson(jsonDecode(userData));
        
        // Set token for API calls
        ApiService().setAuthToken(_token!);
        
        return true;
      }
    } catch (error) {
      // Clear invalid data
      await logout();
    }
    
    return false;
  }
}
