import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  static const String routeName = '/orders';

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đơn hàng'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          onTap: (index) {
            setState(() {
              switch (index) {
                case 0:
                  _selectedStatus = 'all';
                  break;
                case 1:
                  _selectedStatus = 'pending';
                  break;
                case 2:
                  _selectedStatus = 'preparing';
                  break;
                case 3:
                  _selectedStatus = 'completed';
                  break;
              }
            });
          },
          tabs: [
            Tab(text: 'Tất cả'),
            Tab(text: 'Chờ xử lý'),
            Tab(text: 'Đang chuẩn bị'),
            Tab(text: 'Hoàn thành'),
          ],
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          if (orderProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          final filteredOrders = _selectedStatus == 'all'
              ? orderProvider.orders
              : orderProvider.orders.where((order) => order.status == _selectedStatus).toList();

          if (filteredOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    _selectedStatus == 'all' ? 'Chưa có đơn hàng nào' : 'Không có đơn hàng ${_getStatusText(_selectedStatus).toLowerCase()}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(
                    _selectedStatus == 'all' 
                        ? 'Hãy đặt món để xem đơn hàng ở đây'
                        : 'Hãy kiểm tra các tab khác',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => orderProvider.loadOrders(),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(filteredOrders),
                _buildOrdersList(orderProvider.orders.where((order) => order.status == 'pending').toList()),
                _buildOrdersList(orderProvider.orders.where((order) => order.status == 'preparing').toList()),
                _buildOrdersList(orderProvider.orders.where((order) => order.status == 'completed').toList()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdersList(List orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Không có đơn hàng nào',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Đơn hàng #${order.id}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _getStatusText(order.status),
                        style: TextStyle(
                          color: _getStatusColor(order.status),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 12),
                
                // Order details
                Row(
                  children: [
                    Icon(
                      Icons.store,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.branchName ?? 'Chi nhánh không xác định',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 8),
                
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 8),
                    Text(
                      _formatDateTime(order.createdAt),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 12),
                
                // Order items preview
                if (order.items != null && order.items!.isNotEmpty) ...[
                  Text(
                    'Món đã đặt:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  ...order.items!.take(3).map((item) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            '• ${item.productName}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Spacer(),
                          Text(
                            'x${item.quantity}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (order.items!.length > 3) ...[
                    SizedBox(height: 4),
                    Text(
                      '... và ${order.items!.length - 3} món khác',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  SizedBox(height: 12),
                ],
                
                // Order total
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Tổng cộng:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      Text(
                        _formatPrice(order.total),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Order actions
                if (order.status == 'pending') ...[
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _showCancelDialog(order);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Hủy đơn'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Navigate to order details
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Tính năng đang phát triển')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Chi tiết'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCancelDialog(order) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Hủy đơn hàng'),
          content: Text('Bạn có chắc chắn muốn hủy đơn hàng #${order.id}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Không'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Implement cancel order
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tính năng đang phát triển')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('Hủy đơn'),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return Colors.green;
      case 'served':
        return Colors.purple;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'preparing':
        return 'Đang chuẩn bị';
      case 'ready':
        return 'Sẵn sàng';
      case 'served':
        return 'Đã phục vụ';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )} VNĐ';
  }
}
