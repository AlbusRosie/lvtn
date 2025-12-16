import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/CategoryProvider.dart';
import '../../providers/ProductProvider.dart';
import '../../models/branch.dart';
import '../../models/category.dart' as CategoryModel;
import '../../models/product.dart';
import '../../constants/app_constants.dart';
import '../cart/CartProvider.dart';
import '../../utils/image_utils.dart';
import '../../services/CartService.dart';
import '../../services/AuthService.dart';
import '../../services/NotificationService.dart';
import '../products/ProductOptionEditDialog.dart';
import '../../models/cart.dart';
import '../../models/product_option.dart';
import '../../services/ProductOptionService.dart';

class ReservationMenuScreen extends StatefulWidget {
  final Branch branch;
  final int reservationId;
  
  const ReservationMenuScreen({
    Key? key,
    required this.branch,
    required this.reservationId,
  }) : super(key: key);
  
  static const String routeName = '/reservation-menu';

  @override
  State<ReservationMenuScreen> createState() => _ReservationMenuScreenState();
}

class _ReservationMenuScreenState extends State<ReservationMenuScreen> {
  int? selectedCategoryId = 0; 
  final ScrollController _scrollController = ScrollController();
  bool _isConfirming = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      
      // Load categories đầy đủ trước
      await categoryProvider.loadCategories();
      
      productProvider.resetPagination();
      await productProvider.loadProducts(branchId: widget.branch.id, loadAll: true);
      
