import 'package:dio/dio.dart';
import '../config/env.dart';
import '../models/chat_message.dart';

class ChatService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: Environment.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  Future<Map<String, dynamic>> sendMessage({
    required String token,
    required String message,
    int? branchId,
    int? userId,
    String? conversationId,
  }) async {
    try {
      final requestData = <String, dynamic>{
        'message': message.trim(),
        if (branchId != null) 'branch_id': branchId,
        if (userId != null) 'user_id': userId,
        if (conversationId != null) 'conversation_id': conversationId,
      };


      final response = await _dio.post(
        '/chat/message',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: requestData,
      );


      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['status'] == 'success') {
          return data['data'] ?? {};
        } else {
          throw Exception(data['message'] ?? 'Failed to send message');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          throw Exception(errorData['message'] ?? 'Failed to send message');
        } else {
          throw Exception('Server error: ${e.response?.statusCode}');
        }
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<List<ChatMessage>> getChatHistory({
    required String token,
    String? conversationId,
  }) async {
    try {
      final response = await _dio.get(
        '/chat/history',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        queryParameters: {
          if (conversationId != null) 'conversation_id': conversationId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'success') {
          final List<dynamic> messages = data['data'] ?? [];
          return messages
              .map((json) => ChatMessage.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<ChatSuggestion>> getSuggestions({
    required String token,
    int? branchId,
  }) async {
    try {
      final response = await _dio.get(
        '/chat/suggestions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        queryParameters: {
          if (branchId != null) 'branch_id': branchId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'success') {
          final List<dynamic> suggestions = data['data'] ?? [];
          return suggestions
              .map((json) => ChatSuggestion.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> executeAction({
    required String token,
    required String action,
    required Map<String, dynamic> data,
  }) async {
    try {

      final response = await _dio.post(
        '/chat/action',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'action': action,
          'data': data,
        },
      );


      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic> && responseData['status'] == 'success') {
          return responseData['data'] ?? {};
        } else {
          throw Exception(responseData['message'] ?? 'Failed to execute action');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          throw Exception(errorData['message'] ?? 'Failed to execute action');
        } else {
          throw Exception('Server error: ${e.response?.statusCode}');
        }
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}

