import '../models/product.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  Future<List<Product>> getAllProducts() async {
    try {
      final response = await ApiService().get(ApiConstants.products);
      return (response as List).map((json) => Product.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Không thể tải danh sách sản phẩm: ${error.toString()}');
    }
  }

  Future<List<Product>> getAvailableProducts() async {
    try {
      final response = await ApiService().get('${ApiConstants.products}/available');
      return (response as List).map((json) => Product.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Không thể tải sản phẩm có sẵn: ${error.toString()}');
    }
  }

  Future<List<Product>> getProductsByBranch(int branchId) async {
    try {
      final response = await ApiService().get('${ApiConstants.products}/branch/$branchId');
      return (response as List).map((json) => Product.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Không thể tải sản phẩm theo chi nhánh: ${error.toString()}');
    }
  }

  Future<Product> getProductById(int id) async {
    try {
      final response = await ApiService().get('${ApiConstants.products}/$id');
      return Product.fromJson(response);
    } catch (error) {
      throw Exception('Không thể tải thông tin sản phẩm: ${error.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await ApiService().get(ApiConstants.categories);
      return (response as List).map((json) => Map<String, dynamic>.from(json)).toList();
    } catch (error) {
      throw Exception('Không thể tải danh mục: ${error.toString()}');
    }
  }
}
