import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/branch.dart';
import '../../models/product.dart';
import '../../providers/BranchProvider.dart';
import '../../providers/ProductProvider.dart';
import '../../providers/CategoryProvider.dart';
import '../../providers/LocationProvider.dart';
import '../../providers/AuthProvider.dart';
import '../cart/CartProvider.dart';
import '../cart/CartScreen.dart';
import '../widgets/AppBottomNav.dart';
import '../../utils/image_utils.dart';
import '../../services/ProductOptionService.dart';
import '../../models/product_option.dart';

class QuickOrderScreen extends StatefulWidget {
  static const String routeName = '/quick-order';
  
  const QuickOrderScreen({super.key});

  @override
  State<QuickOrderScreen> createState() => _QuickOrderScreenState();
}

class _QuickOrderScreenState extends State<QuickOrderScreen> {
  int _currentStep = 0;
  Branch? _selectedBranch;
  final Map<int, int> _cartItems = {};
  final Map<int, List<SelectedOption>> _cartItemOptions = {};
  final Map<int, String> _cartItemSpecialInstructions = {};
  bool _isLoading = false;


  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _numberOfGuests = 2;
  String _specialRequests = '';


  int? _selectedCategoryId = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BranchProvider>(context, listen: false).loadBranches();
      Provider.of<LocationProvider>(context, listen: false).loadProvinces();
      Provider.of<CategoryProvider>(context, listen: false).loadCategories();
    });
  }

  Future<void> _loadProducts() async {
    if (_selectedBranch == null) return;
    setState(() => _isLoading = true);
    try {
      await Provider.of<ProductProvider>(context, listen: false)
          .loadProducts(branchId: _selectedBranch!.id);
      await Provider.of<CategoryProvider>(context, listen: false)
          .loadCategories();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  List<Product> _getFilteredProducts() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    if (_selectedCategoryId == 0 || _selectedCategoryId == null) {
      return productProvider.products;
    }
    return productProvider.products.where((product) => product.categoryId == _selectedCategoryId).toList();
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: SafeArea(
          bottom: false,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.grey[800],
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Đặt hàng nhanh',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[900],
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Consumer<CartProvider>(
                    builder: (context, cartProvider, child) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showCartBottomSheet(cartProvider),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
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
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: _buildCurrentStepContent(),
          ),
          _buildBottomNavigation(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Chi nhánh', 'Đặt bàn', 'Chọn món'];
    
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStepItem(
            stepIndex: 0,
            stepName: steps[0],
            isActive: _currentStep == 0,
            isCompleted: _currentStep > 0,
            showConnector: true,
          ),
          _buildStepItem(
            stepIndex: 1,
            stepName: steps[1],
            isActive: _currentStep == 1,
            isCompleted: _currentStep > 1,
            showConnector: true,
          ),
          _buildStepItem(
            stepIndex: 2,
            stepName: steps[2],
            isActive: _currentStep == 2,
            isCompleted: false,
            showConnector: false,
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required int stepIndex,
    required String stepName,
    required bool isActive,
    required bool isCompleted,
    required bool showConnector,
  }) {
    final primaryColor = Color(0xFFFF8A00);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted || isActive
                    ? primaryColor
                    : Colors.grey[200],
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: isCompleted
                    ? Icon(Icons.check_rounded, color: Colors.white, size: 20)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              stepName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? primaryColor : Colors.grey[600],
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        if (showConnector)
          Container(
            width: 60,
            height: 2,
            margin: EdgeInsets.only(bottom: 20, left: 8, right: 8),
            decoration: BoxDecoration(
              color: isCompleted ? primaryColor : Colors.grey[300],
              borderRadius: BorderRadius.circular(1),
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildBranchSelectionStep();
      case 1:
        return _buildReservationStep();
      case 2:
        return _buildMenuSelectionStep();
      default:
        return SizedBox();
    }
  }


  Widget _buildBranchSelectionStep() {
    final branchProvider = Provider.of<BranchProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final branches = _getSuggestedBranches(
      branchProvider,
      provinceId: locationProvider.selectedProvince?.id,
      districtId: locationProvider.selectedDistrict?.id,
    );
    final primaryColor = Color(0xFFFF8A00);

    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Chọn nhà hàng',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                  letterSpacing: -0.4,
                  height: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: branches.length,
              separatorBuilder: (_, __) => SizedBox(height: 16),
              itemBuilder: (context, index) {
                final branch = branches[index];
                final isSelected = _selectedBranch?.id == branch.id;
                
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedBranch = branch;
                      });

                      Future.delayed(Duration(milliseconds: 300), () {
                        if (mounted) {
                          setState(() {
                            _currentStep = 1;
                          });
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? primaryColor : Colors.grey[200]!,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? primaryColor.withOpacity(0.15)
                                : Colors.black.withOpacity(0.06),
                            blurRadius: 20,
                            offset: Offset(0, 4),
                            spreadRadius: 0,
                          ),
                          if (!isSelected)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                              spreadRadius: 0,
                            ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _getBranchImageUrl(branch.image),
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isSelected
                                          ? [primaryColor.withOpacity(0.8), primaryColor]
                                          : [Colors.grey[300]!, Colors.grey[400]!],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.store_rounded,
                                    color: Colors.white,
                                    size: 32,
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                branch.name,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[900],
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, 
                                    size: 14, 
                                    color: Colors.grey[600]
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      branch.address,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 20,
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
      ),
    );
  }


  Widget _buildReservationStep() {
    final primaryColor = Color(0xFFFF8A00);
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryColor.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.store_rounded, color: primaryColor, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedBranch?.name ?? '',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900],
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _selectedBranch?.address ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _currentStep = 0),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text(
                        'Đổi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Chi tiết đặt bàn',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[900],
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                

                Row(
                  children: [

                    Expanded(
                      child: _buildCompactInfoTile(
                        icon: Icons.calendar_today_outlined,
                        label: 'Ngày',
                        value: _formatCompactDate(_selectedDate),
                        onTap: _selectDate,
                      ),
                    ),
                    SizedBox(width: 12),

                    Expanded(
                      child: _buildCompactInfoTile(
                        icon: Icons.access_time_outlined,
                        label: 'Giờ',
                        value: _selectedTime.format(context),
                        onTap: _selectTime,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 12),
                

                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.people_rounded, color: primaryColor, size: 20),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Số khách',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacer(),
                      _buildCompactCounter(
                        icon: Icons.remove_rounded,
                        onTap: _numberOfGuests > 1
                            ? () => setState(() => _numberOfGuests--)
                            : null,
                      ),
                      Container(
                        width: 50,
                        alignment: Alignment.center,
                        child: Text(
                          '$_numberOfGuests',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      _buildCompactCounter(
                        icon: Icons.add_rounded,
                        onTap: _numberOfGuests < 20
                            ? () => setState(() => _numberOfGuests++)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.currentUser;
              final hasInfo = user?.name?.isNotEmpty == true && 
                             user?.phone?.isNotEmpty == true;
              
              return Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hasInfo ? Colors.green.withOpacity(0.2) : primaryColor.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: hasInfo ? Colors.green : primaryColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(width: 12),
                        Icon(
                          hasInfo ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                          color: hasInfo ? Colors.green : primaryColor,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Thông tin liên hệ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[900],
                            letterSpacing: -0.3,
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
                                'Họ tên',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                user?.name ?? 'Chưa có',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: user?.name != null ? Colors.grey[900] : primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Điện thoại',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                user?.phone ?? 'Chưa có',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: user?.phone != null ? Colors.grey[900] : primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!hasInfo) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryColor.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, 
                              color: primaryColor, 
                              size: 18
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Vui lòng cập nhật thông tin trong Tài khoản',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(Icons.note_alt_outlined, color: primaryColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Yêu cầu đặc biệt',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[900],
                        letterSpacing: -0.3,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '(Tùy chọn)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextField(
                  maxLines: 3,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                  decoration: InputDecoration(
                    hintText: 'VD: Gần cửa sổ, tránh thức ăn cay...',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    contentPadding: EdgeInsets.all(16),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) => _specialRequests = value,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCompactInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final primaryColor = Color(0xFFFF8A00);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: primaryColor, size: 18),
                  ),
                  SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[900],
                      ),
                    ),
                  ),
                  Icon(Icons.edit_rounded, size: 16, color: Colors.grey[400]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildCompactCounter({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final primaryColor = Color(0xFFFF8A00);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap != null ? primaryColor : Colors.grey[300],
          shape: BoxShape.circle,
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }


  Widget _buildMenuSelectionStep() {
    final productProvider = Provider.of<ProductProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final primaryColor = Color(0xFFFF8A00);
    
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      );
    }
    
    if (productProvider.products.isEmpty) {
      Future.microtask(() => _loadProducts());
      return Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      );
    }

    final filteredProducts = _getFilteredProducts();

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
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
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Chọn món ăn',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[900],
                      letterSpacing: -0.4,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: primaryColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: primaryColor),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_formatDate(_selectedDate)} • ${_selectedTime.format(context)} • $_numberOfGuests người',
                        style: TextStyle(
                          fontSize: 14,
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        

        Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Danh mục món',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 16),
              Container(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categoryProvider.categories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isAllSelected = _selectedCategoryId == 0;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategoryId = isAllSelected ? null : 0;
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 80,
                            margin: EdgeInsets.only(right: 12),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isAllSelected ? primaryColor : Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isAllSelected ? primaryColor : Colors.grey[200]!,
                                width: isAllSelected ? 2 : 1,
                              ),
                              boxShadow: isAllSelected
                                  ? [
                                      BoxShadow(
                                        color: primaryColor.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.apps,
                                  color: Colors.grey[600],
                                  size: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tất cả',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isAllSelected ? Colors.white : Colors.grey[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                    
                    final category = categoryProvider.categories[index - 1];
                    final isSelected = _selectedCategoryId == category.id;
                    
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategoryId = isSelected ? null : category.id;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 80,
                          margin: EdgeInsets.only(right: 12),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryColor : Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? primaryColor : Colors.grey[200]!,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _getCategoryEmoji(category.name),
                              style: TextStyle(fontSize: 20),
                            ),
                            SizedBox(height: 4),
                            Text(
                              category.name,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
          ),
        ),
        

        Expanded(
          child: filteredProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu, color: Colors.grey[400], size: 48),
                      SizedBox(height: 8),
                      Text(
                        'Không có món trong danh mục này',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.all(16),
                  itemCount: filteredProducts.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    final quantity = _cartItems[product.id] ?? 0;
                    return _ProductDineInItem(
                      product: product,
                      quantity: quantity,
                      onQuantityChanged: (q, {List<SelectedOption>? options, String? specialInstructions}) {
                        setState(() {
                          if (q <= 0) {
                            _cartItems.remove(product.id);
                            _cartItemOptions.remove(product.id);
                            _cartItemSpecialInstructions.remove(product.id);
                          } else {
                            _cartItems[product.id] = q;
                            if (options != null) {
                              _cartItemOptions[product.id] = options;
                            }
                            if (specialInstructions != null && specialInstructions.isNotEmpty) {
                              _cartItemSpecialInstructions[product.id] = specialInstructions;
                            }
                          }
                        });
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    final canProceed = _canProceedToNextStep();
    final primaryColor = Color(0xFFFF8A00);
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep--),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryColor, width: 1.5),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Quay lại',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _currentStep == 2 && _cartItems.isNotEmpty
                  ? _buildFinalSubmitButton()
                  : Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: canProceed
                            ? [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: ElevatedButton(
                        onPressed: canProceed ? _handleNextStep : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          disabledBackgroundColor: Colors.grey[300],
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentStep == 2 ? 'Bỏ qua chọn món' : 'Tiếp tục',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
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

  Widget _buildFinalSubmitButton() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final primaryColor = Color(0xFFFF8A00);
    final total = _cartItems.entries.fold<double>(0, (sum, e) {
      final p = productProvider.products.firstWhere((x) => x.id == e.key);
      return sum + p.basePrice * e.value;
    });

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _onSubmitReservation,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Xác nhận đặt bàn',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
            if (_cartItems.isNotEmpty) ...[
              SizedBox(height: 4),
              Text(
                '${_cartItems.length} món • ${_formatCurrency(total)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0:
        return _selectedBranch != null;
      case 1:

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.currentUser;
        return user?.name?.isNotEmpty == true && user?.phone?.isNotEmpty == true;
      case 2:
        return true;
      default:
        return false;
    }
  }

  void _handleNextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      if (_currentStep == 2) {
        _loadProducts();
      }
    } else {
      _onSubmitReservation();
    }
  }

  Future<void> _onSubmitReservation() async {
    if (_selectedBranch == null) return;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user?.name?.isEmpty == true || user?.phone?.isEmpty == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng cập nhật đầy đủ thông tin cá nhân trước khi đặt bàn'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    try {







      

      if (cartProvider.needsBranchSwitchConfirmation(_selectedBranch!.id)) {
        final shouldSwitch = await _showBranchSwitchDialog(
          cartProvider.currentBranchName ?? 'previous branch',
          _selectedBranch!.name,
        );
        
        if (shouldSwitch != true) {
          return;
        }
        
        await cartProvider.clearCartForBranchSwitch();
      }
      
      for (final e in _cartItems.entries) {
        final productId = e.key;
        final qty = e.value;
        final options = _cartItemOptions[productId];
        final specialInstructions = _cartItemSpecialInstructions[productId];
        
        await cartProvider.addToCart(
          _selectedBranch!.id,
          productId,
          quantity: qty,
          orderType: 'dine_in',
          selectedOptions: options,
          specialInstructions: specialInstructions,
        );
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Đặt bàn thành công!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_formatDate(_selectedDate)} • ${_selectedTime.format(context)}',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.orange),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.orange),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  List<dynamic> _getSuggestedBranches(
    BranchProvider branchProvider, {
    int? provinceId,
    int? districtId,
  }) {
    final list = List.from(branchProvider.branches);
    list.sort((a, b) {
      int scoreA = 0, scoreB = 0;
      if (provinceId != null) {
        if (a.provinceId == provinceId) scoreA += 2;
        if (b.provinceId == provinceId) scoreB += 2;
      }
      if (districtId != null) {
        if (a.districtId == districtId) scoreA += 3;
        if (b.districtId == districtId) scoreB += 3;
      }
      return scoreB.compareTo(scoreA);
    });
    return list;
  }

  String _formatDate(DateTime date) {
    final weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return '${weekdays[date.weekday % 7]}, ${date.day}/${date.month}/${date.year}';
  }


  String _formatCompactDate(DateTime date) {
    final weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return '${weekdays[date.weekday % 7]} ${date.day}/${date.month}';
  }


  String _getBranchImageUrl(String? imagePath) {
    return ImageUtils.getBranchImageUrl(imagePath);
  }

  String _formatCurrency(double value) {
    final s = value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$s đ';
  }

  void _showCartBottomSheet(CartProvider cartProvider) {
    final currentBranchId = cartProvider.currentBranchId ?? (_selectedBranch?.id ?? 5);
    final currentBranchName = cartProvider.currentBranchName ?? (_selectedBranch?.name ?? 'Beast Bite - The Pearl District');

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


class _ProductDineInItem extends StatefulWidget {
  final Product product;
  final int quantity;
  final Function(int, {List<SelectedOption>? options, String? specialInstructions}) onQuantityChanged;

  const _ProductDineInItem({
    required this.product,
    required this.quantity,
    required this.onQuantityChanged,
  });

  @override
  State<_ProductDineInItem> createState() => _ProductDineInItemState();
}

class _ProductDineInItemState extends State<_ProductDineInItem> {
  bool _showOptions = false;
  int _tempQuantity = 0;
  List<ProductOptionType> _productOptions = [];
  List<SelectedOption> _selectedOptions = [];
  bool _isLoadingOptions = false;

  @override
  void initState() {
    super.initState();
    _tempQuantity = widget.quantity;
  }

  @override
  void didUpdateWidget(_ProductDineInItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantity != widget.quantity) {
      _tempQuantity = widget.quantity;
      _showOptions = false;
    }
  }

  Future<void> _loadProductOptions() async {
    if (_isLoadingOptions) return;
    
    setState(() => _isLoadingOptions = true);
    try {
      final options = await ProductOptionService().getProductOptionsWithDetails(widget.product.id);
      setState(() {
        _productOptions = options;

        _selectedOptions = ProductOptionService().createDefaultSelections(options);
      });
    } catch (e) {
    } finally {
      setState(() => _isLoadingOptions = false);
    }
  }



Future<void> _showProductOptionsDialog() async {
  await _loadProductOptions();
  
  if (!mounted) return;
  
  int quantity = _tempQuantity;
  String? specialRequest = '';
  List<ProductOptionType> productOptions = _productOptions;
  List<SelectedOption> selectedOptions = _selectedOptions;
  bool isLoadingOptions = _isLoadingOptions;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final double basePrice = widget.product.basePrice;
          final double optionsModifier = ProductOptionService().calculateTotalPriceModifier(selectedOptions);
          final double itemTotal = basePrice + optionsModifier;
          final double grandTotal = itemTotal * quantity;
          final primaryColor = Color(0xFFFF8A00);

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
                                    child: widget.product.image != null && widget.product.image!.isNotEmpty
                                        ? Image.network(
                                            _getImageUrl(widget.product.image),
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
                                  widget.product.name,
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
                                      'Quick Order',
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
                                      colors: [primaryColor.withOpacity(0.9), primaryColor],
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
                                  color: primaryColor,
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
                                          color: primaryColor,
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
                                            color: quantity > 1 ? primaryColor : Colors.grey[300]!,
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.remove,
                                          size: 20,
                                          color: quantity > 1 ? primaryColor : Colors.grey[400],
                                        ),
                                      ),
                                    ),

                                    Expanded(
                                      child: Center(
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '$quantity',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
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
                                            colors: [primaryColor.withOpacity(0.9), primaryColor],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: primaryColor.withOpacity(0.3),
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
                                    colors: [primaryColor.withOpacity(0.9), primaryColor],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () async {
                                      if (quantity <= 0) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Vui lòng chọn số lượng'),
                                            backgroundColor: Color(0xFFFF8A00),
                                          ),
                                        );
                                        return;
                                      }
                                      
                                      final quickOrderState = context.findAncestorStateOfType<_QuickOrderScreenState>();
                                      if (quickOrderState == null || quickOrderState._selectedBranch == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Vui lòng chọn chi nhánh trước'),
                                            backgroundColor: Color(0xFFFF8A00),
                                          ),
                                        );
                                        return;
                                      }
                                      
                                      try {
                                        final cartProvider = Provider.of<CartProvider>(context, listen: false);
                                        
                                        await cartProvider.addToCart(
                                          quickOrderState._selectedBranch!.id,
                                          widget.product.id,
                                          quantity: quantity,
                                          orderType: 'dine_in',
                                          selectedOptions: selectedOptions.isNotEmpty ? selectedOptions : null,
                                          specialInstructions: (specialRequest?.isNotEmpty ?? false) ? specialRequest : null,
                                        );
                                        
                                        Navigator.of(context).pop();
                                        widget.onQuantityChanged(
                                          quantity,
                                          options: selectedOptions,
                                          specialInstructions: (specialRequest?.isNotEmpty ?? false) ? specialRequest : null,
                                        );
                                        setState(() {
                                          _tempQuantity = quantity;
                                          _selectedOptions = selectedOptions;
                                          _showOptions = false;
                                        });
                                        
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                Icon(Icons.check_circle, color: Colors.white, size: 20),
                                                SizedBox(width: 8),
                                                Expanded(
                                                  child: Text('Đã thêm vào giỏ hàng'),
                                                ),
                                              ],
                                            ),
                                            backgroundColor: Colors.green,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Lỗi: ${e.toString()}'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
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
    final primaryColor = Color(0xFFFF8A00);
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
                    colors: [primaryColor.withOpacity(0.9), primaryColor],
                  )
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
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
    final primaryColor = Color(0xFFFF8A00);
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
                    colors: [primaryColor.withOpacity(0.9), primaryColor],
                  )
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
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


