import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/home/HomeScreen.dart';
import 'ui/branches/BranchScreen.dart';
import 'ui/branches/BranchDetailScreen.dart';
import 'ui/menu/BranchMenuScreen.dart';
import 'ui/menu/ProductDetailScreen.dart';
import 'ui/profile/ProfileScreen.dart';
import 'ui/splash_screen.dart';
import 'ui/auth/AuthScreen.dart';
import 'providers/AuthProvider.dart';
import 'providers/BranchProvider.dart';
import 'providers/LocationProvider.dart';
import 'providers/CategoryProvider.dart';
import 'providers/ProductProvider.dart';
import 'services/StorageService.dart';

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
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: themeData,
        home: const SafeArea(child: SplashScreen()),
        routes: {
          '/auth': (ctx) => const SafeArea(child: AuthScreen()),
          HomeScreen.routeName: (ctx) => const SafeArea(child: HomeScreen()),
          BranchScreen.routeName: (ctx) => const SafeArea(child: BranchScreen()),
          ProfileScreen.routeName: (ctx) => const SafeArea(child: ProfileScreen()),
        },
        onGenerateRoute: (settings) {
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
          
          if (settings.name == BranchMenuScreen.routeName) {
            final branch = settings.arguments as dynamic;
            return MaterialPageRoute(
              builder: (ctx) {
                return SafeArea(
                  child: BranchMenuScreen(branch: branch),
                );
              },
            );
          }
          
          if (settings.name == ProductDetailScreen.routeName) {
            return MaterialPageRoute(
              builder: (ctx) {
                return SafeArea(
                  child: ProductDetailScreen(),
                );
              },
              settings: settings,
            );
          }
          
          return null;
        },
      ),
    );
  }
}