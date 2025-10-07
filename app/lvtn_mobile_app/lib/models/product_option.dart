class ProductOptionType {
  final int id;
  final int productId;
  final String name;
  final String type; // 'select' or 'checkbox'
  final bool required;
  final int displayOrder;
  final List<ProductOptionValue> values;

  ProductOptionType({
    required this.id,
    required this.productId,
    required this.name,
    required this.type,
    required this.required,
    required this.displayOrder,
    required this.values,
  });

  factory ProductOptionType.fromJson(Map<String, dynamic> json) {
    return ProductOptionType(
      id: json['id'],
      productId: json['product_id'],
      name: json['name'],
      type: json['type'] ?? 'select',
      required: json['required'] == 1 || json['required'] == true,
      displayOrder: json['display_order'] ?? 0,
      values: (json['values'] as List<dynamic>?)
          ?.map((v) => ProductOptionValue.fromJson(v))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'type': type,
      'required': required ? 1 : 0,
      'display_order': displayOrder,
      'values': values.map((v) => v.toJson()).toList(),
    };
  }
}

class ProductOptionValue {
  final int id;
  final int optionTypeId;
  final String value;
  final double priceModifier;
  final int displayOrder;

  ProductOptionValue({
    required this.id,
    required this.optionTypeId,
    required this.value,
    required this.priceModifier,
    required this.displayOrder,
  });

  factory ProductOptionValue.fromJson(Map<String, dynamic> json) {
    return ProductOptionValue(
      id: json['id'],
      optionTypeId: json['option_type_id'],
      value: json['value'],
      priceModifier: (json['price_modifier'] ?? 0).toDouble(),
      displayOrder: json['display_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'option_type_id': optionTypeId,
      'value': value,
      'price_modifier': priceModifier,
      'display_order': displayOrder,
    };
  }

  String get formattedPriceModifier {
    if (priceModifier == 0) return '';
    if (priceModifier > 0) {
      return '+${priceModifier.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')} đ';
    } else {
      return '${priceModifier.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')} đ';
    }
  }
}

class SelectedOption {
  final int optionTypeId;
  final String optionName;
  final List<int> selectedValueIds;
  final List<String> selectedValues;
  final double totalPriceModifier;

  SelectedOption({
    required this.optionTypeId,
    required this.optionName,
    required this.selectedValueIds,
    required this.selectedValues,
    required this.totalPriceModifier,
  });

  Map<String, dynamic> toJson() {
    return {
      'option_type_id': optionTypeId,
      'option_name': optionName,
      'selected_value_ids': selectedValueIds,
      'selected_values': selectedValues,
      'total_price_modifier': totalPriceModifier,
    };
  }
}
