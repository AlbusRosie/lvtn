import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/BranchProvider.dart';
import '../../providers/CategoryProvider.dart';
import '../../providers/ProductProvider.dart';
import '../../models/branch.dart';
import '../../models/category.dart' as CategoryModel;
import '../../models/product.dart';
import 'ProductDetailScreen.dart';
import '../../constants/app_constants.dart';

class BranchMenuScreen extends StatefulWidget {
  final Branch branch;
  
  const BranchMenuScreen({
    Key? key,
    required this.branch,
  }) : super(key: key);
  
  static const String routeName = '/branch-menu';

  @override
  State<BranchMenuScreen> createState() => _BranchMenuScreenState();
}

class _BranchMenuScreenState extends State<BranchMenuScreen> {
  int? selectedCategoryId = 0; 
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).loadCategories();
      Provider.of<ProductProvider>(context, listen: false).loadProducts(branchId: widget.branch.id);
    });
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
      default:
        return '🍽️';
    }
  }

  String _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return AppConstants.defaultProductImage;
    }
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    if (imagePath.startsWith('/public')) {
      return 'http://10.0.2.2:3000$imagePath';
    }
    return 'http://10.0.2.2:3000/public/uploads/$imagePath';
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
          'Menu category',
          style: TextStyle(
            color: Colors.grey[900],
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Text(
                  'View All',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 4),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<CategoryProvider>(
          builder: (context, categoryProvider, child) {
            if (categoryProvider.isLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: Colors.orange,
                ),
              );
            }

            if (categoryProvider.categories.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 24),
                  
                  Container(
                    height: 130,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categoryProvider.categories.length + 1, // +1 for All category
                        itemBuilder: (context, index) {
                          if (index == 0) {
                             final isAllSelected = selectedCategoryId == 0;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedCategoryId = isAllSelected ? null : 0; // 0 for All
                                });
                                if (isAllSelected) {
                                  Provider.of<ProductProvider>(context, listen: false).clearCategoryFilter();
                                } else {
                                  Provider.of<ProductProvider>(context, listen: false).loadProducts(branchId: widget.branch.id);
                                }
                              },
                              child: Container(
                                width: 80,
                                margin: EdgeInsets.only(right: 12),
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isAllSelected ? Colors.orange : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                   Container(
                                     width: 40,
                                     height: 40,
                                     decoration: BoxDecoration(
                                       shape: BoxShape.circle,
                                       color: Colors.white,
                                       border: Border.all(
                                         color: Colors.grey[200]!,
                                         width: 1,
                                       ),
                                       boxShadow: [
                                         BoxShadow(
                                           color: Colors.grey.withOpacity(0.1),
                                           spreadRadius: 0,
                                           blurRadius: 2,
                                           offset: Offset(0, 1),
                                         ),
                                       ],
                                     ),
                                     child: Icon(
                                       Icons.apps,
                                       color: Colors.grey[600],
                                       size: 22,
                                     ),
                                   ),
                                    
                                     SizedBox(height: 8),
                                     
                                     Text(
                                       'All',
                                       style: TextStyle(
                                         fontSize: 12,
                                         fontWeight: FontWeight.bold,
                                         color: isAllSelected ? Colors.white : Colors.grey[700],
                                         fontFamily: 'Inter',
                                       ),
                                       textAlign: TextAlign.center,
                                     ),
                                     
                                     SizedBox(height: 8),
                                     
                                    Container(
                                      margin: EdgeInsets.symmetric(horizontal: 1),
                                      child: Center(
                                        child: Container(
                                          width: 30,
                                          height: 1,
                                          color: isAllSelected ? Colors.white : Colors.orange,
                                        ),
                                      ),
                                    ),
                                    
                                    SizedBox(height: 10),
                                    
                                    Container(
                                      margin: EdgeInsets.symmetric(horizontal: 2),
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: isAllSelected ? Colors.white : Colors.orange,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            spreadRadius: 0,
                                            blurRadius: 1,
                                            offset: Offset(0, 0.5),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.keyboard_arrow_right,
                                        color: isAllSelected ? Colors.orange : Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          
                          final category = categoryProvider.categories[index - 1]; // -1 because All takes index 0
                          final isSelected = selectedCategoryId == category.id;
                          
                           final shouldHighlight = isSelected;
                          
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCategoryId = isSelected ? null : category.id;
                              });
                              if (isSelected) {
                                Provider.of<ProductProvider>(context, listen: false).clearCategoryFilter();
                              } else {
                                Provider.of<ProductProvider>(context, listen: false).applyCategoryFilter(category.id);
                              }
                            },
                            child: Container(
                              width: 80,
                              margin: EdgeInsets.only(right: 12),
                              padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: shouldHighlight ? Colors.orange : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                   Container(
                                     width: 40,
                                     height: 40,
                                     decoration: BoxDecoration(
                                       shape: BoxShape.circle,
                                       color: Colors.transparent,
                                     ),
                                     child: Center(
                                       child: Text(
                                         _getCategoryEmoji(category.name),
                                         style: TextStyle(fontSize: 28),
                                       ),
                                     ),
                                   ),
                                  
                                   SizedBox(height: 8),
                                   
                                   Text(
                                     category.name,
                                     style: TextStyle(
                                       fontSize: 12,
                                       fontWeight: FontWeight.bold,
                                       color: shouldHighlight ? Colors.white : Colors.grey[700],
                                       fontFamily: 'Inter',
                                     ),
                                     textAlign: TextAlign.center,
                                     maxLines: 1,
                                     overflow: TextOverflow.ellipsis,
                                   ),
                                   
                                   SizedBox(height: 8),
                                   
                                  Container(
                                    margin: EdgeInsets.symmetric(horizontal: 1),
                                    child: Center(
                                      child: Container(
                                        width: 30,
                                        height: 1,
                                        color: shouldHighlight ? Colors.white : Colors.orange,
                                      ),
                                    ),
                                  ),
                                  
                                  SizedBox(height: 12),
                                  
                                  Container(
                                    margin: EdgeInsets.symmetric(horizontal: 3),
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: shouldHighlight ? Colors.white : Colors.orange,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          spreadRadius: 0,
                                          blurRadius: 1,
                                          offset: Offset(0, 0.5),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.keyboard_arrow_right,
                                      color: shouldHighlight ? Colors.orange : Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Popular Dishes', // Thay đổi tiêu đề giống ảnh mẫu
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                            fontFamily: 'Inter',
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'View All',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 4),
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _buildProductsGrid(categoryProvider),
                  ),
                  
                  SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
