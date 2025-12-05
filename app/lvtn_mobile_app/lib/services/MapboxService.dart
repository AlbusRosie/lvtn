import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:io';
import '../constants/api_constants.dart';

/// Service để quản lý Mapbox API
class MapboxService {
  static final MapboxService _instance = MapboxService._internal();
  factory MapboxService() => _instance;
  MapboxService._internal();

  String? _apiKey;
  bool _isLoading = false;
  
  late final http.Client _httpClient = _createHttpClient();
  
  static http.Client _createHttpClient() {
    final httpClient = HttpClient();
    httpClient.connectionTimeout = Duration(seconds: 30);
    httpClient.idleTimeout = Duration(seconds: 30);
    httpClient.autoUncompress = true;
    return IOClient(httpClient);
  }

  /// Lấy Mapbox API Key từ backend
  Future<String> get apiKey async {
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      return _apiKey!;
    }
    
    if (!_isLoading) {
      await _fetchApiKeyFromBackend();
    }
    
    return _apiKey ?? '';
  }

  /// Fetch API key từ backend
  Future<void> _fetchApiKeyFromBackend() async {
    if (_isLoading) return;
    
    _isLoading = true;
    try {
      final url = '${ApiConstants.baseUrl}/config/mapbox-key';
      print('MapboxService: Đang lấy API key từ: $url');
      
      final response = await _httpClient.get(
        Uri.parse(url),
      ).timeout(
        Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Request timeout khi lấy API key');
        },
      );

      print('MapboxService: Response status: ${response.statusCode}');
      print('MapboxService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('MapboxService: Parsed data: $data');
        
        if (data['status'] == 'success' && data['data'] != null) {
          _apiKey = data['data']['apiKey'] as String?;
          if (_apiKey != null && _apiKey!.isNotEmpty) {
            print('MapboxService: ✅ Đã lấy API key thành công (${_apiKey!.length} ký tự)');
          } else {
            print('MapboxService: ⚠️ API key rỗng');
          }
        } else {
          print('MapboxService: ⚠️ Response không đúng format: ${data['status']}');
        }
      } else {
        print('MapboxService: ❌ Không thể lấy API key từ backend: ${response.statusCode}');
        print('MapboxService: Response: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('MapboxService: ❌ Lỗi khi lấy API key từ backend: $e');
      print('MapboxService: Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
    }
  }

  /// Tìm kiếm địa chỉ với Mapbox Geocoding API (qua backend proxy)
  /// [query] - Từ khóa tìm kiếm
  /// [proximity] - Tọa độ ưu tiên (lng,lat) - optional
  Future<List<MapboxPlace>> searchPlaces(String query, {String? proximity}) async {
    try {
      print('MapboxService: Bắt đầu tìm kiếm: $query (qua backend proxy)');
      
      final queryParams = <String, String>{
        'query': query.trim(),
        'limit': '10',
      };
      
      if (proximity != null) {
        queryParams['proximity'] = proximity;
        print('MapboxService: Sử dụng proximity: $proximity');
      }
      
      final queryString = Uri(queryParameters: queryParams).query;
      final url = '${ApiConstants.baseUrl}/map/mapbox/search?$queryString';
      
      print('MapboxService: Gọi backend proxy: $url');
      
      final response = await _httpClient.get(
        Uri.parse(url),
      ).timeout(
        Duration(seconds: 15),
        onTimeout: () {
          print('MapboxService: ⚠️ Request timeout sau 15 giây');
          throw TimeoutException('Request timeout');
        },
      );
      
      print('MapboxService: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        Map<String, dynamic> responseData;
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          
          if (data['status'] == 'success' && data['data'] != null) {
            responseData = data['data'] as Map<String, dynamic>;
          } else {
            responseData = data;
          }
          
          print('MapboxService: Response data keys: ${responseData.keys}');
        } catch (e) {
          print('MapboxService: ❌ Lỗi khi parse JSON: $e');
          print('MapboxService: Response body (first 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
          return [];
        }
        
        if (responseData['features'] != null) {
          final features = responseData['features'] as List;
          print('MapboxService: Features array length: ${features.length}');
          
          if (features.isEmpty) {
            print('MapboxService: ⚠️ Features array rỗng - không tìm thấy kết quả');
            print('MapboxService: Query: "$query" (${query.length} ký tự)');
            
            if (query.trim().length < 3) {
              print('MapboxService: 💡 Gợi ý: Query quá ngắn, thử gõ thêm ký tự');
            }
            
            return [];
          }
          
          print('MapboxService: ✅ Tìm thấy ${features.length} kết quả');
          
          final places = features.map((feature) {
            try {
              return MapboxPlace.fromJson(feature);
            } catch (e) {
              print('MapboxService: Lỗi parse feature: $e');
              print('MapboxService: Feature data: $feature');
              return null;
            }
          }).whereType<MapboxPlace>().toList();
          
          print('MapboxService: ✅ Parse thành công ${places.length} places');
          return places;
        } else {
          print('MapboxService: ⚠️ Không có features trong response');
          print('MapboxService: Response structure: ${responseData.toString().substring(0, responseData.toString().length > 500 ? 500 : responseData.toString().length)}');
        }
      } else {
        print('MapboxService: ❌ HTTP Error ${response.statusCode}');
        print('MapboxService: Error response body: ${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}');
      }
      
      return [];
    } catch (e, stackTrace) {
      print('MapboxService: ❌ Lỗi khi tìm kiếm địa chỉ: $e');
      print('MapboxService: Lỗi type: ${e.runtimeType}');
      if (e is TimeoutException) {
        print('MapboxService: ⚠️ Request bị timeout - có thể do backend chậm hoặc không phản hồi');
      }
      print('MapboxService: Stack trace: $stackTrace');
      return [];
    }
  }

  /// Lấy chi tiết địa chỉ từ place ID (qua backend proxy)
  Future<MapboxPlace?> getPlaceDetails(String placeId) async {
    try {
      final url = '${ApiConstants.baseUrl}/map/mapbox/place?placeId=${Uri.encodeComponent(placeId)}';
      
      print('MapboxService: Gọi backend proxy để lấy place details: $url');
      
      final response = await _httpClient.get(
        Uri.parse(url),
      ).timeout(
        Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Request timeout khi lấy place details');
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        Map<String, dynamic> responseData;
        if (data['status'] == 'success' && data['data'] != null) {
          responseData = data['data'] as Map<String, dynamic>;
        } else {
          responseData = data;
        }
        
        if (responseData['features'] != null && (responseData['features'] as List).isNotEmpty) {
          return MapboxPlace.fromJson(responseData['features'][0]);
        }
      }
      
      return null;
    } catch (e) {
      print('MapboxService: Lỗi khi lấy chi tiết địa chỉ: $e');
      return null;
    }
  }

  /// Initialize - Fetch API key từ backend khi app khởi động
  Future<void> initialize() async {
    await _fetchApiKeyFromBackend();
  }
}

/// Model cho Mapbox Place
class MapboxPlace {
  final String id;
  final String name;
  final String fullAddress;
  final double latitude;
  final double longitude;
  final Map<String, dynamic>? context;

  MapboxPlace({
    required this.id,
    required this.name,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    this.context,
  });

  factory MapboxPlace.fromJson(Map<String, dynamic> json) {
    try {
      final geometry = json['geometry'] as Map<String, dynamic>?;
      if (geometry == null) {
        throw Exception('Geometry is null');
      }
      
      final coordinates = geometry['coordinates'] as List?;
      if (coordinates == null || coordinates.length < 2) {
        throw Exception('Invalid coordinates');
      }
      
      final lng = (coordinates[0] as num).toDouble();
      final lat = (coordinates[1] as num).toDouble();

      String fullAddress = json['place_name'] as String? ?? 
                          json['text'] as String? ?? 
                          '';
      
      String name = json['text'] as String? ?? fullAddress;

      Map<String, dynamic>? contextData;
      if (json['context'] != null) {
        if (json['context'] is List) {
          final contextList = json['context'] as List;
          contextData = {};
          for (var i = 0; i < contextList.length; i++) {
            if (contextList[i] is Map) {
              final ctxItem = contextList[i] as Map<String, dynamic>;
              final id = ctxItem['id']?.toString() ?? '';
              contextData![id] = ctxItem;
            }
          }
        } else if (json['context'] is Map) {
          contextData = json['context'] as Map<String, dynamic>;
        }
      }

      return MapboxPlace(
        id: json['id']?.toString() ?? '',
        name: name,
        fullAddress: fullAddress,
        latitude: lat,
        longitude: lng,
        context: contextData,
      );
    } catch (e) {
      print('MapboxPlace: Lỗi khi parse JSON: $e');
      print('MapboxPlace: JSON: $json');
      rethrow;
    }
  }

  /// Lấy thông tin chi tiết từ context
  String? get city {
    if (context == null) return null;
    for (var item in context!.values) {
      if (item is Map && item['id']?.toString().startsWith('place.') == true) {
        return item['text'] as String?;
      }
    }
    return null;
  }

  String? get district {
    if (context == null) return null;
    for (var item in context!.values) {
      if (item is Map && item['id']?.toString().startsWith('district.') == true) {
        return item['text'] as String?;
      }
    }
    return null;
  }

  String? get province {
    if (context == null) return null;
    for (var item in context!.values) {
      if (item is Map && item['id']?.toString().startsWith('region.') == true) {
        return item['text'] as String?;
      }
    }
    return null;
  }
}

