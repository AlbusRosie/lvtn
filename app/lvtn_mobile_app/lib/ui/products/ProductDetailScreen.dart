import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../../models/product.dart';
import '../../models/branch.dart';
import '../../models/product_option.dart';
import '../../providers/AuthProvider.dart';
import '../../providers/CategoryProvider.dart';
import '../../providers/ProductProvider.dart';
import '../../services/ProductOptionService.dart';
import '../../utils/image_utils.dart';
import '../../services/CartService.dart';
import '../../services/AuthService.dart';
import '../../ui/cart/CartProvider.dart';
import '../../ui/cart/CartScreen.dart';
import '../../constants/app_constants.dart';


class ProductReview {
  final String id;
  final String userName;
  final String userAvatar;
  final double rating;
  final String comment;
  final DateTime createdAt;
  
  ProductReview({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
}

class ProductDetailScreen extends StatefulWidget {
  static const String routeName = '/product-detail';
  final int? branchId; // Add branchId parameter

  const ProductDetailScreen({Key? key, this.branchId}) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> with TickerProviderStateMixin {
  bool _loadedRelated = false;
  bool _loadedOptions = false;
  bool _isFavorite = false;
  List<ProductOptionType> _productOptions = [];
  List<SelectedOption> _selectedOptions = [];
  final ProductOptionService _optionService = ProductOptionService();
  

  late AnimationController _favoriteAnimationController;
  Animation<double> _favoriteScaleAnimation = const AlwaysStoppedAnimation(1.0);
  late AnimationController _ratingPulseController;
  Animation<double> _ratingPulseAnimation = const AlwaysStoppedAnimation(1.0);
  

  double _averageRating = 4.5;
  int _totalReviews = 128;
  List<ProductReview> _reviews = [
    ProductReview(
      id: '1',
      userName: 'Nguyễn Văn A',
      userAvatar: 'https://i.pravatar.cc/150?img=1',
      rating: 5.0,
      comment: 'Sản phẩm rất ngon, giao hàng nhanh. Sẽ ủng hộ thêm!',
      createdAt: DateTime.now().subtract(Duration(days: 2)),
    ),
    ProductReview(
      id: '2',
      userName: 'Trần Thị B',
      userAvatar: 'https://i.pravatar.cc/150?img=2',
      rating: 4.0,
      comment: 'Món ăn ổn, nhưng hơi nhỏ so với giá tiền.',
      createdAt: DateTime.now().subtract(Duration(days: 5)),
    ),
    ProductReview(
      id: '3',
      userName: 'Lê Minh C',
      userAvatar: 'https://i.pravatar.cc/150?img=3',
      rating: 5.0,
      comment: 'Tuyệt vời! Đúng khẩu vị của tôi.',
      createdAt: DateTime.now().subtract(Duration(days: 7)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    

    _favoriteAnimationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    
    _favoriteScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _favoriteAnimationController,
      curve: Curves.easeInOut,
    ));


    _ratingPulseController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _ratingPulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _ratingPulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _favoriteAnimationController.dispose();
    _ratingPulseController.dispose();
    super.dispose();
  }

  String _getImageUrl(String? imagePath) {
    return ImageUtils.getImageUrl(imagePath);
  }

  Future<void> _loadProductOptions(int productId) async {
    if (_loadedOptions) return;
    
    try {
      final options = await _optionService.getProductOptionsWithDetails(productId);
      final defaultSelections = _optionService.createDefaultSelections(options);
      
      setState(() {
        _productOptions = options;
        _selectedOptions = defaultSelections;
        _loadedOptions = true;
      });
    } catch (error) {
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


  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    
    _favoriteAnimationController.forward(from: 0.0);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isFavorite ? Symbols.favorite : Symbols.heart_broken,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 12),
            Text(
              _isFavorite ? 'Đã thêm vào yêu thích' : 'Đã xóa khỏi yêu thích',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: _isFavorite ? Colors.red.shade600 : Colors.grey[700],
        duration: Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }


  void _openReviewSheet(Product product) {
    double userRating = 5.0;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  left: 24,
                  right: 24,
                  top: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Đánh giá sản phẩm',
                      style: TextStyle(
                          fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () {
                              setSheetState(() {
                                userRating = index + 1.0;
                              });
                            },
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                                  index < userRating ? Symbols.grade : Symbols.grade,
                                  color: index < userRating ? Colors.amber[600] : Colors.grey[300],
                                  size: 44,
                                ),
                            ),
                          );
                        }),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: commentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Chia sẻ trải nghiệm của bạn...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.orange, width: 2),
                        ),
                          contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                        height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          if (commentController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Vui lòng nhập nội dung đánh giá'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          
                          setState(() {
                            _reviews.insert(0, ProductReview(
                              id: DateTime.now().toString(),
                              userName: 'Bạn',
                              userAvatar: 'https://i.pravatar.cc/150?img=10',
                              rating: userRating,
                              comment: commentController.text,
                              createdAt: DateTime.now(),
                            ));
                            _totalReviews++;
                            double sum = _reviews.fold(0, (prev, review) => prev + review.rating);
                            _averageRating = sum / _reviews.length;
                          });
                          
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Symbols.check_circle, color: Colors.white, fill: 1),
                                    SizedBox(width: 12),
                                    Text('Cảm ơn bạn đã đánh giá!'),
                                  ],
                                ),
                              backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: EdgeInsets.all(16),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Gửi đánh giá',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  void _viewAllReviews() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Customer reviews',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _reviews.length,
                    itemBuilder: (context, index) {
                      return _buildReviewCard(_reviews[index]);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openOptionsSheet(Product product, int branchId, String branchName) async {
    if (!_loadedOptions) {
      await _loadProductOptions(product.id);
    }

    if (_productOptions.isEmpty) {

                          try {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            if (!authProvider.isAuth) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Please log in to add items to cart.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final token = AuthService().token;
                            
                            if (token == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Authentication token not found. Please log in again.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final cartProvider = Provider.of<CartProvider>(context, listen: false);
                            
                            // Check if switching branches with items in cart
                            if (cartProvider.needsBranchSwitchConfirmation(branchId)) {
                              final shouldSwitch = await _showBranchSwitchDialog(
                                cartProvider.currentBranchName ?? 'previous branch',
                                branchName,
                              );
                              
                              if (shouldSwitch != true) {
                                return; // User cancelled
                              }
                              
                              // Clear old cart before adding to new branch
                              await cartProvider.clearCartForBranchSwitch();
                            }
                            
                            await cartProvider.addToCart(
                              branchId, // Use the correct branch ID
                              product.id,
                              quantity: 1,
                              orderType: 'dine_in', // Default to dine_in
                              selectedOptions: [], // No options for products without options
                            );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${product.name} to cart\nTotal: ${_formatPrice(cartProvider.currentCart?.total ?? 0.0)}'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to cart: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.orange.shade50,
                Colors.white,
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                int sheetQuantity = 1; // Move inside StatefulBuilder
                
                void updateInSheet(ProductOptionType optionType, ProductOptionValue value, bool isSelected) {
                  setState(() => _updateOptionSelection(optionType, value, isSelected));
                  setSheetState(() {});
                }

                Widget optionItem(ProductOptionType option) {
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
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.shade100, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.08),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                              Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.orange.shade400, Colors.orange.shade600],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  option.type == 'select' 
                                      ? Symbols.radio_button_checked 
                                      : Symbols.checklist,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                              if (option.required)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Required',
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 12),
                        if (option.type == 'select') ...[
                          ...option.values.map((value) {
                            final isSelected = currentSelection.selectedValueIds.contains(value.id);
                              return Container(
                                margin: EdgeInsets.only(bottom: 8),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => updateInSheet(option, value, true),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.orange.shade50 : Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected ? Colors.orange.shade300 : Colors.grey[200]!,
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isSelected ? Colors.orange : Colors.grey[400]!,
                                                width: 2,
                                              ),
                                              color: isSelected ? Colors.orange : Colors.transparent,
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
                                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                                color: isSelected ? Colors.grey[800] : Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                          if (value.priceModifier != 0)
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: value.priceModifier > 0
                                                    ? Colors.green.shade50
                                                    : Colors.red.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                value.formattedPriceModifier,
                                                style: TextStyle(
                                                  color: value.priceModifier > 0
                                                      ? Colors.green[700]
                                                      : Colors.red[700],
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            );
                          })
                        ] else ...[
                          ...option.values.map((value) {
                            final isSelected = currentSelection.selectedValueIds.contains(value.id);
                              return Container(
                                margin: EdgeInsets.only(bottom: 8),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => updateInSheet(option, value, !isSelected),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.orange.shade50 : Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected ? Colors.orange.shade300 : Colors.grey[200]!,
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(5),
                                              border: Border.all(
                                                color: isSelected ? Colors.orange : Colors.grey[400]!,
                                                width: 2,
                                              ),
                                              color: isSelected ? Colors.orange : Colors.transparent,
                                            ),
                                            child: isSelected
                                                ? Icon(
                                                    Symbols.check,
                                                    color: Colors.white,
                                                    size: 14,
                                                  )
                                                : null,
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              value.value,
                                  style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                                color: isSelected ? Colors.grey[800] : Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                          if (value.priceModifier != 0)
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: value.priceModifier > 0
                                                    ? Colors.green.shade50
                                                    : Colors.red.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                value.formattedPriceModifier,
                                                style: TextStyle(
                                                  color: value.priceModifier > 0
                                                      ? Colors.green[700]
                                                      : Colors.red[700],
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            );
                          })
                        ],
                      ],
                    ),
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                      Container(
                        padding: EdgeInsets.fromLTRB(24, 16, 24, 20),
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Symbols.tune,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Customize',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Make it exactly how you like it',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
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
                      

                    Flexible(
                      child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: _productOptions.map(optionItem).toList(),
                        ),
                      ),
                    ),
                      

                      Container(
                        padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Colors.grey[200]!, width: 1),
                          ),
                        ),
                        child: Column(
                          children: [

                    Row(
                      children: [
                                Text(
                                  'Quantity',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Spacer(),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[200]!, width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(11),
                                            bottomLeft: Radius.circular(11),
                                          ),
                                          onTap: sheetQuantity > 1
                                              ? () {
                                                  setSheetState(() => sheetQuantity -= 1);
                                                }
                                              : null,
                                          child: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: sheetQuantity > 1
                                                  ? Colors.orange.shade50
                                                  : Colors.grey[50],
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(11),
                                                bottomLeft: Radius.circular(11),
                                              ),
                                            ),
                                            child: Icon(
                                              Symbols.remove,
                                              color: sheetQuantity > 1
                                                  ? Colors.orange.shade700
                                                  : Colors.grey[400],
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 50,
                                        height: 40,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          border: Border.symmetric(
                                            vertical: BorderSide(
                                              color: Colors.grey[200]!,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                          child: Text(
                                          sheetQuantity.toString(),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ),
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(11),
                                            bottomRight: Radius.circular(11),
                                          ),
                                          onTap: () {
                                            setSheetState(() => sheetQuantity += 1);
                                          },
                                          child: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.orange.shade400,
                                                  Colors.orange.shade600,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.only(
                                                topRight: Radius.circular(11),
                                                bottomRight: Radius.circular(11),
                                              ),
                                            ),
                                            child: Icon(
                                              Symbols.add,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total amount',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        _formatPrice(_calculateTotalPrice(product) * sheetQuantity),
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 54,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!_optionService.validateRequiredOptions(_productOptions, _selectedOptions)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  Icon(Symbols.warning, color: Colors.white, fill: 1),
                                                  SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text('Please select all required options'),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: Colors.red,
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              margin: EdgeInsets.all(16),
                                            ),
                                );
                                return;
                              }
                              
                              try {
                                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                if (!authProvider.isAuth) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Please log in to add items to cart.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                final token = AuthService().token;
                                
                                if (token == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Authentication token not found. Please log in again.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                final cartProvider = Provider.of<CartProvider>(context, listen: false);
                                
                                // Check if switching branches with items in cart
                                if (cartProvider.needsBranchSwitchConfirmation(branchId)) {
                                  final shouldSwitch = await _showBranchSwitchDialog(
                                    cartProvider.currentBranchName ?? 'previous branch',
                                    branchName,
                                  );
                                  
                                  if (shouldSwitch != true) {
                                    return; // User cancelled, keep bottom sheet open
                                  }
                                  
                                  // Clear old cart before adding to new branch
                                  await cartProvider.clearCartForBranchSwitch();
                                }
                                
                                // Close the bottom sheet
                                Navigator.pop(ctx);
                                
                                await cartProvider.addToCart(
                                  branchId,
                                  product.id,
                                  quantity: sheetQuantity,
                                  orderType: 'dine_in',
                                  selectedOptions: _selectedOptions,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Symbols.check_circle, color: Colors.white, fill: 1),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text('Added ${product.name} x$sheetQuantity to cart\nTotal: ${_formatPrice(_calculateTotalPrice(product) * sheetQuantity)}'),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    margin: EdgeInsets.all(16),
                                  ),
                                );
                              } catch (e) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to add to cart: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: Ink(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.orange.shade400,
                                              Colors.orange.shade600,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(14),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.orange.withOpacity(0.4),
                                              blurRadius: 12,
                                              offset: Offset(0, 4),
                        ),
                      ],
                    ),
                                        child: Container(
                                          alignment: Alignment.center,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Symbols.shopping_bag,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Add to cart',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
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
                          ],
                        ),
                      ),
                  ],
                );
              },
              ),
            ),
          ),
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final Product product = args['product'];
    final Branch branch = args['branch'];
    

    final int branchId = widget.branchId ?? branch.id;

    if (!_loadedOptions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadProductOptions(product.id);
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomBar(product, branchId, branch.name),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            children: [

              Container(
                height: MediaQuery.of(context).size.height * 0.5,
                child: Stack(
                  clipBehavior: Clip.none,
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
                              icon: Icon(Symbols.arrow_back_ios, color: Colors.white, size: 20, fill: 1),
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
                          _buildHeaderCartButton(product, branchId),
                        ],
                      ),
                    ),


                    Positioned(
                      bottom: -20,
                      left: 0,
                      right: 0,
                      child: Center(child: _buildEnhancedRatingBadge()),
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
                              width: 320,
                              height: 320,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(175),
                                child: Image.network(
                                  _getImageUrl(product.image),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: Icon(Symbols.fastfood, size: 100, color: Colors.grey, fill: 1),
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


              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
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

                    SizedBox(height: 16),

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

                    SizedBox(height: 24),

                    _buildReviewsList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedFavoriteButton() {
    return ScaleTransition(
      scale: _favoriteScaleAnimation,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: _isFavorite
              ? LinearGradient(
                  colors: [Colors.red.shade400, Colors.red.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.2)],
                ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _isFavorite ? Colors.red.withOpacity(0.4) : Colors.black.withOpacity(0.1),
              blurRadius: _isFavorite ? 12 : 8,
              offset: Offset(0, 4),
              spreadRadius: _isFavorite ? 2 : 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: _toggleFavorite,
            child: Center(
              child: Icon(
                _isFavorite ? Symbols.favorite : Symbols.favorite, // use filled color to distinguish
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCartButton(Product product, int branchId) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CartScreen(
                  branchId: branchId,
                  branchName: 'Beast Bite Branch $branchId', // You can get actual branch name from context
                ),
              ),
            );
          },
          child: Center(
            child: Icon(Symbols.shopping_cart, color: Colors.white, size: 22, fill: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomFavoriteButton() {
    return ScaleTransition(
      scale: _favoriteScaleAnimation,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _isFavorite ? Colors.red.shade50 : Colors.grey[100],
          border: Border.all(color: _isFavorite ? Colors.red.shade200 : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: _toggleFavorite,
            child: Icon(
              _isFavorite ? Symbols.favorite : Symbols.favorite,
              color: _isFavorite ? Colors.red : Colors.grey[700],
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedRatingBadge() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final Product? product = args != null ? args['product'] as Product? : null;

    return ScaleTransition(
      scale: _ratingPulseAnimation,
      child: GestureDetector(
        onTap: () {
          if (product != null) {
            _openReviewSheet(product);
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.amber.shade400,
                Colors.orange.shade500,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.5),
                blurRadius: 12,
                offset: Offset(0, 4),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.amber.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
      ),
      child: Row(
            mainAxisSize: MainAxisSize.min,
        children: [
              Icon(Symbols.grade, color: Colors.white, size: 18, fill: 1),
          SizedBox(width: 6),
          Text(
            _averageRating.toStringAsFixed(1),
            style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(width: 8),
              Container(
                width: 1,
                height: 14,
                color: Colors.white.withOpacity(0.5),
              ),
              SizedBox(width: 8),
          Text(
                '$_totalReviews',
            style: TextStyle(
                  fontSize: 13,
                fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.95),
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Symbols.reviews, color: Colors.orange, size: 20, fill: 1),
                SizedBox(width: 8),
            Text(
                  'Customer reviews',
              style: TextStyle(
                    fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
                ),
              ],
            ),
            TextButton(
              onPressed: _viewAllReviews,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: Row(
                children: [
                  Text(
                    'See all',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                      fontSize: 13,
                ),
                  ),
                  SizedBox(width: 4),
                  Icon(Symbols.chevron_right, color: Colors.orange, size: 14, fill: 1),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        ..._reviews.take(2).map((review) => _buildReviewCard(review)).toList(),
      ],
    );
  }


  Widget _buildReviewCard(ProductReview review) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.orange.shade100, width: 2),
                ),
                child: CircleAvatar(
                  radius: 18,
                backgroundImage: NetworkImage(review.userAvatar),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Symbols.grade, color: Colors.amber[700], size: 14, fill: 1),
                              SizedBox(width: 4),
                              Text(
                                review.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.amber[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          _getTimeAgo(review.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            review.comment,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7} tuần trước';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  Widget _buildBottomBar(Product product, int branchId, String branchName) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                SizedBox(height: 4),
                Text(
                  _formatPrice(_calculateTotalPrice(product)),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 12),
            child: _buildBottomFavoriteButton(),
          ),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _openOptionsSheet(product, branchId, branchName),
              icon: Icon(Symbols.add_shopping_cart, color: Colors.white, size: 20, fill: 1),
              label: Text(
                'Add to cart',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 2,
                shadowColor: Colors.orange.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
