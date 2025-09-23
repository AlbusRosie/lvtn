import 'package:flutter/foundation.dart';
import '../models/branch.dart';
import '../services/branch_service.dart';

class BranchProvider with ChangeNotifier {
  final BranchService _branchService = BranchService();
  
  List<Branch> _branches = [];
  Branch? _selectedBranch;
  bool _isLoading = false;
  String? _error;

  List<Branch> get branches => _branches;
  Branch? get selectedBranch => _selectedBranch;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadBranches() async {
    _setLoading(true);
    _clearError();
    
    try {
      print('BranchProvider: Loading branches...');
      _branches = await _branchService.getActiveBranches();
      print('BranchProvider: Loaded ${_branches.length} branches');
      print('BranchProvider: Branches: $_branches');
    } catch (e) {
      print('BranchProvider: Error loading branches: $e');
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void selectBranch(Branch branch) {
    _selectedBranch = branch;
    notifyListeners();
  }

  void clearSelectedBranch() {
    _selectedBranch = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
