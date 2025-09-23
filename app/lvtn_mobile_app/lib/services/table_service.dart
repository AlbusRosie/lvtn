import '../models/table.dart';
import 'api_service.dart';
import '../constants/api_constants.dart';

class TableService {
    static final TableService _instance = TableService._internal();
    factory TableService() => TableService._internal();
    TableService._internal();

    final ApiService _apiService = ApiService();

    Future<List<Table>> getAllTables() async {
        try {
        final response = await _apiService.get(ApiConstants.tables);
        final List<dynamic> tablesData = response['tables'] ?? [];
        return tablesData.map((json) => Table.fromJson(json)).toList();
        } catch (e) {
        throw Exception('Lỗi khi tải danh sách bàn: ${e.toString()}');
        }
    }

    Future<List<Table>> getTablesByBranch(int branchId) async {
        try {
        final response = await _apiService.get('${ApiConstants.tables}?branch_id=$branchId');
        final List<dynamic> tablesData = response['tables'] ?? [];
        return tablesData.map((json) => Table.fromJson(json)).toList();
        } catch (e) {
        throw Exception('Lỗi khi tải bàn theo chi nhánh: ${e.toString()}');
        }
    }

    Future<List<Table>> getTablesByFloor(int floorId) async {
        try {
        final response = await _apiService.get('${ApiConstants.tables}?floor_id=$floorId');
        final List<dynamic> tablesData = response['tables'] ?? [];
        return tablesData.map((json) => Table.fromJson(json)).toList();
        } catch (e) {
        throw Exception('Lỗi khi tải bàn theo tầng: ${e.toString()}');
        }
    }

    Future<List<Table>> getAvailableTables(int branchId) async {
        try {
        final response = await _apiService.get('${ApiConstants.tables}?branch_id=$branchId&status=available');
        final List<dynamic> tablesData = response['tables'] ?? [];
        return tablesData.map((json) => Table.fromJson(json)).toList();
        } catch (e) {
        throw Exception('Lỗi khi tải bàn trống: ${e.toString()}');
        }
    }
}
