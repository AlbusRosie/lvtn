import 'package:flutter/material.dart';
import '../../models/branch.dart';
import '../menu/BranchMenuScreen.dart';
import '../../services/BranchService.dart';
import '../../constants/app_constants.dart';
import '../tables/TableScreen.dart';
import '../../constants/api_constants.dart';

class BranchDetailScreen extends StatelessWidget {
  final Branch branch;
  
  const BranchDetailScreen({super.key, required this.branch});

  static const String routeName = '/branch-detail';

  @override
  Widget build(BuildContext context) {
    final Future<Branch> latestBranchFuture = BranchService().getBranchById(branch.id);
    String _getImageUrl(String? imagePath) {
      if (imagePath == null || imagePath.isEmpty) {
        return AppConstants.defaultProductImage;
      }
      if (imagePath.startsWith('http')) {
        return imagePath;
      }
      if (imagePath.startsWith('/public')) {
        return '${ApiConstants.fileBaseUrl}$imagePath';
      }
      return '${ApiConstants.fileBaseUrl}/public/uploads/$imagePath';
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.grey[900],
        title: Text(
          'Branch Details',
          style: TextStyle(
            color: Colors.grey[900],
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<Branch>(
          future: latestBranchFuture,
          builder: (context, snapshot) {
            final Branch effectiveBranch = snapshot.data ?? branch;
            return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 190,
                      width: double.infinity,
                      child: Image.network(
                        _getImageUrl(effectiveBranch.image),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.network(_getImageUrl(AppConstants.defaultProductImage), fit: BoxFit.cover);
                        },
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.25),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              
              Text(
                effectiveBranch.name,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                  fontFamily: 'Inter',
                  height: 1.2,
                ),
                textAlign: TextAlign.left,
              ),
              
              SizedBox(height: 8),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 18,
                    color: Colors.orange[600],
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      effectiveBranch.address,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: 'Inter',
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 4),
              
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          'Services',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFFF9800),
                            Color(0xFFFF6F00),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.4),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            BranchMenuScreen.routeName,
                            arguments: effectiveBranch,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'View Menu',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 14),
                    
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.withOpacity(0.05),
                            Colors.orange.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            TableScreen.routeName,
                            arguments: effectiveBranch,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange[700],
                          side: BorderSide(
                            color: Colors.orange,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: Colors.transparent,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_seat,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Reserve Table',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 0),
              
              Container(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
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
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.access_time,
                      'Opening hours',
                      _formatHours(effectiveBranch.openingHours, effectiveBranch.closeHours),
                    ),
                    SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.phone,
                      'Phone',
                      effectiveBranch.phone,
                    ),
                    SizedBox(height: 12),
                    if (effectiveBranch.email != null)
                      _buildInfoRow(
                        Icons.email_outlined,
                        'Email',
                        effectiveBranch.email!,
                      ),
                    SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.verified,
                      'Status',
                      effectiveBranch.status == 'active' ? 'Open' : effectiveBranch.status,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
          },
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
              Navigator.pushReplacementNamed(context, '/branches');
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Colors.orange[700],
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'Inter',
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatHours(int? opening, int? closing) {
  if (opening == null || closing == null) return 'Not available';
  String pad(int v) => v.toString().padLeft(2, '0');
  return '${pad(opening)}:00 - ${pad(closing)}:00';
}