import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/AuthService.dart';
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
    return await _authService.tryAutoLogin();
  }
}
