import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../services/ChatService.dart';
import '../services/AuthService.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final Uuid _uuid = const Uuid();

  List<ChatMessage> _messages = [];
  List<ChatSuggestion> _suggestions = [];
  bool _isLoading = false;
  bool _isTyping = false;
  String? _conversationId;
  int? _currentBranchId;

  List<ChatMessage> get messages => _messages;
  List<ChatSuggestion> get suggestions => _suggestions;
  bool get isLoading => _isLoading;
  bool get isTyping => _isTyping;
  String? get conversationId => _conversationId;

  void setCurrentBranch(int branchId) {
    _currentBranchId = branchId;
    notifyListeners();
  }

  void startNewConversation() {
    _conversationId = _uuid.v4();
    _messages.clear();
    _addWelcomeMessage();
    _loadSuggestions();
    notifyListeners();
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      id: _uuid.v4(),
      content: 'Xin chào! Tôi là trợ lý ảo của Beast Bite. Tôi có thể giúp bạn:\n\n'
          '• 🍽️ Xem menu và đặt món\n'
          '• 🪑 Đặt bàn tại nhà hàng\n'
          '• ℹ️ Tìm hiểu thông tin chi nhánh\n'
          '• 📦 Kiểm tra đơn hàng của bạn\n\n'
          'Bạn cần tôi giúp gì?',
      isUser: false,
      timestamp: DateTime.now(),
      type: ChatMessageType.text,
    );
    _messages.add(welcomeMessage);
  }

  Future<void> loadChatHistory() async {
    final token = _authService.token;
    if (token == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final history = await _chatService.getChatHistory(
        token: token,
        conversationId: _conversationId,
      );
      
      if (history.isNotEmpty) {
        _messages = history;
      } else if (_messages.isEmpty) {
        _addWelcomeMessage();
      }
    } catch (e) {
      if (_messages.isEmpty) {
        _addWelcomeMessage();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSuggestions() async {
    final token = _authService.token;
    if (token == null) return;

    try {
      _suggestions = await _chatService.getSuggestions(
        token: token,
        branchId: _currentBranchId,
      );
      notifyListeners();
    } catch (e) {
      _suggestions = _getDefaultSuggestions();
      notifyListeners();
    }
  }

  List<ChatSuggestion> _getDefaultSuggestions() {
    return [
      ChatSuggestion(
        text: '🍽️ Xem menu',
        action: 'view_menu',
        data: {'branch_id': _currentBranchId},
      ),
      ChatSuggestion(
        text: '🪑 Đặt bàn',
        action: 'book_table',
        data: {'branch_id': _currentBranchId},
      ),
      ChatSuggestion(
        text: '📍 Chi nhánh gần tôi',
        action: 'find_branch',
        data: {},
      ),
      ChatSuggestion(
        text: '📦 Đơn hàng của tôi',
        action: 'view_orders',
        data: {},
      ),
    ];
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final token = _authService.token;
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
      type: ChatMessageType.text,
    );
    _messages.add(userMessage);
    notifyListeners();

    _isTyping = true;
    notifyListeners();

    try {
      final response = await _chatService.sendMessage(
        token: token,
        message: content,
        branchId: _currentBranchId,
        userId: _authService.currentUser?.id,
        conversationId: _conversationId,
      );

      final botMessage = ChatMessage(
        id: response['id'] ?? _uuid.v4(),
        content: response['message'] ?? 'Xin lỗi, tôi không hiểu. Bạn có thể nói rõ hơn được không?',
        isUser: false,
        timestamp: DateTime.now(),
        type: _getMessageType(response['type']),
        metadata: response['metadata'],
      );
      _messages.add(botMessage);

      if (response['suggestions'] != null && response['suggestions'] is List) {
        try {
          _suggestions = (response['suggestions'] as List)
              .map((json) => ChatSuggestion.fromJson(json))
              .toList();
        } catch (e) {
          _suggestions = _getDefaultSuggestions();
        }
      }

      if (response['action'] != null && response['action_data'] != null) {
        try {
          await _handleAction(response['action'], response['action_data']);
        } catch (e) {
          final actionErrorMessage = ChatMessage(
            id: _uuid.v4(),
            content: 'Có lỗi khi thực hiện hành động: ${e.toString()}',
            isUser: false,
            timestamp: DateTime.now(),
            type: ChatMessageType.error,
          );
          _messages.add(actionErrorMessage);
        }
      }
    } catch (e) {
      final errorMessage = ChatMessage(
        id: _uuid.v4(),
        content: 'Xin lỗi, đã có lỗi xảy ra: ${e.toString()}',
        isUser: false,
        timestamp: DateTime.now(),
        type: ChatMessageType.error,
      );
      _messages.add(errorMessage);
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  Future<void> _handleAction(String action, Map<String, dynamic>? data) async {
    final token = _authService.token;
    if (token == null || data == null) return;

    try {
      final result = await _chatService.executeAction(
        token: token,
        action: action,
        data: data,
      );
      
      
      switch (action) {
        case 'navigate_menu':
          break;
        case 'navigate_orders':
          break;
        case 'show_reservation_details':
          break;
        case 'add_to_cart':
          break;
        default:
      }
    } catch (e) {
    }
  }

  void handleSuggestionTap(ChatSuggestion suggestion) {
    sendMessage(suggestion.text);
  }

  ChatMessageType _getMessageType(String? type) {
    if (type == null) return ChatMessageType.text;
    
    switch (type.toLowerCase()) {
      case 'action':
        return ChatMessageType.action;
      case 'suggestion':
        return ChatMessageType.suggestion;
      case 'menu':
        return ChatMessageType.menu;
      case 'order':
        return ChatMessageType.order;
      case 'reservation':
        return ChatMessageType.reservation;
      case 'error':
        return ChatMessageType.error;
      default:
        return ChatMessageType.text;
    }
  }

  void clearMessages() {
    _messages.clear();
    _conversationId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _messages.clear();
    super.dispose();
  }
}

