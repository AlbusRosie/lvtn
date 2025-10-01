import '../models/branch.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

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
}
