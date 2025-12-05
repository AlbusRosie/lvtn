import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/BranchProvider.dart';
import '../../providers/LocationProvider.dart';
import '../../providers/AuthProvider.dart';
import '../../models/branch.dart';
import 'BranchMenuScreen.dart';
import 'BranchDetailScreen.dart';
import '../../constants/app_constants.dart';
import '../../utils/image_utils.dart';
import '../cart/CartProvider.dart';
import '../cart/CartScreen.dart';
import '../widgets/AppBottomNav.dart';
import '../widgets/MapboxAutocompleteField.dart';

class BranchScreen extends StatefulWidget {
  const BranchScreen({super.key});

  static const String routeName = '/branches';

  @override
  State<BranchScreen> createState() => _BranchScreenState();
}

class _BranchScreenState extends State<BranchScreen> {
  String currentAddress = 'Chưa chọn địa chỉ';
  bool isLoadingLocation = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadDisplayAddress();
    _loadBranches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadDisplayAddress() {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    setState(() {
      currentAddress = locationProvider.detailAddress.isNotEmpty
          ? locationProvider.detailAddress
          : 'Chưa chọn địa chỉ';
      });
  }

  Future<void> _loadBranches() async {
    final branchProvider = Provider.of<BranchProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);

    if (locationProvider.latitude != null && locationProvider.longitude != null) {
      await branchProvider.loadNearbyBranches(
        latitude: locationProvider.latitude!,
        longitude: locationProvider.longitude!,
      );
    } else {
      await branchProvider.loadBranches();
    }
  }

  String _getImageUrl(String? imagePath) {
    return ImageUtils.getBranchImageUrl(imagePath);
  }

  void _showLocationDialogIfNeeded() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final locationProvider = Provider.of<LocationProvider>(context, listen: false);
            final branchProvider = Provider.of<BranchProvider>(context, listen: false);

            final addressController = TextEditingController(text: locationProvider.detailAddress);
            
            double? selectedLat = locationProvider.latitude;
            double? selectedLng = locationProvider.longitude;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
        child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
          decoration: BoxDecoration(
            color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                      spreadRadius: 0,
              ),
                  ],
          ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.fromLTRB(24, 24, 20, 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
              child: Row(
                children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Color(0xFFFFA500).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFFFFA500),
                              size: 24,
                            ),
                  ),
                          SizedBox(width: 16),
                  Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chọn địa chỉ giao hàng',
          style: TextStyle(
                        fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    letterSpacing: -0.5,
                      ),
        ),
                                SizedBox(height: 4),
                                Text(
                                  'Tìm nhà hàng gần bạn nhất',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: Colors.grey[600],
                                  size: 22,
                                ),
                              ),
                      ),
                    ),
                        ],
                      ),
                    ),
                    
                    Divider(height: 1, thickness: 1, color: Colors.grey[200]),
                
                    Flexible(
                      child: Consumer<LocationProvider>(
                        builder: (context, lp, child) {
                          if (lp.isLoading && lp.provinces.isEmpty) {
                            return Container(
                              padding: EdgeInsets.all(40),
                                child: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFFFA500),
                                ),
                              ),
                            );
                          }

                          return SingleChildScrollView(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 16),
                                
                                MapboxAutocompleteField(
                                  controller: addressController,
                                  labelText: 'Địa chỉ giao hàng',
                                  hintText: 'Nhập địa chỉ để tìm kiếm...',
                                  proximity: locationProvider.latitude != null && locationProvider.longitude != null
                                      ? '${locationProvider.longitude},${locationProvider.latitude}'
                                      : null,
                                  onPlaceSelected: (address, lat, lng) {
                                    locationProvider.setDetailAddress(address);
                                    locationProvider.setCoordinates(lat, lng);
                                    addressController.text = address;
                                    selectedLat = lat;
                                    selectedLng = lng;
                                    setDialogState(() {});
                                  },
                                  onChanged: (value) {
                                    setDialogState(() {});
                                  },
                                ),
                                
                                SizedBox(height: 24),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    
                    Container(
                      padding: EdgeInsets.fromLTRB(24, 20, 24, 24),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                side: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1.5,
                                ),
                              ),
                          child: Text(
                                'Bỏ qua',
                            style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                            ),
                                  ),
                          ),
                        ),
                          SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFFFFA500).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                      ),
                  ],
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                  final lp = Provider.of<LocationProvider>(context, listen: false);
                                  final bp = Provider.of<BranchProvider>(context, listen: false);
                                  final ap = Provider.of<AuthProvider>(context, listen: false);

                                  final address = addressController.text.trim().isNotEmpty 
                                      ? addressController.text.trim()
                                      : lp.detailAddress;

                                  final finalLat = selectedLat ?? locationProvider.latitude ?? lp.latitude;
                                  final finalLng = selectedLng ?? locationProvider.longitude ?? lp.longitude;
                                  
                                  if (finalLat == null || finalLng == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Vui lòng chọn địa chỉ từ danh sách đề xuất'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    return;
                                  }

                                  if (address.isNotEmpty) {
                                    lp.setDetailAddress(address);
                                  }
                                  lp.setCoordinates(finalLat, finalLng);
                                  
                                  try {
                                    await bp.loadNearbyBranches(
                                      latitude: finalLat,
                                      longitude: finalLng,
                                    );
                                  } catch (e) {
                                    print('BranchScreen: Lỗi khi reload branches: $e');
                                  }
                                  
                                  bp.clearFilters();

                                  if (ap.isAuth && ap.currentUser != null && address.isNotEmpty) {
                                    ap.updateUserAddress(address).catchError((e) {
                                      print('Không thể lưu địa chỉ vào tài khoản: $e');
                                    });
                                  }

                                  Navigator.of(context).pop();
                                  setState(() {
                                    currentAddress = address.isNotEmpty ? address : 'Chưa chọn địa chỉ';
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: Color(0xFFFFA500),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_outline, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Xác nhận',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
          ),
        ],
              ),
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
          },
        );
      },
    );
  }

  String _getGreeting() {
    final now = DateTime.now();
    final hour = now.hour;
    
    if (hour >= 5 && hour < 12) {
      return 'Chào buổi sáng';
    } else if (hour >= 12 && hour < 17) {
      return 'Chào buổi chiều';
    } else if (hour >= 17 && hour < 22) {
      return 'Chào buổi tối';
    } else {
      return 'Chúc ngủ ngon';
    }
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
        backgroundColor: Colors.white,
      extendBodyBehindAppBar: false,
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
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: _isSearchExpanded ? 0 : null,
                    child: _isSearchExpanded
                        ? SizedBox.shrink()
                        : Expanded(
                    child: GestureDetector(
                      onTap: _showLocationDialogIfNeeded,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                      child: Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFFFF8A00),
                        size: 20,
                      ),
                                    SizedBox(width: 12),
                      Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                              'GIAO ĐẾN',
                                    style: TextStyle(
                                color: Color(0xFFFF8A00),
                                    fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                    height: 1.2,
                                    ),
                                  ),
                            SizedBox(height: 2),
                                Consumer<LocationProvider>(
                builder: (context, locationProvider, child) {
                  final address = locationProvider.detailAddress.isNotEmpty
                      ? locationProvider.detailAddress
                      : 'Chọn địa chỉ giao hàng';
                  return Row(
              children: [
                      Flexible(
                        child: Text(
                          address,
                                    style: TextStyle(
                                              color: Colors.grey[800],
                                fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                height: 1.2,
                                    ),
                              maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                            ),
                ),
                SizedBox(width: 4),
                Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: Colors.grey[600],
                                          size: 16,
                ),
              ],
                  );
                },
                                ),
                              ],
              ),
            ),
          ],
        ),
                    ),
                  ),
                          ),
                  ),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: _isSearchExpanded ? null : 0,
                    child: _isSearchExpanded
                        ? Expanded(
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value.toLowerCase().trim();
                                  });
                                },
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Tìm món ăn, nhà hàng',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  prefixIcon: Padding(
                                    padding: EdgeInsets.only(left: 12, right: 8),
                                    child: Icon(
                                      Icons.search_rounded,
                                      color: Color(0xFFFF8A00),
                                      size: 20,
                                    ),
                                  ),
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_searchQuery.isNotEmpty)
                                        IconButton(
                                          icon: Icon(Icons.clear_rounded, color: Colors.grey[500], size: 18),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {
                                              _searchQuery = '';
                                            });
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(
                                            minWidth: 32,
                                            minHeight: 32,
                                          ),
                                        ),
                                      IconButton(
                                        icon: Icon(Icons.close_rounded, color: Colors.grey[600], size: 18),
                                        onPressed: () {
                                          setState(() {
                                            _isSearchExpanded = false;
                                            _searchController.clear();
                                            _searchQuery = '';
                                          });
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                      ),
                                    ],
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 12,
                                  ),
                                  isDense: true,
                                ),
                              ),
                            ),
                          )
                        : SizedBox.shrink(),
                  ),
                  SizedBox(width: 12),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                        setState(() {
                          _isSearchExpanded = !_isSearchExpanded;
                          if (!_isSearchExpanded) {
                            _searchController.clear();
                            _searchQuery = '';
                          }
                        });
                          },
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
                          _isSearchExpanded ? Icons.close_rounded : Icons.search_rounded,
                          color: Colors.grey[800],
                              size: 20,
                                       ),
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
      body: Consumer2<BranchProvider, LocationProvider>(
        builder: (context, branchProvider, locationProvider, child) {
          if (branchProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFFFF8A00),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Đang tải danh sách chi nhánh...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          final hasBranches = (locationProvider.latitude != null && locationProvider.longitude != null)
              ? branchProvider.nearbyBranches.isNotEmpty
              : branchProvider.branches.isNotEmpty;

          if (!hasBranches) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.store_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Không có chi nhánh nào',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Vui lòng thử lại sau',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (locationProvider.latitude != null && locationProvider.longitude != null) {
                        await branchProvider.loadNearbyBranches(
                          latitude: locationProvider.latitude!,
                          longitude: locationProvider.longitude!,
                        );
                      } else {
                        await branchProvider.loadBranches();
                      }
                    },
                    icon: Icon(Icons.refresh),
                    label: Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFF8A00),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 80,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final userName = authProvider.currentUser?.name ?? 'Khách';
                      final greeting = _getGreeting();
                      
                      return Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFFFF8A00).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.waving_hand_rounded,
                              color: Color(0xFFFF8A00),
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                text: 'Xin chào $userName,\n',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                  height: 1.4,
                                  letterSpacing: -0.3,
                                ),
                                children: [
                                  TextSpan(
                                    text: '$greeting!',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey[900],
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                
                SizedBox(height: 20),
                
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Color(0xFFFF8A00),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Nhà hàng gần bạn',
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
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Xem tất cả',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFFF8A00),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 12,
                                  color: Color(0xFFFF8A00),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 16),
                
                Builder(
                  builder: (context) {
                    List<Branch> branchesToShow;
                    if (locationProvider.latitude != null && locationProvider.longitude != null) {
                      if (branchProvider.nearbyBranches.isNotEmpty) {
                        branchesToShow = branchProvider.nearbyBranches;
                      } else {
                        branchesToShow = branchProvider.branches;
                      }
                    } else {
                      branchesToShow = branchProvider.branches;
                    }

                    if (branchesToShow.isEmpty) {
                      return SizedBox.shrink();
                    }
                    
                    final featuredBranches = branchesToShow.take(3).toList();
                    
                    return SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        itemCount: featuredBranches.length,
                        itemBuilder: (context, index) {
                          final branch = featuredBranches[index];
                          return Container(
                            width: MediaQuery.of(context).size.width * 0.75,
                            margin: EdgeInsets.only(
                              right: index == featuredBranches.length - 1 ? 0 : 16,
                            ),
                            child: _buildFeaturedCard(branch, context, locationProvider),
                          );
                        },
                      ),
                    );
                  },
                ),
                
                SizedBox(height: 28),
                
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Color(0xFFFF8A00),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Tất cả chi nhánh',
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
                ),
                
                SizedBox(height: 16),
                
                Builder(
                  builder: (context) {
                    List<Branch> branchesToShow;
                    if (locationProvider.latitude != null && locationProvider.longitude != null) {
                      if (branchProvider.nearbyBranches.isNotEmpty) {
                        branchesToShow = branchProvider.nearbyBranches;
                      } else {
                        branchesToShow = branchProvider.sortBranchesByDistance(
                          branches: branchProvider.branches,
                          userLatitude: locationProvider.latitude,
                          userLongitude: locationProvider.longitude,
                        );
                      }
                    } else {
                      branchesToShow = branchProvider.branches;
                    }

                    if (_searchQuery.isNotEmpty) {
                      branchesToShow = branchesToShow.where((branch) {
                        final name = (branch.name ?? '').toLowerCase();
                        final address = (branch.addressDetail ?? '').toLowerCase();
                        final description = (branch.description ?? '').toLowerCase();
                        return name.contains(_searchQuery) || 
                               address.contains(_searchQuery) || 
                               description.contains(_searchQuery);
                      }).toList();
                    }

                    if (_searchQuery.isNotEmpty && branchesToShow.isEmpty) {
                      return Container(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Không tìm thấy kết quả',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Thử tìm kiếm với từ khóa khác',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (branchesToShow.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.store_outlined,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Không có chi nhánh nào',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Vui lòng thử lại sau',
                              style: TextStyle(
                                color: Colors.grey[400],
                              ),
                            ),
                            SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _loadBranches,
                              icon: Icon(Icons.refresh),
                              label: Text('Thử lại'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFF8A00),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                      itemCount: branchesToShow.length,
                      itemBuilder: (context, index) {
                        final branch = branchesToShow[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: _buildBranchCard(branch, context, locationProvider),
                        );
                      },
                    );
                  },
                ),
                
                SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
      ),
      ),
     );
   }

  Widget _buildFeaturedCard(Branch branch, BuildContext context, LocationProvider? locationProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            spreadRadius: 0,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            BranchDetailScreen.routeName,
            arguments: branch,
          );
        },
          borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
              ),
                child: Stack(
                  children: [
                    Container(
                      height: 140,
                width: double.infinity,
                child: Image.network(
                  _getImageUrl(branch.image),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Icon(
                                Icons.restaurant_rounded,
                                color: Colors.grey[400],
                                size: 40,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
                            SizedBox(width: 4),
                            Text(
                              '4.7',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[900],
                              ),
                            ),
                          ],
                ),
              ),
            ),
                  ],
                ),
              ),
              
            Flexible(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            branch.name ?? 'Chi nhánh',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[900],
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (branch.status == 'active')
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Mở',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 3),
                    Text(
                      branch.address ?? '',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 3,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_shipping_rounded,
                              color: Color(0xFFFF8A00),
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Free',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (locationProvider != null && 
                            locationProvider.latitude != null && 
                            locationProvider.longitude != null)
                          Builder(
                            builder: (context) {
                              final branchProvider = Provider.of<BranchProvider>(context, listen: false);
                              double? distance = branchProvider.calculateDistance(
                                userLatitude: locationProvider.latitude,
                                userLongitude: locationProvider.longitude,
                                branch: branch,
                              );
                              if (distance == null) return SizedBox.shrink();
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    color: Color(0xFFFF8A00),
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    distance < 1 
                                        ? '${(distance * 1000).toStringAsFixed(0)}m'
                                        : '${distance.toStringAsFixed(1)}km',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            },
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
      ),
    );
  }

  Widget _buildBranchCard(Branch branch, BuildContext context, LocationProvider? locationProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            spreadRadius: 0,
            blurRadius: 16,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              BranchDetailScreen.routeName,
              arguments: branch,
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                child: Container(
                  width: 120,
                  height: 120,
                  child: Image.network(
                    _getImageUrl(branch.image),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.restaurant_rounded,
                            color: Colors.grey[400],
                            size: 30,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              branch.name ?? 'Chi nhánh',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[900],
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (branch.status == 'active')
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Mở',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        branch.description ?? 'Nhà hàng',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFB800),
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '4.7',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_shipping_rounded,
                                color: Color(0xFFFF8A00),
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Free',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          if (locationProvider != null && 
                              locationProvider.latitude != null && 
                              locationProvider.longitude != null)
                            Builder(
                              builder: (context) {
                                final branchProvider = Provider.of<BranchProvider>(context, listen: false);
                                double? distance = branchProvider.calculateDistance(
                                  userLatitude: locationProvider.latitude,
                                  userLongitude: locationProvider.longitude,
                                  branch: branch,
                                );
                                if (distance == null) return SizedBox.shrink();
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      color: Color(0xFFFF8A00),
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      distance < 1 
                                          ? '${(distance * 1000).toStringAsFixed(0)}m'
                                          : '${distance.toStringAsFixed(1)}km',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                );
                              },
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
      ),
    );
  }

  void _showCartBottomSheet(CartProvider cartProvider) {
    final currentBranchId = cartProvider.currentBranchId ?? 5;
    final currentBranchName = cartProvider.currentBranchName ?? 'Beast Bite - The Pearl District';

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
