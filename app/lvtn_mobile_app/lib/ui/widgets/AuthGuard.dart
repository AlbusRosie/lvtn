import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/AuthProvider.dart';
import '../home/HomeScreen.dart';
import '../delivery/DeliveryDriverScreen.dart';

/// Widget bảo vệ các màn hình yêu cầu đăng nhập
/// Nếu chưa đăng nhập, sẽ tự động chuyển đến màn hình đăng nhập
class AuthGuard extends StatefulWidget {
  final Widget child;
  
  const AuthGuard({
    super.key,
    required this.child,
  });

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _hasChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasChecked) {
      _hasChecked = true;
      _checkAuth();
    }
  }

  void _checkAuth() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final user = authProvider.currentUser;
    final isValidUser = user != null && 
                        user.id > 0 && 
                        (user.username.isNotEmpty || user.email.isNotEmpty);
    
    print('AuthGuard: isAuth = ${authProvider.isAuth}, user = ${user?.id ?? "null"}, isValidUser = $isValidUser');
    
    if (!authProvider.isAuth || !isValidUser) {
      print('AuthGuard: Chuyển đến màn hình đăng nhập');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/auth',
            (route) => false,
          );
        }
      });
      return;
    }
    
    // Kiểm tra role và redirect đến màn hình phù hợp nếu đang ở sai màn hình
    if (user != null && user.roleId == 7) {
      // Delivery staff - kiểm tra xem có đang ở DeliveryDriverScreen không
      final currentRoute = ModalRoute.of(context)?.settings.name;
      if (currentRoute != DeliveryDriverScreen.routeName) {
        print('AuthGuard: Delivery driver đang ở sai màn hình, redirect đến DeliveryDriverScreen');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              DeliveryDriverScreen.routeName,
              (route) => false,
            );
          }
        });
      }
    } else {
      // Customer - kiểm tra xem có đang ở HomeScreen không
      final currentRoute = ModalRoute.of(context)?.settings.name;
      if (currentRoute == DeliveryDriverScreen.routeName) {
        print('AuthGuard: Customer đang ở DeliveryDriverScreen, redirect đến HomeScreen');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              HomeScreen.routeName,
              (route) => false,
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;
        final isValidUser = user != null && 
                            user.id > 0 && 
                            (user.username.isNotEmpty || user.email.isNotEmpty);
        
        if (!authProvider.isAuth || !isValidUser) {
          if (!_hasChecked) {
            return Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFFFFA500),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Đang kiểm tra đăng nhập...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFA500),
              ),
            ),
          );
        }
        
        return widget.child;
      },
    );
  }
}

