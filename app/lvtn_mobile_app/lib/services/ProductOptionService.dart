import '../models/product_option.dart';
import '../constants/api_constants.dart';
import 'APIService.dart';

class ProductOptionService {
  static final ProductOptionService _instance = ProductOptionService._internal();
  factory ProductOptionService() => _instance;
  ProductOptionService._internal();

  Future<List<ProductOptionType>> getProductOptions(int productId) async {
    try {
      final response = await ApiService().get('/api/products/$productId/options');
      
      if (response is List) {
        return response.map((json) => ProductOptionType.fromJson(json)).toList();
      } else if (response is Map<String, dynamic> && response.containsKey('data')) {
        final List<dynamic> options = response['data'];
        return options.map((json) => ProductOptionType.fromJson(json)).toList();
      }
      
      return [];
    } catch (error) {
      print('ProductOptionService: Error loading product options: $error');
      return [];
    }
  }

  Future<List<ProductOptionType>> getProductOptionsWithDetails(int productId) async {
    try {
      print('🔍 ProductOptionService: Loading options for product ID: $productId');
      final response = await ApiService().get('/api/products/$productId/options');
      
      print('📡 ProductOptionService: API Response type: ${response.runtimeType}');
      print('📡 ProductOptionService: API Response: $response');
      
      List<ProductOptionType> options = [];
      
      if (response is List) {
        print('📋 ProductOptionService: Response is List with ${response.length} items');
        options = response.map((json) => ProductOptionType.fromJson(json)).toList();
      } else if (response is Map<String, dynamic>) {
        print('📋 ProductOptionService: Response is Map with keys: ${response.keys}');
        if (response.containsKey('data')) {
          final List<dynamic> optionsData = response['data'];
          print('📋 ProductOptionService: Found data field with ${optionsData.length} items');
          options = optionsData.map((json) => ProductOptionType.fromJson(json)).toList();
        } else if (response.containsKey('options')) {
          final List<dynamic> optionsData = response['options'];
          print('📋 ProductOptionService: Found options field with ${optionsData.length} items');
          options = optionsData.map((json) => ProductOptionType.fromJson(json)).toList();
        } else {
          print('📋 ProductOptionService: No data or options field found');
        }
      } else {
        print('📋 ProductOptionService: Unexpected response type: ${response.runtimeType}');
      }
      
      print('🎯 ProductOptionService: Parsed ${options.length} options');
      
      // Sort by display order
      options.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      
      // Sort values within each option by display order
      for (var option in options) {
        option.values.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        print('🎯 ProductOptionService: Option "${option.name}" has ${option.values.length} values');
      }
      
      return options;
    } catch (error) {
      print('❌ ProductOptionService: Error loading product options with details: $error');
      return [];
    }
  }

  double calculateTotalPriceModifier(List<SelectedOption> selectedOptions) {
    return selectedOptions.fold(0.0, (sum, option) => sum + option.totalPriceModifier);
  }

  List<SelectedOption> createDefaultSelections(List<ProductOptionType> options) {
    List<SelectedOption> selections = [];
    
    for (var option in options) {
      if (option.type == 'select' && option.values.isNotEmpty) {
        // For select type, select the first value by default
        final firstValue = option.values.first;
        selections.add(SelectedOption(
          optionTypeId: option.id,
          optionName: option.name,
          selectedValueIds: [firstValue.id],
          selectedValues: [firstValue.value],
          totalPriceModifier: firstValue.priceModifier,
        ));
      } else if (option.type == 'checkbox') {
        // For checkbox type, start with no selections
        selections.add(SelectedOption(
          optionTypeId: option.id,
          optionName: option.name,
          selectedValueIds: [],
          selectedValues: [],
          totalPriceModifier: 0.0,
        ));
      }
    }
    
    return selections;
  }

  SelectedOption updateSelection(
    SelectedOption currentSelection,
    ProductOptionType optionType,
    ProductOptionValue value,
    bool isSelected,
  ) {
    List<int> newValueIds = List.from(currentSelection.selectedValueIds);
    List<String> newValues = List.from(currentSelection.selectedValues);
    double newPriceModifier = currentSelection.totalPriceModifier;

    if (optionType.type == 'select') {
      // For select type, replace current selection
      newValueIds = [value.id];
      newValues = [value.value];
      newPriceModifier = value.priceModifier;
    } else if (optionType.type == 'checkbox') {
      // For checkbox type, add or remove selection
      if (isSelected) {
        if (!newValueIds.contains(value.id)) {
          newValueIds.add(value.id);
          newValues.add(value.value);
          newPriceModifier += value.priceModifier;
        }
      } else {
        if (newValueIds.contains(value.id)) {
          newValueIds.remove(value.id);
          newValues.remove(value.value);
          newPriceModifier -= value.priceModifier;
        }
      }
    }

    return SelectedOption(
      optionTypeId: currentSelection.optionTypeId,
      optionName: currentSelection.optionName,
      selectedValueIds: newValueIds,
      selectedValues: newValues,
      totalPriceModifier: newPriceModifier,
    );
  }

  bool validateRequiredOptions(List<ProductOptionType> options, List<SelectedOption> selections) {
    for (var option in options) {
      if (option.required) {
        final selection = selections.firstWhere(
          (s) => s.optionTypeId == option.id,
          orElse: () => SelectedOption(
            optionTypeId: option.id,
            optionName: option.name,
            selectedValueIds: [],
            selectedValues: [],
            totalPriceModifier: 0.0,
          ),
        );
        
        if (selection.selectedValueIds.isEmpty) {
          return false;
        }
      }
    }
    return true;
  }
}
