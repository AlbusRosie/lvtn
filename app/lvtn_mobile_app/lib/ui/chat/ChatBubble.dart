import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/chat_message.dart';
import '../../providers/ChatProvider.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isTyping;
  final int? sectionIndex;

  const ChatBubble({
    Key? key,
    required this.message,
    this.isTyping = false,
    this.sectionIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            _buildAvatar(),
            SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: Offset(0, 2),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: isTyping ? _buildTypingIndicator() : _buildContent(),
                ),
                SizedBox(height: 6),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (!message.isUser && message.suggestions != null && message.suggestions!.isNotEmpty)
                  _buildSuggestions(),
              ],
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: 12),
            _buildAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: message.isUser 
            ? Color(0xFFFF8A00)
            : Color(0xFFFF8A00),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFF8A00).withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: message.isUser 
          ? null
          : Icon(
              Icons.restaurant,
              color: Colors.white,
              size: 18,
            ),
    );
  }

  Widget _buildSectionHeader() {
    if (message.metadata == null || message.metadata!.isEmpty) {
      return SizedBox.shrink();
    }

    final rank = message.metadata!['rank'] ?? sectionIndex ?? 1;
    final confidence = message.metadata!['confidence'] ?? message.metadata!['score'];
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFFFF8A00).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFFFF8A00),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'S${rank}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Body',
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (confidence != null) ...[
            Spacer(),
            _buildMetricPill(
              icon: Icons.table_restaurant_rounded,
              label: 'Confidence',
              value: (confidence is num) ? confidence.toStringAsFixed(2) : confidence.toString(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: EdgeInsets.only(left: 6),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (message.type == ChatMessageType.error) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 10),
            Flexible(
              child: Text(
                _removeEmoji(message.content),
                style: TextStyle(
                  color: Colors.red[800],
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Check if content has structured format (like the reference image)
    final hasStructuredContent = message.content.contains('**') || 
                                  message.content.contains('\n\n') ||
                                  message.metadata != null;

    if (hasStructuredContent && !message.isUser) {
      return _buildStructuredContent();
    }

    return Text(
      _removeEmoji(message.content),
      style: TextStyle(
        color: message.isUser ? Colors.grey[900] : Colors.grey[800],
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildStructuredContent() {
    final lines = message.content.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.trim().isEmpty) {
          return SizedBox(height: 8);
        }
        
        final isBold = line.contains('**');
        final cleanLine = _removeEmoji(line.replaceAll('**', ''));
        
        return Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text(
            cleanLine,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: isBold ? 15 : 14,
              fontWeight: FontWeight.w400,
              height: 1.5,
              letterSpacing: -0.2,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDot(delay: 0),
        SizedBox(width: 6),
        _buildDot(delay: 200),
        SizedBox(width: 6),
        _buildDot(delay: 400),
      ],
    );
  }

  Widget _buildDot({required int delay}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Color(0xFFFF8A00),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  IconData? _getSuggestionIcon(String? action) {
    if (action == null) return null;
    
    switch (action) {
      case 'view_menu':
      case 'navigate_menu':
      case 'order_food':
        return Icons.restaurant_menu_rounded;
      case 'book_table':
      case 'confirm_booking':
        return Icons.table_restaurant_rounded;
      case 'view_branches':
      case 'find_branch':
      case 'select_branch':
        return Icons.location_on_rounded;
      case 'view_orders':
      case 'navigate_orders':
      case 'check_order_status':
        return Icons.shopping_bag_outlined;
      case 'order_takeaway':
      case 'select_branch_for_takeaway':
        return Icons.shopping_bag_rounded;
      case 'select_branch_for_delivery':
        return Icons.delivery_dining_rounded;
      case 'search_food':
        return Icons.search_rounded;
      default:
        return null;
    }
  }

  String _removeEmoji(String text) {
    // Remove common emojis
    return text
        .replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{2600}-\u{26FF}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{2700}-\u{27BF}]', unicode: true), '')
        .trim();
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: EdgeInsets.only(top: 12, left: 4, right: 4),
      child: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final multiLineSuggestions = message.suggestions!.where((s) => s.text.contains('\n')).toList();
          final singleLineSuggestions = message.suggestions!.where((s) => !s.text.contains('\n')).toList();
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (singleLineSuggestions.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: singleLineSuggestions.map((suggestion) {
                      final cleanText = _removeEmoji(suggestion.text);
                      final icon = _getSuggestionIcon(suggestion.action);
                      return Padding(
                        padding: EdgeInsets.only(right: 10, bottom: 10),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              chatProvider.handleSuggestionTap(suggestion);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Color(0xFFFF8A00).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFFFF8A00).withOpacity(0.15),
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (icon != null) ...[
                                    Icon(
                                      icon,
                                      size: 16,
                                      color: Color(0xFFFF8A00),
                                    ),
                                    SizedBox(width: 6),
                                  ],
                                  Text(
                                    cleanText,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFFF8A00),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              
              ...multiLineSuggestions.map((suggestion) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        chatProvider.handleSuggestionTap(suggestion);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Color(0xFFFF8A00).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFFF8A00).withOpacity(0.12),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: suggestion.text.split('\n').map((line) {
                            if (line.trim().isEmpty) return SizedBox(height: 4);
                            final cleanLine = _removeEmoji(line);
                            final isHeader = line.contains('**') || cleanLine.length < 50;
                            return Padding(
                              padding: EdgeInsets.only(bottom: 6),
                              child: Text(
                                cleanLine.replaceAll('**', ''),
                                style: TextStyle(
                                  fontSize: isHeader ? 15 : 13.5,
                                  fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400,
                                  color: Colors.grey[900],
                                  height: 1.5,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return DateFormat('HH:mm').format(timestamp);
    } else {
      return DateFormat('dd/MM HH:mm').format(timestamp);
    }
  }
}

