import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../models/branch.dart';
import '../../models/product_option.dart';
import '../../providers/CategoryProvider.dart';
import '../../providers/ProductProvider.dart';
import '../../services/ProductOptionService.dart';

class ProductDetailScreen extends StatefulWidget {
  static const String routeName = '/product-detail';

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _loadedRelated = false;
  bool _loadedOptions = false;
  List<ProductOptionType> _productOptions = [];
  List<SelectedOption> _selectedOptions = [];
  final ProductOptionService _optionService = ProductOptionService();
  String _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&auto=format&fit=crop';
    }
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    if (imagePath.startsWith('/public')) {
      return 'http://10.0.2.2:3000$imagePath';
    }
    return 'http://10.0.2.2:3000/public/uploads/$imagePath';
  }

  Future<void> _loadProductOptions(int productId) async {
    if (_loadedOptions) return;
    
    print('🔄 ProductDetailScreen: Loading options for product ID: $productId');
    
    try {
      final options = await _optionService.getProductOptionsWithDetails(productId);
      final defaultSelections = _optionService.createDefaultSelections(options);
      
      print('✅ ProductDetailScreen: Loaded ${options.length} options');
      for (var option in options) {
        print('  📋 Option: ${option.name} (${option.type}) - ${option.values.length} values');
      }
      
      setState(() {
        _productOptions = options;
        _selectedOptions = defaultSelections;
        _loadedOptions = true;
      });
      
      print('✅ ProductDetailScreen: Options loaded successfully');
    } catch (error) {
      print('❌ ProductDetailScreen: Error loading product options: $error');
    }
  }

  double _calculateTotalPrice(Product product) {
    final basePrice = product.basePrice;
    final modifierTotal = _optionService.calculateTotalPriceModifier(_selectedOptions);
    return basePrice + modifierTotal;
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')} đ';
  }

  void _updateOptionSelection(ProductOptionType optionType, ProductOptionValue value, bool isSelected) {
    setState(() {
      final index = _selectedOptions.indexWhere((s) => s.optionTypeId == optionType.id);
      if (index != -1) {
        _selectedOptions[index] = _optionService.updateSelection(
          _selectedOptions[index],
          optionType,
          value,
          isSelected,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final Product product = args['product'];
    final Branch branch = args['branch'];

    // Load product options
    if (!_loadedOptions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadProductOptions(product.id);
      });
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Stack(
                children: [
                   Container(
                     height: MediaQuery.of(context).size.height * 0.32,
                    decoration: BoxDecoration(
                       gradient: LinearGradient(
                         begin: Alignment.topCenter,
                         end: Alignment.bottomCenter,
                         colors: [
                           Colors.orange,
                           Colors.orange.shade400,
                         ],
                      ),
                       borderRadius: BorderRadius.only(
                         bottomLeft: Radius.circular(150),
                         bottomRight: Radius.circular(150),
                       ),
                    ),
                  ),

                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Consumer<CategoryProvider>(
                            builder: (context, categoryProvider, child) {
                              String categoryName = 'Category';
                              try {
                                final category = categoryProvider.categories
                                    .firstWhere((cat) => cat.id == product.categoryId);
                                categoryName = category.name;
                              } catch (e) {
                                categoryName = 'Category';
                              }
                              
                              return Text(
                                categoryName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontFamily: 'Inter',
                                ),
                              );
                            },
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 22),
                            padding: EdgeInsets.zero,
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ),


                   Positioned(
                     bottom: -40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                           Container(
                             width: 450,
                             height: 450,
                             decoration: BoxDecoration(
                               shape: BoxShape.circle,
                               gradient: RadialGradient(
                                 colors: [
                                   Colors.orange.shade100.withOpacity(0.4),
                                   Colors.orange.shade50.withOpacity(0.2),
                                   Colors.transparent,
                                 ],
                               ),
                             ),
                           ),
                           Container(
                             width: 400,
                             height: 400,
                             decoration: BoxDecoration(
                               shape: BoxShape.circle,
                               gradient: RadialGradient(
                                 colors: [
                                   Colors.orange.shade100.withOpacity(0.3),
                                   Colors.orange.shade50.withOpacity(0.1),
                                   Colors.transparent,
                                 ],
                               ),
                             ),
                           ),
                          Container(
                            width: 300,
                            height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(160),
                              child: Image.network(
                                _getImageUrl(product.image),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Icon(Icons.food_bank, size: 80, color: Colors.grey),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

             Expanded(
               child: Padding(
                 padding: EdgeInsets.symmetric(horizontal: 24),
                 child: SingleChildScrollView(
                   physics: BouncingScrollPhysics(),
                   child: Column(
                   children: [
                     SizedBox(height: 24),

                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                        fontFamily: 'Inter',
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Large',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontFamily: 'Inter',
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '|',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[400],
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          _formatPrice(_calculateTotalPrice(product)),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12),

                    Text(
                      product.description ?? 'Tomato, Mozzarella, Green basil, Olives, Bell pepper',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: 'Inter',
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 24),

                    // Product Options Section
                    if (_productOptions.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Customize your order',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      ..._productOptions.map((option) => _buildOptionWidget(option)),
                      SizedBox(height: 24),
                    ] else if (_loadedOptions) ...[
                      // Show message when no options are available
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No customization options available for this product',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                    ] else ...[
                      // Show loading indicator while loading options
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Loading customization options...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                    ],

                    Container(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          // Validate required options
                          if (!_optionService.validateRequiredOptions(_productOptions, _selectedOptions)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please select all required options'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }

                          // Show selected options in snackbar
                          final selectedOptionsText = _selectedOptions
                              .where((s) => s.selectedValues.isNotEmpty)
                              .map((s) => '${s.optionName}: ${s.selectedValues.join(', ')}')
                              .join('\n');

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Added ${product.name} to cart'),
                                  if (selectedOptionsText.isNotEmpty) ...[
                                    SizedBox(height: 4),
                                    Text(
                                      selectedOptionsText,
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                  SizedBox(height: 4),
                                  Text(
                                    'Total: ${_formatPrice(_calculateTotalPrice(product))}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        },
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.orange,
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(28),
                           ),
                           elevation: 0,
                         ),
                        child: Text(
                          'Add to cart - ${_formatPrice(_calculateTotalPrice(product))}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),

                     SizedBox(height: 16),

                    SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'More in this category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Consumer<ProductProvider>(
                      builder: (context, productProvider, _) {
                        // Lazy load related products for current branch/category
                        if (!_loadedRelated) {
                          WidgetsBinding.instance.addPostFrameCallback((_) async {
                            await Provider.of<ProductProvider>(context, listen: false)
                                .loadProducts(branchId: branch.id, categoryId: product.categoryId);
                            setState(() { _loadedRelated = true; });
                          });
                        }
                        final related = productProvider.allProducts
                            .where((p) => p.categoryId == product.categoryId && p.id != product.id)
                            .take(10)
                            .toList();

                        if (productProvider.isLoading && !_loadedRelated) {
                          return Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator()));
                        }
                        if (related.isEmpty) return SizedBox.shrink();

                        return SizedBox(
                          height: 160,
                          child: ListView.separated(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            scrollDirection: Axis.horizontal,
                            itemCount: related.length,
                            separatorBuilder: (_, __) => SizedBox(width: 16),
                            itemBuilder: (ctx, i) {
                              final rp = related[i];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    ProductDetailScreen.routeName,
                                    arguments: {'product': rp, 'branch': branch},
                                  );
                                },
                                child: Container(
                                  width: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 10,
                                        offset: Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          _getImageUrl(rp.image),
                                          width: 90,
                                          height: 90,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 90,
                                            height: 90,
                                            color: Colors.grey[200],
                                            child: Icon(Icons.food_bank, color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        rp.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                        textAlign: TextAlign.center,
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
                     
                     SizedBox(height: 16),
                  ],
                ),
               ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionWidget(ProductOptionType option) {
    final currentSelection = _selectedOptions.firstWhere(
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
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
                  fontFamily: 'Inter',
                ),
              ),
              if (option.required) ...[
                SizedBox(width: 8),
                Text(
                  '*',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 12),
          if (option.type == 'select') ...[
            // Radio buttons for select type
            ...option.values.map((value) {
              final isSelected = currentSelection.selectedValueIds.contains(value.id);
              return GestureDetector(
                onTap: () => _updateOptionSelection(option, value, true),
                child: Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange.withOpacity(0.1) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.orange : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.orange : Colors.grey[400],
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          value.value,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? Colors.orange[700] : Colors.grey[700],
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      if (value.priceModifier != 0)
                        Text(
                          value.formattedPriceModifier,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: value.priceModifier > 0 ? Colors.green[600] : Colors.red[600],
                            fontFamily: 'Inter',
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ] else if (option.type == 'checkbox') ...[
            // Checkboxes for checkbox type
            ...option.values.map((value) {
              final isSelected = currentSelection.selectedValueIds.contains(value.id);
              return GestureDetector(
                onTap: () => _updateOptionSelection(option, value, !isSelected),
                child: Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange.withOpacity(0.1) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.orange : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                        color: isSelected ? Colors.orange : Colors.grey[400],
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          value.value,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? Colors.orange[700] : Colors.grey[700],
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      if (value.priceModifier != 0)
                        Text(
                          value.formattedPriceModifier,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: value.priceModifier > 0 ? Colors.green[600] : Colors.red[600],
                            fontFamily: 'Inter',
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildRelatedProductCard(String name, String? image) {
    return Container(
      width: 100,
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange, width: 3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(45),
              child: Image.network(
                _getImageUrl(image),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.food_bank, size: 40, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// _RelatedCarousel removed; related products are rendered inline above using
// Consumer<ProductProvider> and a horizontal ListView.