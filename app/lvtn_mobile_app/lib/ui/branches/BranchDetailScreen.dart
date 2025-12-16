import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/branch.dart';
import '../../models/product.dart';
import '../../models/category.dart';
import '../../models/product_option.dart';
import '../../services/BranchService.dart';
import '../../services/ProductService.dart';
import '../../services/CategoryService.dart';
import '../../services/ProductOptionService.dart';
import '../../constants/app_constants.dart';
import '../../constants/api_constants.dart';
import '../cart/CartProvider.dart';
import '../cart/CartScreen.dart';
import '../../services/NotificationService.dart';
import '../widgets/AppBottomNav.dart';
import '../products/ProductDetailScreen.dart';

class BranchDetailScreen extends StatefulWidget {
  final Branch branch;
  
  const BranchDetailScreen({
    super.key, 
    required this.branch,
  });

  static const String routeName = '/branch-detail';

  @override
  State<BranchDetailScreen> createState() => _BranchDetailScreenState();
}

class _BranchDetailScreenState extends State<BranchDetailScreen> {
  final BranchService _branchService = BranchService();
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();
  final ScrollController _scrollController = ScrollController();
  
  Branch? _branch;
  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int? _selectedCategoryId;
  
  int _currentPage = 1;
  int _limit = 20;
  bool _hasMore = true;
  Map<String, dynamic>? _metadata;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    _scrollController.addListener(_onScroll);
    _loadData();
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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients && 
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMoreProducts();
      }
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      _hasMore = true;
      _products = [];
    });

    try {
      final branch = await _branchService.getBranchById(widget.branch.id);
      
      final result = await _productService.getBranchProductsWithMetadata(
        widget.branch.id,
        categoryId: _selectedCategoryId,
        page: _currentPage,
        limit: _limit,
      );
      
      final products = result['products'] as List<Product>? ?? [];
      _metadata = result['metadata'] as Map<String, dynamic>?;
      
      final categories = await _categoryService.getAllCategories();
      
      if (_metadata != null) {
        final currentPage = _metadata!['page'] as int? ?? 1;
        final lastPage = _metadata!['lastPage'] as int? ?? 1;
        _hasMore = currentPage < lastPage;
      } else {
        _hasMore = products.length >= _limit;
      }
      
      if (mounted) {
        setState(() {
          _branch = branch;
          _products = products;
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    try {
      _currentPage++;
      final result = await _productService.getBranchProductsWithMetadata(
        widget.branch.id,
        categoryId: _selectedCategoryId,
        page: _currentPage,
        limit: _limit,
      );
      
      final newProducts = result['products'] as List<Product>? ?? [];
      _metadata = result['metadata'] as Map<String, dynamic>?;
      
      if (_metadata != null) {
        final currentPage = _metadata!['page'] as int? ?? 1;
        final lastPage = _metadata!['lastPage'] as int? ?? 1;
        _hasMore = currentPage < lastPage;
      } else {
        _hasMore = newProducts.length >= _limit;
      }
      
      if (mounted) {
        setState(() {
          _products.addAll(newProducts);
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      _currentPage--;
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBranch = _branch ?? widget.branch;

    return Builder(
        builder: (context) {
    if (_isLoading) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
        ),
      );
    }

    if (_error != null) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Lỗi khi tải dữ liệu',
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
                onPressed: _loadData,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56),
        child: SafeArea(
          bottom: false,
          child: Container(
            color: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
              children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 40,
                          height: 40,
                          constraints: BoxConstraints(
                            minWidth: 40,
                            maxWidth: 40,
                            minHeight: 40,
                            maxHeight: 40,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_rounded,
                            color: Colors.grey[800],
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Spacer(),
                  Consumer<CartProvider>(
                    builder: (context, cartProvider, child) {
                      return SizedBox(
                        width: 40,
                        height: 40,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _showCartBottomSheet(cartProvider, effectiveBranch),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  constraints: BoxConstraints(
                                    minWidth: 40,
                                    maxWidth: 40,
                                    minHeight: 40,
                                    maxHeight: 40,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.shopping_cart_outlined,
                                    color: Colors.grey[800],
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                                if (cartProvider.itemCount > 0)
                                  Positioned(
                              right: -2,
                              top: -2,
                                    child: Container(
                                width: 20,
                                height: 20,
                                      decoration: BoxDecoration(
                                  color: Color(0xFFFF8A00),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFFFF8A00).withOpacity(0.4),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                      ),
                                  ],
                                      ),
                                child: Center(
                                      child: Text(
                                    '${cartProvider.itemCount > 99 ? '99+' : cartProvider.itemCount}',
                                        style: TextStyle(
                                          color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      height: 1,
                                        ),
                                  ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        );
                    },
                  ),
                  ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 180,
              child: effectiveBranch.image != null && effectiveBranch.image!.isNotEmpty
                  ? Image.network(
                      _getImageUrl(effectiveBranch.image),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFE53E3E),
                                Color(0xFFC53030),
                    ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.restaurant,
                              color: Colors.white,
                              size: 80,
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFE53E3E),
                            Color(0xFFC53030),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.restaurant,
                          color: Colors.white,
                          size: 80,
                        ),
                      ),
                  ),
                ),
            Container(
              margin: EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 0),
              padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          effectiveBranch.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${_getBranchStatus(effectiveBranch)} • ${effectiveBranch.address}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.orange, size: 16),
                            SizedBox(width: 4),
                            Text(
                              '4.5',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.access_time, color: Colors.grey[600], size: 16),
                      SizedBox(width: 4),
                      Text(
                        _getOpeningHours(effectiveBranch),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.local_shipping, color: Colors.grey[600], size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Free shipping',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 6),
            
            // Divider section với gradient và icon
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.grey[300]!,
                            Colors.grey[300]!,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.08),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.restaurant_menu_rounded,
                          size: 16,
                          color: Colors.orange[700],
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Menu',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.grey[300]!,
                            Colors.grey[300]!,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 12),
            
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryChip('All', '🔥', _selectedCategoryId == null, null),
                  SizedBox(width: 12),
                  ..._getAvailableCategories().map<Widget>((category) {
                    return Row(
                      children: [
                        _buildCategoryChip(
                          category.name, 
                          _getCategoryEmoji(category.name), 
                          _selectedCategoryId == category.id,
                          category,
                        ),
                        SizedBox(width: 12),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
            SizedBox(height: 16),
            
            _buildMenuContent(),
          ],
    ),
  ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
      ),
      ),
    );
        },
    );
  }

  String _getBranchStatus(Branch branch) {
    final now = DateTime.now();
    final currentHour = now.hour;
    
    if (branch.openingHours != null && branch.closeHours != null) {
      if (currentHour >= branch.openingHours! && currentHour < branch.closeHours!) {
        return 'Open';
      } else {
        return 'Closed';
      }
    }
    return branch.status == 'active' ? 'Open' : 'Closed';
  }

  String _getOpeningHours(Branch branch) {
    if (branch.openingHours != null && branch.closeHours != null) {
      return '${branch.openingHours!.toString().padLeft(2, '0')}:00 - ${branch.closeHours!.toString().padLeft(2, '0')}:00';
    }
    return 'Opening hours not available';
  }

  List<Category> _getAvailableCategories() {
    if (_products.isEmpty) {
      return [];
    }
    
    Set<int> categoryIds = _products
        .where((p) => p.categoryId != null)
        .map((p) => p.categoryId!)
        .toSet();
    
    return _categories
        .where((cat) => categoryIds.contains(cat.id))
        .toList();
  }

  Widget _buildMenuContent() {
    if (_products.isEmpty) {
      return Container(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
      children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
        Text(
              'No products available',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'This branch has no products yet',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    List<Product> filteredProducts = _products;

    if (filteredProducts.isEmpty) {
      return Container(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No products in this category',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different category',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    final Map<int, List<Product>> productsByCategory = {};
    for (final product in filteredProducts) {
      if (!productsByCategory.containsKey(product.categoryId)) {
        productsByCategory[product.categoryId] = [];
      }
      productsByCategory[product.categoryId]!.add(product);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        int crossAxisCount = screenWidth > 600 ? 3 : 2;
        double childAspectRatio = screenWidth > 600 ? 0.7 : 0.6;
        
        return Column(
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            final product = filteredProducts[index];
            return _buildProductCard(product);
          },
            ),
            if (_isLoadingMore)
              Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.orange,
                  ),
                ),
              ),
            if (!_hasMore && filteredProducts.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Đã hiển thị tất cả món ăn',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildProductItem(Product product) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.image != null && product.image!.isNotEmpty
                  ? Image.network(
                      _getImageUrl(product.image),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[100],
                          child: Icon(Icons.restaurant, color: Colors.grey, size: 40),
                        );
                      },
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[100],
                      child: Icon(Icons.restaurant, color: Colors.grey, size: 40),
                    ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Text(
                  product.name,
            style: TextStyle(
                    fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
                if (product.description != null && product.description!.isNotEmpty)
          Text(
                    product.description!,
            style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
            ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
          ),
                SizedBox(height: 8),
          Text(
                  product.formattedPrice,
            style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          GestureDetector(
            onTap: () => _showProductOptionsDialog(product),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final bool isFeatured = product.status == 'featured';
    
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          ProductDetailScreen.routeName,
          arguments: {
            'product': product,
            'branch': widget.branch,
          },
        );
      },
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 0,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                double imageHeight = constraints.maxWidth > 600 ? 140 : 150;
                return Container(
                  height: imageHeight,
                  width: double.infinity,
                  padding: EdgeInsets.all(8),
                  child: Center(
                    child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _getImageUrl(product.image),
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[100],
                            child: Icon(
                              Icons.food_bank,
                              color: Colors.grey[400],
                              size: constraints.maxWidth > 600 ? 40 : 50,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                        fontFamily: 'Inter',
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: 4),
                    
                    Text(
                      widget.branch.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[500],
                        fontFamily: 'Inter',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: 8),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          product.formattedPrice,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                            fontFamily: 'Inter',
                          ),
                        ),
                        
          Container(
                          width: 32,
                          height: 32,
            decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.3),
                                spreadRadius: 0,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: () {
                              _showProductOptionsDialog(product);
                            },
                            icon: Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
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
  }

  Future<void> _showProductOptionsDialog(Product product) async {
    int quantity = 1;
    String? specialRequest = '';
    List<ProductOptionType> productOptions = [];
    List<SelectedOption> selectedOptions = [];
    bool isLoadingOptions = true;
    double totalPriceModifier = 0.0;

    try {
      productOptions = await ProductOptionService().getProductOptionsWithDetails(product.id);
      selectedOptions = ProductOptionService().createDefaultSelections(productOptions);
      totalPriceModifier = ProductOptionService().calculateTotalPriceModifier(selectedOptions);
      isLoadingOptions = false;
    } catch (e) {
      productOptions = [];
      selectedOptions = [];
      isLoadingOptions = false;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final double basePrice = product.basePrice;
            final double optionsModifier = ProductOptionService().calculateTotalPriceModifier(selectedOptions);
            final double itemTotal = basePrice + optionsModifier;
            final double grandTotal = itemTotal * quantity;

            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, controller) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
              children: [
                      Container(
                        margin: EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      Expanded(
                        child: ListView(
                          controller: controller,
                          padding: EdgeInsets.zero,
                          children: [
                            Container(
                              padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
                              child: Column(
                                children: [
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: GestureDetector(
                                      onTap: () => Navigator.of(context).pop(),
                    child: Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          size: 20,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 16),

                                  Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                      ),
                      child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                        child: product.image != null && product.image!.isNotEmpty
                            ? Image.network(
                                _getImageUrl(product.image),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[100],
                                                  child: Icon(
                                                    Icons.restaurant,
                                                    color: Colors.grey[400],
                                                    size: 50,
                                                  ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[100],
                                              child: Icon(
                                                Icons.restaurant,
                                                color: Colors.grey[400],
                                                size: 50,
                              ),
                      ),
                    ),
                  ),

                                  SizedBox(height: 20),

                                  Text(
                                    product.name,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[900],
                                      height: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  SizedBox(height: 8),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.store,
                                        size: 16,
                                        color: Colors.grey[500],
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        widget.branch.name,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.orange[400]!, Colors.orange[600]!],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                Text(
                                          'Base Price: ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white.withOpacity(0.9),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          _formatPrice(basePrice),
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (isLoadingOptions)
                              Container(
                                padding: EdgeInsets.all(40),
                                child: Center(
                                  child: CircularProgressIndicator(
                      color: Colors.orange,
                    ),
                  ),
                              )
                            else if (productOptions.isNotEmpty) ...[
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: Colors.orange,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Customize Your Order',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[900],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 20),

                                    ...productOptions.map((option) => _buildModernOptionWidget(
                                      option,
                                      selectedOptions,
                                      setState,
                                    )),
                                  ],
                                ),
                              ),
                            ],

                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                                      color: Colors.grey[900],
                  ),
                ),
                                  SizedBox(height: 16),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (quantity > 1) {
                                setState(() {
                                  quantity--;
                                });
                              }
                            },
                            child: Container(
                                          width: 44,
                                          height: 44,
                              decoration: BoxDecoration(
                                            color: quantity > 1 ? Colors.white : Colors.grey[100],
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: quantity > 1 ? Colors.orange : Colors.grey[300]!,
                                              width: 2,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.remove,
                                            size: 20,
                                            color: quantity > 1 ? Colors.orange : Colors.grey[400],
                                          ),
                                        ),
                                      ),

                                      Expanded(
                                        child: Center(
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                            '$quantity',
                  style: TextStyle(
                                                fontSize: 24,
                    fontWeight: FontWeight.bold,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                          GestureDetector(
                            onTap: () {
                              setState(() {
                                quantity++;
                              });
                            },
                            child: Container(
                                          width: 44,
                                          height: 44,
                              decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Colors.orange[400]!, Colors.orange[600]!],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.orange.withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.add,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                            ),
                          ),
                        ],
                      ),
                    ],
                              ),
                            ),

                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.edit_note,
                                        size: 20,
                                        color: Colors.grey[600],
                                      ),
                                      SizedBox(width: 8),
                Text(
                                        'Special Instructions',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                                          color: Colors.grey[900],
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        '(Optional)',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[500],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: TextField(
                    onChanged: (value) {
                      specialRequest = value;
                    },
                    decoration: InputDecoration(
                                        hintText: 'e.g., No onions, extra spicy, well done...',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 14,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.all(16),
                                      ),
                                      maxLines: 3,
                                      style: TextStyle(fontSize: 14),
                                    ),
                  ),
                ],
              ),
                            ),

                            SizedBox(height: 120),
                          ],
                        ),
                      ),

                      Container(
                        padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Colors.grey[200]!, width: 1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, -5),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Total Price',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _formatPrice(grandTotal),
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[900],
                                        height: 1.2,
                                      ),
                                    ),
                                    if (optionsModifier != 0) ...[
                                      SizedBox(height: 4),
                                      Text(
                                        '${_formatPrice(basePrice)} + ${_formatPrice(optionsModifier)} × $quantity',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              SizedBox(width: 16),

                              Expanded(
                                child: Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.orange[400]!, Colors.orange[600]!],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () async {
                    Navigator.of(context).pop();
                                        await _addToCartWithOptions(
                                          product,
                                          quantity,
                                          specialRequest,
                                          selectedOptions,
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.shopping_cart,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Add to Cart',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildModernOptionWidget(
    ProductOptionType option,
    List<SelectedOption> selectedOptions,
    StateSetter setState,
  ) {
    final currentSelection = selectedOptions.firstWhere(
      (s) => s.optionTypeId == option.id,
      orElse: () => SelectedOption(
        optionTypeId: option.id,
        optionName: option.name,
        selectedValueIds: [],
        selectedValues: [],
        totalPriceModifier: 0.0,
      ),
    );

    return Container(
      margin: EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                option.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              if (option.required) ...[
                SizedBox(width: 6),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    'Required',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          if (option.type == 'select') ...[
            SizedBox(height: 8),
            Text(
              'Choose one option',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ] else if (option.type == 'checkbox') ...[
            SizedBox(height: 8),
            Text(
              'Choose one or more',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ],
          
          SizedBox(height: 12),

          if (option.type == 'select')
            Column(
              children: option.values
                  .map((value) => Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: _buildModernSelectOption(
                          value,
                          currentSelection,
                          option,
                          selectedOptions,
                          setState,
                        ),
                      ))
                  .toList(),
            )
          else if (option.type == 'checkbox')
            Column(
              children: option.values
                  .map((value) => Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: _buildModernCheckboxOption(
                          value,
                          currentSelection,
                          option,
                          selectedOptions,
                          setState,
                        ),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildModernSelectOption(
    ProductOptionValue value,
    SelectedOption currentSelection,
    ProductOptionType option,
    List<SelectedOption> selectedOptions,
    StateSetter setState,
  ) {
    final isSelected = currentSelection.selectedValueIds.contains(value.id);

    return GestureDetector(
      onTap: () {
        setState(() {
          final index = selectedOptions.indexWhere((s) => s.optionTypeId == option.id);
          if (index != -1) {
            selectedOptions[index] = ProductOptionService().updateSelection(
              selectedOptions[index],
              option,
              value,
              true,
            );
          }
        });
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Colors.orange[400]!, Colors.orange[600]!],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orange[600]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.grey[400]!,
                  width: 2,
                ),
                color: Colors.transparent,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),

            SizedBox(width: 12),

            Expanded(
              child: Text(
                value.value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ),

            if (value.priceModifier != 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : (value.priceModifier > 0 ? Colors.green[50] : Colors.red[50]),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  value.formattedPriceModifier,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (value.priceModifier > 0 ? Colors.green[700] : Colors.red[700]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCheckboxOption(
    ProductOptionValue value,
    SelectedOption currentSelection,
    ProductOptionType option,
    List<SelectedOption> selectedOptions,
    StateSetter setState,
  ) {
    final isSelected = currentSelection.selectedValueIds.contains(value.id);

    return GestureDetector(
      onTap: () {
        setState(() {
          final index = selectedOptions.indexWhere((s) => s.optionTypeId == option.id);
          if (index != -1) {
            selectedOptions[index] = ProductOptionService().updateSelection(
              selectedOptions[index],
              option,
              value,
              !isSelected,
            );
          }
        });
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Colors.orange[400]!, Colors.orange[600]!],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orange[600]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20,
              color: isSelected ? Colors.white : Colors.grey[400],
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                value.value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ),
            if (value.priceModifier != 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : (value.priceModifier > 0 ? Colors.green[50] : Colors.red[50]),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  value.formattedPriceModifier,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (value.priceModifier > 0 ? Colors.green[700] : Colors.red[700]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCartWithOptions(Product product, int quantity, String? specialRequest, List<SelectedOption> selectedOptions) async {
    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      
      if (cartProvider.needsBranchSwitchConfirmation(widget.branch.id)) {
        final shouldSwitch = await _showBranchSwitchDialog(
          cartProvider.currentBranchName ?? 'previous branch',
          widget.branch.name,
        );
        
        if (shouldSwitch != true) {
          return;
        }
        
        await cartProvider.clearCartForBranchSwitch();
      }
      
      await cartProvider.addToCart(
        widget.branch.id,
        product.id,
        quantity: quantity,
        selectedOptions: selectedOptions,
        specialInstructions: specialRequest,
      );
      
      if (mounted) {
        NotificationService().showSuccess(
          context: context,
          message: 'Đã thêm $quantity x ${product.name} vào giỏ hàng',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService().showError(
          context: context,
          message: 'Lỗi: ${e.toString()}',
        );
      }
    }
  }

  Future<bool?> _showBranchSwitchDialog(String currentBranchName, String newBranchName) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text('Switch Branch?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You have items in your cart from:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.store, color: Colors.orange, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        currentBranchName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Adding items from "$newBranchName" will clear your current cart.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Do you want to continue?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
              child: Text(
                'Cancel',
                style: TextStyle(fontSize: 15),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                'Clear & Continue',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    if (imagePath.startsWith('/public')) {
      return '${ApiConstants.fileBaseUrl}$imagePath';
    }
    return '${ApiConstants.fileBaseUrl}/public/uploads/$imagePath';
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')} đ';
  }

  Widget _buildOptionWidget(ProductOptionType option, List<SelectedOption> selectedOptions, StateSetter setState) {
    final currentSelection = selectedOptions.firstWhere(
      (s) => s.optionTypeId == option.id,
      orElse: () => SelectedOption(
        optionTypeId: option.id,
        optionName: option.name,
        selectedValueIds: [],
        selectedValues: [],
        totalPriceModifier: 0.0,
      ),
    );

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                option.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              if (option.required)
                Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          if (option.type == 'select')
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: option.values.map((value) => _buildSelectOption(value, currentSelection, option, selectedOptions, setState)).toList(),
            )
          else if (option.type == 'checkbox')
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: option.values.map((value) => _buildCheckboxOption(value, currentSelection, option, selectedOptions, setState)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectOption(ProductOptionValue value, SelectedOption currentSelection, ProductOptionType option, List<SelectedOption> selectedOptions, StateSetter setState) {
    final isSelected = currentSelection.selectedValueIds.contains(value.id);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          final index = selectedOptions.indexWhere((s) => s.optionTypeId == option.id);
          if (index != -1) {
            selectedOptions[index] = ProductOptionService().updateSelection(
              selectedOptions[index],
              option,
              value,
              true,
            );
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value.value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
            if (value.priceModifier != 0) ...[
              SizedBox(width: 8),
              Text(
                value.formattedPriceModifier,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : (value.priceModifier > 0 ? Colors.green : Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxOption(ProductOptionValue value, SelectedOption currentSelection, ProductOptionType option, List<SelectedOption> selectedOptions, StateSetter setState) {
    final isSelected = currentSelection.selectedValueIds.contains(value.id);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          final index = selectedOptions.indexWhere((s) => s.optionTypeId == option.id);
          if (index != -1) {
            selectedOptions[index] = ProductOptionService().updateSelection(
              selectedOptions[index],
              option,
              value,
              !isSelected,
            );
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              color: isSelected ? Colors.white : Colors.grey[400],
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              value.value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
            if (value.priceModifier != 0) ...[
              SizedBox(width: 8),
              Text(
                value.formattedPriceModifier,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : (value.priceModifier > 0 ? Colors.green : Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String title, String emoji, bool isSelected, Category? category) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryId = category?.id;
        });
        _currentPage = 1;
        _hasMore = true;
        _loadData();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFFFF3E0) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Color(0xFFFFB74D) : Colors.grey[200]!,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Color(0xFFFFB74D).withOpacity(0.25),
              spreadRadius: 0,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: TextStyle(fontSize: 19),
            ),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Color(0xFFFF8A00) : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryEmoji(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'burger':
        return '🍔';
      case 'pizza':
        return '🍕';
      case 'hot dog':
        return '🌭';
      case 'chicken':
        return '🍗';
      case 'sandwich':
        return '🥪';
      case 'salad':
        return '🥗';
      case 'drink':
      case 'beverage':
      case 'refreshment':
        return '☕';
      case 'light bites':
        return '🥙';
      case 'dessert':
        return '🍰';
      case 'coffee':
        return '☕';
      case 'tea':
        return '🍵';
      case 'main course':
        return '🍽️';
      case 'appetizer':
        return '🥗';
      case 'soup':
        return '🍲';
      default:
        return '🍽️';
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.orange),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  void _showCartBottomSheet(CartProvider cartProvider, Branch branch) {
    final currentBranchId = cartProvider.currentBranchId ?? branch.id;
    final currentBranchName = cartProvider.currentBranchName ?? branch.name;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: CartScreen(
            branchId: currentBranchId,
            branchName: currentBranchName,
          ),
        );
      },
    );
  }
}
