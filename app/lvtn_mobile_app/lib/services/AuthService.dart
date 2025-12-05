import 'dart:convert';
import '../models/user.dart';
import '../constants/app_constants.dart';
import '../constants/api_constants.dart';
import 'APIService.dart';
import 'StorageService.dart';

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
      print('AuthService: Bắt đầu đăng nhập với username: $username');
      
      final response = await ApiService().post(ApiConstants.login, {
        'username': username,
        'password': password,
      });

      print('AuthService: Response từ API: $response');
      print('AuthService: Response type: ${response.runtimeType}');

      if (response == null) {
        print('AuthService: Response là null');
        throw Exception('Không nhận được phản hồi từ server');
      }

      if (response is! Map) {
        print('AuthService: Response không phải là Map, type: ${response.runtimeType}');
        throw Exception('Dữ liệu phản hồi không hợp lệ: không phải object');
      }

      print('AuthService: Response keys: ${(response as Map).keys.toList()}');
      
      if (response['token'] == null || response['user'] == null) {
        print('AuthService: Response không hợp lệ - token: ${response['token'] != null}, user: ${response['user'] != null}');
        print('AuthService: Full response: $response');
        throw Exception('Dữ liệu phản hồi không hợp lệ: thiếu token hoặc user');
      }

      _token = response['token'];
      print('AuthService: Nhận được token: ${_token!.substring(0, _token!.length > 20 ? 20 : _token!.length)}...');
      
      print('AuthService: User data từ API: ${response['user']}');
      
      final userData = response['user'];
      if (userData == null || userData is! Map) {
        print('AuthService: User data không hợp lệ từ API');
        throw Exception('Dữ liệu user không hợp lệ');
      }
      
      _currentUser = User.fromJson(Map<String, dynamic>.from(userData));
      print('AuthService: Đã parse user - ID: ${_currentUser!.id}, Username: ${_currentUser!.username}, Name: ${_currentUser!.name}, Email: ${_currentUser!.email}');
      
      if (_currentUser!.id <= 0 || (_currentUser!.username.isEmpty && _currentUser!.email.isEmpty)) {
        print('AuthService: User không hợp lệ sau khi parse - ID: ${_currentUser!.id}, Username: ${_currentUser!.username}, Email: ${_currentUser!.email}');
        throw Exception('Thông tin user không hợp lệ');
      }
      
      final storageService = StorageService();
      await storageService.ensureInitialized();
      
      await storageService.setString(AppConstants.authTokenKey, _token!);
      final userJson = jsonEncode(_currentUser!.toJson());
      await storageService.setString(AppConstants.userDataKey, userJson);
      
      final savedToken = await storageService.getString(AppConstants.authTokenKey);
      final savedUserData = await storageService.getString(AppConstants.userDataKey);
      print('AuthService: Đã lưu token và user data vào storage');
      print('AuthService: Verify - savedToken: ${savedToken != null ? "có" : "không"}, savedUserData: ${savedUserData != null ? "có" : "không"}');
      print('AuthService: User ID: ${_currentUser!.id}, Username: ${_currentUser!.username}, Name: ${_currentUser!.name}');
      
      ApiService().setAuthToken(_token!);
      
      return _currentUser!;
    } catch (error) {
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
        'role_id': AppConstants.customerRole,
      });

      if (response == null) {
        throw Exception('Không nhận được phản hồi từ server');
      }

      if (response['user'] == null) {
        throw Exception('Dữ liệu phản hồi không hợp lệ');
      }

      return await login(username, password);
    } catch (error) {
      throw Exception('Đăng ký thất bại: ${error.toString()}');
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _token = null;
    
    final storageService = StorageService();
    await storageService.ensureInitialized();
    
    await storageService.remove(AppConstants.authTokenKey);
    await storageService.remove(AppConstants.userDataKey);
    ApiService().clearAuthToken();
    
    print('AuthService: Đã xóa token và user data khỏi storage');
  }

  Future<bool> tryAutoLogin() async {
    try {
      final storageService = StorageService();
      await storageService.ensureInitialized();
      
      final token = await storageService.getString(AppConstants.authTokenKey);
      final userData = await storageService.getString(AppConstants.userDataKey);
      
      print('AuthService: tryAutoLogin - token: ${token != null ? "có" : "không"}, userData: ${userData != null ? "có" : "không"}');
      
      if (token != null && userData != null) {
        _token = token;
        print('AuthService: userData từ storage: $userData');
        try {
          final userJson = jsonDecode(userData);
          print('AuthService: userJson parsed: $userJson');
          if (userJson is Map) {
            _currentUser = User.fromJson(Map<String, dynamic>.from(userJson));
          } else {
            throw Exception('User data không phải là object');
          }
          print('AuthService: Đã load user từ storage - ID: ${_currentUser!.id}, Username: ${_currentUser!.username}, Name: ${_currentUser!.name}, Email: ${_currentUser!.email}');
          
          if (_currentUser!.id <= 0 || (_currentUser!.username.isEmpty && _currentUser!.email.isEmpty)) {
            print('AuthService: User không hợp lệ - ID: ${_currentUser!.id}, Username: ${_currentUser!.username}, Email: ${_currentUser!.email}');
            await logout();
            return false;
          }
          
          ApiService().setAuthToken(_token!);
          return true;
        } catch (e) {
          print('AuthService: Lỗi khi parse userData: $e');
          await logout();
          return false;
        }
      } else {
        print('AuthService: Không tìm thấy token hoặc userData trong storage');
      }
    } catch (error) {
      print('AuthService: Lỗi khi tryAutoLogin: $error');
      await logout();
    }
    
    return false;
  }

  Future<void> updateCurrentUser(User user) async {
    _currentUser = user;
    
    final storageService = StorageService();
    await storageService.ensureInitialized();
    
    await storageService.setString(AppConstants.userDataKey, jsonEncode(user.toJson()));
    print('AuthService: Đã cập nhật user data trong storage');
  }
}
