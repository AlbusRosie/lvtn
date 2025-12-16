import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/AuthProvider.dart';
import '../../services/OrderService.dart';
import '../../services/AuthService.dart';
import '../../services/NotificationService.dart';
import '../../models/order.dart';
import '../../constants/app_constants.dart';
import '../auth/AuthScreen.dart';

class DeliveryDriverScreen extends StatefulWidget {
  static const String routeName = '/delivery-driver';

  const DeliveryDriverScreen({super.key});

  @override
  State<DeliveryDriverScreen> createState() => _DeliveryDriverScreenState();
}

class _DeliveryDriverScreenState extends State<DeliveryDriverScreen> with WidgetsBindingObserver {
  final OrderService _orderService = OrderService();
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedStatusFilter;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    _loadOrders();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    // Cleanup notification overlay
    NotificationService().hideNotification();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh khi app quay lại foreground
      _loadOrders();
    }
  }

  void _startAutoRefresh() {
    // Auto refresh mỗi 10 giây để nhận đơn mới
    _refreshTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (mounted) {
        _loadOrders(silent: true); // Silent refresh không hiển thị loading
      }
    });
  }

  Future<void> _loadOrders({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuth || authProvider.currentUser == null) {
        throw Exception('Vui lòng đăng nhập');
      }

      final authService = AuthService();
      final token = authService.token;
      if (token == null) {
        throw Exception('Token không hợp lệ');
      }

      // Luôn load tất cả orders (không filter) để phát hiện đơn mới ở mọi tab
      final orders = await _orderService.getDeliveryOrders(
        token: token,
        status: null, // Load tất cả để phát hiện đơn mới
      );
      
      // Kiểm tra xem có đơn mới không (so sánh ID)
      final previousOrderIds = _orders.map((o) => o.id).toSet();
      final newOrders = orders.where((o) => !previousOrderIds.contains(o.id)).toList();
      final hasNewOrders = newOrders.isNotEmpty;
      
      setState(() {
        _orders = orders;
        _isLoading = false;
      });

      // Hiển thị thông báo nếu có đơn mới (luôn hiển thị, kể cả khi silent refresh)
      if (hasNewOrders && mounted) {
        // Hiển thị thông báo nổi bật hơn
        _showNewOrderNotification(newOrders);
      }
    } catch (e) {
      if (!silent) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _showNewOrderNotification(List<Order> newOrders) {
    if (newOrders.isEmpty || !mounted) return;

    final notificationService = NotificationService();
    
    // Hiển thị thông báo overlay ở top màn hình
    if (newOrders.length == 1) {
      final order = newOrders.first;
      notificationService.showTopNotification(
        context: context,
        title: 'Đơn hàng mới!',
        message: 'Đơn #${order.id} - ${_formatCurrency(order.total ?? 0)}',
        icon: Icons.local_shipping_rounded,
        backgroundColor: Color(0xFF4CAF50),
        iconColor: Colors.white,
        duration: Duration(seconds: 5),
        onTap: () {
          // Có thể scroll đến đơn mới hoặc chuyển tab
        },
      );
    } else {
      notificationService.showTopNotification(
        context: context,
        title: 'Bạn có ${newOrders.length} đơn hàng mới!',
        message: 'Vui lòng kiểm tra danh sách đơn hàng',
        icon: Icons.notifications_active,
        backgroundColor: Color(0xFF4CAF50),
        iconColor: Colors.white,
        duration: Duration(seconds: 5),
        onTap: () {
          // Có thể scroll đến đơn mới hoặc chuyển tab
        },
      );
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return formatter.format(amount);
  }

  Future<void> _updateOrderStatus(Order order, String newStatus) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuth || authProvider.currentUser == null) {
        throw Exception('Vui lòng đăng nhập');
      }

      final authService = AuthService();
      final token = authService.token;
      if (token == null) {
        throw Exception('Token không hợp lệ');
      }

      await _orderService.updateOrderStatus(
        orderId: order.id,
        status: newStatus,
        token: token,
      );

      if (mounted) {
        NotificationService().showSuccess(
          context: context,
          message: 'Đã cập nhật trạng thái đơn hàng',
        );
        _loadOrders();
      }
    } catch (e) {
      if (mounted) {
        NotificationService().showError(
          context: context,
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  List<Order> get _filteredOrders {
    // Filter orders theo status filter đã chọn
    if (_selectedStatusFilter == null) {
      return _orders;
    }
    return _orders.where((order) => order.status == _selectedStatusFilter).toList();
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case AppConstants.pending:
        return 'Chờ xử lý';
      case AppConstants.preparing:
        return 'Đang chuẩn bị';
      case AppConstants.ready:
        return 'Sẵn sàng';
      case AppConstants.outForDelivery:
        return 'Đang giao hàng';
      case AppConstants.completed:
        return 'Hoàn thành';
      case AppConstants.cancelled:
        return 'Đã hủy';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.pending:
        return Color(0xFFFF9500); // Cam đậm hơn một chút
      case AppConstants.preparing:
        return Color(0xFFFF6B35); // Cam đỏ (warm)
      case AppConstants.ready:
        return Color(0xFFFFB347); // Cam vàng (warm)
      case AppConstants.outForDelivery:
        return Color(0xFFFF6B6B); // Đỏ hồng (warm)
      case AppConstants.completed:
        return Colors.green[600]!; // Xanh lá cho hoàn thành
      case AppConstants.cancelled:
        return Color(0xFFFF5252); // Đỏ nhạt (warm)
      default:
        return Colors.grey[600]!;
    }
  }

  List<String>? _getNextStatusOptions(String currentStatus) {
    switch (currentStatus) {
      case AppConstants.ready:
        return [AppConstants.outForDelivery];
      case AppConstants.outForDelivery:
        return [AppConstants.completed];
      default:
        return null;
    }
  }

  String _getGreeting() {
    final now = DateTime.now();
    final hour = now.hour;
    
    if (hour >= 5 && hour < 12) {
      return 'Chào buổi sáng';
    } else if (hour >= 12 && hour < 17) {
      return 'Chào buổi chiều';
    } else if (hour >= 17 && hour < 22) {
      return 'Chào buổi tối';
    } else {
      return 'Chúc ngủ ngon';
    }
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),
        SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey[900],
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        extendBodyBehindAppBar: false,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(100),
          child: SafeArea(
            bottom: false,
            child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Row(
          children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Color(0xFFFF8A00).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
              Icons.delivery_dining,
              color: Color(0xFFFF8A00),
                              size: 20,
                            ),
            ),
            SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
            Text(
                                  'GIAO HÀNG',
              style: TextStyle(
                                    color: Color(0xFFFF8A00),
                                    fontSize: 10,
                fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    height: 1.2,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Consumer<AuthProvider>(
                                  builder: (context, authProvider, child) {
                                    final userName = authProvider.currentUser?.name ?? 'Tài xế';
                                    return Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            userName,
                                            style: TextStyle(
                                              color: Colors.grey[800],
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w500,
                                              height: 1.2,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      child: Material(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _showLogoutDialog,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.logout,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Đăng xuất',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
          ),
        ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ),
        body: Column(
          children: [
            // Greeting section
            Container(
              margin: EdgeInsets.fromLTRB(20, 16, 20, 0),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
               child: Consumer<AuthProvider>(
                 builder: (context, authProvider, child) {
                   final userName = authProvider.currentUser?.name ?? 'Tài xế';
                   final greeting = _getGreeting();
                   
                   return Row(
                     children: [
                       Container(
                         padding: EdgeInsets.all(10),
                         decoration: BoxDecoration(
                           color: Color(0xFFFF8A00).withOpacity(0.1),
                           borderRadius: BorderRadius.circular(12),
                         ),
                         child: Icon(
                           Icons.emoji_emotions_rounded,
                           color: Color(0xFFFF8A00),
                           size: 22,
                         ),
                       ),
                       SizedBox(width: 14),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             Text(
                               greeting,
                               style: TextStyle(
                                 fontSize: 16,
                                 fontWeight: FontWeight.w700,
                                 color: Colors.grey[900],
                                 letterSpacing: -0.3,
                               ),
                             ),
                             SizedBox(height: 4),
                             Text(
                               '$userName, sẵn sàng nhận đơn mới!',
                               style: TextStyle(
                                 fontSize: 13,
                                 fontWeight: FontWeight.w500,
                                 color: Colors.grey[600],
                                 letterSpacing: -0.2,
                               ),
                             ),
                           ],
                         ),
                       ),
                     ],
                   );
                 },
               ),
             ),
            
            SizedBox(height: 16),
            
            // Stats section
            if (!_isLoading && _error == null && _orders.isNotEmpty)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Tổng đơn',
                        '${_orders.length}',
                        Icons.receipt_long_rounded,
                        Color(0xFFFF8A00),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 35,
                      color: Colors.grey[200],
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Đang giao',
                        '${_orders.where((o) => o.status == AppConstants.outForDelivery).length}',
                        Icons.local_shipping_rounded,
                        Color(0xFF4A90E2),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 35,
                      color: Colors.grey[200],
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Hoàn thành',
                        '${_orders.where((o) => o.status == AppConstants.completed).length}',
                        Icons.check_circle_rounded,
                        Colors.green[600]!,
                      ),
                    ),
                  ],
                ),
              ),
            
            SizedBox(height: 16),
            
            // Filter section
            Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Color(0xFFFF8A00),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Lọc theo trạng thái',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900],
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tất cả', null),
                        SizedBox(width: 12),
                  _buildFilterChip('Đang giao', AppConstants.outForDelivery),
                        SizedBox(width: 12),
                  _buildFilterChip('Hoàn thành', AppConstants.completed),
                ],
              ),
                  ),
                ],
            ),
          ),

          // Orders list
          Expanded(
            child: _isLoading
                ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                      color: Color(0xFFFF8A00),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Đang tải đơn hàng...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              _error!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _loadOrders,
                              icon: Icon(Icons.refresh),
                              label: Text('Thử lại'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFF8A00),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _filteredOrders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                 Container(
                                   padding: EdgeInsets.all(24),
                                   decoration: BoxDecoration(
                                     color: Color(0xFFFF8A00).withOpacity(0.1),
                                     shape: BoxShape.circle,
                                   ),
                                   child: Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                     color: Color(0xFFFF8A00),
                                ),
                                 ),
                                 SizedBox(height: 24),
                                Text(
                                  'Không có đơn hàng nào',
                                   style: TextStyle(
                                     color: Colors.grey[900],
                                     fontSize: 18,
                                     fontWeight: FontWeight.w600,
                                   ),
                                 ),
                                 SizedBox(height: 8),
                                 Text(
                                   _selectedStatusFilter == null
                                       ? 'Bạn chưa có đơn hàng nào được phân công'
                                       : 'Không có đơn hàng với trạng thái này',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                     fontSize: 14,
                                  ),
                                   textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadOrders,
                            color: Color(0xFFFF8A00),
                            child: ListView.builder(
                                padding: EdgeInsets.all(20),
                              itemCount: _filteredOrders.length,
                              itemBuilder: (context, index) {
                                final order = _filteredOrders[index];
                                return _buildOrderCard(order);
                              },
                            ),
                          ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = _selectedStatusFilter == status;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
        setState(() {
            _selectedStatusFilter = isSelected ? null : status;
        });
        _loadOrders();
      },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected 
                ? Color(0xFFFF8A00) 
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected 
                  ? Color(0xFFFF8A00) 
                  : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Colors.white,
                ),
              if (isSelected) SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final nextStatusOptions = _getNextStatusOptions(order.status);
    final canUpdate = nextStatusOptions != null && nextStatusOptions.isNotEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: Colors.grey[100]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50], // Background xám nhẹ thay vì màu status
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: order.status == AppConstants.outForDelivery
                        ? Color(0xFF4A90E2).withOpacity(0.15) // Xanh dương nhạt cho "Đang giao hàng"
                        : _getStatusColor(order.status).withOpacity(0.12), // Background nhẹ cho màu nóng
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: order.status == AppConstants.outForDelivery
                          ? Color(0xFF4A90E2).withOpacity(0.4)
                          : _getStatusColor(order.status).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusLabel(order.status),
                    style: TextStyle(
                      color: order.status == AppConstants.outForDelivery
                          ? Color(0xFF4A90E2) // Xanh dương cho "Đang giao hàng"
                          : _getStatusColor(order.status), // Màu nóng cho các status khác
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Spacer(),
                Text(
                  '#${order.id}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Delivery address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Color(0xFFFF8A00),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Địa chỉ giao hàng',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            order.deliveryAddress ?? 'Chưa có địa chỉ',
                            style: TextStyle(
                              color: Colors.grey[900],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Customer info
                if (order.customerName != null || order.deliveryPhone != null)
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: Colors.grey[600],
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      if (order.customerName != null)
                        Expanded(
                          child: Text(
                            order.customerName!,
                            style: TextStyle(
                              color: Colors.grey[900],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (order.deliveryPhone != null) ...[
                        SizedBox(width: 12),
                        Icon(
                          Icons.phone,
                          color: Colors.grey[600],
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          order.deliveryPhone!,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),

                if (order.customerName != null || order.deliveryPhone != null)
                  SizedBox(height: 16),

                // Order info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tổng tiền',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          NumberFormat.currency(
                            locale: 'vi_VN',
                            symbol: 'đ',
                          ).format(order.total),
                          style: TextStyle(
                            color: Color(0xFFFF8A00),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Thời gian',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          DateFormat('HH:mm dd/MM/yyyy').format(order.createdAt),
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons
          if (canUpdate)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: nextStatusOptions!.map((status) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: status != nextStatusOptions.last ? 8 : 0,
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          _showUpdateStatusDialog(order, status);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFF8A00), // Cam chủ đạo cho tất cả button
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _getStatusLabel(status),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _showUpdateStatusDialog(Order order, String newStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Xác nhận cập nhật',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn cập nhật đơn hàng #${order.id} sang trạng thái "${_getStatusLabel(newStatus)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateOrderStatus(order, newStatus);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF8A00),
              foregroundColor: Colors.white,
            ),
            child: Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Đăng xuất',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Hiển thị loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF8A00),
                  ),
                ),
              );
              
              try {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                
                // Logout và xóa dữ liệu
                await authProvider.logout();
                
                if (mounted) {
                  // Đóng loading dialog trước
                  Navigator.of(context).pop();
                  
                  // Navigate đến auth screen và xóa tất cả route
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AuthScreen.routeName,
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  // Đóng loading dialog nếu còn mở
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                  NotificationService().showError(
                    context: context,
                    message: 'Lỗi khi đăng xuất: ${e.toString()}',
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}

