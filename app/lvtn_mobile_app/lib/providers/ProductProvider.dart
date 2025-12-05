import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/ProductService.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();
  
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int? _selectedCategoryId;
  int? _selectedBranchId;
  
  int _currentPage = 1;
  int _limit = 20;
  bool _hasMore = true;
  Map<String, dynamic>? _metadata;

  List<Product> get products => _filteredProducts;
  List<Product> get allProducts => _products;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  int? get selectedCategoryId => _selectedCategoryId;
  int? get selectedBranchId => _selectedBranchId;
  bool get hasMore => _hasMore;

  Future<void> loadProducts({int? branchId, int? categoryId, bool loadAll = false}) async {
    _isLoading = true;
    _error = null;
    _currentPage = 1;
    _hasMore = true;
    _products = [];
    _filteredProducts = [];
    notifyListeners();
    
    try {
      Map<String, dynamic> result;
      if (branchId != null) {
        _selectedBranchId = branchId;
        if (loadAll) {
          result = await _productService.getBranchProductsWithMetadata(
            branchId, 
            categoryId: categoryId,
            page: 1,
            limit: 1000,
          );
          _hasMore = false;
        } else {
          result = await _productService.getBranchProductsWithMetadata(
            branchId, 
            categoryId: categoryId,
            page: _currentPage,
            limit: _limit,
          );
        }
      } else {
        result = await _productService.getProductsWithMetadata(
          categoryId: categoryId,
          page: _currentPage,
          limit: _limit,
        );
      }
      
      final products = result['products'] as List<Product>? ?? [];
      _metadata = result['metadata'] as Map<String, dynamic>?;
      _products = products;
      _filteredProducts = _products;
      
      if (!loadAll) {
        if (_metadata != null) {
          final currentPage = _metadata!['page'] as int? ?? 1;
          final lastPage = _metadata!['lastPage'] as int? ?? 1;
          _hasMore = currentPage < lastPage;
        } else {
          _hasMore = products.length >= _limit;
        }
      }
      
      if (categoryId != null) {
        _selectedCategoryId = categoryId;
        applyCategoryFilter(categoryId);
      }
    } catch (error) {
      _error = error.toString();
    };
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) return;
    
    _isLoadingMore = true;
    notifyListeners();
    
    try {
      _currentPage++;
      Map<String, dynamic> result;
      
      if (_selectedBranchId != null) {
        result = await _productService.getBranchProductsWithMetadata(
          _selectedBranchId!, 
          categoryId: _selectedCategoryId,
          page: _currentPage,
          limit: _limit,
        );
      } else {
        result = await _productService.getProductsWithMetadata(
          categoryId: _selectedCategoryId,
          page: _currentPage,
          limit: _limit,
        );
      }
      
      final newProducts = result['products'] as List<Product>? ?? [];
      _metadata = result['metadata'] as Map<String, dynamic>?;
      _products.addAll(newProducts);
      
      if (_selectedCategoryId != null) {
        _filteredProducts = _products.where((product) => product.categoryId == _selectedCategoryId).toList();
      } else {
        _filteredProducts = _products;
      }
      
      if (_metadata != null) {
        final currentPage = _metadata!['page'] as int? ?? 1;
        final lastPage = _metadata!['lastPage'] as int? ?? 1;
        _hasMore = currentPage < lastPage;
      } else {
        _hasMore = newProducts.length >= _limit;
      }
    } catch (error) {
      _currentPage--;
      _error = error.toString();
    }
    
    _isLoadingMore = false;
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

  void resetPagination() {
    _currentPage = 1;
    _hasMore = true;
    _metadata = null;
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
