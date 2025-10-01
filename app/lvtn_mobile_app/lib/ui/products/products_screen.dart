import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/branch_provider.dart';
import '../../providers/table_provider.dart';
import '../../providers/auth_provider.dart';
import 'product_detail_screen.dart';
import '../tables/tables_screen.dart';
import '../profile/profile_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  static const String routeName = '/products';

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedBranchId = '';
  String _selectedCategoryId = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final branchProvider = Provider.of<BranchProvider>(context, listen: false);
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final tableProvider = Provider.of<TableProvider>(context, listen: false);
      
      branchProvider.loadBranches();
      productProvider.loadProducts();
      tableProvider.loadTables();
    });
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
        title: Text('Thực đơn'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_tabController.index == 0) // Only show search for products tab
            IconButton(
              icon: Icon(Icons.search),
              onPressed: _showSearchDialog,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: Icon(Icons.restaurant_menu),
              text: 'Món ăn',
            ),
            Tab(
              icon: Icon(Icons.table_restaurant),
              text: 'Bàn',
            ),
            Tab(
              icon: Icon(Icons.person),
              text: 'Tài khoản',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsTab(),
          _buildTablesTab(),
          _buildProfileTab(),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return Column(
      children: [
        // Filter section
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Branch filter
              Consumer<BranchProvider>(
                builder: (context, branchProvider, child) {
                  return DropdownButtonFormField<String>(
                    value: _selectedBranchId.isEmpty ? null : _selectedBranchId,
                    decoration: InputDecoration(
                      labelText: 'Chi nhánh',
                      prefixIcon: Icon(Icons.store),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: '',
                        child: Text('Tất cả chi nhánh'),
                      ),
                      ...branchProvider.branches.map((branch) {
                        return DropdownMenuItem<String>(
                          value: branch.id.toString(),
                          child: Text(branch.name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedBranchId = value ?? '';
                      });
                      _loadProducts();
                    },
                  );
                },
              ),
              SizedBox(height: 12),
              
              // Category filter
              Consumer<ProductProvider>(
                builder: (context, productProvider, child) {
                  return DropdownButtonFormField<String>(
                    value: _selectedCategoryId.isEmpty ? null : _selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: 'Danh mục',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: '',
                        child: Text('Tất cả danh mục'),
                      ),
                      ...productProvider.categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category['id'].toString(),
                          child: Text(category['name']),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value ?? '';
                      });
                      _loadProducts();
                    },
                  );
                },
              ),
            ],
          ),
        ),
        
        // Products list
        Expanded(
          child: Consumer<ProductProvider>(
            builder: (context, productProvider, child) {
              if (productProvider.isLoading) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (productProvider.products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Không có sản phẩm nào',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Vui lòng chọn chi nhánh khác',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _loadProducts,
                child: GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: productProvider.products.length,
                  itemBuilder: (context, index) {
                    final product = productProvider.products[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            ProductDetailScreen.routeName,
                            arguments: product,
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product image
                            Expanded(
                              flex: 3,
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                ),
                                child: product.image != null && product.image!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(12),
                                        ),
                                        child: Image.network(
                                          product.image!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(
                                              Icons.restaurant,
                                              size: 40,
                                              color: Theme.of(context).primaryColor,
                                            );
                                          },
                                        ),
                                      )
                                    : Icon(
                                        Icons.restaurant,
                                        size: 40,
                                        color: Theme.of(context).primaryColor,
                                      ),
                              ),
                            ),
                            
                            // Product info
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      product.categoryName ?? 'Không có danh mục',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Spacer(),
                                    Row(
                                      children: [
                                        Text(
                                          '${_formatPrice(product.branchPrice ?? product.basePrice)}',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Spacer(),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: product.branchAvailable == true
                                                ? Colors.green.withOpacity(0.1)
                                                : Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            product.branchAvailable == true ? 'Có sẵn' : 'Hết hàng',
                                            style: TextStyle(
                                              color: product.branchAvailable == true
                                                  ? Colors.green
                                                  : Colors.red,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
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
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTablesTab() {
    return Consumer<TableProvider>(
      builder: (context, tableProvider, child) {
        if (tableProvider.isLoading) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        if (tableProvider.tables.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.table_restaurant,
                  size: 80,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Không có bàn nào',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 8),
                Text(
                  'Vui lòng chọn chi nhánh khác',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => tableProvider.loadTables(),
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: tableProvider.tables.length,
            itemBuilder: (context, index) {
              final table = tableProvider.tables[index];
              return Card(
                margin: EdgeInsets.only(bottom: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: table.status == 'available'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    child: Icon(
                      Icons.table_restaurant,
                      color: table.status == 'available' ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(
                    'Bàn ${table.tableNumber}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sức chứa: ${table.capacity} người'),
                      Text('Tầng: ${table.floorId}'),
                    ],
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: table.status == 'available'
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      table.status == 'available' ? 'Trống' : 'Đã đặt',
                      style: TextStyle(
                        color: table.status == 'available' ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () {
                    if (table.status == 'available') {
                      // TODO: Show booking dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tính năng đặt bàn đang phát triển')),
                      );
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProfileTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        
        if (user == null) {
          return Center(
            child: Text('Không có thông tin người dùng'),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile card
              Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: user.avatar != null
                            ? ClipOval(
                                child: Image.network(
                                  user.avatar!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.white,
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '@${user.username}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Menu items
              _buildMenuItem(
                context,
                'Thông tin cá nhân',
                Icons.person_outline,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tính năng đang phát triển')),
                  );
                },
              ),
              _buildMenuItem(
                context,
                'Đơn hàng của tôi',
                Icons.receipt_long,
                () {
                  Navigator.pushNamed(context, '/orders');
                },
              ),
              _buildMenuItem(
                context,
                'Cài đặt',
                Icons.settings,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tính năng đang phát triển')),
                  );
                },
              ),
              _buildMenuItem(
                context,
                'Hỗ trợ',
                Icons.help_outline,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tính năng đang phát triển')),
                  );
                },
              ),
              SizedBox(height: 20),

              // Logout button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Đăng xuất'),
                        content: Text('Bạn có chắc muốn đăng xuất?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Đăng xuất'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await authProvider.logout();
                      if (mounted) {
                        Navigator.pushReplacementNamed(context, '/auth');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Đăng xuất'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Future<void> _loadProducts() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await productProvider.loadProducts(
      branchId: _selectedBranchId.isEmpty ? null : int.parse(_selectedBranchId),
      categoryId: _selectedCategoryId.isEmpty ? null : int.parse(_selectedCategoryId),
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Tìm kiếm sản phẩm'),
          content: TextField(
            decoration: InputDecoration(
              hintText: 'Nhập tên sản phẩm...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _loadProducts();
              },
              child: Text('Tìm kiếm'),
            ),
          ],
        );
      },
    );
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )} VNĐ';
  }
}
