import '../models/table.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

class TableService {
  static final TableService _instance = TableService._internal();
  factory TableService() => _instance;
  TableService._internal();

  Future<List<Table>> getAllTables() async {
    try {
      final response = await ApiService().get(ApiConstants.tables);
      return (response as List).map((json) => Table.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Không thể tải danh sách bàn: ${error.toString()}');
    }
  }

  Future<List<Table>> getTablesByBranch(int branchId) async {
    try {
      final response = await ApiService().get('${ApiConstants.tables}?branch_id=$branchId');
      return (response as List).map((json) => Table.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Không thể tải bàn theo chi nhánh: ${error.toString()}');
    }
  }

  Future<List<Table>> getAvailableTables(int branchId) async {
    try {
      final response = await ApiService().get('${ApiConstants.tables}?branch_id=$branchId&status=available');
      return (response as List).map((json) => Table.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Không thể tải bàn trống: ${error.toString()}');
    }
  }
}
