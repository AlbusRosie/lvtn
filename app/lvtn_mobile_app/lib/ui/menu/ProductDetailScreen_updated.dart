  Future<void> _openOptionsSheet(Product product) async {
    if (!_loadedOptions) {
      await _loadProductOptions(product.id);
    }

    if (_productOptions.isEmpty) {
      await _addToCart(product, 1);
      return;
    }

    int sheetQuantity = 1;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.orange.shade50,
                Colors.white,
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                void updateInSheet(ProductOptionType optionType, ProductOptionValue value, bool isSelected) {
                  setState(() => _updateOptionSelection(optionType, value, isSelected));
                  setSheetState(() {});
                }

                Widget optionItem(ProductOptionType option) {
                  final currentSelection = _selectedOptions.firstWhere(
                    (s) => s.optionTypeId == option.id,
                    orElse: () => SelectedOption(
                      optionTypeId: option.id,
                      optionName: option.name,
                      selectedValueIds: [],
                      selectedValues: [],
                      totalPriceModifier: 0.0,
                    ),
                  );

                  return Container(
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.shade100, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.08),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                              Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.orange.shade400, Colors.orange.shade600],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  option.type == 'select' 
                                      ? Symbols.radio_button_checked 
                                      : Symbols.checklist,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                              if (option.required)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Text(
                                    'Required',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.red.shade600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 12),
                          if (option.type == 'select') ...[
                            ...option.values.map((value) => Container(
                              margin: EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () => updateInSheet(option, value, true),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: currentSelection.selectedValueIds.contains(value.id)
                                        ? Colors.orange.shade50
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: currentSelection.selectedValueIds.contains(value.id)
                                          ? Colors.orange.shade300
                                          : Colors.grey.shade200,
                                      width: currentSelection.selectedValueIds.contains(value.id) ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        currentSelection.selectedValueIds.contains(value.id)
                                            ? Symbols.radio_button_checked
                                            : Symbols.radio_button_unchecked,
                                        color: currentSelection.selectedValueIds.contains(value.id)
                                            ? Colors.orange.shade600
                                            : Colors.grey.shade400,
                                        size: 20,
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          value.value,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: currentSelection.selectedValueIds.contains(value.id)
                                                ? Colors.orange.shade800
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                      if (value.priceModifier != 0)
                                        Text(
                                          '${value.priceModifier > 0 ? '+' : ''}${_formatPrice(value.priceModifier)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: value.priceModifier > 0
                                                ? Colors.green.shade600
                                                : Colors.red.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            )),
                          ] else ...[
                            ...option.values.map((value) => Container(
                              margin: EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () => updateInSheet(option, value, !currentSelection.selectedValueIds.contains(value.id)),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: currentSelection.selectedValueIds.contains(value.id)
                                        ? Colors.orange.shade50
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: currentSelection.selectedValueIds.contains(value.id)
                                          ? Colors.orange.shade300
                                          : Colors.grey.shade200,
                                      width: currentSelection.selectedValueIds.contains(value.id) ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        currentSelection.selectedValueIds.contains(value.id)
                                            ? Symbols.check_box
                                            : Symbols.check_box_outline_blank,
                                        color: currentSelection.selectedValueIds.contains(value.id)
                                            ? Colors.orange.shade600
                                            : Colors.grey.shade400,
                                        size: 20,
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          value.value,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: currentSelection.selectedValueIds.contains(value.id)
                                                ? Colors.orange.shade800
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                      if (value.priceModifier != 0)
                                        Text(
                                          '${value.priceModifier > 0 ? '+' : ''}${_formatPrice(value.priceModifier)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: value.priceModifier > 0
                                                ? Colors.green.shade600
                                                : Colors.red.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            )),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.orange.shade100, Colors.orange.shade50],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade600,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Symbols.restaurant,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          _formatPrice(_calculateTotalPrice(product)),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 20),
                            ..._productOptions.map((option) => optionItem(option)),
                            SizedBox(height: 20),
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Symbols.shopping_cart,
                                    color: Colors.orange.shade600,
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Quantity:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Spacer(),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: sheetQuantity > 1 ? () => setSheetState(() => sheetQuantity--) : null,
                                        icon: Icon(Icons.remove_circle_outline),
                                        color: Colors.orange.shade600,
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: Colors.orange.shade200),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '$sheetQuantity',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange.shade700,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => setSheetState(() => sheetQuantity++),
                                        icon: Icon(Icons.add_circle_outline),
                                        color: Colors.orange.shade600,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: Colors.grey.shade200)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _formatPrice(_calculateTotalPrice(product) * sheetQuantity),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                Navigator.pop(context);
                                await _addToCart(product, sheetQuantity);
                              },
                              icon: Icon(Symbols.add_shopping_cart, color: Colors.white, size: 20, fill: 1),
                              label: Text(
                                'Add to cart',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: EdgeInsets.symmetric(horizontal: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 2,
                                shadowColor: Colors.orange.withOpacity(0.4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          ),
        );
      },
    );
  }

  Future<void> _addToCart(Product product, int quantity) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please login to add items to cart')),
        );
        return;
      }

      // Get current branch from context or use a default
      final branchId = 5; // TODO: Get from current context
      
      final cart = await CartService.addToCart(
        token: token,
        branchId: branchId,
        productId: product.id,
        quantity: quantity,
        orderType: 'dine_in',
      );

      // Update cart provider
      context.read<CartProvider>().setCart(cart);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${product.name} to cart'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding to cart: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
