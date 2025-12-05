class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final ChatMessageType type;
  final Map<String, dynamic>? metadata;
  final List<ChatSuggestion>? suggestions;
  final MessageStatus status;
  final String? errorMessage;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.type = ChatMessageType.text,
    this.metadata,
    this.suggestions,
    this.status = MessageStatus.sent,
    this.errorMessage,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    List<ChatSuggestion>? suggestions;
    if (json['suggestions'] != null && json['suggestions'] is List) {
      try {
        suggestions = (json['suggestions'] as List)
            .map((item) => ChatSuggestion.fromJson(item))
            .toList();
      } catch (e) {
        suggestions = null;
      }
    }
    
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? json['message_content']?.toString() ?? '',
      isUser: json['is_user'] ?? json['message_type'] == 'user' ?? false,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      type: _parseMessageType(json['type']),
      metadata: json['metadata'] ?? json['entities'],
      suggestions: suggestions,
      status: MessageStatus.sent,
      errorMessage: null,
    );
  }
  
  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    ChatMessageType? type,
    Map<String, dynamic>? metadata,
    List<ChatSuggestion>? suggestions,
    MessageStatus? status,
    String? errorMessage,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
      suggestions: suggestions ?? this.suggestions,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  static ChatMessageType _parseMessageType(dynamic type) {
    if (type == null) return ChatMessageType.text;
    
    final typeString = type.toString().toLowerCase();
    switch (typeString) {
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'is_user': isUser,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
      'metadata': metadata,
      'suggestions': suggestions?.map((s) => s.toJson()).toList(),
      'error_message': errorMessage,
      'status': status.toString().split('.').last,
    };
  }
  
  bool get isError => type == ChatMessageType.error || errorMessage != null;
  
  bool get hasSuggestions => suggestions != null && suggestions!.isNotEmpty;
  
  String get formattedTimestamp {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

enum ChatMessageType {
  text,
  action,
  suggestion,
  menu,
  order,
  reservation,
  error,
}

enum MessageStatus {
  sending,
  sent,
  failed,
  retrying,
}

class ChatIntent {
  final String intent;
  final Map<String, dynamic> entities;
  final double confidence;

  ChatIntent({
    required this.intent,
    required this.entities,
    required this.confidence,
  });

  factory ChatIntent.fromJson(Map<String, dynamic> json) {
    return ChatIntent(
      intent: json['intent'] ?? '',
      entities: json['entities'] ?? {},
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }
}

class ChatSuggestion {
  final String text;
  final String action;
  final Map<String, dynamic>? data;

  ChatSuggestion({
    required this.text,
    required this.action,
    this.data,
  });

  factory ChatSuggestion.fromJson(Map<String, dynamic> json) {
    return ChatSuggestion(
      text: json['text']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      data: json['data'] is Map<String, dynamic> ? json['data'] : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'action': action,
      'data': data,
    };
  }
  
  bool get hasData => data != null && data!.isNotEmpty;
  
  int? get branchId {
    if (data != null && data!['branch_id'] != null) {
      final branchIdValue = data!['branch_id'];
      if (branchIdValue is int) return branchIdValue;
      if (branchIdValue is String) return int.tryParse(branchIdValue);
    }
    return null;
  }
}

