import 'package:flutter/foundation.dart';
import '../models/branch.dart';
import '../services/branch_service.dart';

class BranchProvider extends ChangeNotifier {
  final BranchService _branchService = BranchService();
  
  List<Branch> _branches = [];
  List<Branch> _activeBranches = [];
  Branch? _selectedBranch;
  bool _isLoading = false;

  List<Branch> get branches => _branches;
  List<Branch> get activeBranches => _activeBranches;
  Branch? get selectedBranch => _selectedBranch;
  bool get isLoading => _isLoading;

  Future<void> loadBranches() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _branches = await _branchService.getAllBranches();
    } catch (error) {
      debugPrint('Error loading branches: $error');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadActiveBranches() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _activeBranches = await _branchService.getActiveBranches();
    } catch (error) {
      debugPrint('Error loading active branches: $error');
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
}
