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
  int? _reservationId;
  Map<String, dynamic>? _reservationInfo;

  Cart? get cart => _cart;
  Cart? get currentCart => _cart;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get itemCount => _cart?.items.fold(0, (sum, item) => sum + item.quantity)?.toInt() ?? 0;
  double get total => _cart?.total ?? 0.0;
  int? get currentBranchId => _currentBranchId;
  String? get currentBranchName => _currentBranchName;
  int? get reservationId => _reservationId;
  Map<String, dynamic>? get reservationInfo => _reservationInfo;

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
    _reservationId = null;
    _reservationInfo = null;
    notifyListeners();
  }

  void setReservation(int reservationId, Map<String, dynamic>? reservationInfo) {
    _reservationId = reservationId;
    _reservationInfo = reservationInfo;
    notifyListeners();
  }

  void clearReservation() {
    _reservationId = null;
    _reservationInfo = null;
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

      // Nếu đang switch branch và có cart của branch cũ, clear nó trước
      if (_currentBranchId != null && _currentBranchId != branchId && _cart != null) {
        try {
          await CartService.clearCart(
            token: token,
            cartId: _cart!.id,
          );
          // Clear session để đảm bảo không dùng session cũ
          await CartService.clearSession();
        } catch (e) {
          // Ignore error nếu cart không tồn tại
          print('Error clearing old cart when switching branch: $e');
        }
        // Clear cart trong memory
        _cart = null;
      }

      final cart = await CartService.getUserCart(
        token: token,
        branchId: branchId,
      );

      if (cart != null) {
        setCart(cart);
        _currentBranchId = branchId;
        setCurrentBranch(branchId, cart.branchName ?? '');
      } else {
        setCart(null);
        _currentBranchId = branchId;
        setCurrentBranch(branchId, '');
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

  Future<void> addToCart(int branchId, int productId, {int quantity = 1, String? orderType, List<SelectedOption>? selectedOptions, String? specialInstructions, String? sessionId}) async {
    try {
      setLoading(true);
      
      final token = AuthService().token;
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // Kiểm tra nếu đang switch branch - cần clear cart cũ và session
      if (_currentBranchId != null && _currentBranchId != branchId) {
        // Nếu có cart của branch cũ, clear nó trước
        if (_cart != null) {
          try {
            await CartService.clearCart(
              token: token,
              cartId: _cart!.id,
            );
          } catch (e) {
            // Ignore error nếu cart không tồn tại
            print('Error clearing old cart: $e');
          }
        }
        // Clear session để tạo session mới cho branch mới
        await CartService.clearSession();
      }

      // Determine orderType: use provided, or from existing cart, or default to 'delivery'
      // Note: 'dine_in' and 'takeaway' should only be used in Quick Dine In and Chatbot (they have separate menu/cart screens)
      String finalOrderType = orderType ?? _cart?.orderType ?? 'delivery';

      final cart = await CartService.addToCart(
        token: token,
        branchId: branchId,
        productId: productId,
        quantity: quantity,
        orderType: finalOrderType,
        sessionId: sessionId,
        selectedOptions: selectedOptions,
        specialInstructions: specialInstructions,
      );

      setCart(cart);
      
      _currentBranchId = branchId;
      setCurrentBranch(branchId, cart.branchName ?? '');
      notifyListeners();
    } catch (e) {
      setError(e.toString());
      rethrow;
    }
  }
}
