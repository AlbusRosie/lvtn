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
  List<Map<String, dynamic>> _allConversations = [];
  bool _isLoading = false;
  bool _isTyping = false;
  String? _conversationId;
  int? _currentBranchId;
  int? _lastUserId;
  
  Function(String routeName, {Map<String, dynamic>? arguments})? onNavigate;

  List<ChatMessage> get messages => _messages;
  List<ChatSuggestion> get suggestions => _suggestions;
  List<Map<String, dynamic>> get allConversations => _allConversations;
  bool get isLoading => _isLoading;
  bool get isTyping => _isTyping;
  String? get conversationId => _conversationId;

  void setCurrentBranch(int branchId) {
    _currentBranchId = branchId;
    notifyListeners();
  }

  Future<void> startNewConversation() async {
    _conversationId = _uuid.v4();
    _messages.clear();
    await _addWelcomeMessage();
    notifyListeners();
  }

  void continueExistingConversation() {
    _loadSuggestions();
    notifyListeners();
  }

  Future<void> _addWelcomeMessage() async {
    final token = _authService.token;
    if (token == null) {
      final welcomeMessage = ChatMessage(
        id: _uuid.v4(),
        content: 'Xin chào! Tôi là trợ lý ảo của Beast Bite. Tôi có thể giúp bạn:\n\n'
            '- Xem menu: Xem menu theo từng chi nhánh\n'
            '- Đặt bàn: Đặt bàn tại nhà hàng\n'
            '- Đặt đơn giao hàng: Đặt đơn giao hàng từ nhà hàng\n'
            '- Đặt đơn mang về: Đặt đơn mang về từ nhà hàng\n'
            '- Tìm món: Tìm kiếm món ăn theo từng chi nhánh\n'
            '- Thông tin chi nhánh: Xem giờ làm việc, địa chỉ, số điện thoại theo từng chi nhánh\n'
            '- Kiểm tra đơn hàng: Xem đơn hàng của bạn\n\n'
            'Bạn cần tôi giúp gì?',
        isUser: false,
        timestamp: DateTime.now(),
        type: ChatMessageType.text,
      );
      _messages.add(welcomeMessage);
      _suggestions = _getDefaultSuggestions();
      notifyListeners();
      return;
    }

    try {
      final response = await _chatService.getWelcomeMessage(
        token: token,
        branchId: _currentBranchId,
        conversationId: _conversationId,
      );

      if (response['conversation_id'] != null) {
        _conversationId = response['conversation_id'] as String;
      }

      List<ChatSuggestion>? messageSuggestions;
      if (response['suggestions'] != null && response['suggestions'] is List) {
        try {
          messageSuggestions = (response['suggestions'] as List)
              .map((json) => ChatSuggestion.fromJson(json))
              .toList();
          _suggestions = messageSuggestions;
        } catch (e) {
          messageSuggestions = _getDefaultSuggestions();
          _suggestions = messageSuggestions;
        }
      } else {
        messageSuggestions = _getDefaultSuggestions();
        _suggestions = messageSuggestions;
      }

      final welcomeMessage = ChatMessage(
        id: response['id'] ?? _uuid.v4(),
        content: response['message'] ?? 'Xin chào! Tôi là trợ lý ảo của Beast Bite.',
        isUser: false,
        timestamp: DateTime.now(),
        type: _getMessageType(response['type']),
        metadata: response['entities'],
        suggestions: messageSuggestions,
      );
      _messages.add(welcomeMessage);

      notifyListeners();
    } catch (e) {
      final welcomeMessage = ChatMessage(
        id: _uuid.v4(),
        content: 'Xin chào! Tôi là trợ lý ảo của Beast Bite. Tôi có thể giúp bạn:\n\n'
            '- Xem menu: Xem menu theo từng chi nhánh\n'
            '- Đặt bàn: Đặt bàn tại nhà hàng\n'
            '- Đặt đơn giao hàng: Đặt đơn giao hàng từ nhà hàng\n'
            '- Đặt đơn mang về: Đặt đơn mang về từ nhà hàng\n'
            '- Tìm món: Tìm kiếm món ăn theo từng chi nhánh\n'
            '- Thông tin chi nhánh: Xem giờ làm việc, địa chỉ, số điện thoại theo từng chi nhánh\n'
            '- Kiểm tra đơn hàng: Xem đơn hàng của bạn\n\n'
            'Bạn cần tôi giúp gì?',
        isUser: false,
        timestamp: DateTime.now(),
        type: ChatMessageType.text,
      );
      _messages.add(welcomeMessage);
      _suggestions = _getDefaultSuggestions();
      notifyListeners();
    }
  }

  Future<void> loadAllConversations() async {
    final token = _authService.token;
    if (token == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _allConversations = await _chatService.getAllConversations(token: token);
    } catch (e) {
      _allConversations = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadChatHistory() async {
    final token = _authService.token;
    final currentUser = _authService.currentUser;
    final currentUserId = currentUser?.id;

    if (currentUserId != null && _lastUserId != null && currentUserId != _lastUserId) {
      _conversationId = null;
      _messages.clear();
      _allConversations.clear();
    }
    _lastUserId = currentUserId;

    if (token == null) {
      _conversationId = null;
      _lastUserId = null;
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      if (_conversationId != null) {
        final history = await _chatService.getChatHistory(
          token: token,
          conversationId: _conversationId,
        );
        
        if (history.isNotEmpty) {
          _messages = history;
          
          _loadSuggestionsFromHistory();
        } else {
          _conversationId = null;
          _messages.clear();
          await _addWelcomeMessage();
        }
      } else {
        _messages.clear();
        await _addWelcomeMessage();
      }
    } catch (e) {
      _conversationId = null;
      _messages.clear();
      await _addWelcomeMessage();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetConversation({bool deleteMessages = true}) async {
    final token = _authService.token;
    if (token == null || _conversationId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _chatService.resetConversation(
        token: token,
        conversationId: _conversationId!,
        deleteMessages: deleteMessages,
      );
      _messages.clear();
      _conversationId = null;
      _suggestions.clear();
      await _addWelcomeMessage();
    } catch (e) {
      // giữ nguyên trạng thái nếu reset thất bại
      rethrow;
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

  /// Load suggestions từ last bot message trong history
  void _loadSuggestionsFromHistory() {
    if (_messages.isEmpty) {
      _suggestions = _getDefaultSuggestions();
      return;
    }
    
    final lastBotMessage = _messages.reversed.firstWhere(
      (msg) => !msg.isUser && msg.suggestions != null && msg.suggestions!.isNotEmpty,
      orElse: () => _messages.last,
    );
    
    if (lastBotMessage.suggestions != null && lastBotMessage.suggestions!.isNotEmpty) {
      _suggestions = lastBotMessage.suggestions!;
    } else {
      _suggestions = _getDefaultSuggestions();
    }
    notifyListeners();
  }
  
  List<ChatSuggestion> _getDefaultSuggestions() {
    return [
      ChatSuggestion(
        text: 'Xem menu',
        action: 'view_menu',
        data: {'branch_id': _currentBranchId},
      ),
      ChatSuggestion(
        text: 'Đặt bàn',
        action: 'book_table',
        data: {'branch_id': _currentBranchId},
      ),
      ChatSuggestion(
        text: 'Xem chi nhánh',
        action: 'view_branches',
        data: {},
      ),
      ChatSuggestion(
        text: 'Đơn hàng của tôi',
        action: 'view_orders',
        data: {},
      ),
    ];
  }

  Future<void> sendMessage(String content, {bool isRetry = false, String? messageId}) async {
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

      if (response['conversation_id'] != null) {
        _conversationId = response['conversation_id'] as String;
      }

      List<ChatSuggestion>? messageSuggestions;
      if (response['suggestions'] != null && response['suggestions'] is List) {
        try {
          messageSuggestions = (response['suggestions'] as List)
              .map((json) => ChatSuggestion.fromJson(json))
              .toList();
          _suggestions = messageSuggestions;
        } catch (e) {
          messageSuggestions = _getDefaultSuggestions();
          _suggestions = messageSuggestions;
        }
      } else {
        _suggestions = [];
      }

      final botMessage = ChatMessage(
        id: response['id'] ?? _uuid.v4(),
        content: response['message'] ?? 'Xin lỗi, tôi không hiểu. Bạn có thể nói rõ hơn được không?',
        isUser: false,
        timestamp: DateTime.now(),
        type: _getMessageType(response['type']),
        metadata: response['entities'] ?? response['metadata'],
        suggestions: messageSuggestions,
      );
      _messages.add(botMessage);

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
      String errorMessage;
      final errorString = e.toString();
      if (errorString.contains('Network error') || 
          errorString.contains('connection') ||
          errorString.contains('timeout')) {
        errorMessage = 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng và thử lại.';
      } else if (errorString.contains('401') || 
                 errorString.contains('authentication') ||
                 errorString.contains('not authenticated')) {
        errorMessage = 'Bạn cần đăng nhập để sử dụng tính năng này.';
      } else if (errorString.contains('429') || 
                 errorString.contains('rate limit') ||
                 errorString.contains('Too many')) {
        errorMessage = 'Bạn đã gửi quá nhiều tin nhắn. Vui lòng đợi một chút rồi thử lại.';
      } else {
        // Thử show message thật từ Exception nếu ngắn, để dễ debug
        if (errorString.contains('Exception:')) {
          final extracted = errorString.split('Exception:').last.trim();
          if (extracted.isNotEmpty && extracted.length < 200) {
            errorMessage = extracted;
          } else {
            errorMessage = 'Xin lỗi, đã có lỗi xảy ra. Vui lòng thử lại sau.';
          }
        } else {
          errorMessage = 'Xin lỗi, đã có lỗi xảy ra. Vui lòng thử lại sau.';
        }
      }
      
      final errorChatMessage = ChatMessage(
        id: _uuid.v4(),
        content: errorMessage,
        isUser: false,
        timestamp: DateTime.now(),
        type: ChatMessageType.error,
        errorMessage: e.toString(),
      );
      _messages.add(errorChatMessage);
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

  void handleSuggestionTap(ChatSuggestion suggestion) async {
      final actionsRequiringExecute = [
      'confirm_booking',
      'modify_booking', 
      'select_branch',
      'select_time',
      'add_to_cart',
      'order_food',
      'navigate_menu',
      'navigate_orders',
      'show_reservation_details',
      'search_food',
      'call_confirmation',
      'confirm_reservation_only',
      'check_order_status',
      'use_existing_cart',
      'order_takeaway',
      'confirm_delivery_address',
      'change_delivery_address',
      'use_saved_address',
      'enter_delivery_address',
    ];

    if (suggestion.action != null && 
        suggestion.action!.isNotEmpty && 
        actionsRequiringExecute.contains(suggestion.action)) {
      final token = _authService.token;
      if (token == null) {
        final errorMessage = ChatMessage(
          id: _uuid.v4(),
          content: 'Bạn cần đăng nhập để sử dụng tính năng này.',
          isUser: false,
          timestamp: DateTime.now(),
          type: ChatMessageType.error,
        );
        _messages.add(errorMessage);
        notifyListeners();
        return;
      }

      final isNavigationAction = suggestion.action == 'navigate_menu' || 
                                  suggestion.action == 'navigate_orders' ||
                                  suggestion.action == 'show_reservation_details' ||
                                  suggestion.action == 'order_food' ||
                                  suggestion.action == 'view_menu' ||
                                  suggestion.action == 'order_takeaway' ||
                                  suggestion.action == 'select_branch_for_takeaway';
      
      if (!isNavigationAction) {
        final userMessage = ChatMessage(
          id: _uuid.v4(),
          content: suggestion.text,
          isUser: true,
          timestamp: DateTime.now(),
          type: ChatMessageType.text,
        );
        _messages.add(userMessage);
        notifyListeners();
      }

      _isTyping = true;
      notifyListeners();

      try {
        final result = await _chatService.executeAction(
          token: token,
          action: suggestion.action!,
          data: suggestion.data ?? {},
        );

        List<ChatSuggestion>? messageSuggestions;
        final suggestionsData = result['suggestions'] ?? result['data']?['suggestions'];
        if (suggestionsData != null && suggestionsData is List) {
          try {
            messageSuggestions = (suggestionsData as List)
                .map((json) => ChatSuggestion.fromJson(json))
                .toList();
            _suggestions = messageSuggestions;
          } catch (e) {
            messageSuggestions = null;
          }
        }

        if (!isNavigationAction && result['message'] != null && (result['message'] as String).trim().isNotEmpty) {
          final actionMessage = ChatMessage(
            id: _uuid.v4(),
            content: result['message'] as String,
            isUser: false,
            timestamp: DateTime.now(),
            type: result['success'] == false ? ChatMessageType.error : ChatMessageType.text,
            suggestions: messageSuggestions,
          );
          _messages.add(actionMessage);
        }
        
        if (messageSuggestions != null && messageSuggestions.isEmpty) {
          _suggestions = [];
        }

        if (suggestion.action == 'confirm_booking') {
          if (result['success'] == true) {
          }
        } else if (suggestion.action == 'select_branch') {
          if (result['data'] != null && result['data']['suggestions'] != null) {
          } else {
            sendMessage('Xem danh sách chi nhánh');
            return;
          }
        } else if (suggestion.action == 'modify_booking') {
        } else if (suggestion.action == 'navigate_menu' || suggestion.action == 'order_food') {
          if (onNavigate != null) {
            final branchId = suggestion.data?['branch_id'];
            final reservationId = suggestion.data?['reservation_id'];
            if (branchId != null) {
              onNavigate!('/branch-menu', arguments: {
                'branchId': branchId,
                'reservationId': reservationId,
              });
            }
          }
        } else if (suggestion.action == 'order_takeaway') {
          if (onNavigate != null) {
            onNavigate!('/takeaway-branch-selection');
          }
        } else if (suggestion.action == 'confirm_reservation_only') {
        } else if (suggestion.action == 'check_order_status') {
        } else if (suggestion.action == 'use_existing_cart') {
        } else if (suggestion.action == 'navigate_orders') {
          if (onNavigate != null) {
            onNavigate!('/orders', arguments: {});
          }
        } else if (suggestion.action == 'show_reservation_details') {
          if (onNavigate != null) {
            final reservationId = suggestion.data?['reservation_id'];
            if (reservationId != null) {
              onNavigate!('/order-detail', arguments: {'orderId': reservationId});
            }
          }
        }
      } catch (e) {
        String errorMessage;
        final errorString = e.toString();
        if (errorString.contains('Network error') || 
            errorString.contains('connection')) {
          errorMessage = 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.';
        } else if (errorString.contains('401') || 
                   errorString.contains('authentication')) {
          errorMessage = 'Bạn cần đăng nhập để thực hiện hành động này.';
        } else {
          // Try to extract the actual error message from the exception
          if (errorString.contains('Exception:')) {
            final extractedMsg = errorString.split('Exception:').last.trim();
            if (extractedMsg.isNotEmpty && extractedMsg.length < 200) {
              errorMessage = extractedMsg;
            } else {
              errorMessage = 'Có lỗi khi thực hiện hành động. Vui lòng thử lại.';
            }
          } else {
            errorMessage = 'Có lỗi khi thực hiện hành động. Vui lòng thử lại.';
          }
        }
        
        final errorChatMessage = ChatMessage(
          id: _uuid.v4(),
          content: errorMessage,
          isUser: false,
          timestamp: DateTime.now(),
          type: ChatMessageType.error,
          errorMessage: e.toString(),
        );
        _messages.add(errorChatMessage);
      } finally {
        _isTyping = false;
        notifyListeners();
      }
    } else {
      if (suggestion.action == 'select_branch_for_takeaway') {
        if (onNavigate != null) {
          final branchId = suggestion.data?['branch_id'];
          if (branchId != null) {
            onNavigate!('/takeaway-menu', arguments: {
              'branchId': branchId,
            });
            return;
          }
        }
      }
      
      if (suggestion.action == 'select_branch_for_delivery') {
        if (onNavigate != null) {
          final branchId = suggestion.data?['branch_id'];
          final deliveryAddress = suggestion.data?['delivery_address'];
          if (branchId != null) {
            onNavigate!('/takeaway-menu', arguments: {
              'branchId': branchId,
              'orderType': 'delivery',
              'deliveryAddress': deliveryAddress,
            });
            return;
          }
        }
      }
      
      
      if (suggestion.action == 'view_menu') {
        final branchId = suggestion.data?['branch_id'];
        final reservationId = suggestion.data?['reservation_id'];
        if (branchId != null && onNavigate != null) {
          onNavigate!('/branch-menu', arguments: {
            'branchId': branchId,
            'reservationId': reservationId,
          });
        }
      } else if (suggestion.action == 'view_orders') {
        if (onNavigate != null) {
          onNavigate!('/orders', arguments: {});
        }
      } else if (suggestion.action == 'find_branch') {
        if (onNavigate != null) {
          onNavigate!('/branches', arguments: {});
        }
      }
      
      sendMessage(suggestion.text);
    }
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

  /// Add a message directly to the messages list (for programmatic messages)
  void addMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  /// Clear suggestions
  void clearSuggestions() {
    _suggestions = [];
    notifyListeners();
  }

  /// Reset tất cả state của chat khi logout hoặc đăng nhập tài khoản khác
  void reset() {
    _messages.clear();
    _conversationId = null;
    _allConversations.clear();
    _suggestions.clear();
    _currentBranchId = null;
    _isLoading = false;
    _isTyping = false;
    _lastUserId = null;
    notifyListeners();
  }

  /// Check order status sau khi quay lại từ menu screen
  Future<void> checkOrderStatus(int reservationId) async {
    final token = _authService.token;
    if (token == null) return;

    try {
      final result = await _chatService.executeAction(
        token: token,
        action: 'check_order_status',
        data: {'reservation_id': reservationId},
      );

      if (result['message'] != null && (result['message'] as String).trim().isNotEmpty) {
        List<ChatSuggestion>? messageSuggestions;
        final suggestionsData = result['suggestions'] ?? result['data']?['suggestions'];
        if (suggestionsData != null && suggestionsData is List) {
          try {
            messageSuggestions = (suggestionsData as List)
                .map((json) => ChatSuggestion.fromJson(json))
                .toList();
            _suggestions = messageSuggestions;
          } catch (e) {
            messageSuggestions = [];
          }
        } else {
          messageSuggestions = [];
          _suggestions = [];
        }

        final orderMessage = ChatMessage(
          id: _uuid.v4(),
          content: result['message'] as String,
          isUser: false,
          timestamp: DateTime.now(),
          type: _getMessageType('order'),
          suggestions: messageSuggestions,
        );

        _messages.add(orderMessage);
        notifyListeners();
      }
    } catch (e) {
      print('Error checking order status: $e');
    }
  }

  @override
  void dispose() {
    _messages.clear();
    super.dispose();
  }
}

