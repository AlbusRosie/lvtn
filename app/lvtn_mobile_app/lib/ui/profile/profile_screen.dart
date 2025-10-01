import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const String routeName = '/profile';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cá nhân'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;
          
          if (user == null) {
            return Center(
              child: Text('Không có thông tin người dùng'),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile card
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.orange,
                          child: user.avatar != null
                              ? ClipOval(
                                  child: Image.network(
                                    user.avatar!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.white,
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white,
                                ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          user.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          user.email,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '@${user.username}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Menu items
                _buildMenuItem(
                  context,
                  'Thông tin cá nhân',
                  Icons.person_outline,
                  () {
                    // TODO: Navigate to edit profile
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tính năng đang phát triển')),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  'Đơn hàng của tôi',
                  Icons.receipt_long,
                  () {
                    Navigator.pushNamed(context, '/orders');
                  },
                ),
                _buildMenuItem(
                  context,
                  'Cài đặt',
                  Icons.settings,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tính năng đang phát triển')),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  'Hỗ trợ',
                  Icons.help_outline,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tính năng đang phát triển')),
                    );
                  },
                ),
                SizedBox(height: 20),

                // Logout button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Đăng xuất'),
                          content: Text('Bạn có chắc muốn đăng xuất?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('Hủy'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text('Đăng xuất'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await authProvider.logout();
                        if (mounted) {
                          Navigator.pushReplacementNamed(context, '/auth');
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Đăng xuất'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
