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

  /// Check if a table is available at a specific date and time
  /// Uses backend API for consistent logic across all platforms
  Future<Map<String, dynamic>> checkTableAvailability({
    required int tableId,
    required String date, // YYYY-MM-DD
    required String time, // HH:MM:SS or HH:MM
    int durationMinutes = 120,
  }) async {
    try {
      // Normalize time format
      String normalizedTime = time;
      if (normalizedTime.length == 5) {
        normalizedTime = '$normalizedTime:00';
      }

      final endpoint = '${ApiConstants.tables}/$tableId/check-availability?date=$date&time=$normalizedTime&duration_minutes=$durationMinutes';
      print('TableService.checkTableAvailability: Calling endpoint: $endpoint');
      
      final response = await ApiService().get(endpoint);
      
      print('TableService.checkTableAvailability: Response type: ${response.runtimeType}');
      print('TableService.checkTableAvailability: Response: $response');
      
      if (response is Map) {
        // APIService already unwraps the 'data' field if status is 'success'
        // So response should directly contain 'available' field
        final result = response.cast<String, dynamic>();
        print('TableService.checkTableAvailability: Parsed result: $result');
        return result;
      }
      
      print('TableService.checkTableAvailability: Response is not Map, returning false');
      return {'available': false};
    } catch (e, stackTrace) {
      print('TableService.checkTableAvailability error: $e');
      print('TableService.checkTableAvailability stack trace: $stackTrace');
      return {'available': false};
    }
  }
}


