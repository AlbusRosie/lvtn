import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/chat_message.dart';
import '../../providers/ChatProvider.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isTyping;

  const ChatBubble({
    Key? key,
    required this.message,
    this.isTyping = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            _buildAvatar(),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: message.isUser
                        ? Border.all(color: Colors.orange, width: 1.5)
                        : null,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(message.isUser ? 20 : 4),
                      topRight: Radius.circular(message.isUser ? 4 : 20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isTyping ? _buildTypingIndicator() : _buildContent(),
                ),
                SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ),
                if (!message.isUser && message.suggestions != null && message.suggestions!.isNotEmpty)
                  _buildSuggestions(),
              ],
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: 8),
            _buildAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: message.isUser ? Colors.blue : Colors.orange,
        shape: BoxShape.circle,
      ),
      child: Icon(
        message.isUser ? Icons.person : Icons.smart_toy,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildContent() {
    if (message.type == ChatMessageType.error) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 18),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              message.content,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 14,
              ),
            ),
          ),
        ],
      );
    }

    return Text(
      message.content,
      style: TextStyle(
        color: Colors.grey[800],
        fontSize: 15,
        height: 1.4,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDot(delay: 0),
        SizedBox(width: 4),
        _buildDot(delay: 200),
        SizedBox(width: 4),
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
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: EdgeInsets.only(top: 8, left: 8, right: 8),
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
                      return Padding(
                        padding: EdgeInsets.only(right: 8, bottom: 8),
                        child: ActionChip(
                          label: Text(
                            suggestion.text,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onPressed: () {
                            chatProvider.handleSuggestionTap(suggestion);
                          },
                          backgroundColor: Colors.orange[50],
                          labelStyle: TextStyle(
                            color: Colors.orange[800],
                          ),
                          side: BorderSide(color: Colors.orange[200]!),
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              
              ...multiLineSuggestions.map((suggestion) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      chatProvider.handleSuggestionTap(suggestion);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange[200]!,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: suggestion.text.split('\n').map((line) {
                          if (line.trim().isEmpty) return SizedBox.shrink();
                          return Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Text(
                              line.trim(),
                              style: TextStyle(
                                fontSize: line.startsWith('📍') ? 15 : 13,
                                fontWeight: line.startsWith('📍') 
                                    ? FontWeight.bold 
                                    : FontWeight.w500,
                                color: Colors.orange[900],
                                height: 1.4,
                              ),
                            ),
                          );
                        }).toList(),
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

