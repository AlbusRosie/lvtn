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
      throw Exception('Không thể tải danh sách sản phẩm: ${error.toString()}');
    }
  }

  Future<Map<String, dynamic>> getProductsWithMetadata({int? categoryId, int? branchId, int page = 1, int limit = 20}) async {
    try {
      String endpoint = ApiConstants.products;
      
      Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
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
      
      return {'products': [], 'metadata': null};
    } catch (error) {
      throw Exception('Không thể tải danh sách sản phẩm: ${error.toString()}');
    }
  }

  Future<Product?> getProductById(int id) async {
    try {
      final response = await ApiService().get('${ApiConstants.products}/$id');
      return Product.fromJson(response);
    } catch (error) {
      return null;
    }
  }

  Future<List<Product>> getBranchProducts(int branchId, {int? categoryId}) async {
    try {
      final result = await getBranchProductsWithMetadata(branchId, categoryId: categoryId);
      final products = result['products'] as List<dynamic>? ?? [];
      return products.map((json) => Product.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Không thể tải sản phẩm của chi nhánh: ${error.toString()}');
    }
  }

  Future<Map<String, dynamic>> getBranchProductsWithMetadata(int branchId, {int? categoryId, int page = 1, int limit = 20}) async {
    try {
      String endpoint = ApiConstants.products;
      Map<String, String> queryParams = {
        'branch_id': branchId.toString(),
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (categoryId != null) {
        queryParams['category_id'] = categoryId.toString();
      }
      
      if (queryParams.isNotEmpty) {
        endpoint += '?' + queryParams.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&');
      }
      final response = await ApiService().get(endpoint);
      List<dynamic> products = [];
      Map<String, dynamic>? metadata;
      
      if (response is Map<String, dynamic>) {
        if (response.containsKey('products')) {
          products = response['products'] as List<dynamic>? ?? [];
          metadata = response['metadata'] as Map<String, dynamic>?;
        } 
        else if (response.containsKey('data')) {
          final data = response['data'];
          if (data is Map<String, dynamic>) {
            if (data.containsKey('products')) {
              products = data['products'] as List<dynamic>? ?? [];
              metadata = data['metadata'] as Map<String, dynamic>?;
            }
          } else if (data is List) {
            products = data;
          }
        }
        else {
          for (var value in response.values) {
            if (value is List) {
              products = value;
              break;
            }
          }
        }
      } else if (response is List) {
        products = response;
      }
      
      print('BranchMenuScreen: Loaded ${products.length} products for branch $branchId (page $page)');
      if (products.isEmpty) {
        print('Warning: No products found in response for branch $branchId');
        print('Response type: ${response.runtimeType}');
        if (response is Map) {
          print('Response keys: ${response.keys}');
          if (response.containsKey('data')) {
            print('Data type: ${response['data'].runtimeType}');
          }
        }
      }
      
      return {
        'products': products.map((json) => Product.fromJson(json)).toList(),
        'metadata': metadata,
      };
    } catch (error) {
      throw Exception('Không thể tải sản phẩm của chi nhánh: ${error.toString()}');
    }
  }
}
