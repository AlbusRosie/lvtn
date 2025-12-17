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
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('Kết nối quá lâu. Vui lòng kiểm tra kết nối mạng và thử lại.');
      }
      
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.');
      }
      
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          final errorMessage = errorData['message'] ?? 
                              errorData['error'] ?? 
                              'Failed to send message';
          throw Exception(errorMessage);
        } else {
          throw Exception('Server error: ${e.response?.statusCode}');
        }
      } else {
        throw Exception('Network error: ${e.message ?? 'Unknown network error'}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Unexpected error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllConversations({
    required String token,
  }) async {
    try {
      final response = await _dio.get(
        '/chat/conversations',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'success') {
          final List<dynamic> conversations = data['data'] ?? [];
          return conversations.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      return [];
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

  Future<Map<String, dynamic>> getWelcomeMessage({
    required String token,
    int? branchId,
    String? conversationId,
  }) async {
    try {
      final response = await _dio.get(
        '/chat/welcome',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        queryParameters: {
          if (branchId != null) 'branch_id': branchId,
          if (conversationId != null) 'conversation_id': conversationId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['status'] == 'success') {
          return data['data'] ?? {};
        } else {
          throw Exception(data['message'] ?? 'Failed to get welcome message');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          throw Exception(errorData['message'] ?? 'Failed to get welcome message');
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
        if (responseData is Map<String, dynamic>) {
          if (responseData['status'] == 'success') {
            final data = responseData['data'] ?? {};
            // Check if data itself indicates failure
            if (data['success'] == false) {
              throw Exception(data['message'] ?? 'Failed to execute action');
            }
            return data;
          } else if (responseData['status'] == 'fail' || responseData['status'] == 'error') {
            throw Exception(responseData['message'] ?? 'Failed to execute action');
          } else {
            // Handle direct response without status wrapper
            if (responseData['success'] == false) {
              throw Exception(responseData['message'] ?? 'Failed to execute action');
            }
            return responseData;
          }
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('Kết nối quá lâu. Vui lòng thử lại.');
      }
      
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.');
      }
      
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          final errorMessage = errorData['message'] ?? 
                              errorData['error'] ?? 
                              'Failed to execute action';
          throw Exception(errorMessage);
        } else {
          throw Exception('Server error: ${e.response?.statusCode}');
        }
      } else {
        throw Exception('Network error: ${e.message ?? 'Unknown network error'}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Unexpected error: $e');
    }
  }

  Future<void> resetConversation({
    required String token,
    required String conversationId,
    bool deleteMessages = true,
  }) async {
    try {
      final response = await _dio.post(
        '/chat/reset',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'conversation_id': conversationId,
          'delete_messages': deleteMessages,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['status'] == 'success') {
          return;
        } else {
          throw Exception(data['message'] ?? 'Failed to reset conversation');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('Kết nối quá lâu. Vui lòng kiểm tra kết nối mạng và thử lại.');
      }

      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.');
      }

      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          final errorMessage = errorData['message'] ??
              errorData['error'] ??
              'Failed to reset conversation';
          throw Exception(errorMessage);
        } else {
          throw Exception('Server error: ${e.response?.statusCode}');
        }
      } else {
        throw Exception('Network error: ${e.message ?? 'Unknown network error'}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Unexpected error: $e');
    }
  }
}

