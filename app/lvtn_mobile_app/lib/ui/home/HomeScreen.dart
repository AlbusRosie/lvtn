import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/BranchProvider.dart';
import '../../providers/AuthProvider.dart';
import '../../providers/LocationProvider.dart';
import '../../providers/CategoryProvider.dart';
import '../../models/province.dart';
import '../../models/category.dart' as CategoryModel;
import '../menu/BranchMenuScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BranchProvider>(context, listen: false).loadBranches();
      Provider.of<LocationProvider>(context, listen: false).loadProvinces();
      Provider.of<CategoryProvider>(context, listen: false).loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.only(left: 16, top: 12, bottom: 12),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.menu, color: Colors.grey[600], size: 20),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DELIVER TO',
              style: TextStyle(
                color: Color(0xFFFF8A00),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Halal Lab office',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey[700],
                  size: 18,
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(0xFF2C2C2C),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 24),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Color(0xFFFF6B00),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '2',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Consumer<BranchProvider>(
        builder: (context, branchProvider, child) {
          if (branchProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Đang tải danh sách chi nhánh...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          if (branchProvider.branches.isEmpty) {
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
                    onPressed: () {
                      branchProvider.loadBranches();
                    },
                    icon: Icon(Icons.refresh),
                    label: Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
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
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final userName = authProvider.currentUser?.name ?? 'Guest';
                      final greeting = _getGreeting();
                      
                      return RichText(
                        text: TextSpan(
                          text: 'Hello $userName, ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[700],
                            fontFamily: 'Lato',
                          ),
                          children: [
                            TextSpan(
                              text: '$greeting!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[900],
                                fontFamily: 'Lato',
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                SizedBox(height: 16),
                
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search dishes, restaurants',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: 20),
                
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'All Categories',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'See All',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 16),
                
                SizedBox(
                  height: 50,
                  child: Consumer<CategoryProvider>(
                    builder: (context, categoryProvider, child) {
                      if (categoryProvider.isLoading) {
                        return Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }

                      if (categoryProvider.error != null) {
                        return Center(
                          child: Text(
                            'Không thể tải danh mục',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        );
                      }

                      return ListView(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          _buildCategoryChip('All', '🔥', categoryProvider.selectedCategory == null, null),
                          SizedBox(width: 12),
                          ...categoryProvider.categories.map<Widget>((CategoryModel.Category category) {
                            return Row(
                              children: [
                                _buildCategoryChip(
                                  category.name, 
                                  _getCategoryEmoji(category.name), 
                                  categoryProvider.selectedCategory?.id == category.id,
                                  category,
                                ),
                                SizedBox(width: 12),
                              ],
                            );
                          }).toList(),
                        ],
                      );
                    },
                  ),
                ),
                
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Open Restaurants',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'See All',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 16),
                
                _buildLocationFilter(),
                
                SizedBox(height: 16),
                Consumer<BranchProvider>(
                  builder: (context, branchProvider, child) {
                    if (branchProvider.isLoading) {
                      return Container(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (branchProvider.error != null) {
                      return Container(
                        height: 200,
                        child: Center(
                          child: Text(
                            'Không thể tải danh sách chi nhánh',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      itemCount: branchProvider.filteredBranches.length,
                      itemBuilder: (context, index) {
                        final branch = branchProvider.filteredBranches[index];
                        return _buildRestaurantCard(branch, context);
                      },
                    );
                  },
                ),
                
                SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey[400],
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.pushNamed(context, '/branches');
              break;
            case 2:
              Navigator.pushNamed(context, '/products');
              break;
            case 3:
              Navigator.pushNamed(context, '/orders');
              break;
            case 4:
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Chi nhánh',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Thực đơn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Đơn hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final now = DateTime.now();
    final hour = now.hour;
    
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 22) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  String _getImageUrl(String imagePath) {
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    if (imagePath.startsWith('/public')) {
      return 'http://10.0.2.2:3000$imagePath';
    }
    return 'http://10.0.2.2:3000/public/uploads/$imagePath';
  }

  Widget _buildCategoryChip(String title, String emoji, bool isSelected, CategoryModel.Category? category) {
    return GestureDetector(
      onTap: () {
        Provider.of<CategoryProvider>(context, listen: false).selectCategory(category);
        Provider.of<BranchProvider>(context, listen: false).filterBranchesByCategory(category?.id);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFFFF3E0) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Color(0xFFFFB74D) : Colors.grey[200]!,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Color(0xFFFFB74D).withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: TextStyle(fontSize: 20),
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
      default:
        return '🍽️';
    }
  }

  Widget _buildRestaurantCard(dynamic branch, BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/branch-menu',
            arguments: branch,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Container(
                height: 180,
                width: double.infinity,
                child: branch.image != null && branch.image!.isNotEmpty
                    ? Image.network(
                        _getImageUrl(branch.image!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.network(
                            'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&auto=format&fit=crop',
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image.network(
                        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&auto=format&fit=crop',
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            
            Padding(
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    branch.name ?? 'Rose Garden Restaurant',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    branch.description ?? 'Burger • Chicken • Riche • Wings',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 10),
                  
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: Colors.orange, size: 20),
                      SizedBox(width: 4),
                      Text(
                        '4.7',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.delivery_dining_rounded, color: Colors.orange, size: 20),
                      SizedBox(width: 4),
                      Text(
                        'Free',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.access_time_rounded, color: Colors.orange, size: 20),
                      SizedBox(width: 4),
                      Text(
                        '20 min',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationFilter() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Consumer2<LocationProvider, BranchProvider>(
        builder: (context, locationProvider, branchProvider, child) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 0,
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
                    Icon(Icons.location_on, color: Colors.orange, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Filter by Location',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 36,
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            value: branchProvider.selectedProvinceId,
                            hint: Text(
                              'Province/City',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            isExpanded: true,
                            menuMaxHeight: 300,
                            isDense: true,
                            items: [
                              DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Provinces/Cities', style: TextStyle(fontSize: 12)),
                              ),
                              ...locationProvider.provinces.map((province) {
                                return DropdownMenuItem<int?>(
                                  value: province.id,
                                  child: Text(province.name, style: TextStyle(fontSize: 12)),
                                );
                              }),
                            ],
                            onChanged: (int? provinceId) {
                              if (provinceId != null) {
                                locationProvider.selectProvince(
                                  locationProvider.provinces.firstWhere(
                                    (p) => p.id == provinceId,
                                  ),
                                );
                              } else {
                                locationProvider.clearSelection();
                              }
                              branchProvider.filterBranchesByLocation(
                                provinceId,
                                null,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 36,
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            value: branchProvider.selectedDistrictId,
                            hint: Text(
                              'Select District',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            isExpanded: true,
                            menuMaxHeight: 300,
                            isDense: true,
                            items: [
                              DropdownMenuItem<int?>(
                                value: null,
                                child: Text('All Districts', style: TextStyle(fontSize: 12)),
                              ),
                              ...locationProvider.filteredDistricts.map((district) {
                                return DropdownMenuItem<int?>(
                                  value: district.id,
                                  child: Text(district.name, style: TextStyle(fontSize: 12)),
                                );
                              }),
                            ],
                            onChanged: branchProvider.selectedProvinceId == null
                                ? null
                                : (int? districtId) {
                                    branchProvider.filterBranchesByLocation(
                                      branchProvider.selectedProvinceId,
                                      districtId,
                                    );
                                  },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (branchProvider.selectedProvinceId != null || 
                    branchProvider.selectedDistrictId != null)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: () {
                            branchProvider.clearFilters();
                            locationProvider.clearSelection();
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.clear, size: 14, color: Colors.orange),
                                SizedBox(width: 4),
                                Text(
                                  'Clear Filter',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
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
      ),
    );
  }
}