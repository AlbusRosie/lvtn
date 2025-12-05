import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/MapboxService.dart';

/// Widget TextField với Mapbox Autocomplete
class MapboxAutocompleteField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Function(String address, double lat, double lng)? onPlaceSelected;
  final ValueChanged<String>? onChanged;
  final String? proximity;

  const MapboxAutocompleteField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.onPlaceSelected,
    this.onChanged,
    this.proximity,
  });

  @override
  State<MapboxAutocompleteField> createState() => _MapboxAutocompleteFieldState();
}

class _MapboxAutocompleteFieldState extends State<MapboxAutocompleteField> {
  final FocusNode _focusNode = FocusNode();
  List<MapboxPlace> _suggestions = [];
  bool _showSuggestions = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isLoading = false;
  late TextEditingController _controller;
  bool _isInternalController = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    
    if (widget.controller == null) {
      _controller = TextEditingController();
      _isInternalController = true;
    } else {
      _controller = widget.controller!;
    }
    
    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        Future.delayed(Duration(milliseconds: 200), () {
          if (mounted) {
            _hideSuggestions();
          }
        });
      }
    });

    MapboxService().initialize();
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (_isInternalController) {
      _controller.dispose();
    }
    _focusNode.dispose();
    _hideSuggestions();
    super.dispose();
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      _hideSuggestions();
      return;
    }
    
    final trimmedQuery = query.trim();

    print('MapboxAutocompleteField: Tìm kiếm: $query');
    
    setState(() {
      _isLoading = true;
    });

    try {
      final mapboxService = MapboxService();
      await mapboxService.initialize();
      
      print('MapboxAutocompleteField: Gọi searchPlaces với query: $trimmedQuery');
      final results = await mapboxService.searchPlaces(
        trimmedQuery,
        proximity: widget.proximity,
      );

      print('MapboxAutocompleteField: Nhận được ${results.length} kết quả');

      if (mounted) {
        setState(() {
          _suggestions = results;
          _showSuggestions = results.isNotEmpty;
          _isLoading = false;
        });

        if (_showSuggestions) {
          print('MapboxAutocompleteField: Hiển thị ${results.length} suggestions');
          _showSuggestionsOverlay();
        } else {
          print('MapboxAutocompleteField: Không có suggestions, ẩn overlay');
          _hideSuggestions();
        }
      }
    } catch (e, stackTrace) {
      print('MapboxAutocompleteField: Lỗi khi tìm kiếm: $e');
      print('MapboxAutocompleteField: Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
          _isLoading = false;
        });
        _hideSuggestions();
      }
    }
  }

  Future<void> _selectPlace(MapboxPlace place) async {
    _controller.text = place.fullAddress;
    widget.onPlaceSelected?.call(place.fullAddress, place.latitude, place.longitude);
    _hideSuggestions();
    _focusNode.unfocus();
  }

  void _showSuggestionsOverlay() {
    _hideSuggestions();
    
    if (!_showSuggestions || _suggestions.isEmpty) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 48,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, 60),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              constraints: BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: _isLoading
                  ? Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.symmetric(vertical: 8),
                      itemCount: _suggestions.length,
                      separatorBuilder: (context, index) => Divider(height: 1),
                      itemBuilder: (context, index) {
                        final place = _suggestions[index];
                        return InkWell(
                          onTap: () => _selectPlace(place),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  color: Color(0xFFFFA500),
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        place.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      if (place.fullAddress != place.name)
                                        Text(
                                          place.fullAddress,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideSuggestions() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: true,
        readOnly: false,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          labelText: widget.labelText ?? 'Địa chỉ giao hàng',
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          hintText: widget.hintText ?? 'Nhập địa chỉ...',
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _controller.text.isNotEmpty
                  ? Color(0xFFFFA500).withOpacity(0.1)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.search_rounded,
              color: _controller.text.isNotEmpty
                  ? Color(0xFFFFA500)
                  : Colors.grey[600],
              size: 20,
            ),
          ),
          suffixIcon: _isLoading
              ? Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFA500)),
                    ),
                  ),
                )
              : null,
          filled: true,
          fillColor: _controller.text.isNotEmpty
              ? Colors.white
              : Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: _controller.text.isNotEmpty
                  ? Color(0xFFFFA500).withOpacity(0.3)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Color(0xFFFFA500),
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
        style: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        onChanged: (value) {
          widget.onChanged?.call(value);
          
          _debounceTimer?.cancel();
          
          if (value.length < 2) {
            setState(() {
              _suggestions = [];
              _showSuggestions = false;
            });
            _hideSuggestions();
            return;
          }
          
          final trimmedQuery = value.trim();
          
          _debounceTimer = Timer(Duration(milliseconds: 300), () {
            if (mounted && _controller.text == value) {
              _searchPlaces(trimmedQuery);
            }
          });
        },
      ),
    );
  }
}

