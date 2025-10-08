import '../constants/api_constants.dart';
import 'APIService.dart';

class TableService {
  static final TableService _instance = TableService._internal();
  factory TableService() => _instance;
  TableService._internal();

  Future<List<dynamic>> getTablesByBranch(int branchId) async {
    final endpoint = '${ApiConstants.tables}?branch_id=$branchId';
    final response = await ApiService().get(endpoint);
    if (response is List) return response;
    if (response is Map && response.containsKey('tables')) return response['tables'];
    return [];
  }
}


