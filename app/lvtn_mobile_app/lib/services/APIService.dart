import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants/api_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  Map<String, String> get _headers {
    final headers = Map<String, String>.from(ApiConstants.defaultHeaders);
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    print('APIService: Response status: ${response.statusCode}');
    print('APIService: Response body: ${response.body}');
    
    final data = json.decode(response.body);
    print('APIService: Parsed data type: ${data.runtimeType}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (data is List) {
        print('APIService: Returning List');
        return data;
      }
      if (data is Map && data['status'] == 'success') {
        print('APIService: Status success, returning data: ${data['data']}');
        return data['data'];
      }
      if (data is Map) {
        print('APIService: Returning Map directly');
        return data;
      }
      print('APIService: Returning data as-is');
      return data;
    } else {
      final errorMsg = data['message'] ?? 'HTTP Error: ${response.statusCode}';
      print('APIService: Error: $errorMsg');
      throw Exception(errorMsg);
    }
  }

  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: _headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: _headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<dynamic> putMultipart(String endpoint, Map<String, dynamic> data, {File? file, String? fileFieldName}) async {
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
    );

    _headers.forEach((key, value) {
      if (key.toLowerCase() != 'content-type') {
        request.headers[key] = value;
      }
    });

    if (file != null && fileFieldName != null) {
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();
      final fileName = file.path.split('/').last;
      final fileExtension = fileName.split('.').last.toLowerCase();
      
      MediaType contentType;
      switch (fileExtension) {
        case 'jpg':
        case 'jpeg':
          contentType = MediaType('image', 'jpeg');
          break;
        case 'png':
          contentType = MediaType('image', 'png');
          break;
        case 'gif':
          contentType = MediaType('image', 'gif');
          break;
        case 'webp':
          contentType = MediaType('image', 'webp');
          break;
        default:
          contentType = MediaType('image', 'jpeg');
      }
      
      final multipartFile = http.MultipartFile(
        fileFieldName,
        fileStream,
        fileLength,
        filename: fileName,
        contentType: contentType,
      );
      request.files.add(multipartFile);
    }

    data.forEach((key, value) {
      if (value == null) {
        request.fields[key] = '';
      } else if (value is String && value.isEmpty) {
        request.fields[key] = '';
      } else {
        request.fields[key] = value.toString();
      }
    });

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }
}
