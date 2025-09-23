import 'package:flutter/foundation.dart';
import '../models/table.dart' as models;
import '../services/table_service.dart';

class TableProvider with ChangeNotifier {
  final TableService _tableService = TableService();
  
  List<models.Table> _tables = [];
  bool _isLoading = false;
  String? _error;

  List<models.Table> get tables => _tables;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTables({int? branchId, int? floorId}) async {
    _setLoading(true);
    _clearError();
    
    try {
      if (branchId != null) {
        _tables = await _tableService.getTablesByBranch(branchId);
      } else if (floorId != null) {
        _tables = await _tableService.getTablesByFloor(floorId);
      } else {
        _tables = await _tableService.getAllTables();
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadAvailableTables(int branchId) async {
    _setLoading(true);
    _clearError();
    
    try {
      _tables = await _tableService.getAvailableTables(branchId);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
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
