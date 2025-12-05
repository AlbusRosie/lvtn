import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/province.dart';
import '../services/LocationService.dart';
import '../services/GeocodingService.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  List<Province> _provinces = [];
  List<District> _districts = [];
  Province? _selectedProvince;
  District? _selectedDistrict;
  int? _selectedProvinceId;
  int? _selectedDistrictId;
  int? _selectedWardId;
  bool _isLoading = false;
  String _detailAddress = '';
  double? _latitude;
  double? _longitude;
  
  static const String _keyDetailAddress = 'user_detail_address';
  static const String _keyLatitude = 'user_latitude';
  static const String _keyLongitude = 'user_longitude';
  
  LocationProvider() {
    _loadSavedAddress();
  }

  List<Province> get provinces => _provinces;
  List<District> get filteredDistricts => _districts;
  Province? get selectedProvince => _selectedProvince;
  District? get selectedDistrict => _selectedDistrict;
  int? get selectedProvinceId => _selectedProvinceId;
  int? get selectedDistrictId => _selectedDistrictId;
  int? get selectedWardId => _selectedWardId;
  bool get isLoading => _isLoading;
  String get detailAddress => _detailAddress;
  double? get latitude => _latitude;
  double? get longitude => _longitude;

  Future<void> loadProvinces() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _provinces = await _locationService.getAllProvinces();
    } catch (e) {
      print('Error loading provinces: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectProvince(int? provinceId) async {
    _selectedProvinceId = provinceId;
    if (provinceId != null) {
      _selectedProvince = _provinces.firstWhere(
        (p) => p.id == provinceId,
        orElse: () => Province(id: 0, name: '', code: '', createdAt: DateTime.now()),
      );
      try {
        _districts = await _locationService.getDistrictsByProvince(provinceId);
      } catch (e) {
        print('Error loading districts: $e');
        _districts = [];
      }
    } else {
      _selectedProvince = null;
      _districts = [];
    }
    _selectedDistrictId = null;
    _selectedDistrict = null;
    notifyListeners();
  }

  void selectDistrict(int? districtId) {
    _selectedDistrictId = districtId;
    if (districtId != null) {
      _selectedDistrict = _districts.firstWhere(
        (d) => d.id == districtId,
        orElse: () => District(id: 0, name: '', code: '', provinceId: 0, createdAt: DateTime.now()),
      );
    } else {
      _selectedDistrict = null;
    }
    notifyListeners();
  }

  void selectWard(int? wardId) {
    _selectedWardId = wardId;
    notifyListeners();
  }

  void setDetailAddress(String address) {
    _detailAddress = address;
    _saveAddressToLocal();
    notifyListeners();
  }

  /// Set tọa độ địa chỉ
  void setCoordinates(double? latitude, double? longitude) {
    _latitude = latitude;
    _longitude = longitude;
    _saveAddressToLocal();
    notifyListeners();
  }
  
  /// Lưu địa chỉ và tọa độ vào SharedPreferences (local storage)
  Future<void> _saveAddressToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyDetailAddress, _detailAddress);
      if (_latitude != null) {
        await prefs.setDouble(_keyLatitude, _latitude!);
      } else {
        await prefs.remove(_keyLatitude);
      }
      if (_longitude != null) {
        await prefs.setDouble(_keyLongitude, _longitude!);
      } else {
        await prefs.remove(_keyLongitude);
      }
      print('LocationProvider: Đã lưu địa chỉ vào local storage');
    } catch (e) {
      print('LocationProvider: Lỗi khi lưu địa chỉ vào local storage: $e');
    }
  }
  
  /// Load địa chỉ đã lưu từ SharedPreferences
  Future<void> _loadSavedAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAddress = prefs.getString(_keyDetailAddress);
      final savedLat = prefs.getDouble(_keyLatitude);
      final savedLng = prefs.getDouble(_keyLongitude);
      
      if (savedAddress != null && savedAddress.isNotEmpty) {
        _detailAddress = savedAddress;
        print('LocationProvider: Đã load địa chỉ từ local storage: $savedAddress');
      }
      
      if (savedLat != null && savedLng != null) {
        _latitude = savedLat;
        _longitude = savedLng;
        print('LocationProvider: Đã load tọa độ từ local storage: lat=$savedLat, lng=$savedLng');
      }
      
      notifyListeners();
    } catch (e) {
      print('LocationProvider: Lỗi khi load địa chỉ từ local storage: $e');
    }
  }
  
  /// Xóa địa chỉ đã lưu (khi logout hoặc clear)
  Future<void> clearSavedAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyDetailAddress);
      await prefs.remove(_keyLatitude);
      await prefs.remove(_keyLongitude);
      print('LocationProvider: Đã xóa địa chỉ từ local storage');
    } catch (e) {
      print('LocationProvider: Lỗi khi xóa địa chỉ từ local storage: $e');
    }
  }

  /// Validate và geocode địa chỉ chi tiết, lưu tọa độ
  /// Sử dụng method mới validateDetailAddress để kiểm tra chính xác hơn
  /// Trả về true nếu địa chỉ hợp lệ và khớp với province/district đã chọn
  Future<bool> validateAndGeocodeAddress(String detailAddress) async {
    try {
      if (_selectedProvince == null) {
        print('LocationProvider: Chưa chọn tỉnh/thành phố');
        _latitude = null;
        _longitude = null;
        notifyListeners();
        return false;
      }

      final geocodingService = GeocodingService();
      
      final result = await geocodingService.validateDetailAddress(
        detailAddress: detailAddress,
        provinceName: _selectedProvince!.name,
        districtName: _selectedDistrict?.name,
      );
      
      if (result.isValid && result.coordinates != null) {
        _latitude = result.coordinates!.latitude;
        _longitude = result.coordinates!.longitude;
        notifyListeners();
        return true;
      } else {
        print('LocationProvider: Địa chỉ không hợp lệ: ${result.errorMessage}');
        _latitude = null;
        _longitude = null;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('LocationProvider: Lỗi khi validate địa chỉ: $e');
      _latitude = null;
      _longitude = null;
      notifyListeners();
      return false;
    }
  }

  List<District> getDistricts() {
    return _districts;
  }

  List<dynamic> getWards() {
    return [];
  }

  void reset() {
    _selectedProvinceId = null;
    _selectedDistrictId = null;
    _selectedWardId = null;
    _selectedProvince = null;
    _selectedDistrict = null;
    _districts = [];
    _detailAddress = '';
    notifyListeners();
  }

  void clearSelection() {
    _selectedProvinceId = null;
    _selectedDistrictId = null;
    _selectedWardId = null;
    _selectedProvince = null;
    _selectedDistrict = null;
    _districts = [];
    _detailAddress = '';
    _latitude = null;
    _longitude = null;
    clearSavedAddress();
    notifyListeners();
  }
}

