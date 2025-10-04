import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import '../../providers/BranchProvider.dart';
import '../../models/branch.dart';
import '../menu/BranchMenuScreen.dart';

class BranchScreen extends StatefulWidget {
  const BranchScreen({super.key});

  static const String routeName = '/branches';

  @override
  State<BranchScreen> createState() => _BranchScreenState();
}

class _BranchScreenState extends State<BranchScreen> {
  String currentAddress = 'Đường Nguyễn Huệ, Quận 1, TP.HCM';
  bool isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoadingLocation = true;
    });

    try {
      await Future.delayed(Duration(milliseconds: 1000)); 
      
      String vietnamLocation = 'Đường Nguyễn Huệ, Quận 1, TP.HCM';
      setState(() {
        currentAddress = vietnamLocation;
        isLoadingLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Location updated: $vietnamLocation'),
              SizedBox(height: 4),
              Text(
                '📍 Fixed location for testing - will use real GPS with physical device',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      return; 
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bật GPS để sử dụng tính năng này'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'MỞ',
                textColor: Colors.white,
                onPressed: () async {
                  await openAppSettings();
                },
              ),
            ),
          );
          setState(() {
            isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GPS bị từ chối vĩnh viễn. Vui lòng mở trong Settings'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'MỞ SETTINGS',
              textColor: Colors.white,
              onPressed: () async {
                await openAppSettings();
              },
            ),
          ),
        );
        setState(() {
          isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: true,
      );

      String newAddress = await _getAddressFromCoordinates(
        position.latitude, 
        position.longitude
      );
      
      setState(() {
        currentAddress = newAddress;
        isLoadingLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Location updated: $newAddress'),
              SizedBox(height: 4),
              Text(
                '💡 For Vietnam location: Set emulator location or use physical device',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể lấy vị trí hiện tại'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        isLoadingLocation = false;
      });
    }
  }

  Future<String> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        List<String> addressParts = [];
        
        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }
        
        if (addressParts.isEmpty) {
          return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
        }
        
        return addressParts.join(', ');
      }
    } catch (e) {
      print('Reverse geocoding error: $e');
    }
    
    return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Chi nhánh',
          style: TextStyle(
            color: Colors.grey[900],
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.grey[600]),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey[400], size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Search on Coody',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.navigation_outlined, color: Colors.grey[400], size: 20),
                          SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(
                                  'Delivery to',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              Text(
                                currentAddress,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.tune, size: 18, color: Colors.grey[700]),
                            SizedBox(width: 6),
                            Text(
                              'Filter',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
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
            
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Best Partners',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                            fontFamily: 'Inter',
                          ),
                        ),
                        Text(
                          'See all',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    
                    Consumer<BranchProvider>(
                      builder: (context, branchProvider, child) {
                        if (branchProvider.branches.isEmpty) {
                          return SizedBox.shrink();
                        }
                        
                        final nearbyBranches = branchProvider.branches.take(3).toList();
                        
                        return SizedBox(
                          height: 195,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            itemCount: nearbyBranches.length,
                            padding: EdgeInsets.symmetric(horizontal: 0),
                            itemBuilder: (context, index) {
                              final branch = nearbyBranches[index];
                              final distances = ['0.2 km', '1.5 km', '2.1 km'][index];
                              final deliveryTypes = ['Free shipping', 'Free shipping', 'Free shipping'][index];
                              
                              return Container(
                                width: 250,
                                margin: EdgeInsets.only(right: index == nearbyBranches.length - 1 ? 0 : 16),
                                child: _buildBestPartnerCard(branch, distances, deliveryTypes, context),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    
                    SizedBox(height: 20),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'All Branches',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    
                    Consumer<BranchProvider>(
                      builder: (context, branchProvider, child) {
                        if (branchProvider.isLoading) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: Colors.orange,
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
                                  onPressed: () {
                                    branchProvider.loadBranches();
                                  },
                                  icon: Icon(Icons.refresh),
                                  label: Text('Thử lại'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
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

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.only(bottom: 100),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: branchProvider.branches.length,
                          itemBuilder: (context, index) {
                            final branch = branchProvider.branches[index];
                            return _buildBranchCard(branch, context);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
       bottomNavigationBar: BottomNavigationBar(
         type: BottomNavigationBarType.fixed,
         currentIndex: 1, 
         selectedItemColor: Colors.orange,
         unselectedItemColor: Colors.grey[400],
         selectedFontSize: 12,
         unselectedFontSize: 12,
         onTap: (index) {
           switch (index) {
             case 0:
               Navigator.pushReplacementNamed(context, '/home');
               break;
             case 1:
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

   Widget _buildBestPartnerCard(Branch branch, String distance, String deliveryType, BuildContext context) {
    return Container(
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
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            BranchMenuScreen.routeName,
            arguments: branch,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Container(
                height: 100,
                width: double.infinity,
                child: Image.network(
                  _getImageUrl(branch.image),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.network(
                      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&auto=format&fit=crop',
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            branch.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                              fontFamily: 'Inter',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 4),
                        if (branch.status == 'active')
                          Icon(
                            Icons.verified,
                            color: Colors.green,
                            size: 18,
                          ),
                      ],
                    ),
                    
                    SizedBox(height: 4),
                    
                    Text(
                      branch.status == 'active' ? 'Open' : 'Close',
                      style: TextStyle(
                        fontSize: 12,
                        color: branch.status == 'active' ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                    Text(
                      branch.address,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontFamily: 'Inter',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    Spacer(),
                    Row(
                      children: [
                        Icon(Icons.star, size: 12, color: Colors.orange),
                        SizedBox(width: 2),
                        Text(
                          '4.5',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                            fontFamily: 'Inter',
                          ),
                        ),
                        SizedBox(width: 4),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          distance,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                            fontFamily: 'Inter',
                          ),
                        ),
                        SizedBox(width: 4),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            deliveryType,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                              fontFamily: 'Inter',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildBranchCard(Branch branch, BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          BranchMenuScreen.routeName,
          arguments: branch,
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            Expanded(
              flex: 6,
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                        Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: Image.network(
                        _getImageUrl(branch.image),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.network(
                            'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&auto=format&fit=crop',
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              '4.5',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            branch.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                              fontFamily: 'Inter',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 4),
                        if (branch.status == 'active')
                          Icon(
                            Icons.verified,
                            color: Colors.green,
                            size: 18,
                          ),
                      ],
                    ),
                    
                    Text(
                      branch.status == 'active' ? 'Open' : 'Close',
                      style: TextStyle(
                        fontSize: 13,
                        color: branch.status == 'active' 
                            ? Colors.green 
                            : Colors.red,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                    
                    Text(
                      branch.description ?? 'Fast food',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontFamily: 'Inter',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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