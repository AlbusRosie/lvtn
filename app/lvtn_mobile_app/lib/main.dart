import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/screens.dart';
import 'ui/home/home_screen.dart';
import 'ui/branches/branches_screen.dart';
import 'ui/branches/branch_detail_screen.dart';
import 'ui/products/products_screen.dart';
import 'ui/products/product_detail_screen.dart';
import 'ui/tables/tables_screen.dart';
import 'ui/orders/orders_screen.dart';
import 'ui/profile/profile_screen.dart';
import 'ui/splash_screen.dart';
import 'ui/auth/auth_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/branch_provider.dart';
import 'providers/product_provider.dart';
import 'providers/table_provider.dart';
import 'providers/order_provider.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await StorageService().initialize();
  
  runApp(const LVTNRestaurantApp());
}

class LVTNRestaurantApp extends StatelessWidget {
  const LVTNRestaurantApp({super.key});

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
      dialogTheme: DialogTheme(
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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BranchProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => TableProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (ctx, authProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeData,
            home: authProvider.isAuth
                ? const SafeArea(child: HomeScreen())
                : FutureBuilder(
                    future: authProvider.tryAutoLogin(),
                    builder: (ctx, snapshot) {
                      return snapshot.connectionState == ConnectionState.waiting
                          ? const SafeArea(child: SplashScreen())
                          : const SafeArea(child: AuthScreen());
                    },
                  ),
            routes: {
              HomeScreen.routeName: (ctx) => const SafeArea(child: HomeScreen()),
              BranchesScreen.routeName: (ctx) => const SafeArea(child: BranchesScreen()),
              ProductsScreen.routeName: (ctx) => const SafeArea(child: ProductsScreen()),
              TablesScreen.routeName: (ctx) => const SafeArea(child: TablesScreen()),
              OrdersScreen.routeName: (ctx) => const SafeArea(child: OrdersScreen()),
              ProfileScreen.routeName: (ctx) => const SafeArea(child: ProfileScreen()),
            },
            onGenerateRoute: (settings) {
              if (settings.name == ProductDetailScreen.routeName) {
                final productId = settings.arguments as int;
                return MaterialPageRoute(
                  builder: (ctx) {
                    return SafeArea(
                      child: ProductDetailScreen(productId: productId),
                    );
                  },
                );
              }
              if (settings.name == BranchDetailScreen.routeName) {
                final branchId = settings.arguments as int;
                return MaterialPageRoute(
                  builder: (ctx) {
                    return SafeArea(
                      child: BranchDetailScreen(branchId: branchId),
                    );
                  },
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
