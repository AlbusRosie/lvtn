import '../models/product.dart';
import '../constants/api_constants.dart';
import 'APIService.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  Future<List<Product>> getProducts({int? categoryId, int? branchId}) async {
    try {
      final result = await getProductsWithMetadata(categoryId: categoryId, branchId: branchId);
      final products = result['products'] as List<dynamic>? ?? [];
      return products.map((json) => Product.fromJson(json)).toList();
    } catch (error) {
      print('ProductService: Error loading products: $error');
      throw Exception('Không thể tải danh sách sản phẩm: ${error.toString()}');
    }
  }

  Future<Map<String, dynamic>> getProductsWithMetadata({int? categoryId, int? branchId}) async {
    try {
      String endpoint = ApiConstants.products;
      
      Map<String, String> queryParams = {};
      if (categoryId != null) {
        queryParams['category_id'] = categoryId.toString();
      }
      if (branchId != null) {
        queryParams['branch_id'] = branchId.toString();
      }
      
      if (queryParams.isNotEmpty) {
        endpoint += '?' + queryParams.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&');
      }

      print('ProductService: Fetching products endpoint: $endpoint');

      final response = await ApiService().get(endpoint);
      
      if (response is Map<String, dynamic>) {
        if (response.containsKey('products')) {
          return response;
        } else if (response.containsKey('data')) {
          return {
            'products': response['data'] as List<dynamic>,
            'metadata': response.containsKey('metadata') ? response['metadata'] : null,
          };
        }
      }
      
      print('ProductService: Unexpected response format: ${response.runtimeType}');
      return {'products': [], 'metadata': null};
    } catch (error) {
      print('ProductService: Error loading products: $error');
      throw Exception('Không thể tải danh sách sản phẩm: ${error.toString()}');
    }
  }

  Future<Product?> getProductById(int id) async {
    try {
      final response = await ApiService().get('${ApiConstants.products}/$id');
      return Product.fromJson(response);
    } catch (error) {
      print('ProductService: Error loading product by ID: $error');
      return null;
    }
  }

  Future<List<Product>> getBranchProducts(int branchId, {int? categoryId}) async {
    try {
      String endpoint = ApiConstants.products;
      Map<String, String> queryParams = {
        'branch_id': branchId.toString(),
      };
      
      if (categoryId != null) {
        queryParams['category_id'] = categoryId.toString();
      }
      
      if (queryParams.isNotEmpty) {
        endpoint += '?' + queryParams.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&');
      }

      print('ProductService: Fetching branch products endpoint: $endpoint');

      final response = await ApiService().get(endpoint);
      
      print('ProductService: API Response type: ${response.runtimeType}');
      print('ProductService: Products field exists: ${response is Map && response.containsKey('products')}');
      
      List<dynamic> products = [];
      if (response is Map<String, dynamic>) {
        if (response.containsKey('products')) {
          products = response['products'] as List<dynamic>? ?? [];
          print('ProductService: Extracted ${products.length} products from data.products');
        } else {
          products = response as List<dynamic>? ?? [];
          print('ProductService: Using response as direct list: ${products.length} items');
        }
      } else if (response is List) {
        products = response;
        print('ProductService: Response is direct list: ${products.length} items');
      }
      
      print('ProductService: Found ${products.length} branch products');
      return products.map((json) => Product.fromJson(json)).toList();
    } catch (error) {
      print('ProductService: Error loading branch products: $error');
      throw Exception('Không thể tải sản phẩm của chi nhánh: ${error.toString()}');
    }
  }
}