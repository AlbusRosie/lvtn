import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../constants/app_constants.dart';
import '../../utils/image_utils.dart';
import '../../services/OrderService.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isInitialized = false;
  
  // Order data
  Order? _order;
  bool _isLoading = false;
  String? _error;
  final OrderService _orderService = OrderService();

  @override
  void initState() {
    super.initState();
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
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
    _isInitialized = true;
    
    // Load order details
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final order = await _orderService.getOrderWithDetails(widget.order.id);
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF8C00),
          ),
        ),
      );
    }
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFFFF8C00),
          ),
              const SizedBox(height: 16),
          Text(
            'Loading order details...',
            style: TextStyle(
              color: Color(0xFF95A5A6),
              fontSize: 16,
            ),
          ),
        ],
          ),
      ),
    );
  }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFFEF5350),
              ),
              const SizedBox(height: 16),
          Text(
                'Error loading order',
            style: TextStyle(
              color: Color(0xFF2D3436),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
            ),
          ),
              const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(
              color: Color(0xFF95A5A6),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
              const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadOrderDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF8C00),
              foregroundColor: Colors.white,
              ),
                child: Text('Retry'),
          ),
        ],
          ),
      ),
    );
  }

    final order = _order ?? widget.order;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(order),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
      child: Column(
        children: [
                    _buildOrderStatusCard(order),
                    _buildOrderInfoCard(order),
                    _buildLocationCard(order),
                    if (order.orderType.toLowerCase() == AppConstants.delivery)
                      _buildDeliveryPersonCard(),
                    _buildOrderItemsCard(order),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(order),
    );
  }
  
  Widget _buildSliverAppBar(Order order) {
    return SliverAppBar(
      expandedHeight: 80,
      backgroundColor: Colors.white,
      pinned: true,
      floating: false,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Branch Image Background
            order.branchImage != null && order.branchImage!.isNotEmpty
                ? Image.network(
                    ImageUtils.getBranchImageUrl(order.branchImage),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
    return Container(
      decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFFFF8C00).withOpacity(0.8),
                              const Color(0xFFFFB84D),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFFF8C00).withOpacity(0.8),
                          const Color(0xFFFFB84D),
                        ],
                      ),
                    ),
                  ),
            // Dark overlay for better text visibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
            // Content - Order ID ở trên cùng header
            SafeArea(
      child: Column(
        children: [
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Order #${order.id}',
                      style: const TextStyle(
        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
          ),
        ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusCard(Order order) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phần header động theo order type
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0E6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
            children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8C00),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getOrderTypeIcon(order.orderType),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getOrderHeaderTitle(order),
                  style: const TextStyle(
                          fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
                      const SizedBox(height: 4),
                      Text(
                        _getOrderHeaderSubtitle(order),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7F8C8D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildProgressIndicator(order),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(Order order) {
    final steps = _getOrderSteps(order);
    final currentStepIndex = _getCurrentStepIndex(order);
    
    return Column(
      children: List.generate(steps.length, (index) {
        final isCompleted = index <= currentStepIndex;
        final isLast = index == steps.length - 1;
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon column
            Column(
              children: [
              Container(
                  width: 32,
                  height: 32,
                decoration: BoxDecoration(
                    color: isCompleted 
                        ? const Color(0xFFFF8C00) 
                        : const Color(0xFFF5F5F5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : steps[index]['icon'],
                    color: isCompleted ? Colors.white : const Color(0xFF95A5A6),
                    size: 16,
                  ),
                ),
                if (!isLast)
                  Container(
                    margin: const EdgeInsets.only(top: 4, bottom: 4),
                    width: 2,
                    height: 30,
                    child: CustomPaint(
                      painter: DottedLinePainter(
                        color: isCompleted 
                            ? const Color(0xFFFF8C00) 
                            : const Color(0xFFE1E8ED),
                  ),
                ),
              ),
            ],
          ),
            const SizedBox(width: 16),
            // Content column
            Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
                    steps[index]['title'],
            style: TextStyle(
                      fontSize: 14,
                      fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w500,
                      color: isCompleted 
                          ? const Color(0xFF2D3436) 
                          : const Color(0xFF95A5A6),
                    ),
                  ),
                  if (steps[index]['time'] != null)
          Text(
                      steps[index]['time'],
                      style: const TextStyle(
                        fontSize: 12,
              color: Color(0xFF95A5A6),
            ),
          ),
        ],
      ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildOrderInfoCard(Order order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
              Text(
                order.branchName ?? 'Restaurant',
                style: const TextStyle(
                  fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoItem(
                Icons.receipt_outlined,
                '${order.itemsCount ?? 0} items',
              ),
              const SizedBox(width: 24),
              _buildInfoItem(
                Icons.credit_card,
                _getPaymentMethodText(order.paymentMethod),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF95A5A6),
            ),
              ),
              Text(
                _formatPrice(order.total),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF8C00),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
        children: [
        Icon(icon, size: 18, color: const Color(0xFF95A5A6)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
                color: Color(0xFF95A5A6),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLocationCard(Order order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildLocationItem(
            const Color(0xFFFF8C00),
            order.branchName ?? 'Restaurant',
            'Restaurant • ${_formatTime(order.createdAt)}',
            true,
          ),
          Container(
            margin: const EdgeInsets.only(left: 20),
            height: 40,
            child: CustomPaint(
              painter: DottedLinePainter(color: const Color(0xFFE1E8ED)),
            ),
          ),
          _buildLocationItem(
            const Color(0xFF4CAF50),
            _getDestinationTitle(order),
            _getDestinationSubtitle(order),
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationItem(Color color, String title, String subtitle, bool isTop) {
    return Row(
        children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              ),
            ),
          ),
        const SizedBox(width: 16),
          Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                color: Color(0xFF2D3436),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF95A5A6),
            ),
          ),
        ],
      ),
        ),
      ],
    );
  }

  Widget _buildDeliveryPersonCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
              image: const DecorationImage(
                image: AssetImage('assets/images/delivery_person.png'),
                fit: BoxFit.cover,
              ),
              border: Border.all(
                color: const Color(0xFFFF8C00),
                width: 2,
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Color(0xFF95A5A6),
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                const Text(
                  'Delivery Partner',
            style: TextStyle(
                    fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'Arriving Soon',
              style: TextStyle(
                        fontSize: 13,
                color: Color(0xFF95A5A6),
              ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 12,
                            color: Color(0xFF4CAF50),
                          ),
                          SizedBox(width: 2),
            Text(
                            '4.8',
              style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.call, color: Colors.white, size: 20),
                  onPressed: () {
                    // Handle call
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8C00),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8C00).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
                  onPressed: () {
                    // Handle chat
                  },
                ),
              ),
            ],
            ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsCard(Order order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shopping_bag_outlined, color: Color(0xFFFF8C00), size: 20),
              SizedBox(width: 8),
          Text(
                'Order Items',
            style: TextStyle(
                  fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
            ],
          ),
          const SizedBox(height: 16),
          // Display actual order items from database
          if (order.items != null && order.items!.isNotEmpty)
            ...order.items!.map((item) => _buildOrderItem(
              item.productName ?? 'Unknown Item',
              item.quantity,
              item.price,
            )).toList()
          else
            // Show message when no items available
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No items found',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order items will appear here',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildOrderItem(String name, int quantity, double price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.fastfood,
              color: Color(0xFFFF8C00),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  color: Color(0xFF2D3436),
                ),
              ),
              Text(
                  'x$quantity',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF95A5A6),
                ),
              ),
            ],
            ),
          ),
          Text(
            _formatPrice(price),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3436),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(Order order) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
      children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // Handle cancel order
                _showCancelDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF5350),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                  'Cancel Order',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // Handle track order
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                shadowColor: const Color(0xFFFF8C00).withOpacity(0.3),
              ),
              child: const Text(
                'Track Order',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Cancel Order',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Are you sure you want to cancel this order?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No', style: TextStyle(color: Color(0xFF95A5A6))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Implement cancel order
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order cancelled successfully'),
                    backgroundColor: Color(0xFFEF5350),
                  ),
                );
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF5350),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );
  }
  
  List<Map<String, dynamic>> _getOrderSteps(Order order) {
    // Timeline for takeaway/delivery system
    return [
      {
        'title': 'Order Placed',
        'time': _formatTime(order.createdAt),
        'icon': Icons.receipt_long,
      },
      {
        'title': 'Preparing',
        'time': order.status == AppConstants.preparing || 
                order.status == AppConstants.ready || 
                order.status == AppConstants.outForDelivery ||
                order.status == AppConstants.completed
            ? _formatTime(order.createdAt.add(const Duration(minutes: 2)))
            : null,
        'icon': Icons.restaurant_menu,
      },
      {
        'title': order.orderType.toLowerCase() == AppConstants.delivery 
            ? 'Out for Delivery' 
            : 'Ready for Pickup',
        'time': order.status == AppConstants.outForDelivery || 
                order.status == AppConstants.ready ||
                order.status == AppConstants.completed
            ? _formatTime(order.createdAt.add(const Duration(minutes: 15)))
            : null,
        'icon': order.orderType.toLowerCase() == AppConstants.delivery 
            ? Icons.delivery_dining 
            : Icons.shopping_bag,
      },
      {
        'title': order.orderType.toLowerCase() == AppConstants.delivery 
            ? 'Delivered' 
            : 'Completed',
        'time': order.status == AppConstants.completed
            ? _formatTime(order.createdAt.add(const Duration(minutes: 30)))
            : null,
        'icon': order.orderType.toLowerCase() == AppConstants.delivery 
            ? Icons.home 
            : Icons.check_circle,
      },
    ];
  }
  
  int _getCurrentStepIndex(Order order) {
    switch (order.status.toLowerCase()) {
      case AppConstants.pending:
        return 0;
      case AppConstants.preparing:
        return 1;
      case AppConstants.ready:
      case AppConstants.outForDelivery:
        return 2;
      case AppConstants.completed:
        return 3;
      case AppConstants.cancelled:
        return -1; // Cancelled order
      default:
        return 0;
    }
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case AppConstants.pending:
        return const Color(0xFFFFA726); // Orange - waiting
      case AppConstants.preparing:
        return const Color(0xFF42A5F5); // Blue - in progress
      case AppConstants.ready:
        return const Color(0xFFAB47BC); // Purple - ready for pickup
      case AppConstants.outForDelivery:
        return const Color(0xFF66BB6A); // Green - on the way
      case AppConstants.completed:
        return const Color(0xFF4CAF50); // Dark green - done
      case AppConstants.cancelled:
        return const Color(0xFFEF5350); // Red - cancelled
      default:
        return const Color(0xFF95A5A6); // Grey - unknown
    }
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}đ';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Helper function for payment method display
  String _getPaymentMethodText(String? paymentMethod) {
    if (paymentMethod == null) return 'Not specified';
    
    switch (paymentMethod.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Credit/Debit Card';
      case 'online':
        return 'Online Payment';
      default:
        return paymentMethod;
    }
  }

  // Helper functions for dynamic content based on order data
  String _getOrderHeaderTitle(Order order) {
    switch (order.orderType.toLowerCase()) {
      case AppConstants.dineIn:
        return 'Dine In at Restaurant';
      case AppConstants.delivery:
        return 'Delivery Your Order';
      default:
        return 'Your Order';
    }
  }

  String _getOrderHeaderSubtitle(Order order) {
    switch (order.orderType.toLowerCase()) {
      case AppConstants.dineIn:
        return order.tableNumber != null 
            ? 'Table ${order.tableNumber}' 
            : 'Please wait for table assignment';
      case AppConstants.delivery:
        return 'Coming within 30 minutes';
      default:
        return 'Processing your order';
    }
  }

  String _getDestinationTitle(Order order) {
    switch (order.orderType.toLowerCase()) {
      case AppConstants.dineIn:
        return order.tableNumber != null 
            ? 'Table ${order.tableNumber}' 
            : 'Table N/A';
      case AppConstants.delivery:
        return order.deliveryAddress ?? 'Your Location';
      default:
        return 'Destination';
    }
  }

  String _getDestinationSubtitle(Order order) {
    final estimatedTime = _formatTime(order.createdAt.add(const Duration(minutes: 30)));
    
    switch (order.orderType.toLowerCase()) {
      case AppConstants.dineIn:
        return 'Dine In • $estimatedTime';
      case AppConstants.delivery:
        return order.deliveryPhone != null 
            ? 'Home • ${order.deliveryPhone}' 
            : 'Delivery • $estimatedTime';
      default:
        return estimatedTime;
    }
  }
}

class DottedLinePainter extends CustomPainter {
  final Color color;
  
  DottedLinePainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashWidth),
        paint,
      );
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}