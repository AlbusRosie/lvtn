import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();
  
  List<Product> _products = [];
  List<Product> _availableProducts = [];
  List<Product> _branchProducts = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  List<Product> get availableProducts => _availableProducts;
  List<Product> get branchProducts => _branchProducts;
  List<Map<String, dynamic>> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> loadProducts({int? branchId, int? categoryId, String? search}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _products = await _productService.getProductsByBranch(branchId ?? 0);
      _categories = await _productService.getCategories();
    } catch (error) {
      debugPrint('Error loading products: $error');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAvailableProducts() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _availableProducts = await _productService.getAvailableProducts();
    } catch (error) {
      debugPrint('Error loading available products: $error');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadProductsByBranch(int branchId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _branchProducts = await _productService.getProductsByBranch(branchId);
    } catch (error) {
      debugPrint('Error loading branch products: $error');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Product? findById(int id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }
}
