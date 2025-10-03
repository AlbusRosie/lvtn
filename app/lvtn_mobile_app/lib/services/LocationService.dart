import '../constants/api_constants.dart';
import '../models/province.dart';
import 'APIService.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Future<List<Province>> getAllProvinces() async {
    try {
      final response = await ApiService().get('/provinces');
      if (response is List) {
        final provinces = response.map((json) => Province.fromJson(json)).toList();
        return provinces;
      }
      return [];
    } catch (error) {
      throw Exception('Không thể tải danh sách tỉnh/thành phố: $error');
    }
  }

  Future<List<District>> getDistrictsByProvince(int provinceId) async {
    try {
      final response = await ApiService().get('/provinces/$provinceId/districts');
      if (response is List) {
        return response.map((json) => District.fromJson(json)).toList();
      }
      return [];
    } catch (error) {
      throw Exception('Không thể tải danh sách quận/huyện: $error');
    }
  }

  Future<List<District>> getAllDistricts() async {
    try {
      final response = await ApiService().get('/provinces/districts/search');
      if (response is List) {
        return response.map((json) => District.fromJson(json)).toList();
      }
      return [];
    } catch (error) {
      throw Exception('Không thể tải danh sách quận/huyện: $error');
    }
  }
}
