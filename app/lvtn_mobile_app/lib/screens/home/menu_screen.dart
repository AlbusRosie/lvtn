import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../../models/category.dart' as models;
import '../../widgets/product_card.dart';
import '../../widgets/category_chip.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  models.Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadCategories();
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thực đơn'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              // TODO: Navigate to cart
            },
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Column(
            children: [
              // Categories
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: productProvider.categories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return CategoryChip(
                        label: 'Tất cả',
                        isSelected: _selectedCategory == null,
                        onTap: () {
                          setState(() {
                            _selectedCategory = null;
                          });
                          productProvider.loadProducts();
                        },
                      );
                    }
                    
                    final category = productProvider.categories[index - 1];
                    return CategoryChip(
                      label: category.name,
                      isSelected: _selectedCategory?.id == category.id,
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                        productProvider.loadProducts(categoryId: category.id);
                      },
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Products
              Expanded(
                child: productProvider.products.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Không có sản phẩm nào',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: productProvider.products.length,
                        itemBuilder: (context, index) {
                          final product = productProvider.products[index];
                          return ProductCard(
                            product: product,
                            onTap: () {
                              // TODO: Show product details
                            },
                            onAddToCart: () {
                              // TODO: Add to cart
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
