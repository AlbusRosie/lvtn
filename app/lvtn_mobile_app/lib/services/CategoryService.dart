import '../models/category.dart';
import '../constants/api_constants.dart';
import 'APIService.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  Future<List<Category>> getAllCategories() async {
    try {
      final response = await ApiService().get(ApiConstants.categories);
      return (response as List).map((json) => Category.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Không thể tải danh sách danh mục: ${error.toString()}');
    }
  }

  Future<Category?> getCategoryById(int id) async {
    try {
      final response = await ApiService().get('${ApiConstants.categories}/$id');
      return Category.fromJson(response);
    } catch (error) {
      return null;
    }
  }
}