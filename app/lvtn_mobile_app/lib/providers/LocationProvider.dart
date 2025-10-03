import 'package:flutter/foundation.dart';
import '../models/province.dart';
import '../services/LocationService.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  
  List<Province> _provinces = [];
  List<District> _districts = [];
  List<District> _filteredDistricts = [];
  Province? _selectedProvince;
  District? _selectedDistrict;
  bool _isLoading = false;
  String? _error;

  List<Province> get provinces => _provinces;
  List<District> get districts => _districts;
  List<District> get filteredDistricts => _filteredDistricts;
  Province? get selectedProvince => _selectedProvince;
  District? get selectedDistrict => _selectedDistrict;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProvinces() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _provinces = await _locationService.getAllProvinces();
    } catch (error) {
      _error = error.toString();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadDistrictsByProvince(int provinceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _filteredDistricts = await _locationService.getDistrictsByProvince(provinceId);
    } catch (error) {
      _error = error.toString();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  void selectProvince(Province? province) {
    _selectedProvince = province;
    _selectedDistrict = null;
    _filteredDistricts = [];
    
    if (province != null) {
      loadDistrictsByProvince(province.id);
    }
    
    notifyListeners();
  }

  void selectDistrict(District? district) {
    _selectedDistrict = district;
    notifyListeners();
  }

  void clearSelection() {
    _selectedProvince = null;
    _selectedDistrict = null;
    _filteredDistricts = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
