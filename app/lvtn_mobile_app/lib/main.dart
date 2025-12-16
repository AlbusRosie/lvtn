import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'ui/home/HomeScreen.dart';
import 'ui/branches/BranchScreen.dart';
import 'ui/branches/BranchDetailScreen.dart';
import 'ui/branches/BranchMenuScreen.dart';
import 'ui/reservation/ReservationMenuScreen.dart';
import 'ui/products/ProductDetailScreen.dart';
import 'ui/profile/ProfileScreen.dart';
import 'ui/profile/EditProfileScreen.dart';
import 'ui/splash_screen.dart';
import 'ui/auth/AuthScreen.dart';
import 'providers/AuthProvider.dart';
import 'providers/BranchProvider.dart';
import 'providers/LocationProvider.dart';
import 'providers/CategoryProvider.dart';
import 'providers/ProductProvider.dart';
import 'providers/ChatProvider.dart';
import 'ui/cart/CartProvider.dart';
import 'services/StorageService.dart';
import 'models/branch.dart';
import 'ui/tables/TableScreen.dart';
import 'ui/orders/QuickOrderScreen.dart';
import 'ui/orders/OrdersScreen.dart';
import 'ui/chat/ChatScreen.dart';
import 'ui/takeaway/TakeawayBranchSelectionScreen.dart';
import 'ui/delivery/DeliveryDriverScreen.dart';
import 'ui/widgets/AuthGuard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService().initialize();
  
  // Set system UI overlay style globally
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  final authProvider = AuthProvider();
  await authProvider.tryAutoLogin();
  
  runApp(LVTNRestaurantApp(authProvider: authProvider));
}

class LVTNRestaurantApp extends StatelessWidget {
  final AuthProvider authProvider;
  
  const LVTNRestaurantApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.orange,
      secondary: Colors.deepOrange,
      surface: Colors.white,
      surfaceTint: Colors.grey[200],
    );
    
    final themeData = ThemeData(
      fontFamily: 'Lato',
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shadowColor: colorScheme.shadow,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
        ),
      ),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => BranchProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: themeData,
        builder: (context, child) {
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              systemNavigationBarColor: Colors.white,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
          );
          return child!;
        },
        home: const SplashScreen(),
        routes: {
          '/auth': (ctx) => const AuthScreen(),
          HomeScreen.routeName: (ctx) => AuthGuard(
            child: const HomeScreen(),
          ),
          BranchScreen.routeName: (ctx) => AuthGuard(
            child: const BranchScreen(),
          ),
          OrdersScreen.routeName: (ctx) => AuthGuard(
            child: const OrdersScreen(),
          ),
          ProfileScreen.routeName: (ctx) => AuthGuard(
            child: const ProfileScreen(),
          ),
          EditProfileScreen.routeName: (ctx) => AuthGuard(
            child: const EditProfileScreen(),
          ),
          QuickOrderScreen.routeName: (ctx) => AuthGuard(
            child: const QuickOrderScreen(),
          ),
          ChatScreen.routeName: (ctx) => AuthGuard(
            child: const ChatScreen(),
          ),
          TakeawayBranchSelectionScreen.routeName: (ctx) => AuthGuard(
            child: const TakeawayBranchSelectionScreen(),
          ),
          DeliveryDriverScreen.routeName: (ctx) => AuthGuard(
            child: const DeliveryDriverScreen(),
          ),
        },
        onGenerateRoute: (settings) {
          if (settings.name == BranchDetailScreen.routeName) {
            final args = settings.arguments;
            Branch branch;
            
            if (args is Map) {
              branch = args['branch'] as Branch;
            } else {
              branch = args as Branch;
            }
            
            return MaterialPageRoute(
              builder: (ctx) {
                return AuthGuard(
                  child: BranchDetailScreen(
                    branch: branch,
                  ),
                );
              },
            );
          }
          
          if (settings.name == BranchMenuScreen.routeName) {
            final args = settings.arguments;
            Branch branch;
            int? reservationId;
            String? orderType;
            
            if (args is Map) {
              branch = args['branch'] as Branch;
              reservationId = args['reservationId'] as int?;
              orderType = args['orderType'] as String?;
            } else {
              branch = args as Branch;
            }
            
            // Nếu có reservationId, dùng trang menu mới
            if (reservationId != null) {
              return MaterialPageRoute(
                builder: (ctx) {
                  return AuthGuard(
                    child: ReservationMenuScreen(
                      branch: branch,
                      reservationId: reservationId!,
                    ),
                  );
                },
              );
            }
            
            return MaterialPageRoute(
              builder: (ctx) {
                return AuthGuard(
                  child: BranchMenuScreen(
                    branch: branch,
                    reservationId: reservationId,
                    orderType: orderType, // Truyền orderType vào BranchMenuScreen
                  ),
                );
              },
            );
          }
          
          if (settings.name == ReservationMenuScreen.routeName) {
            final args = settings.arguments as Map<String, dynamic>;
            final branch = args['branch'] as Branch;
            final reservationId = args['reservationId'] as int;
            
            return MaterialPageRoute(
              builder: (ctx) {
                return AuthGuard(
                  child: ReservationMenuScreen(
                    branch: branch,
                    reservationId: reservationId,
                  ),
                );
              },
            );
          }
          
          if (settings.name == ProductDetailScreen.routeName) {
            return MaterialPageRoute(
              builder: (ctx) {
                return AuthGuard(
                  child: ProductDetailScreen(),
                );
              },
              settings: settings,
            );
          }
          if (settings.name == TableScreen.routeName) {
            final branch = settings.arguments as Branch;
            return MaterialPageRoute(
              builder: (ctx) {
                return AuthGuard(
                  child: TableScreen(branch: branch),
                );
              },
            );
          }
          
          return null;
        },
      ),
    );
  }
}
