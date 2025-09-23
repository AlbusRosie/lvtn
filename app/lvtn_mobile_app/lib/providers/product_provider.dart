import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/category.dart' as models;
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();
  
  List<Product> _products = [];
  List<models.Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  List<models.Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProducts({int? categoryId, int? branchId}) async {
    _setLoading(true);
    _clearError();
    
    try {
      _products = await _productService.getProducts(
        categoryId: categoryId,
        branchId: branchId,
      );
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _productService.getCategories();
    } catch (e) {
      _setError(e.toString());
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
