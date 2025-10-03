import 'package:flutter/foundation.dart';
import '../models/category.dart' as CategoryModel;
import '../services/CategoryService.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _categoryService = CategoryService();
  
  List<CategoryModel.Category> _categories = [];
  CategoryModel.Category? _selectedCategory;
  bool _isLoading = false;
  String? _error;

  List<CategoryModel.Category> get categories => _categories;
  CategoryModel.Category? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _categories = await _categoryService.getAllCategories();
    } catch (error) {
      _error = error.toString();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  void selectCategory(CategoryModel.Category? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void clearSelection() {
    _selectedCategory = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
