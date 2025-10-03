import '../models/category.dart' as CategoryModel;
import '../constants/api_constants.dart';
import 'APIService.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  Future<List<CategoryModel.Category>> getAllCategories() async {
    try {
      final response = await ApiService().get(ApiConstants.categories);
      if (response is List) {
        return response.map((json) => CategoryModel.Category.fromJson(json)).toList();
      }
      return [];
    } catch (error) {
      throw Exception('Không thể tải danh sách danh mục: $error');
    }
  }

  Future<CategoryModel.Category> getCategoryById(int id) async {
    try {
      final response = await ApiService().get('${ApiConstants.categories}/$id');
      return CategoryModel.Category.fromJson(response);
    } catch (error) {
      throw Exception('Không thể tải thông tin danh mục: $error');
    }
  }
}