Widget _buildModernQuantityButton({
  required IconData icon,
  required bool enabled,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: enabled ? Colors.orange : Colors.grey[200],
        shape: BoxShape.circle,
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        color: enabled ? Colors.white : Colors.grey[400],
        size: 24,
      ),
    ),
  );
}

  String _getImageUrl(String? imagePath) {
    return ImageUtils.getImageUrl(imagePath);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.quantity > 0 ? Colors.orange.withOpacity(0.5) : Colors.grey[200]!,
          width: widget.quantity > 0 ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.quantity > 0 
                ? Colors.orange.withOpacity(0.1)
                : Colors.grey.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  _getImageUrl(widget.product.image),
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey[100],
                      child: Icon(
                        Icons.food_bank,
                        color: Colors.grey[400],
                        size: 30,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.product.formattedPrice,
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),

              GestureDetector(
                onTap: () async {
                  if (widget.quantity == 0) {

                    await _showProductOptionsDialog();
                  } else {

                    widget.onQuantityChanged(0);
                  }
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.quantity > 0 ? Colors.red : Colors.orange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (widget.quantity > 0 ? Colors.red : Colors.orange).withOpacity(0.3),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: Icon(
                    widget.quantity > 0 ? Icons.remove : Icons.add,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionWidget(ProductOptionType option, [StateSetter? setDialogState]) {
    final optionId = option.id;
    final optionName = option.name;
    final optionType = option.type;
    final isRequired = option.required;
    final values = option.values;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  optionType == 'select' ? Icons.arrow_drop_down : Icons.check_box,
                  color: Colors.grey[600],
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  optionName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                if (isRequired) ...[
                  SizedBox(width: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Text(
                      'Bắt buộc',
                      style: TextStyle(
                        color: Colors.red[600],
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              children: values.map<Widget>((value) {
                final isSelected = _isValueSelected(optionId, value.id);
                
                return Container(
                  margin: EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: () {
                      if (setDialogState != null) {
                        setDialogState(() {
                          _updateSelection(optionId, value);
                        });
                      } else {
                        setState(() {
                          _updateSelection(optionId, value);
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.grey[100] : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.grey[400]! : Colors.grey[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.grey[600] : Colors.transparent,
                              borderRadius: BorderRadius.circular(optionType == 'select' ? 10 : 4),
                              border: Border.all(
                                color: isSelected ? Colors.grey[600]! : Colors.grey[400]!,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
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
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (value.priceModifier != 0.0) ...[
                            Text(
                              value.priceModifier > 0 
                                  ? '+${_formatCurrency(value.priceModifier)}'
                                  : '${_formatCurrency(value.priceModifier)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: value.priceModifier > 0 
                                    ? Colors.green[600] 
                                    : Colors.red[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }


  ProductOptionValue? _getSelectedValueForOption(int optionId) {
    final selection = _selectedOptions.firstWhere(
      (s) => s.optionTypeId == optionId,
      orElse: () => SelectedOption(
        optionTypeId: optionId,
        optionName: '',
        selectedValueIds: [],
        selectedValues: [],
        totalPriceModifier: 0.0,
      ),
    );
    
    if (selection.selectedValueIds.isEmpty) return null;
    
    final option = _productOptions.firstWhere((o) => o.id == optionId);
    return option.values.firstWhere((v) => v.id == selection.selectedValueIds.first);
  }

  bool _isValueSelected(int optionId, int valueId) {
    final selection = _selectedOptions.firstWhere(
      (s) => s.optionTypeId == optionId,
      orElse: () => SelectedOption(
        optionTypeId: optionId,
        optionName: '',
        selectedValueIds: [],
        selectedValues: [],
        totalPriceModifier: 0.0,
      ),
    );
    
    return selection.selectedValueIds.contains(valueId);
  }

  void _updateSelection(int optionId, ProductOptionValue value) {
    final option = _productOptions.firstWhere((o) => o.id == optionId);
    

    if (option.type == 'select') {
      final index = _selectedOptions.indexWhere((s) => s.optionTypeId == optionId);
      if (index != -1) {
        _selectedOptions[index] = SelectedOption(
          optionTypeId: optionId,
          optionName: option.name,
          selectedValueIds: [value.id],
          selectedValues: [value.value],
          totalPriceModifier: value.priceModifier,
        );
      } else {
        _selectedOptions.add(SelectedOption(
          optionTypeId: optionId,
          optionName: option.name,
          selectedValueIds: [value.id],
          selectedValues: [value.value],
          totalPriceModifier: value.priceModifier,
        ));
      }
    } else {

      final currentSelection = _selectedOptions.firstWhere(
        (s) => s.optionTypeId == optionId,
        orElse: () => SelectedOption(
          optionTypeId: optionId,
          optionName: option.name,
          selectedValueIds: [],
          selectedValues: [],
          totalPriceModifier: 0.0,
        ),
      );

      final updatedSelection = ProductOptionService().updateSelection(
        currentSelection,
        option,
        value,
        true,
      );

      final index = _selectedOptions.indexWhere((s) => s.optionTypeId == optionId);
      if (index != -1) {
        _selectedOptions[index] = updatedSelection;
      } else {
        _selectedOptions.add(updatedSelection);
      }
    }
  }

  void _toggleCheckboxSelection(int optionId, ProductOptionValue value) {
    final option = _productOptions.firstWhere((o) => o.id == optionId);
    final currentSelection = _selectedOptions.firstWhere(
      (s) => s.optionTypeId == optionId,
      orElse: () => SelectedOption(
        optionTypeId: optionId,
        optionName: option.name,
        selectedValueIds: [],
        selectedValues: [],
        totalPriceModifier: 0.0,
      ),
    );

    final isCurrentlySelected = currentSelection.selectedValueIds.contains(value.id);
    final updatedSelection = ProductOptionService().updateSelection(
      currentSelection,
      option,
      value,
      !isCurrentlySelected,
    );

    final index = _selectedOptions.indexWhere((s) => s.optionTypeId == optionId);
    if (index != -1) {
      _selectedOptions[index] = updatedSelection;
    } else {
      _selectedOptions.add(updatedSelection);
    }
  }

  String _formatCurrency(double value) {
    final s = value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$s đ';
  }

  Widget _simpleCircleButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    StateSetter? setDialogState,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? Colors.grey[100] : Colors.grey[50],
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? Colors.grey[400]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.grey[700] : Colors.grey[400],
          size: 18,
        ),
      ),
    );
  }
}
