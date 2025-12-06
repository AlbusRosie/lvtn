import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/cart.dart';
import '../../services/CartService.dart';
import '../../services/AuthService.dart';
import '../../utils/image_utils.dart';
import '../../ui/cart/CartProvider.dart';
import '../../constants/app_constants.dart';
import '../../constants/api_constants.dart';
import '../../providers/LocationProvider.dart';

class CheckoutScreen extends StatefulWidget {
  final int branchId;
  final String branchName;

  const CheckoutScreen({
    Key? key,
    required this.branchId,
    required this.branchName,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = false;
  String _voucherCode = '';

  String _getImageUrl(String? imagePath) {
    return ImageUtils.getImageUrl(imagePath);
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,###', 'vi_VN').format(amount.toInt());
  }

  Future<void> _submitOrder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cart = context.read<CartProvider>().cart;
      if (cart == null || cart.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cart is empty'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await _processCashPayment(cart);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing order: $e'),
            backgroundColor: Colors.red,
          ),
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

  Future<void> _processCashPayment(Cart cart) async {
    try {
      final token = AuthService().token;
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      
      try {
        final refreshedCart = await CartService.getUserCart(
          token: token,
          branchId: widget.branchId,
        );
        
        if (refreshedCart != null) {
          // Get delivery address if order type is delivery
          String? deliveryAddress;
          String? deliveryPhone;
          String? customerName;
          String? customerPhone;
          
          final authService = AuthService();
          final user = authService.currentUser;
          
          if (refreshedCart.orderType == 'delivery') {
            final locationProvider = Provider.of<LocationProvider>(context, listen: false);
            deliveryAddress = locationProvider.detailAddress;
            if (user != null && user.phone != null && user.phone!.isNotEmpty) {
              deliveryPhone = user.phone;
              customerPhone = user.phone;
            }
          }
          
          // Get customer name and phone from user account
          if (user != null) {
            if (user.name.isNotEmpty) {
              customerName = user.name;
            }
            if (user.phone != null && user.phone!.isNotEmpty && customerPhone == null) {
              customerPhone = user.phone;
            }
          }
          
          // Lấy reservation_id từ CartProvider nếu có
          final cartProvider = Provider.of<CartProvider>(context, listen: false);
          final reservationId = cartProvider.reservationId;
          
          final body = <String, dynamic>{};
          if (reservationId != null) {
            body['reservation_id'] = reservationId;
          }
          if (deliveryAddress != null && deliveryAddress.isNotEmpty) {
            body['delivery_address'] = deliveryAddress;
          }
          if (deliveryPhone != null && deliveryPhone.isNotEmpty) {
            body['delivery_phone'] = deliveryPhone;
          }
          if (customerName != null && customerName.isNotEmpty) {
            body['customer_name'] = customerName;
          }
          if (customerPhone != null && customerPhone.isNotEmpty) {
            body['customer_phone'] = customerPhone;
          }
          
          final response = await http.post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.checkout(refreshedCart.id)}'),
            headers: ApiConstants.authHeaders(token),
            body: body.isNotEmpty ? jsonEncode(body) : null,
          );


          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order placed successfully! Order ID: ${data['data']['id']}'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );

              // Clear cart và reservation sau khi checkout thành công
              context.read<CartProvider>().clearCart();
              context.read<CartProvider>().clearReservation();
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          } else {
            final error = jsonDecode(response.body);
            throw Exception(error['message'] ?? 'Failed to place order');
          }
        } else {
          throw Exception('Cart not found on server');
        }
      } catch (refreshError) {
        
        try {
          
          await CartService.clearSession();
          
          Cart? newCart;
          for (int i = 0; i < cart.items.length; i++) {
            final item = cart.items[i];
            newCart = await CartService.addToCart(
              token: token,
              branchId: widget.branchId,
              productId: item.productId,
              quantity: item.quantity,
            );
          }
          
          if (newCart != null) {
            // Get delivery address if order type is delivery
            String? deliveryAddress;
            String? deliveryPhone;
            String? customerName;
            String? customerPhone;
            
            final authService = AuthService();
            final user = authService.currentUser;
            
            if (newCart.orderType == 'delivery') {
              final locationProvider = Provider.of<LocationProvider>(context, listen: false);
              deliveryAddress = locationProvider.detailAddress;
              if (user != null && user.phone != null && user.phone!.isNotEmpty) {
                deliveryPhone = user.phone;
                customerPhone = user.phone;
              }
            }
            
            // Get customer name and phone from user account
            if (user != null) {
              if (user.name.isNotEmpty) {
                customerName = user.name;
              }
              if (user.phone != null && user.phone!.isNotEmpty && customerPhone == null) {
                customerPhone = user.phone;
              }
            }
            
            // Lấy reservation_id từ CartProvider nếu có
            final cartProvider = Provider.of<CartProvider>(context, listen: false);
            final reservationId = cartProvider.reservationId;
            
            final body = <String, dynamic>{};
            if (reservationId != null) {
              body['reservation_id'] = reservationId;
            }
            if (deliveryAddress != null && deliveryAddress.isNotEmpty) {
              body['delivery_address'] = deliveryAddress;
            }
            if (deliveryPhone != null && deliveryPhone.isNotEmpty) {
              body['delivery_phone'] = deliveryPhone;
            }
            if (customerName != null && customerName.isNotEmpty) {
              body['customer_name'] = customerName;
            }
            if (customerPhone != null && customerPhone.isNotEmpty) {
              body['customer_phone'] = customerPhone;
            }
            
            final response = await http.post(
              Uri.parse('${ApiConstants.baseUrl}${ApiConstants.checkout(newCart.id)}'),
              headers: ApiConstants.authHeaders(token),
              body: body.isNotEmpty ? jsonEncode(body) : null,
            );


            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Order placed successfully! Order ID: ${data['data']['id']}'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                  ),
                );

                // Clear cart và reservation sau khi checkout thành công
                context.read<CartProvider>().clearCart();
                context.read<CartProvider>().clearReservation();
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            } else {
              final error = jsonDecode(response.body);
              throw Exception(error['message'] ?? 'Failed to place order');
            }
          } else {
            throw Exception('Failed to create new cart');
          }
        } catch (createError) {
          throw Exception('Unable to process order. Please try again.');
        }
      }
    } catch (e) {
      throw Exception('Error processing cash payment: $e');
    }
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
          'Confirm Order',
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
          if (cart == null || cart.isEmpty) {
            return const Center(
              child: Text('No items in cart'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery to',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: Colors.green[600],
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '(323) 238-0678',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '909-1/2 E 49th St Los Angeles, California(CA), 90011',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 12,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '1.5 km',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
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
                      const SizedBox(height: 16),
                      ...cart.items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                         return Column(
                           children: [
                             Row(
                               crossAxisAlignment: CrossAxisAlignment.center,
                               children: [
                                 Container(
                                   width: 70,
                                   height: 70,
                                   decoration: BoxDecoration(
                                     borderRadius: BorderRadius.circular(8),
                                     color: Colors.grey[100],
                                   ),
                                   child: ClipRRect(
                                     borderRadius: BorderRadius.circular(8),
                                     child: item.productImage != null && item.productImage!.isNotEmpty
                                         ? Image.network(
                                             _getImageUrl(item.productImage),
                                             width: 70,
                                             height: 70,
                                             fit: BoxFit.cover,
                                             errorBuilder: (context, error, stackTrace) {
                                               return Container(
                                                 width: 70,
                                                 height: 70,
                                                 color: Colors.grey[100],
                                                 child: const Icon(Icons.restaurant, color: Colors.grey, size: 35),
                                               );
                                             },
                                           )
                                         : Container(
                                             width: 70,
                                             height: 70,
                                             color: Colors.grey[100],
                                             child: const Icon(Icons.restaurant, color: Colors.grey, size: 35),
                                           ),
                                   ),
                                 ),
                                 
                                 SizedBox(width: 8),
                                
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      
                                      Text(
                                        item.productDescription ?? 'Delicious food',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      
                                      Text(
                                        'Quantity: ${item.quantity}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      
                                      Text(
                                        '${_formatCurrency(item.price * item.quantity)} đ',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (index < cart.items.length - 1)
                              Container(
                                margin: const EdgeInsets.symmetric(vertical: 16),
                                child: Divider(
                                  color: Colors.grey[300],
                                  thickness: 0.5,
                                ),
                              ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
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
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subtotal (${cart.items.length} items)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontFamily: 'Inter',
                            ),
                          ),
                          Text(
                            '${_formatCurrency(cart.items.fold<double>(0.0, (sum, item) => sum + (item.price * item.quantity)))} đ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Delivery',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontFamily: 'Inter',
                            ),
                          ),
                          Text(
                            '\$ 0.00',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Voucher',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontFamily: 'Inter',
                            ),
                          ),
                          Text(
                            '-',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                              fontFamily: 'Inter',
                            ),
                          ),
                          Text(
                            '${_formatCurrency(cart.total)} đ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
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
                      Icon(
                        Icons.percent,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Add Voucher',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Add',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Submit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

}