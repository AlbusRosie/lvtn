class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final ChatMessageType type;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.type = ChatMessageType.text,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
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
    };
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
}

