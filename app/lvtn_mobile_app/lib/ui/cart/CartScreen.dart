import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart.dart';
import '../models/product.dart';
import '../services/CartService.dart';
import '../services/AuthService.dart';
import '../ui/cart/CartProvider.dart';
import '../ui/cart/CartItemWidget.dart';
import '../ui/cart/TableReservationWidget.dart';
import '../ui/cart/CheckoutScreen.dart';

class CartScreen extends StatefulWidget {
  final int branchId;
  final String branchName;

  const CartScreen({
    Key? key,
    required this.branchId,
    required this.branchName,
  }) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token != null) {
        final cart = await CartService.getUserCart(
          token: token,
          branchId: widget.branchId,
        );
        
        if (mounted) {
          context.read<CartProvider>().setCart(cart);
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addToCart(Product product) async {
    try {
      final token = await AuthService.getToken();
      if (token != null) {
        final cart = await CartService.addToCart(
          token: token,
          branchId: widget.branchId,
          productId: product.id,
          quantity: 1,
          orderType: 'dine_in',
        );
        
        if (mounted) {
          context.read<CartProvider>().setCart(cart);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding item: $e')),
        );
      }
    }
  }

  Future<void> _updateQuantity(CartItem item, int newQuantity) async {
    try {
      final token = await AuthService.getToken();
      if (token != null) {
        final cart = await CartService.updateCartItemQuantity(
          token: token,
          cartId: item.cartId,
          productId: item.productId,
          quantity: newQuantity,
        );
        
        if (mounted) {
          context.read<CartProvider>().setCart(cart);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating quantity: $e')),
        );
      }
    }
  }

  Future<void> _removeItem(CartItem item) async {
    try {
      final token = await AuthService.getToken();
      if (token != null) {
        final cart = await CartService.removeFromCart(
          token: token,
          cartId: item.cartId,
          productId: item.productId,
        );
        
        if (mounted) {
          context.read<CartProvider>().setCart(cart);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing item: $e')),
        );
      }
    }
  }

  Future<void> _reserveTable({
    required int tableId,
    required String reservationDate,
    required String reservationTime,
    required int guestCount,
  }) async {
    try {
      final cart = context.read<CartProvider>().cart;
      if (cart == null) return;

      final token = await AuthService.getToken();
      if (token != null) {
        final updatedCart = await CartService.reserveTable(
          token: token,
          cartId: cart.id,
          tableId: tableId,
          reservationDate: reservationDate,
          reservationTime: reservationTime,
          guestCount: guestCount,
        );
        
        if (mounted) {
          context.read<CartProvider>().setCart(updatedCart);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Table reserved successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reserving table: $e')),
        );
      }
    }
  }

  Future<void> _cancelReservation() async {
    try {
      final cart = context.read<CartProvider>().cart;
      if (cart == null) return;

      final token = await AuthService.getToken();
      if (token != null) {
        final updatedCart = await CartService.cancelTableReservation(
          token: token,
          cartId: cart.id,
        );
        
        if (mounted) {
          context.read<CartProvider>().setCart(updatedCart);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Table reservation cancelled')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling reservation: $e')),
        );
      }
    }
  }

  Future<void> _checkout() async {
    try {
      final cart = context.read<CartProvider>().cart;
      if (cart == null) return;

      final token = await AuthService.getToken();
      if (token != null) {
        final result = await CartService.checkout(
          token: token,
          cartId: cart.id,
        );
        
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CheckoutScreen(
                orderId: result['order_id'],
                reservationId: result['reservation_id'],
                total: result['total'],
                branchName: widget.branchName,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cart - ${widget.branchName}'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCart,
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading cart',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadCart,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final cart = cartProvider.cart;
          if (cart == null || cart.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add some items to get started',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Cart items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return CartItemWidget(
                      item: item,
                      onQuantityChanged: (newQuantity) => _updateQuantity(item, newQuantity),
                      onRemove: () => _removeItem(item),
                    );
                  },
                ),
              ),

              // Table reservation section
              if (cart.isDineIn) ...[
                TableReservationWidget(
                  cart: cart,
                  onReserveTable: _reserveTable,
                  onCancelReservation: _cancelReservation,
                ),
                const Divider(height: 1),
              ],

              // Cart summary and checkout
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${cart.total.toStringAsFixed(0)} VND',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: cart.isEmpty ? null : _checkout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          cart.isEmpty ? 'Cart is empty' : 'Checkout',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
