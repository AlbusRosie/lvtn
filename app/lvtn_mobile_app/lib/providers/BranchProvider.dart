import 'package:flutter/foundation.dart';
import '../models/branch.dart';
import '../services/BranchService.dart';

class BranchProvider extends ChangeNotifier {
  final BranchService _branchService = BranchService();
  
  List<Branch> _branches = [];
  List<Branch> _activeBranches = [];
  List<Branch> _filteredBranches = [];
  Branch? _selectedBranch;
  int? _selectedProvinceId;
  int? _selectedDistrictId;
  int? _selectedCategoryId;
  bool _isLoading = false;
  String? _error;

  List<Branch> get branches => _branches;
  List<Branch> get activeBranches => _activeBranches;
  List<Branch> get filteredBranches => _filteredBranches.isNotEmpty ? _filteredBranches : _branches;
  Branch? get selectedBranch => _selectedBranch;
  int? get selectedProvinceId => _selectedProvinceId;
  int? get selectedDistrictId => _selectedDistrictId;
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

  void selectBranch(Branch branch) {
    _selectedBranch = branch;
    notifyListeners();
  }

  void clearSelectedBranch() {
    _selectedBranch = null;
    notifyListeners();
  }

  void filterBranchesByLocation(int? provinceId, int? districtId) {
    _selectedProvinceId = provinceId;
    _selectedDistrictId = districtId;
    _applyFilters();
  }

  void filterBranchesByCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    _applyFilters();
  }

  void _applyFilters() {
    if (_selectedProvinceId == null && _selectedDistrictId == null && _selectedCategoryId == null) {
      _filteredBranches = [];
    } else {
      _filteredBranches = _branches.where((branch) {
        bool matchesProvince = _selectedProvinceId == null || branch.provinceId == _selectedProvinceId;
        bool matchesDistrict = _selectedDistrictId == null || branch.districtId == _selectedDistrictId;
        return matchesProvince && matchesDistrict;
      }).toList();
    }
    
    notifyListeners();
  }

  void clearFilters() {
    _selectedProvinceId = null;
    _selectedDistrictId = null;
    _selectedCategoryId = null;
    _filteredBranches = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
