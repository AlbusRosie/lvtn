import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/BranchProvider.dart';
import '../../providers/LocationProvider.dart';
import '../../models/branch.dart';
import 'TakeawayMenuScreen.dart';
import '../../utils/image_utils.dart';

class TakeawayBranchSelectionScreen extends StatefulWidget {
  const TakeawayBranchSelectionScreen({Key? key}) : super(key: key);

  static const String routeName = '/takeaway-branch-selection';

  @override
  State<TakeawayBranchSelectionScreen> createState() => _TakeawayBranchSelectionScreenState();
}

class _TakeawayBranchSelectionScreenState extends State<TakeawayBranchSelectionScreen> {
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final branchProvider = Provider.of<BranchProvider>(context, listen: false);
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      
      // Load nearby branches với khoảng cách nếu có vị trí
      if (locationProvider.latitude != null && locationProvider.longitude != null) {
        await branchProvider.loadNearbyBranches(
          latitude: locationProvider.latitude!,
          longitude: locationProvider.longitude!,
        );
      } else {
        // Fallback: load tất cả branches nếu không có vị trí
        await branchProvider.loadBranches();
      }
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

  String _getImageUrl(String? imagePath) {
    return ImageUtils.getBranchImageUrl(imagePath);
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    final userAddress = locationProvider.detailAddress.isNotEmpty
        ? locationProvider.detailAddress
        : 'Chưa có địa chỉ';

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
        title: Text(
          'Chọn chi nhánh (Takeaway)',
          style: TextStyle(
            color: Colors.grey[900],
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.grey[600], size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.orange, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Địa chỉ giao hàng',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          userAddress,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[900],
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            
            // Section header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.near_me, color: Color(0xFFFFA500), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Gợi ý gần bạn',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Consumer2<BranchProvider, LocationProvider>(
                builder: (context, branchProvider, locationProvider, child) {
                  if (branchProvider.isLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFFA500),
                      ),
                    );
                  }

                  // Luôn ưu tiên nearby branches (có sẵn distanceKm từ API) nếu có vị trí
                  List<Branch> branchesToShow;
                  if (locationProvider.latitude != null && locationProvider.longitude != null) {
                    // Nếu có vị trí, luôn ưu tiên nearby branches (đã có distanceKm từ API)
                    if (branchProvider.nearbyBranches.isNotEmpty) {
                      branchesToShow = branchProvider.nearbyBranches;
                    } else {
                      // Nếu chưa có nearby branches, load ngay
                      branchesToShow = branchProvider.branches;
                      // Trigger load nearby branches
                      WidgetsBinding.instance.addPostFrameCallback((_) async {
                        if (mounted && branchProvider.nearbyBranches.isEmpty) {
                          await branchProvider.loadNearbyBranches(
                            latitude: locationProvider.latitude!,
                            longitude: locationProvider.longitude!,
                          );
                        }
                      });
                    }
                  } else {
                    // Không có vị trí, hiển thị branches thông thường
                    branchesToShow = branchProvider.branches;
                  }

                  if (branchesToShow.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.store_outlined, size: 64, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            'Không có chi nhánh nào',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: branchesToShow.length,
                    itemBuilder: (context, index) {
                      final branch = branchesToShow[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                        ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TakeawayMenuScreen(
                                  branch: branch,
                                ),
                              ),
                            );
                          },
                            borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                  // Icon/Image
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Color(0xFFFFA500).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: branch.image != null && branch.image!.isNotEmpty
                                        ? Padding(
                                            padding: EdgeInsets.all(10),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    _getImageUrl(branch.image),
                                                width: 36,
                                                height: 36,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.store,
                                                  color: Color(0xFFFFA500),
                                                    size: 20,
                                                );
                                              },
                                              ),
                                            ),
                                          )
                                        : Icon(
                                            Icons.store,
                                            color: Color(0xFFFFA500),
                                            size: 20,
                                  ),
                                ),
                                SizedBox(width: 16),
                                
                                  // Branch info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Branch name
                                      Text(
                                        branch.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[900],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 8),
                                      
                                      // Address - luôn hiển thị đầy đủ
                                      if (branch.addressDetail != null && branch.addressDetail!.isNotEmpty)
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                                            SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                branch.addressDetail!,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[700],
                                                  height: 1.4,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        Row(
                                          children: [
                                            Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[400]),
                                            SizedBox(width: 6),
                                            Text(
                                              'Chưa có địa chỉ',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[500],
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ),
                                      
                                      SizedBox(height: 6),
                                      
                                      // Distance - luôn hiển thị
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on, 
                                            size: 16, 
                                            color: branch.distanceKm != null 
                                                ? Color(0xFFFFA500) 
                                                : Colors.grey[400],
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            branch.distanceKm != null 
                                                ? '${branch.distanceKm!.toStringAsFixed(1)} km'
                                                : 'Đang tính khoảng cách...',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: branch.distanceKm != null 
                                                  ? Color(0xFFFFA500)
                                                  : Colors.grey[500],
                                              fontWeight: branch.distanceKm != null 
                                                  ? FontWeight.w600 
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                  SizedBox(width: 8),
                                  
                                  // Arrow icon
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey[400],
                                    size: 24,
                                  ),
                              ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

