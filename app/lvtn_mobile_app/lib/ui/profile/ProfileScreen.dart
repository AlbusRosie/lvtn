import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/AuthProvider.dart';
import '../../providers/ChatProvider.dart';
import '../widgets/AppBottomNav.dart';
import 'EditProfileScreen.dart';
import '../../utils/image_utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const String routeName = '/profile';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFFFF8A00);
    
    return Scaffold(
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
              child: Center(
                child: Text(
                  'Cá nhân',
                  style: TextStyle(
                    color: Colors.grey[900],
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;
          
          print('ProfileScreen: isAuth = ${authProvider.isAuth}');
          print('ProfileScreen: currentUser = ${user?.id ?? "null"}');
          if (user != null) {
            print('ProfileScreen: username = ${user.username}, name = ${user.name}, email = ${user.email}');
          }
          
          if (user == null) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_off_rounded,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Không có thông tin người dùng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vui lòng đăng nhập để tiếp tục',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
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
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/auth');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Đăng nhập lại',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 20,
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        spreadRadius: 0,
                        blurRadius: 20,
                        offset: Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        spreadRadius: 0,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF8A00),
                          shape: BoxShape.circle,
                        ),
                        child: user.avatar != null && user.avatar!.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  ImageUtils.getImageUrl(user.avatar),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.white,
                                    );
                                  },
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.name.isNotEmpty ? user.name : 'Người dùng',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900],
                          letterSpacing: -0.4,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (user.email.isNotEmpty)
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      if (user.email.isEmpty) const SizedBox(height: 0),
                      const SizedBox(height: 6),
                      if (user.username.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '@${user.username}',
                            style: TextStyle(
                              fontSize: 13,
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Tài khoản',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900],
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _buildMenuItem(
                  context,
                  'Thông tin cá nhân',
                  Icons.person_outline_rounded,
                  primaryColor,
                  () async {
                    final result = await Navigator.pushNamed(context, EditProfileScreen.routeName);
                    if (result == true && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cập nhật thông tin thành công'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildMenuItem(
                  context,
                  'Đơn hàng của tôi',
                  Icons.receipt_long_rounded,
                  primaryColor,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tính năng đang phát triển'),
                        backgroundColor: primaryColor,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildMenuItem(
                  context,
                  'Cài đặt',
                  Icons.settings_rounded,
                  primaryColor,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tính năng đang phát triển'),
                        backgroundColor: primaryColor,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Đăng xuất'),
                          content: const Text('Bạn có chắc muốn đăng xuất?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Hủy'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Đăng xuất'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await authProvider.logout();
                        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                        chatProvider.reset();
                        if (mounted) {
                          Navigator.pushReplacementNamed(context, '/auth');
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Đăng xuất',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: 4),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    Color primaryColor,
    VoidCallback onTap,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            spreadRadius: 0,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            spreadRadius: 0,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey[600],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
