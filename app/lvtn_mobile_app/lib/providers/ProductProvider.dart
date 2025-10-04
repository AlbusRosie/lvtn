import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/ProductService.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();
  
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String? _error;
  int? _selectedCategoryId;
  int? _selectedBranchId;

  List<Product> get products => _filteredProducts;
  List<Product> get allProducts => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get selectedCategoryId => _selectedCategoryId;
  int? get selectedBranchId => _selectedBranchId;

  Future<void> loadProducts({int? branchId, int? categoryId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      if (branchId != null) {
        _selectedBranchId = branchId;
        _products = await _productService.getBranchProducts(branchId, categoryId: categoryId);
      } else {
        _products = await _productService.getProducts(categoryId: categoryId);
      }
      _filteredProducts = _products;
      
      if (categoryId != null) {
        _selectedCategoryId = categoryId;
        applyCategoryFilter(categoryId);
      }
    } catch (error) {
      _error = error.toString();
      print('ProductProvider Error: $_error');
    };
    
    _isLoading = false;
    notifyListeners();
  }

  void applyCategoryFilter(int categoryId) {
    _selectedCategoryId = categoryId;
    _filteredProducts = _products.where((product) => product.categoryId == categoryId).toList();
    notifyListeners();
  }

  void clearCategoryFilter() {
    _selectedCategoryId = null;
    _filteredProducts = _products;
    notifyListeners();
  }

  void updateBranch(int branchId) {
    _selectedBranchId = branchId;
    clearCategoryFilter();
  }

  Future<void> refreshProducts() async {
    if (_selectedBranchId != null) {
      await loadProducts(branchId: _selectedBranchId, categoryId: _selectedCategoryId);
    } else {
      await loadProducts(categoryId: _selectedCategoryId);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  List<Product> getFeaturedProducts() {
    return _filteredProducts.where((product) => product.status == 'featured').take(6).toList();
  }

  List<Product> getTrendingProducts() {
    return _filteredProducts.take(6).toList();
  }
}