      await cartProvider.loadCart(widget.branch.id);
    });
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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      if (!productProvider.isLoadingMore && productProvider.hasMore) {
        productProvider.loadMoreProducts();
      }
    }
  }

  String _getCategoryEmoji(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'burger': return '🍔';
      case 'pizza': return '🍕';
      case 'hot dog': return '🌭';
      case 'chicken': return '🍗';
      case 'sandwich': return '🥪';
      case 'salad': return '🥗';
      case 'drink':
      case 'beverage':
      case 'refreshment': return '☕';
      case 'light bites': return '🥙';
      case 'dessert': return '🍰';
      case 'coffee': return '☕';
      case 'tea': return '🍵';
      default: return '🍽️';
    }
  }

  String _getImageUrl(String? imagePath) {
    return ImageUtils.getImageUrl(imagePath);
  }

  String _formatCurrency(double value) {
    final s = value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$s đ';
  }

  Future<void> _editProductOptions(CartItem item, CartProvider cartProvider) async {
    await showDialog(
      context: context,
      builder: (context) => ProductOptionEditDialog(
        cartItem: item,
        onOptionUpdated: (updatedItem) async {
          await cartProvider.loadCart(widget.branch.id);
        },
      ),
    );
  }

  Future<void> _showProductOptionsDialog(Product product) async {
    int quantity = 1;
    String? specialRequest = '';
    List<ProductOptionType> productOptions = [];
    List<SelectedOption> selectedOptions = [];
    bool isLoadingOptions = true;

    try {
      productOptions = await ProductOptionService().getProductOptionsWithDetails(product.id);
      selectedOptions = ProductOptionService().createDefaultSelections(productOptions);
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
                                          'Giá: ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white.withOpacity(0.9),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          _formatCurrency(basePrice),
                                          style: TextStyle(
                                            fontSize: 20,
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
                                          'Tùy chọn',
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
                                    'Số lượng',
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
                                        'Ghi chú đặc biệt',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[900],
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        '(Tùy chọn)',
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
                                        hintText: 'Ví dụ: Không hành, cay vừa, chín kỹ...',
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
                                      'Tổng tiền',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _formatCurrency(grandTotal),
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[900],
                                        height: 1.2,
                                      ),
                                    ),
                                    if (optionsModifier != 0) ...[
                                      SizedBox(height: 4),
                                      Text(
                                        '${_formatCurrency(basePrice)} + ${_formatCurrency(optionsModifier)} × $quantity',
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
                                              'Thêm vào giỏ',
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
                    'Bắt buộc',
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
              'Chọn một tùy chọn',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ] else if (option.type == 'checkbox') ...[
            SizedBox(height: 8),
            Text(
              'Chọn một hoặc nhiều',
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

  Future<void> _confirmOrder(BuildContext? bottomSheetContext) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    if (cartProvider.cart == null || cartProvider.itemCount == 0) {
      NotificationService().showWarning(
        context: context,
        message: 'Vui lòng chọn ít nhất một món',
      );
      return;
    }

    setState(() {
      _isConfirming = true;
    });

    try {
      final token = AuthService().token;
      if (token == null) {
        throw Exception('Bạn cần đăng nhập để đặt món');
      }

      final cart = cartProvider.cart!;
      
      // Get customer name and phone from user account
      String? customerName;
      String? customerPhone;
      final authService = AuthService();
      final user = authService.currentUser;
      
      if (user != null) {
        if (user.name.isNotEmpty) {
          customerName = user.name;
        }
        if (user.phone != null && user.phone!.isNotEmpty) {
          customerPhone = user.phone;
        }
      }
      
      await CartService.checkout(
        token: token,
        cartId: cart.id,
        reservationId: widget.reservationId,
        customerName: customerName,
        customerPhone: customerPhone,
      );

      if (bottomSheetContext != null && Navigator.canPop(bottomSheetContext)) {
        Navigator.pop(bottomSheetContext);
      }

      if (mounted) {
        final returnResult = {'orderCreated': true, 'reservationId': widget.reservationId};
        
        Navigator.pop(context, returnResult);
      }
    } catch (e) {
      if (mounted) {
        NotificationService().showError(
          context: context,
          message: 'Lỗi khi đặt món: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConfirming = false;
        });
      }
    }
  }

  void _showCartBottomSheet(CartProvider cartProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    Text(
                      'Giỏ hàng',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(bottomSheetContext),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: cartProvider.cart == null || cartProvider.itemCount == 0
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
                            SizedBox(height: 16),
                            Text(
                              'Giỏ hàng trống',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: cartProvider.cart!.items.length,
                        itemBuilder: (context, index) {
                          final item = cartProvider.cart!.items[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => _editProductOptions(item, cartProvider),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.orange[100],
                                  child: Icon(Icons.restaurant, color: Colors.orange),
                                ),
                                title: Text(item.productName ?? 'Món'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${item.quantity}x - ${item.price.toStringAsFixed(0)}đ'),
                                    if (item.selectedOptions != null && item.selectedOptions!.isNotEmpty)
                                      Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Có ${item.selectedOptions!.length} tùy chọn',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.orange[700],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${(item.price * item.quantity).toStringAsFixed(0)}đ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.edit, size: 18, color: Colors.grey[600]),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tổng tiền:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${cartProvider.total.toStringAsFixed(0)}đ',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isConfirming ? null : () => _confirmOrder(bottomSheetContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isConfirming
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Xác nhận đặt món',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.grey[600]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Đặt món cho đặt bàn',
          style: TextStyle(
            color: Colors.grey[900],
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              return Padding(
                padding: EdgeInsets.only(right: 16, top: 8, bottom: 8),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: () => _showCartBottomSheet(cartProvider),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Color(0xFF2C2C2C),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 24),
                      ),
                    ),
                    if (cartProvider.itemCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            '${cartProvider.itemCount}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
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
      body: Consumer2<CategoryProvider, ProductProvider>(
        builder: (context, categoryProvider, productProvider, child) {
            List<CategoryModel.Category> availableCategories = [];
            if (!productProvider.isLoading && productProvider.allProducts.isNotEmpty) {
              Set<int> categoryIds = productProvider.allProducts
                  .where((p) => p.categoryId != null)
                  .map((p) => p.categoryId!)
                  .toSet();

              availableCategories = categoryProvider.categories
                  .where((cat) => categoryIds.contains(cat.id))
                  .toList();
            }

            if (categoryProvider.isLoading || productProvider.isLoading) {
              return Center(child: CircularProgressIndicator());
            }

            if (availableCategories.isEmpty && !productProvider.isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      'Chưa có món nào',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Container(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: availableCategories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSelected = selectedCategoryId == 0;
                        return Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text('Tất cả'),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                selectedCategoryId = 0;
                              });
                            },
                            selectedColor: Colors.orange,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[700],
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      }

                      final category = availableCategories[index - 1];
                      final isSelected = selectedCategoryId == category.id;
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_getCategoryEmoji(category.name ?? '')),
                              SizedBox(width: 4),
                              Text(category.name ?? ''),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              selectedCategoryId = category.id;
                            });
                          },
                          selectedColor: Colors.orange,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16),
                    itemCount: selectedCategoryId == 0
                        ? productProvider.allProducts.length
                        : productProvider.allProducts
                            .where((p) => p.categoryId == selectedCategoryId)
                            .length,
                    itemBuilder: (context, index) {
                      final products = selectedCategoryId == 0
                          ? productProvider.allProducts
                          : productProvider.allProducts
                              .where((p) => p.categoryId == selectedCategoryId)
                              .toList();
                      
                      if (index >= products.length) {
                        return SizedBox.shrink();
                      }

                      final product = products[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            _showProductOptionsDialog(product);
                          },
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _getImageUrl(product.image),
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[200],
                                        child: Icon(Icons.restaurant, color: Colors.grey[400]),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name ?? 'Món',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        product.description ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '${product.basePrice.toStringAsFixed(0)}đ',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.itemCount == 0) {
            return SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: () => _showCartBottomSheet(cartProvider),
            backgroundColor: Colors.orange,
            icon: Icon(Icons.shopping_cart, color: Colors.white),
            label: Text(
              'Giỏ hàng (${cartProvider.itemCount})',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
      ),
    );
  }
}

