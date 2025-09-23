import '../models/user.dart';
import '../constants/app_constants.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
    static final AuthService _instance = AuthService._internal();
    factory AuthService() => _instance;
    AuthService._internal();

    final ApiService _apiService = ApiService();
    final StorageService _storageService = StorageService();

    User? _currentUser;

    User? get currentUser => _currentUser;

    bool get isLoggedIn => _currentUser != null;

    Future<void> initialize() async {
        final token = await _storageService.getAuthToken();
        final userData = await _storageService.getUserData();
        
        if (token != null && userData != null) {
        _apiService.setAuthToken(token);
        _currentUser = User.fromJson(userData);
        }
    }

    Future<Map<String, dynamic>> login(String username, String password) async {
        try {
        print('Attempting login with username: $username');
        final response = await _apiService.post(ApiConstants.login, {
            'username': username,
            'password': password,
        });

        print('Login response: $response');
        final token = response['token'];
        final userData = response['user'];

        if (token != null && userData != null) {
            _apiService.setAuthToken(token);
            _currentUser = User.fromJson(userData);
            
            await _storageService.saveAuthToken(token);
            await _storageService.saveUserData(userData);
        }

        return response;
        } catch (e) {
        print('Login error: $e');
        throw Exception('Đăng nhập thất bại: ${e.toString()}');
        }
    }

    Future<Map<String, dynamic>> register({
        required String username,
        required String password,
        required String email,
        required String name,
        required int roleId,
        String? address,
        String? phone,
    }) async {
        try {
        final response = await _apiService.post(ApiConstants.register, {
            'username': username,
            'password': password,
            'email': email,
            'name': name,
            'role_id': roleId,
            'address': address,
            'phone': phone,
        });

        return response;
        } catch (e) {
        throw Exception('Đăng ký thất bại: ${e.toString()}');
        }
    }

    Future<void> logout() async {
        _currentUser = null;
        _apiService.clearAuthToken();
        await _storageService.clearAuthData();
    }

    Future<User> updateProfile(Map<String, dynamic> userData) async {
        if (_currentUser == null) {
        throw Exception('Chưa đăng nhập');
        }

        try {
        final response = await _apiService.put(
            '${ApiConstants.users}/${_currentUser!.id}',
            userData,
        );

        _currentUser = User.fromJson(response['user']);
        await _storageService.saveUserData(response['user']);
        
        return _currentUser!;
        } catch (e) {
        throw Exception('Cập nhật thông tin thất bại: ${e.toString()}');
        }
    }
}
