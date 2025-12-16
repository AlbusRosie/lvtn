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
      
      // Handle different response structures
      List<dynamic> branchesList = [];
      if (response is List) {
        branchesList = response;
      } else if (response is Map) {
        if (response.containsKey('data')) {
          branchesList = response['data'] is List ? response['data'] : [];
        } else if (response.containsKey('branches')) {
          branchesList = response['branches'] is List ? response['branches'] : [];
        }
      }
      
      final branches = branchesList.map((json) {
        final branch = Branch.fromJson(json);
        print('BranchService: Branch ${branch.name} - distance: ${branch.distanceKm} km');
        return branch;
      }).toList();
      print('BranchService: Loaded ${branches.length} nearby branches with distances');
      if (branches.isNotEmpty) {
        final withDistance = branches.where((b) => b.distanceKm != null).length;
        print('BranchService: Branches with distance: $withDistance/${branches.length}');
        if (branches.first.distanceKm != null) {
          print('BranchService: First branch distance: ${branches.first.distanceKm!.toStringAsFixed(2)} km');
        }
      }
      return branches;
    } catch (error) {
      throw Exception('Không thể tải danh sách chi nhánh gần bạn: ${error.toString()}');
    }
  }
}
