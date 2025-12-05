import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/AuthService.dart';
import '../services/UserService.dart';
import '../ui/cart/CartProvider.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? get currentUser => _authService.currentUser;
  bool get isAuth => _authService.isAuthenticated;

  Future<User> login(String username, String password, {CartProvider? cartProvider}) async {
    try {
      final user = await _authService.login(username, password);
      

      if (cartProvider != null) {
        await cartProvider.loadSavedBranchInfo();

      }
      
      notifyListeners();
      return user;
    } catch (error) {
      rethrow;
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
      final user = await _authService.register(
        username: username,
        password: password,
        email: email,
        name: name,
        phone: phone,
        address: address,
      );
      notifyListeners();
      return user;
    } catch (error) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }

  Future<bool> tryAutoLogin() async {
    final result = await _authService.tryAutoLogin();
    if (result) {
      notifyListeners();
    }
    return result;
  }

  Future<User> updateUserAddress(String address) async {
    try {
      if (currentUser == null) {
        throw Exception('Chưa đăng nhập');
      }
      
      print('AuthProvider: Đang cập nhật địa chỉ cho user ID: ${currentUser!.id}');
      final userService = UserService();
      final updatedUser = await userService.updateUserAddress(currentUser!.id, address);
      
      if (updatedUser.id <= 0 || (updatedUser.username.isEmpty && updatedUser.email.isEmpty)) {
        print('AuthProvider: Updated user không hợp lệ, giữ nguyên user hiện tại');
        throw Exception('Thông tin user không hợp lệ sau khi cập nhật');
      }
      
      await _authService.updateCurrentUser(updatedUser);
      print('AuthProvider: Đã cập nhật user thành công - ID: ${updatedUser.id}, Address: ${updatedUser.address}');
      notifyListeners();
      return updatedUser;
    } catch (error) {
      print('AuthProvider: Lỗi khi cập nhật địa chỉ: $error');
      rethrow;
    }
  }
}
