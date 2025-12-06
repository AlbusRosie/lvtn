import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/cart.dart';
import '../../models/product.dart';
import '../../models/branch.dart';
import '../../services/CartService.dart';
import '../../services/AuthService.dart';
import '../../ui/cart/CartProvider.dart';
import '../../providers/AuthProvider.dart';
import '../../providers/ChatProvider.dart';
import '../../constants/api_constants.dart';
import '../products/ProductOptionEditDialog.dart';
import '../branches/BranchDetailScreen.dart';
import 'CheckoutScreen.dart';

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
      final token = AuthService().token;
      if (token == null) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/auth');
        }
        return;
      }

      final cart = await CartService.getUserCart(
        token: token,
        branchId: widget.branchId,
      );
      
      if (mounted) {
        Provider.of<CartProvider>(context, listen: false).setCart(cart);
        Provider.of<CartProvider>(context, listen: false).setCurrentBranch(widget.branchId, widget.branchName);
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        
        if (errorMessage.contains('Invalid token') || 
            errorMessage.contains('401') ||
            errorMessage.contains('Unauthorized')) {
          await AuthService().logout();
          
          if (mounted) {
            final chatProvider = Provider.of<ChatProvider>(context, listen: false);
            chatProvider.reset();
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Session expired. Please login again.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          
          Future.delayed(Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/auth');
            }
          });
        } else {
          setState(() {
            _error = errorMessage;
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateQuantity(CartItem item, int newQuantity) async {
    if (newQuantity < 1) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final token = AuthService().token;
      if (token != null) {
        final cart = await CartService.updateCartItemQuantity(
          token: token,
          cartId: item.cartId,
          productId: item.productId,
          quantity: newQuantity,
        );
        if (mounted) {
          Provider.of<CartProvider>(context, listen: false).setCart(cart);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating quantity: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeItem(CartItem item) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = AuthService().token;
      if (token != null) {
        final cart = await CartService.removeFromCart(
          token: token,
          cartId: item.cartId,
          productId: item.productId,
        );
        if (mounted) {
          Provider.of<CartProvider>(context, listen: false).setCart(cart);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing item: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _editProductOptions(CartItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => ProductOptionEditDialog(
        cartItem: item,
        onOptionUpdated: (updatedItem) async {
          Navigator.pop(context);
          _loadCart();
        },
      ),
    );
  }

  Future<void> _checkout() async {
    try {
      final cart = context.read<CartProvider>().cart;
      if (cart == null) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckoutScreen(
            branchId: widget.branchId,
            branchName: widget.branchName,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error navigating to checkout: $e')),
        );
      }
    }
  }

  /// Show dialog to ask user if they want to reserve a table
  /// Returns: true = reserve table (dine_in), false/null = delivery
  Future<bool?> _showReservationPromptDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.table_restaurant,
                    color: Colors.white,
                    size: 35,
                  ),
                ),
                
                SizedBox(height: 20),
                
                Text(
                  'Đặt bàn trước?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 12),
                
                Text(
                  'Bạn có muốn đặt bàn trước không? Điều này sẽ đảm bảo bạn có chỗ ngồi khi đến nhà hàng.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 24),
                
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: Icon(Icons.event_seat, size: 18),
                        label: Text(
                          'Có, đặt bàn ngay',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 12),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Text(
                          'Không, giao hàng',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    return '${ApiConstants.fileBaseUrl}$imagePath';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.grey[600]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Cart',
          style: TextStyle(
            color: Colors.grey[900],
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          final cart = cartProvider.cart;

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading cart',
                    style: TextStyle(fontSize: 18, color: Colors.red[700]),
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

          if (cart == null || cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add some delicious items to get started!',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Consumer<CartProvider>(
                builder: (context, cartProvider, child) {
                  final reservationInfo = cartProvider.reservationInfo;
                  
                  return Column(
                    children: [
                      Container(
                        margin: EdgeInsets.all(16),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 0,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.store, color: Colors.orange, size: 24),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.branchName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  Text(
                                    '${cart.items.length} items in cart',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Hiển thị thông tin reservation nếu có
                      if (reservationInfo != null)
                        Builder(
                          builder: (context) {
                            // Kiểm tra reservation có expired không
                            bool isExpired = false;
                            String? expiredMessage;
                            if (reservationInfo['reservation_date'] != null && reservationInfo['reservation_time'] != null) {
                              try {
                                final dateStr = reservationInfo['reservation_date'] as String;
                                final timeStr = reservationInfo['reservation_time'].toString().substring(0, 5);
                                final reservationDateTime = DateTime.parse('$dateStr $timeStr');
                                final now = DateTime.now();
                                final expiredThreshold = reservationDateTime.add(Duration(minutes: 30));
                                isExpired = now.isAfter(expiredThreshold);
                                
                                if (isExpired) {
                                  final minutesOverdue = now.difference(expiredThreshold).inMinutes;
                                  if (minutesOverdue >= 60) {
                                    expiredMessage = 'Reservation đã quá hơn 1 giờ. Vui lòng đặt bàn mới.';
                                  } else {
                                    expiredMessage = 'Reservation đã quá giờ ${minutesOverdue} phút. Vui lòng đặt bàn mới.';
                                  }
                                }
                              } catch (e) {
                                // Nếu không parse được, không hiển thị expired
                              }
                            }
                            
                            return Container(
                              margin: EdgeInsets.symmetric(horizontal: 16),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isExpired ? Colors.red[50] : Colors.orange[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isExpired ? Colors.red[200]! : Colors.orange[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isExpired ? Colors.red[100] : Colors.orange[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          isExpired ? Icons.warning : Icons.table_restaurant,
                                          color: isExpired ? Colors.red[700] : Colors.orange[700],
                                          size: 20,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  isExpired ? 'Reservation Expired' : 'Table Reserved',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: isExpired ? Colors.red[900] : Colors.orange[900],
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isExpired ? Colors.red[200] : Colors.orange[200],
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    'ID: ${cartProvider.reservationId}',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                      color: isExpired ? Colors.red[900] : Colors.orange[900],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 4),
                                            if (reservationInfo['reservation_date'] != null)
                                              Text(
                                                'Date: ${reservationInfo['reservation_date']}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            if (reservationInfo['reservation_time'] != null)
                                              Text(
                                                'Time: ${reservationInfo['reservation_time'].toString().substring(0, 5)}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            if (reservationInfo['guest_count'] != null)
                                              Text(
                                                'Guests: ${reservationInfo['guest_count']}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isExpired) ...[
                                    SizedBox(height: 8),
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            size: 14,
                                            color: Colors.red[700],
                                          ),
                                          SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              expiredMessage ?? 'Reservation đã quá giờ',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.red[900],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    SizedBox(height: 8),
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            size: 14,
                                            color: Colors.orange[700],
                                          ),
                                          SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Order sẽ được liên kết với reservation này khi checkout',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[700],
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  );
                },
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return Dismissible(
                      key: Key(item.productId.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      onDismissed: (_) => _removeItem(item),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.grey[100],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: item.productImage != null && item.productImage!.isNotEmpty
                                        ? Image.network(
                                            _getImageUrl(item.productImage),
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                width: 120,
                                                height: 120,
                                                color: Colors.grey[100],
                                                child: const Icon(Icons.restaurant, color: Colors.grey, size: 50),
                                              );
                                            },
                                          )
                                        : Container(
                                            width: 120,
                                            height: 120,
                                            color: Colors.grey[100],
                                            child: const Icon(Icons.restaurant, color: Colors.grey, size: 50),
                                          ),
                                  ),
                                ),
                                
                                SizedBox(height: 8),
                                
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: item.quantity > 1
                                            ? () => _updateQuantity(item, item.quantity - 1)
                                            : null,
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                          child: Icon(
                                            Icons.remove,
                                            color: item.quantity > 1 ? Colors.grey[600] : Colors.grey[400],
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                      
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(
                                          '${item.quantity}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      
                                      GestureDetector(
                                        onTap: () => _updateQuantity(item, item.quantity + 1),
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                          child: Icon(
                                            Icons.add,
                                            color: Colors.orange,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            SizedBox(width: 16),
                            
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _editProductOptions(item),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.productName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(
                                          Icons.edit,
                                          size: 16,
                                          color: Colors.grey[400],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    
                                    Text(
                                      item.productDescription ?? 'Delicious food',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    Text(
                                      '${_formatCurrency(item.price)} đ',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    
                                    if (item.selectedOptions != null && item.selectedOptions!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tap to edit options',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.orange[600],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subtotal (${cart.items.length} items)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            '${_formatCurrency(cart.items.fold<double>(0.0, (sum, item) => sum + (item.price * item.quantity)))} đ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 8),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Delivery',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            'Free',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[600],
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 12),
                      
                      Divider(color: Colors.grey[300]),
                      
                      SizedBox(height: 12),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                            ),
                          ),
                          Text(
                            '${_formatCurrency(cart.total)} đ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 20),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: cart.isEmpty ? null : _checkout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Proceed to Checkout',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReservationInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.orange[700]),
        SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[900],
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,###', 'vi_VN').format(amount.toInt());
  }
}