Widget _buildProductsGrid(CategoryProvider categoryProvider) {
  return Consumer<ProductProvider>(
    builder: (context, productProvider, child) {
      if (productProvider.isLoading) {
        return Container(
          height: 320,
          child: Center(
            child: CircularProgressIndicator(
              color: Colors.orange,
            ),
          ),
        );
      }

      if (productProvider.error != null) {
        return Container(
          height: 320,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.grey[400], size: 48),
                SizedBox(height: 8),
                Text(
                  'Failed to load products',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 4),
                TextButton(
                  onPressed: () {
                    productProvider.refreshProducts();
                  },
                  child: Text('Retry', style: TextStyle(color: Colors.orange)),
                ),
              ],
            ),
          ),
        );
      }

      List<Product> products = productProvider.products;
      
      if (products.isEmpty) {
        return Container(
          height: 320,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu, color: Colors.grey[400], size: 48),
                SizedBox(height: 8),
                Text(
                  'No products available',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      }

      return GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65, // Adjusted for new layout
          crossAxisSpacing: 12, // Increased spacing
          mainAxisSpacing: 12, // Increased spacing
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildMenuCardFromProduct(product);
        },
      );
    },
  );
}
Widget _buildMenuCardFromProduct(Product product) {
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
            Container(
                height: 190,
                width: double.infinity,
                padding: EdgeInsets.all(8),
            child: Center(
                child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                    _getImageUrl(product.image),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                    return Container(
                        color: Colors.grey[100],
                        child: Icon(
                        Icons.food_bank,
                        color: Colors.grey[400],
                        size: 50,
                        ),
                    );
                    },
                ),
                ),
            ),
            ),
            
            Expanded(
            child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(
                    product.name,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                        fontFamily: 'Inter',
                        height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: 2),
                    
                    Text(
                    widget.branch.name,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[500],
                        fontFamily: 'Inter',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    ),
                    
                     SizedBox(height: 3),
                     Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                        Text(
                        product.formattedPrice,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                            fontFamily: 'Inter',
                        ),
                        ),
                        
                        Container(
                        width: 36,
                        height: 36,
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
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                content: Text('Added ${product.name} to cart'),
                                backgroundColor: Colors.orange,
                                duration: Duration(seconds: 1),
                                ),
                            );
                            },
                            icon: Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
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
}