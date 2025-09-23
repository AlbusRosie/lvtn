import '../models/product.dart';
import '../models/category.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

class ProductService {
    static final ProductService _instance = ProductService._internal();
    factory ProductService() => ProductService._internal();
    ProductService._internal();

    final ApiService _apiService = ApiService();

    Future<List<Product>> getProducts({int? categoryId, int? branchId}) async {
        try {
        String endpoint = ApiConstants.products;
        List<String> queryParams = [];
        
        if (categoryId != null) {
            queryParams.add('category_id=$categoryId');
        }
        if (branchId != null) {
            queryParams.add('branch_id=$branchId');
        }
        
        if (queryParams.isNotEmpty) {
            endpoint += '?${queryParams.join('&')}';
        }

        final response = await _apiService.get(endpoint);
        final List<dynamic> productsData = response['products'] ?? [];
        return productsData.map((json) => Product.fromJson(json)).toList();
        } catch (e) {
        throw Exception('Lỗi khi tải danh sách sản phẩm: ${e.toString()}');
        }
    }

    Future<Product> getProductById(int id) async {
        try {
        final response = await _apiService.get('${ApiConstants.products}/$id');
        return Product.fromJson(response['product']);
        } catch (e) {
        throw Exception('Lỗi khi tải thông tin sản phẩm: ${e.toString()}');
        }
    }

    Future<List<Category>> getCategories() async {
        try {
        final response = await _apiService.get(ApiConstants.categories);
        final List<dynamic> categoriesData = response['categories'] ?? [];
        return categoriesData.map((json) => Category.fromJson(json)).toList();
        } catch (e) {
        throw Exception('Lỗi khi tải danh mục: ${e.toString()}');
        }
    }

    Future<List<CategoryWithCount>> getCategoriesWithCount() async {
        try {
        final response = await _apiService.get('${ApiConstants.categories}/with-count');
        final List<dynamic> categoriesData = response['categories'] ?? [];
        return categoriesData.map((json) => CategoryWithCount.fromJson(json)).toList();
        } catch (e) {
        throw Exception('Lỗi khi tải danh mục với số lượng: ${e.toString()}');
        }
    }

    Future<List<BranchProduct>> getBranchProducts(int branchId) async {
        try {
        final response = await _apiService.get('${ApiConstants.branches}/$branchId/products');
        final List<dynamic> productsData = response['products'] ?? [];
        return productsData.map((json) => BranchProduct.fromJson(json)).toList();
        } catch (e) {
        throw Exception('Lỗi khi tải sản phẩm chi nhánh: ${e.toString()}');
        }
    }
}
