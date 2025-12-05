import 'package:flutter/material.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final branchProvider = Provider.of<BranchProvider>(context, listen: false);
      branchProvider.loadBranches();
    });
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

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Đặt món mang về',
          style: TextStyle(
            color: Colors.grey[900],
            fontSize: 18,
            fontWeight: FontWeight.bold,
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
            
            Expanded(
              child: Consumer<BranchProvider>(
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
                    padding: EdgeInsets.all(16),
                    itemCount: branchProvider.branches.length,
                    itemBuilder: (context, index) {
                      final branch = branchProvider.branches[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _getImageUrl(branch.image),
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[200],
                                        child: Icon(Icons.store, color: Colors.grey[400]),
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
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[900],
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                                          SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              branch.addressDetail ?? '',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (branch.phone != null && branch.phone!.isNotEmpty) ...[
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                                            SizedBox(width: 4),
                                            Text(
                                              branch.phone!,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                
                                Icon(Icons.chevron_right, color: Colors.grey[400]),
                              ],
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

