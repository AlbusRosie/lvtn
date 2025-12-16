import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/AuthProvider.dart';
import '../../services/OrderService.dart';
import '../../services/AuthService.dart';
import '../../services/NotificationService.dart';
import '../../models/order.dart';
import '../../models/reservation.dart';
import '../../constants/app_constants.dart';
import '../../utils/image_utils.dart';
import '../widgets/AppBottomNav.dart';
import 'OrderDetailScreen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  static const String routeName = '/orders';

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<Order> _orders = [];
  
  bool _isLoading = true;
  String? _error;
  String? _selectedOrderTypeFilter; // null = "Tất cả"
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
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _loadData();
    _startAutoRefresh();
    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh khi app quay lại foreground
      _loadData(silent: true);
    }
  }

  void _startAutoRefresh() {
    // Auto refresh mỗi 10 giây để nhận cập nhật đơn hàng real-time
    _refreshTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (mounted) {
        _loadData(silent: true); // Silent refresh không hiển thị loading
      }
    });
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuth && authProvider.currentUser != null) {
        final orderService = OrderService();
        
        // Lưu trạng thái cũ để so sánh
        final previousOrders = List<Order>.from(_orders);
        final previousOrderMap = {for (var o in previousOrders) o.id: o};
        
        final orders = await orderService.getUserOrders(authProvider.currentUser!.id);

        // Kiểm tra xem có đơn nào thay đổi status không
        bool hasStatusChanged = false;
        for (var order in orders) {
          final previousOrder = previousOrderMap[order.id];
          if (previousOrder != null && previousOrder.status != order.status) {
            hasStatusChanged = true;
            break;
          }
        }

        setState(() {
          _orders = orders;
          if (!silent) {
            _isLoading = false;
          }
        });

        // Hiển thị thông báo nếu có đơn thay đổi status (chỉ khi silent refresh)
        if (silent && hasStatusChanged && mounted) {
          NotificationService().showInfo(
            context: context,
            message: 'Đơn hàng của bạn đã được cập nhật',
            title: 'Cập nhật đơn hàng',
          );
        }
      } else {
        if (!silent) {
          setState(() {
            _isLoading = false;
            _error = 'Please login to view your orders';
          });
        }
      }
    } catch (e) {
      if (!silent) {
        setState(() {
          _isLoading = false;
          _error = 'Unable to load data: ${e.toString()}';
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        appBar: _buildAppBar(),
      body: Container(
        color: Color(0xFFF8F9FA),
        child: _isLoading
            ? _buildSkeletonLoading()
            : _error != null
                ? _buildErrorState()
                : Column(
                    children: [
                      _buildOrderTypeFilter(),
                      Expanded(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildOngoingTab(),
                              _buildHistoryTab(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: 3),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight + 50),
      child: SafeArea(
        bottom: false,
         child: AppBar(
           backgroundColor: Colors.white,
           elevation: 0,
           systemOverlayStyle: SystemUiOverlayStyle.dark,
           leading: Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Text(
        'My Orders',
        style: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(50),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _tabController.animateTo(0),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _tabController.index == 0 
                              ? Color(0xFFFF8C00) 
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'Ongoing',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _tabController.index == 0 
                            ? Color(0xFFFF8C00) 
                            : Color(0xFF95A5A6),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _tabController.animateTo(1),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _tabController.index == 1 
                              ? Color(0xFFFF8C00) 
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'History',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _tabController.index == 1 
                            ? Color(0xFFFF8C00) 
                            : Color(0xFF95A5A6),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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
    );
  }


  Widget _buildSkeletonLoading() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          5,
          (index) => Container(
            margin: EdgeInsets.only(bottom: 16),
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 150,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Color(0xFFFFEBEB),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: Color(0xFFFF8C00),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3436),
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              _error!,
              style: TextStyle(
                color: Color(0xFF95A5A6),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF8C00),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded, size: 18),
                SizedBox(width: 8),
                Text('Try Again', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOngoingTab() {
    var ongoingOrders = _orders.where((order) => 
        order.status.toLowerCase() != AppConstants.completed && 
        order.status.toLowerCase() != AppConstants.cancelled).toList();
    
    // Apply order type filter
    if (_selectedOrderTypeFilter != null) {
      ongoingOrders = ongoingOrders.where((order) => 
        order.orderType.toLowerCase() == _selectedOrderTypeFilter!.toLowerCase()
      ).toList();
    }
    
    return Column(
      children: [
        Expanded(
          child: ongoingOrders.isEmpty
              ? _buildEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No Ongoing Orders',
                  subtitle: 'Your ongoing orders will appear here',
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: Color(0xFFFF8C00),
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: ongoingOrders.length,
                    itemBuilder: (context, index) {
                      final order = ongoingOrders[index];
                      return TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: Duration(milliseconds: 500 + (index * 100)),
                        builder: (context, double value, child) {
                          return Transform.translate(
                            offset: Offset(0, 50 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: _buildEnhancedOrderCard(order),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    var historyOrders = _orders.where((order) => 
        order.status.toLowerCase() == AppConstants.completed || 
        order.status.toLowerCase() == AppConstants.cancelled).toList();
    
    // Apply order type filter
    if (_selectedOrderTypeFilter != null) {
      historyOrders = historyOrders.where((order) => 
        order.orderType.toLowerCase() == _selectedOrderTypeFilter!.toLowerCase()
      ).toList();
    }
    
    return Column(
      children: [
        Expanded(
          child: historyOrders.isEmpty
              ? _buildEmptyState(
                  icon: Icons.history_rounded,
                  title: 'No Order History',
                  subtitle: 'Your completed orders will appear here',
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: Color(0xFFFF8C00),
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: historyOrders.length,
                    itemBuilder: (context, index) {
                      final order = historyOrders[index];
                      return TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: Duration(milliseconds: 500 + (index * 100)),
                        builder: (context, double value, child) {
                          return Transform.translate(
                            offset: Offset(0, 50 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: _buildEnhancedOrderCard(order),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }



  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFF8C00).withOpacity(0.1),
                  Color(0xFFFFB84D).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFFF8C00).withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 70,
              color: Color(0xFFFF8C00),
            ),
          ),
          SizedBox(height: 32),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2D3436),
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF95A5A6),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 32),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF8C00), Color(0xFFFFB84D)],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFFF8C00).withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Place Your First Order',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedOrderCard(Order order) {
    return GestureDetector(
      onTap: () => _navigateToOrderDetail(order),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getOrderTypeText(order.orderType),
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(order.status),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(order.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            Row(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: order.branchImage != null && order.branchImage!.isNotEmpty
                        ? Image.network(
                            ImageUtils.getBranchImageUrl(order.branchImage),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.store_rounded,
                                  color: Color(0xFF95A5A6),
                                  size: 28,
                                ),
                              );
                            },
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.store_rounded,
                              color: Color(0xFF95A5A6),
                              size: 28,
                            ),
                          ),
                  ),
                ),
                SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              order.branchName ?? 'Unknown Branch',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '#${order.id}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF95A5A6),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatPrice(order.total),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _formatDateTime(order.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF95A5A6),
                            ),
                          ),
                          Text(
                            ' | ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF95A5A6),
                            ),
                          ),
                          Text(
                            '${order.itemsCount ?? 0} Items',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF95A5A6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            Row(
              children: _buildActionButtons(order),
            ),
          ],
        ),
      ),
    ),
    );
  }

  void _navigateToOrderDetail(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(order: order),
      ),
    );
  }

  IconData _getOrderTypeIcon(String orderType) {
    switch (orderType.toLowerCase()) {
      case AppConstants.dineIn:
        return Icons.restaurant_rounded;
      case AppConstants.delivery:
        return Icons.delivery_dining_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case AppConstants.pending:
        return 'Pending';
      case AppConstants.preparing:
        return 'Preparing';
      case AppConstants.ready:
        return 'Ready for Pickup';
      case AppConstants.outForDelivery:
        return 'Out for Delivery';
      case AppConstants.completed:
        return 'Completed';
      case AppConstants.cancelled:
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _getOrderTypeText(String orderType) {
    switch (orderType.toLowerCase()) {
      case AppConstants.dineIn:
        return 'Dine In';
      case AppConstants.delivery:
        return 'Delivery';
      default:
        return orderType;
    }
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}đ';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case AppConstants.pending:
        return Colors.orange;
      case AppConstants.preparing:
        return Colors.blue;
      case AppConstants.ready:
        return Colors.green;
      case AppConstants.outForDelivery:
        return Colors.purple;
      case AppConstants.completed:
        return Colors.green.shade700;
      case AppConstants.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _rateOrder(Order order) {
    NotificationService().showInfo(
      context: context,
      message: 'Tính năng đánh giá sắp ra mắt!',
    );
  }

  void _reorderItems(Order order) {
    NotificationService().showInfo(
      context: context,
      message: 'Tính năng đặt lại sắp ra mắt!',
    );
  }

  List<Widget> _buildActionButtons(Order order) {
    final status = order.status.toLowerCase();
    final canCancel = status == AppConstants.pending;
    final isOngoing = status != AppConstants.completed && status != AppConstants.cancelled;
    final isCompleted = status == AppConstants.completed || status == AppConstants.cancelled;
    
    if (canCancel) {
      // Đơn pending: hiển thị "Theo dõi" + "Hủy đơn"
      return [
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFFFF8C00), width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () => _viewOrderDetails(order),
              child: Text(
                'Theo dõi',
                style: TextStyle(
                  color: Color(0xFFFF8C00),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFFEF5350),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () => _cancelOrder(order),
              child: Text(
                'Hủy đơn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ];
    } else if (isOngoing) {
      // Đơn ongoing nhưng không phải pending (preparing, ready, out_for_delivery): chỉ hiển thị "Theo dõi"
      return [
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFFFF8C00), width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () => _viewOrderDetails(order),
              child: Text(
                'Theo dõi',
                style: TextStyle(
                  color: Color(0xFFFF8C00),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ];
    } else {
      // Đơn completed/cancelled: hiển thị "Rate" + "Re-Order"
      return [
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFFFF8C00), width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () => _rateOrder(order),
              child: Text(
                'Rate',
                style: TextStyle(
                  color: Color(0xFFFF8C00),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFFFF8C00),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () => _reorderItems(order),
              child: Text(
                'Re-Order',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ];
    }
  }

  void _viewOrderDetails(Order order) {
    _navigateToOrderDetail(order);
  }

  void _cancelOrder(Order order) {
    // Chỉ cho phép hủy khi trạng thái là pending
    if (order.status.toLowerCase() != AppConstants.pending) {
      NotificationService().showError(
        context: context,
        message: 'Không thể hủy đơn hàng. Đơn hàng đã được xử lý.',
      );
      return;
    }
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final authService = AuthService();
    final token = authService.token;
    
    if (token == null) {
      NotificationService().showWarning(
        context: context,
        message: 'Bạn cần đăng nhập để hủy đơn hàng',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Hủy đơn hàng',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Bạn có chắc chắn muốn hủy đơn hàng này không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Không', style: TextStyle(color: Color(0xFF95A5A6))),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _handleCancelOrder(order, token);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF5350),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Có, hủy đơn'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleCancelOrder(Order order, String token) async {
    try {
      final orderService = OrderService();
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF8C00),
          ),
        ),
      );

      final success = await orderService.cancelOrder(order.id, token: token);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      if (success) {
        await _loadData();
        
        if (mounted) {
          NotificationService().showSuccess(
            context: context,
            message: 'Đơn hàng đã được hủy thành công',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        
        NotificationService().showError(
          context: context,
          message: 'Không thể hủy đơn hàng: ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    }
  }

  Widget _buildOrderTypeFilter() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterButton(
              label: 'Tất cả',
              isSelected: _selectedOrderTypeFilter == null,
              onTap: () {
                setState(() {
                  _selectedOrderTypeFilter = null;
                });
              },
            ),
          ),
          SizedBox(width: 4),
          Expanded(
            child: _buildFilterButton(
              label: 'Giao hàng',
              isSelected: _selectedOrderTypeFilter == AppConstants.delivery,
              onTap: () {
                setState(() {
                  _selectedOrderTypeFilter = AppConstants.delivery;
                });
              },
            ),
          ),
          SizedBox(width: 4),
          Expanded(
            child: _buildFilterButton(
              label: 'Mang đi',
              isSelected: _selectedOrderTypeFilter == 'takeaway',
              onTap: () {
                setState(() {
                  _selectedOrderTypeFilter = 'takeaway';
                });
              },
            ),
          ),
          SizedBox(width: 4),
          Expanded(
            child: _buildFilterButton(
              label: 'Tại chỗ',
              isSelected: _selectedOrderTypeFilter == AppConstants.dineIn,
              onTap: () {
                setState(() {
                  _selectedOrderTypeFilter = AppConstants.dineIn;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Color(0xFFFF8C00) : Color(0xFF95A5A6),
          ),
        ),
      ),
    );
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Color(0xFFE1E8ED),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Details #${order.id}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text('Order details will be displayed here'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}