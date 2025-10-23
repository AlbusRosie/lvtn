import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/product_option.dart';
import '../../models/cart.dart';
import '../../services/ProductOptionService.dart';
import '../../services/CartService.dart';
import '../../services/AuthService.dart';
import '../../constants/api_constants.dart';

class ProductOptionEditDialog extends StatefulWidget {
  final CartItem cartItem;
  final Function(CartItem) onOptionUpdated;

  const ProductOptionEditDialog({
    Key? key,
    required this.cartItem,
    required this.onOptionUpdated,
  }) : super(key: key);

  @override
  State<ProductOptionEditDialog> createState() => _ProductOptionEditDialogState();
}

class _ProductOptionEditDialogState extends State<ProductOptionEditDialog> {
  List<ProductOptionType> _options = [];
  List<SelectedOption> _selectedOptions = [];
  bool _isLoading = true;
  String? _error;
  double _basePrice = 0.0;
  double _totalPriceModifier = 0.0;
  String _specialInstructions = '';
  late TextEditingController _specialInstructionsController;

  @override
  void initState() {
    super.initState();
    _specialInstructionsController = TextEditingController();
    _loadProductOptions();
  }

  @override
  void dispose() {
    _specialInstructionsController.dispose();
    super.dispose();
  }

  Future<void> _loadProductOptions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final options = await ProductOptionService().getProductOptionsWithDetails(widget.cartItem.productId);
      

