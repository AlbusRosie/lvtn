import 'package:flutter/material.dart';
import '../../models/cart.dart';

class CartProvider extends ChangeNotifier {
  Cart? _cart;
  bool _isLoading = false;

  Cart? get cart => _cart;
  bool get isLoading => _isLoading;
  bool get hasCart => _cart != null && !_cart!.isEmpty;
  double get total => _cart?.total ?? 0.0;
  int get itemCount => _cart?.items.length ?? 0;

  void setCart(Cart? cart) {
    _cart = cart;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearCart() {
    _cart = null;
    notifyListeners();
  }

  bool hasProduct(int productId) {
    if (_cart == null) return false;
    return _cart!.items.any((item) => item.productId == productId);
  }

  int getProductQuantity(int productId) {
    if (_cart == null) return 0;
    final item = _cart!.items.firstWhere(
      (item) => item.productId == productId,
      orElse: () => CartItem(
        id: 0,
        cartId: 0,
        productId: productId,
        quantity: 0,
        price: 0,
        productName: '',
      ),
    );
    return item.quantity;
  }
}
