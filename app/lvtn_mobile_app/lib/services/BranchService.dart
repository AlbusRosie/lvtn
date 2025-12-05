import '../models/branch.dart';
import '../constants/api_constants.dart';
import 'APIService.dart';

class BranchService {
  static final BranchService _instance = BranchService._internal();
  factory BranchService() => _instance;
  BranchService._internal();

  Future<List<Branch>> getAllBranches() async {
    try {
      final response = await ApiService().get(ApiConstants.branches);
      return (response as List).map((json) => Branch.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Không thể tải danh sách chi nhánh: ${error.toString()}');
    }
  }

  Future<List<Branch>> getActiveBranches() async {
    try {
      final response = await ApiService().get(ApiConstants.activeBranches);
      return (response as List).map((json) => Branch.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Không thể tải chi nhánh hoạt động: ${error.toString()}');
    }
  }

  Future<Branch> getBranchById(int id) async {
    try {
      final response = await ApiService().get('${ApiConstants.branches}/$id');
      return Branch.fromJson(response);
    } catch (error) {
      throw Exception('Không thể tải thông tin chi nhánh: ${error.toString()}');
    }
  }

  /// Lấy danh sách chi nhánh theo khoảng cách từ vị trí người dùng
  /// Backend trả về thêm trường distance_km (map vào Branch.distanceKm)
  Future<List<Branch>> getNearbyBranches({
    required double latitude,
    required double longitude,
    double? maxKm,
  }) async {
    try {
      final queryParams = <String, String>{
        'lat': latitude.toString(),
        'lng': longitude.toString(),
      };
      if (maxKm != null) {
        queryParams['maxKm'] = maxKm.toString();
      }

      final queryString = Uri(queryParameters: queryParams).query;
      final url = '${ApiConstants.branches}/nearby?$queryString';

      final response = await ApiService().get(url);
      return (response as List).map((json) => Branch.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Không thể tải danh sách chi nhánh gần bạn: ${error.toString()}');
    }
  }
}
