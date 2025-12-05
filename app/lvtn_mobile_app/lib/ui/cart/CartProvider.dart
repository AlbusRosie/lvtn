import 'package:flutter/material.dart';
import '../../models/cart.dart';
import '../../models/product_option.dart';
import '../../services/CartService.dart';
import '../../services/AuthService.dart';
import '../../services/StorageService.dart';

class CartProvider extends ChangeNotifier {
  Cart? _cart;
  bool _isLoading = false;
  String? _error;
  int? _currentBranchId;
  String? _currentBranchName;

  Cart? get cart => _cart;
  Cart? get currentCart => _cart;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get itemCount => _cart?.items.fold(0, (sum, item) => sum + item.quantity)?.toInt() ?? 0;
  double get total => _cart?.total ?? 0.0;
  int? get currentBranchId => _currentBranchId;
  String? get currentBranchName => _currentBranchName;

  void setCart(Cart? cart) {
    _cart = cart;
    _error = null;
    notifyListeners();
  }

  void setCurrentBranch(int branchId, String branchName) {
    _currentBranchId = branchId;
    _currentBranchName = branchName;
    
    StorageService().setInt('current_branch_id', branchId);
    StorageService().setString('current_branch_name', branchName);
    
    notifyListeners();
  }


  Future<void> loadSavedBranchInfo() async {
    try {
      final branchId = await StorageService().getInt('current_branch_id');
      final branchName = await StorageService().getString('current_branch_name');
      
      if (branchId != null && branchName != null) {
        _currentBranchId = branchId;
        _currentBranchName = branchName;
        notifyListeners();
      }
    } catch (e) {
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void clearCart() {
    _cart = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }


  Future<void> loadCart(int branchId) async {
    try {
      setLoading(true);
      
      final token = AuthService().token;
      
      if (token == null) {
        setLoading(false);
        return;
      }

      
      final cart = await CartService.getUserCart(
        token: token,
        branchId: branchId,
      );

      if (cart != null) {
        setCart(cart);
        _currentBranchId = branchId;
      } else {
        setCart(null);
      }
    } catch (e) {
      setError(e.toString());
    }
  }


  Future<void> refreshCart() async {
    if (_currentBranchId != null) {
      await loadCart(_currentBranchId!);
    }
  }


  bool needsBranchSwitchConfirmation(int newBranchId) {
    if (_cart == null || _cart!.items.isEmpty) {
      return false;
    }
    
    if (_currentBranchId != null && _currentBranchId != newBranchId) {
      return true;
    }
    
    return false;
  }

  Future<void> clearCartForBranchSwitch() async {
    try {
      final token = AuthService().token;
      if (token == null || _cart == null) {
        clearCart();
        return;
      }

      await CartService.clearCart(
        token: token,
        cartId: _cart!.id,
      );
      
      clearCart();
    } catch (e) {
      clearCart();
    }
  }

  Future<void> addToCart(int branchId, int productId, {int quantity = 1, String orderType = 'dine_in', List<SelectedOption>? selectedOptions, String? specialInstructions}) async {
    try {
      setLoading(true);
      
      final token = AuthService().token;
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final cart = await CartService.addToCart(
        token: token,
        branchId: branchId,
        productId: productId,
        quantity: quantity,
        orderType: orderType,
        selectedOptions: selectedOptions,
        specialInstructions: specialInstructions,
      );

      setCart(cart);
      
      _currentBranchId = branchId;
      notifyListeners();
    } catch (e) {
      setError(e.toString());
      rethrow;
    }
  }
}
