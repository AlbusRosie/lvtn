import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/order_item.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];
  List<OrderItem> _cartItems = [];
  bool _isLoading = false;

  List<Order> get orders => _orders;
  List<OrderItem> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  
  double get cartTotal {
    return _cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  int get cartItemCount {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // TODO: Implement actual API call
      // For now, using mock data
      _orders = [];
    } catch (error) {
      debugPrint('Error loading orders: $error');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  void addToCart(OrderItem item) {
    final existingIndex = _cartItems.indexWhere((cartItem) => cartItem.productId == item.productId);
    
    if (existingIndex >= 0) {
      _cartItems[existingIndex] = OrderItem(
        id: _cartItems[existingIndex].id,
        orderId: _cartItems[existingIndex].orderId,
        productId: _cartItems[existingIndex].productId,
        quantity: _cartItems[existingIndex].quantity + item.quantity,
        price: _cartItems[existingIndex].price,
        specialInstructions: item.specialInstructions,
        productName: _cartItems[existingIndex].productName,
        productImage: _cartItems[existingIndex].productImage,
      );
    } else {
      _cartItems.add(item);
    }
    
    notifyListeners();
  }

  void removeFromCart(int productId) {
    _cartItems.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  void updateCartItemQuantity(int productId, int quantity) {
    final index = _cartItems.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index] = OrderItem(
          id: _cartItems[index].id,
          orderId: _cartItems[index].orderId,
          productId: _cartItems[index].productId,
          quantity: quantity,
          price: _cartItems[index].price,
          specialInstructions: _cartItems[index].specialInstructions,
          productName: _cartItems[index].productName,
          productImage: _cartItems[index].productImage,
        );
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  void addOrder(Order order) {
    _orders.insert(0, order);
    notifyListeners();
  }

  void updateOrderStatus(int orderId, String status) {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index >= 0) {
      _orders[index] = Order(
        id: _orders[index].id,
        userId: _orders[index].userId,
        branchId: _orders[index].branchId,
        tableId: _orders[index].tableId,
        orderType: _orders[index].orderType,
        total: _orders[index].total,
        status: status,
        paymentStatus: _orders[index].paymentStatus,
        paymentMethod: _orders[index].paymentMethod,
        deliveryAddress: _orders[index].deliveryAddress,
        deliveryPhone: _orders[index].deliveryPhone,
        notes: _orders[index].notes,
        createdAt: _orders[index].createdAt,
      );
      notifyListeners();
    }
  }
}
