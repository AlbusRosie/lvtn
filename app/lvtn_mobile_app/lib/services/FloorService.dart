import '../constants/api_constants.dart';
import 'APIService.dart';

class FloorService {
  static final FloorService _instance = FloorService._internal();
  factory FloorService() => _instance;
  FloorService._internal();

  Future<List<dynamic>> getFloorsByBranch(int branchId) async {
    final endpoint = '${ApiConstants.floors}?branch_id=$branchId';
    final response = await ApiService().get(endpoint);
    if (response is List) return response;
    if (response is Map && response.containsKey('floors')) return response['floors'];
    return [];
  }
}


