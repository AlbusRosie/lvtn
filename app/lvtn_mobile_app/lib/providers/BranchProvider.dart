import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import '../models/branch.dart';
import '../services/BranchService.dart';

class BranchProvider extends ChangeNotifier {
  final BranchService _branchService = BranchService();
  
  List<Branch> _branches = [];
  List<Branch> _activeBranches = [];
  List<Branch> _nearbyBranches = [];
  List<Branch> _filteredBranches = [];
  Branch? _selectedBranch;
  int? _selectedCategoryId;
  bool _isLoading = false;
  String? _error;

  List<Branch> get branches => _branches;
  List<Branch> get activeBranches => _activeBranches;
  List<Branch> get nearbyBranches => _nearbyBranches;
  List<Branch> get filteredBranches {
    if (_selectedCategoryId != null) {
      return _filteredBranches;
    }
    return _branches;
  }
  Branch? get selectedBranch => _selectedBranch;
  int? get selectedCategoryId => _selectedCategoryId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadBranches() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _branches = await _branchService.getAllBranches();
    } catch (error) {
      _error = error.toString();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadActiveBranches() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _activeBranches = await _branchService.getActiveBranches();
    } catch (error) {
      _error = error.toString();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  /// Tải danh sách chi nhánh gần vị trí user (sử dụng API backend đã tính sẵn khoảng cách)
  Future<void> loadNearbyBranches({
    required double latitude,
    required double longitude,
    double? maxKm,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('BranchProvider: Đang gọi API getNearbyBranches với lat=$latitude, lng=$longitude');
      _nearbyBranches = await _branchService.getNearbyBranches(
        latitude: latitude,
        longitude: longitude,
        maxKm: maxKm,
      );
      print('BranchProvider: Đã nhận ${_nearbyBranches.length} branches từ API nearby');
      if (_nearbyBranches.isNotEmpty) {
        print('BranchProvider: Branch gần nhất: ${_nearbyBranches.first.name} - ${_nearbyBranches.first.distanceKm?.toStringAsFixed(2) ?? "N/A"} km');
        print('BranchProvider: Branch xa nhất: ${_nearbyBranches.last.name} - ${_nearbyBranches.last.distanceKm?.toStringAsFixed(2) ?? "N/A"} km');
      } else {
        print('BranchProvider: WARNING - nearbyBranches rỗng! Có thể không có branches nào có tọa độ hợp lệ.');
      }
    } catch (error) {
      _error = error.toString();
      print('BranchProvider: Lỗi khi load nearbyBranches: $error');
      _nearbyBranches = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectBranch(Branch branch) {
    _selectedBranch = branch;
    notifyListeners();
  }

  void clearSelectedBranch() {
    _selectedBranch = null;
    notifyListeners();
  }


  void filterBranchesByCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    _applyFilters();
  }

  void _applyFilters() {
    if (_selectedCategoryId == null) {
      notifyListeners();
      return;
    }
    
    _filteredBranches = _branches.where((branch) {
      return true;
    }).toList();
    
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategoryId = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Tính khoảng cách chính xác từ tọa độ user đến branch (km)
  /// Sử dụng công thức Haversine
  double? calculateDistance({
    required double? userLatitude,
    required double? userLongitude,
    required Branch branch,
  }) {
    if (userLatitude != null && userLongitude != null && 
        branch.latitude != null && branch.longitude != null) {
      return _haversineDistance(
        userLatitude,
        userLongitude,
        branch.latitude!,
        branch.longitude!,
      );
    }
    
    return null;
  }


  /// Công thức Haversine để tính khoảng cách giữa 2 điểm trên Trái Đất (km)
  /// Công thức này chính xác hơn Spherical Law of Cosines cho khoảng cách ngắn
  /// và ổn định hơn về mặt số học
  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371.0;
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double lat1Rad = _degreesToRadians(lat1);
    final double lat2Rad = _degreesToRadians(lat2);
    
    final double a = 
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final double clampedA = a.clamp(0.0, 1.0);
    
    final double c = 2 * math.atan2(math.sqrt(clampedA), math.sqrt(1 - clampedA));
    
    return R * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// Sắp xếp branches theo khoảng cách
  /// Sử dụng tọa độ chính xác từ Mapbox
  /// Cập nhật distanceKm cho mỗi branch sau khi tính toán
  List<Branch> sortBranchesByDistance({
    required List<Branch> branches,
    double? userLatitude,
    double? userLongitude,
  }) {
    final branchesWithDistance = branches.map((branch) {
      final distance = calculateDistance(
        userLatitude: userLatitude,
        userLongitude: userLongitude,
        branch: branch,
      );
      return Branch(
        id: branch.id,
        name: branch.name,
        addressDetail: branch.addressDetail,
        phone: branch.phone,
        email: branch.email,
        managerId: branch.managerId,
        status: branch.status,
        openingHours: branch.openingHours,
        closeHours: branch.closeHours,
        description: branch.description,
        image: branch.image,
        latitude: branch.latitude,
        longitude: branch.longitude,
        distanceKm: distance,
        createdAt: branch.createdAt,
      );
    }).toList();
    
    branchesWithDistance.sort((a, b) {
      final distA = a.distanceKm ?? 999;
      final distB = b.distanceKm ?? 999;
      return distA.compareTo(distB);
    });
    
    return branchesWithDistance;
  }
}
