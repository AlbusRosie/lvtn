import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../models/order.dart';
import '../../models/order_detail.dart';
import '../../constants/app_constants.dart';
import '../../utils/image_utils.dart';
import '../../services/OrderService.dart';
import '../../services/NotificationService.dart';
import '../../providers/AuthProvider.dart';
import '../../services/AuthService.dart';

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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Builder(
        builder: (context) {
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
        },
      ),
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
              Expanded(
                child: Text(
                  order.branchName ?? 'Restaurant',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
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
              Expanded(
                child: _buildInfoItem(
                  Icons.receipt_outlined,
                  '${order.itemsCount ?? 0} items',
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildInfoItem(
                  Icons.credit_card,
                  _getPaymentMethodText(order.paymentMethod),
                ),
              ),
            ],
          ),
          if (order.customerName != null && order.customerName!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoItem(
              Icons.person_outline,
              order.customerName!,
            ),
          ],
          if (order.customerPhone != null && order.customerPhone!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoItem(
              Icons.phone_outlined,
              order.customerPhone!,
            ),
          ],
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.note_outlined, size: 18, color: Color(0xFF95A5A6)),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ghi chú',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF95A5A6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.notes!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2D3436),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF95A5A6)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF95A5A6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  Widget _buildLocationCard(Order order) {
    // Chỉ hiển thị location card cho delivery và dine_in
    if (order.orderType.toLowerCase() != AppConstants.delivery && 
        order.orderType.toLowerCase() != AppConstants.dineIn) {
      return const SizedBox.shrink();
    }
    
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
            'Restaurant • ${_formatDateTime(order.createdAt)}',
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF95A5A6),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
          if (order.items != null && order.items!.isNotEmpty)
            ...order.items!.map((item) => _buildOrderItem(item)).toList()
          else
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
  
  Widget _buildOrderItem(OrderDetail item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item.productImage != null && item.productImage!.isNotEmpty
                  ? Image.network(
                      ImageUtils.getImageUrl(item.productImage),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFF5F5F5),
                          child: const Icon(
                            Icons.fastfood,
                            color: Color(0xFFFF8C00),
                            size: 24,
                          ),
                        );
                      },
                    )
                  : const Icon(
                      Icons.fastfood,
                      color: Color(0xFFFF8C00),
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName ?? 'Unknown Item',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3436),
                  ),
                ),
                if (item.productDescription != null && item.productDescription!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.productDescription!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF95A5A6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'x${item.quantity}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF95A5A6),
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        final formattedInstructions = _formatSpecialInstructions(item.specialInstructions);
                        if (formattedInstructions != null && formattedInstructions.isNotEmpty) {
                          return Expanded(
                            child: Row(
                              children: [
                                const SizedBox(width: 8),
                                const Icon(Icons.info_outline, size: 14, color: Color(0xFF95A5A6)),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    formattedInstructions,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF95A5A6),
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatPrice(item.price * item.quantity),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3436),
                ),
              ),
              if (item.quantity > 1)
                Text(
                  '${_formatPrice(item.price)} × ${item.quantity}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF95A5A6),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(Order order) {
    final canCancel = order.status.toLowerCase() == AppConstants.pending;
    
    if (order.status.toLowerCase() == AppConstants.cancelled || 
        order.status.toLowerCase() == AppConstants.completed) {
      return const SizedBox.shrink();
    }

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
          if (canCancel)
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : () {
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
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Hủy đơn hàng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          if (canCancel) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
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
                'Theo dõi đơn hàng',
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
    final order = _order ?? widget.order;
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
      setState(() {
        _isLoading = true;
      });

      final success = await _orderService.cancelOrder(order.id, token: token);
      
      if (success) {
        await _loadOrderDetails();
        
        if (mounted) {
          NotificationService().showSuccess(
            context: context,
            message: 'Đơn hàng đã được hủy thành công',
          );
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        NotificationService().showError(
          context: context,
          message: 'Không thể hủy đơn hàng: ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    }
  }
  
  List<Map<String, dynamic>> _getOrderSteps(Order order) {
    return [
      {
        'title': 'Order Placed',
        'time': _formatDateTime(order.createdAt),
        'icon': Icons.receipt_long,
      },
      {
        'title': 'Preparing',
        'time': order.status == AppConstants.preparing || 
                order.status == AppConstants.ready || 
                order.status == AppConstants.outForDelivery ||
                order.status == AppConstants.completed
            ? _formatDateTime(order.createdAt.add(const Duration(minutes: 2)))
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
            ? _formatDateTime(order.createdAt.add(const Duration(minutes: 15)))
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
            ? _formatDateTime(order.createdAt.add(const Duration(minutes: 30)))
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
        return -1;
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
        return const Color(0xFFFFA726);
      case AppConstants.preparing:
        return const Color(0xFF42A5F5);
      case AppConstants.ready:
        return const Color(0xFFAB47BC);
      case AppConstants.outForDelivery:
        return const Color(0xFF66BB6A);
      case AppConstants.completed:
        return const Color(0xFF4CAF50);
      case AppConstants.cancelled:
        return const Color(0xFFEF5350);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  String? _formatSpecialInstructions(String? instructions) {
    if (instructions == null || instructions.isEmpty) {
      return null;
    }
    
    // Kiểm tra xem có phải là JSON string không
    try {
      // Nếu bắt đầu bằng [ hoặc {, có thể là JSON
      final trimmed = instructions.trim();
      if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
        final decoded = jsonDecode(instructions);
        // Nếu là array, format thành text đẹp hơn
        if (decoded is List) {
          final List<String> options = [];
          for (var item in decoded) {
            if (item is Map) {
              final optionName = item['option_name']?.toString();
              if (optionName != null && optionName.isNotEmpty) {
                options.add(optionName);
              }
            }
          }
          return options.isNotEmpty ? options.join(', ') : null;
        }
        // Nếu là object, bỏ qua
        return null;
      }
    } catch (e) {
      // Không phải JSON hợp lệ, trả về text gốc
    }
    
    // Nếu không phải JSON, trả về text gốc
    return instructions;
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${_formatTime(dateTime)}';
  }

  String _getPaymentMethodText(String? paymentMethod) {
    // Tất cả đơn chỉ hỗ trợ cash, mặc định là cash
    return 'Cash';
  }

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
        if (order.tableName != null && order.tableName!.isNotEmpty) {
          return order.tableName!;
        } else if (order.tableIdDisplay != null) {
          return 'Table #${order.tableIdDisplay}';
        } else {
          return 'Please wait for table assignment';
        }
      case AppConstants.delivery:
        return 'Coming within 30 minutes';
      default:
        return 'Processing your order';
    }
  }

  String _getDestinationTitle(Order order) {
    switch (order.orderType.toLowerCase()) {
      case AppConstants.dineIn:
        if (order.tableName != null && order.tableName!.isNotEmpty) {
          return order.tableName!;
        } else if (order.tableIdDisplay != null) {
          return 'Table #${order.tableIdDisplay}';
        } else {
          return 'Table N/A';
        }
      case AppConstants.delivery:
        return order.deliveryAddress ?? 'Your Location';
      default:
        return 'Destination';
    }
  }

  String _getDestinationSubtitle(Order order) {
    final estimatedTime = _formatDateTime(order.createdAt.add(const Duration(minutes: 30)));
    
    switch (order.orderType.toLowerCase()) {
      case AppConstants.dineIn:
        return 'Dine In • ${_formatDateTime(order.createdAt)}';
      case AppConstants.delivery:
        return order.deliveryPhone != null 
            ? '${order.deliveryPhone} • $estimatedTime' 
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