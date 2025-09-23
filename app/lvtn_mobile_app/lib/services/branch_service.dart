import '../models/branch.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

class BranchService {
    static final BranchService _instance = BranchService._internal();
    factory BranchService() => BranchService._internal();
    BranchService._internal();

    final ApiService _apiService = ApiService();

    Future<List<Branch>> getAllBranches() async {
        try {
        final response = await _apiService.get(ApiConstants.branches);
        final List<dynamic> branchesData = response['branches'] ?? [];
        return branchesData.map((json) => Branch.fromJson(json)).toList();
        } catch (e) {
        throw Exception('Lỗi khi tải danh sách chi nhánh: ${e.toString()}');
        }
    }

    Future<List<Branch>> getActiveBranches() async {
        try {
        print('BranchService: Fetching active branches...');
        final response = await _apiService.get(ApiConstants.activeBranches);
        print('BranchService: API response type: ${response.runtimeType}');
        print('BranchService: API response: $response');
        
        // API trả về List trực tiếp
        final List<dynamic> branchesData = response is List ? response : [];
        print('BranchService: Branches data: $branchesData');
        
        final branches = branchesData.map((json) => Branch.fromJson(json)).toList();
        print('BranchService: Parsed ${branches.length} branches');
        return branches;
        } catch (e) {
        print('BranchService: Error: $e');
        throw Exception('Lỗi khi tải chi nhánh đang hoạt động: ${e.toString()}');
        }
    }

    Future<Branch> getBranchById(int id) async {
        try {
        final response = await _apiService.get('${ApiConstants.branches}/$id');
        return Branch.fromJson(response['branch']);
        } catch (e) {
        throw Exception('Lỗi khi tải thông tin chi nhánh: ${e.toString()}');
        }
    }

    Future<Map<String, dynamic>> getBranchStatistics() async {
        try {
        final response = await _apiService.get('${ApiConstants.branches}/statistics');
        return response;
        } catch (e) {
        throw Exception('Lỗi khi tải thống kê chi nhánh: ${e.toString()}');
        }
    }
}