      final token = AuthService().token;
      if (token != null) {
        try {
          final response = await http.get(
            Uri.parse('${ApiConstants.baseUrl}/products/${widget.cartItem.productId}/branch-price/${widget.cartItem.cartId}'),
            headers: ApiConstants.authHeaders(token),
          );
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            _basePrice = double.tryParse(data['data']['base_price'].toString()) ?? widget.cartItem.price;
          } else {
            _basePrice = widget.cartItem.price; // Fallback
          }
        } catch (e) {
          _basePrice = widget.cartItem.price; // Fallback
        }
      } else {
        _basePrice = widget.cartItem.price;
      }
      
      setState(() {
        _options = options;

        if (widget.cartItem.selectedOptions != null && widget.cartItem.selectedOptions!.isNotEmpty) {
          _selectedOptions = widget.cartItem.selectedOptions!;
        } else {
          _selectedOptions = ProductOptionService().createDefaultSelections(options);
        }
        _totalPriceModifier = ProductOptionService().calculateTotalPriceModifier(_selectedOptions);
        _specialInstructions = _cleanSpecialInstructions(widget.cartItem.specialInstructions ?? '');
        _specialInstructionsController.text = _specialInstructions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _updateOptionSelection(ProductOptionType optionType, ProductOptionValue value, bool isSelected) {
    setState(() {
      final currentSelection = _selectedOptions.firstWhere(
        (s) => s.optionTypeId == optionType.id,
        orElse: () => SelectedOption(
          optionTypeId: optionType.id,
          optionName: optionType.name,
          selectedValueIds: [],
          selectedValues: [],
          totalPriceModifier: 0.0,
        ),
      );

      final updatedSelection = ProductOptionService().updateSelection(
        currentSelection,
        optionType,
        value,
        isSelected,
      );

      _selectedOptions.removeWhere((s) => s.optionTypeId == optionType.id);
      _selectedOptions.add(updatedSelection);
      _totalPriceModifier = ProductOptionService().calculateTotalPriceModifier(_selectedOptions);
    });
  }

  bool _isOptionValueSelected(ProductOptionType optionType, ProductOptionValue value) {
    final selection = _selectedOptions.firstWhere(
      (s) => s.optionTypeId == optionType.id,
      orElse: () => SelectedOption(
        optionTypeId: optionType.id,
        optionName: optionType.name,
        selectedValueIds: [],
        selectedValues: [],
        totalPriceModifier: 0.0,
      ),
    );
    return selection.selectedValueIds.contains(value.id);
  }

  Future<void> _saveOptions() async {
    try {
      final token = AuthService().token;
      if (token == null) return;


      if (!ProductOptionService().validateRequiredOptions(_options, _selectedOptions)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select all required options')),
        );
        return;
      }


      final updatedCart = await CartService.updateCartItemOptions(
        token: token,
        cartId: widget.cartItem.cartId,
        productId: widget.cartItem.productId,
        selectedOptions: _selectedOptions,
        specialInstructions: _specialInstructions,
      );


      final updatedCartItem = CartItem(
        id: widget.cartItem.id,
        cartId: widget.cartItem.cartId,
        productId: widget.cartItem.productId,
        productName: widget.cartItem.productName,
        productDescription: widget.cartItem.productDescription,
        productImage: widget.cartItem.productImage,
        quantity: widget.cartItem.quantity,
        price: _basePrice + _totalPriceModifier,
        specialInstructions: _specialInstructions,
        selectedOptions: _selectedOptions,
      );

      widget.onOptionUpdated(updatedCartItem);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Options updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating options: $e')),
        );
      }
    }
  }

  String _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    return '${ApiConstants.fileBaseUrl}$imagePath';
  }

  String _cleanSpecialInstructions(String instructions) {
    if (instructions.isEmpty) return '';
    
    // Check if it's JSON data (auto-generated from options)
    if (instructions.trim().startsWith('{') || instructions.trim().startsWith('[')) {
      // If it's JSON data, it means it was auto-generated from options
      // Return empty string so user can write their own instructions
      return '';
    }
    
    // If it's plain text, it means user wrote it themselves
    // Return as is
    return instructions;
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,###', 'vi_VN').format(amount.toInt());
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
        child: Column(
          children: [
              // Drag Handle
            Container(
                margin: EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Container(
                padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      children: [
                    // Close Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Product Image
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: widget.cartItem.productImage != null && widget.cartItem.productImage!.isNotEmpty
                            ? Image.network(
                                _getImageUrl(widget.cartItem.productImage),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[100],
                                    child: Icon(
                                      Icons.restaurant,
                                      color: Colors.grey[400],
                                      size: 50,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[100],
                                child: Icon(
                                  Icons.restaurant,
                                  color: Colors.grey[400],
                                  size: 50,
                                ),
                              ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Product Name
                    Text(
                      widget.cartItem.productName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: 8),

                    // Edit Options Text
                    Text(
                      'Edit Your Options',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                  ),
                ],
              ),
            ),

              // Scrollable Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, size: 48, color: Colors.red[300]),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading options',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          controller: controller,
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          children: [
                            // Show options if available
                            if (_options.isNotEmpty) ...[
                              // Section Title
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Customize Your Order',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[900],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),

                              // Options List
                              ..._options.map((option) => _buildModernOptionSection(option)),
                            ],
                            
                            // Show message if no options
                            if (_options.isEmpty) ...[
                              Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.restaurant_menu, size: 48, color: Colors.grey[400]),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No options available',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'This product has no customization options',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 32),
                                  ],
                                ),
                              ),
                            ],
                            
                            // Always show Special Instructions section
                            Container(
                              margin: EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.edit_note,
                                        size: 20,
                                        color: Colors.grey[600],
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Special Instructions',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[900],
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        '(Optional)',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[500],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: TextField(
                                      onChanged: (value) {
                                        setState(() {
                                          _specialInstructions = value;
                                        });
                                      },
                                      controller: _specialInstructionsController,
                                      decoration: InputDecoration(
                                        hintText: 'e.g., No onions, extra spicy, well done...',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 14,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.all(16),
                                      ),
                                      maxLines: 3,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            SizedBox(height: 120), // Space for bottom bar
                          ],
                        )
              ),

              // Bottom Action Bar
              Container(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Price Summary
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Base Price:',
                          style: TextStyle(
                                    fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          '${_formatCurrency(_basePrice)} đ',
                                  style: TextStyle(
                                    fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (_totalPriceModifier != 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Options:',
                            style: TextStyle(
                                      fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            '${_totalPriceModifier > 0 ? '+' : ''}${_formatCurrency(_totalPriceModifier)} đ',
                            style: TextStyle(
                                      fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _totalPriceModifier > 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                            const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                                  style: TextStyle(
                                    fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_formatCurrency(_basePrice + _totalPriceModifier)} đ',
                                  style: TextStyle(
                                    fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Save Button
                    SizedBox(
                      width: double.infinity,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.orange[400]!, Colors.orange[600]!],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.4),
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _saveOptions,
                              borderRadius: BorderRadius.circular(16),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.save,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                          'Save Options',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    ),
                ),
              ),
          ],
        ),
        );
      },
    );
  }

  Widget _buildModernOptionSection(ProductOptionType option) {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Option Title
          Row(
            children: [
              Text(
                option.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              if (option.required) ...[
                SizedBox(width: 6),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    'Required',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          if (option.type == 'select') ...[
            SizedBox(height: 8),
          Text(
              'Choose one option',
            style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ] else if (option.type == 'checkbox') ...[
            SizedBox(height: 8),
            Text(
              'Choose one or more',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ],
          
          SizedBox(height: 12),

          // Option Values
          if (option.type == 'select')
            Column(
              children: option.values
                  .map((value) => Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: _buildModernSelectOption(option, value),
                      ))
                  .toList(),
            )
          else if (option.type == 'checkbox')
            Column(
              children: option.values
                  .map((value) => Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: _buildModernCheckboxOption(option, value),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildModernSelectOption(ProductOptionType option, ProductOptionValue value) {
    final isSelected = _isOptionValueSelected(option, value);

    return GestureDetector(
      onTap: () => _updateOptionSelection(option, value, true),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Colors.orange[400]!, Colors.orange[600]!],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orange[600]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Radio Button
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.grey[400]!,
                  width: 2,
                ),
                color: Colors.transparent,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),

            SizedBox(width: 12),

            // Value Text
            Expanded(
              child: Text(
                value.value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ),

            // Price Modifier
            if (value.priceModifier != 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : (value.priceModifier > 0 ? Colors.green[50] : Colors.red[50]),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  value.formattedPriceModifier,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (value.priceModifier > 0 ? Colors.green[700] : Colors.red[700]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCheckboxOption(ProductOptionType option, ProductOptionValue value) {
    final isSelected = _isOptionValueSelected(option, value);

    return GestureDetector(
      onTap: () => _updateOptionSelection(option, value, !isSelected),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Colors.orange[400]!, Colors.orange[600]!],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orange[600]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20,
              color: isSelected ? Colors.white : Colors.grey[400],
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                value.value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ),
            if (value.priceModifier != 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : (value.priceModifier > 0 ? Colors.green[50] : Colors.red[50]),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  value.formattedPriceModifier,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (value.priceModifier > 0 ? Colors.green[700] : Colors.red[700]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectOption(ProductOptionType option, ProductOptionValue value) {
    final isSelected = _isOptionValueSelected(option, value);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _updateOptionSelection(option, value, true),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.orange.withOpacity(0.1) : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.orange : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Radio<bool>(
                  value: true,
                  groupValue: isSelected,
                  onChanged: (bool? newValue) {
                    if (newValue == true) {
                      _updateOptionSelection(option, value, true);
                    }
                  },
                  activeColor: Colors.orange,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value.value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? Colors.orange[800] : Colors.black87,
                        ),
                      ),
                      if (value.priceModifier != 0)
                        Text(
                          value.formattedPriceModifier,
                          style: TextStyle(
                            fontSize: 14,
                            color: value.priceModifier > 0 ? Colors.green[600] : Colors.red[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxOption(ProductOptionType option, ProductOptionValue value) {
    final isSelected = _isOptionValueSelected(option, value);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _updateOptionSelection(option, value, !isSelected),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.orange.withOpacity(0.1) : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.orange : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (bool? newValue) {
                    _updateOptionSelection(option, value, newValue ?? false);
                  },
                  activeColor: Colors.orange,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value.value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? Colors.orange[800] : Colors.black87,
                        ),
                      ),
                      if (value.priceModifier != 0)
                        Text(
                          value.formattedPriceModifier,
                          style: TextStyle(
                            fontSize: 14,
                            color: value.priceModifier > 0 ? Colors.green[600] : Colors.red[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

