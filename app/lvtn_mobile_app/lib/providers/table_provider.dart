import 'package:flutter/foundation.dart';
import '../models/table.dart';
import '../services/table_service.dart';

class TableProvider extends ChangeNotifier {
  final TableService _tableService = TableService();
  
  List<Table> _tables = [];
  List<Table> _availableTables = [];
  Table? _selectedTable;
  bool _isLoading = false;

  List<Table> get tables => _tables;
  List<Table> get availableTables => _availableTables;
  Table? get selectedTable => _selectedTable;
  bool get isLoading => _isLoading;

  Future<void> loadTables() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _tables = await _tableService.getAllTables();
    } catch (error) {
      debugPrint('Error loading tables: $error');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTablesByBranch(int branchId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _tables = await _tableService.getTablesByBranch(branchId);
    } catch (error) {
      debugPrint('Error loading branch tables: $error');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAvailableTables(int branchId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _availableTables = await _tableService.getAvailableTables(branchId);
    } catch (error) {
      debugPrint('Error loading available tables: $error');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  void selectTable(Table table) {
    _selectedTable = table;
    notifyListeners();
  }

  void clearSelectedTable() {
    _selectedTable = null;
    notifyListeners();
  }
}
