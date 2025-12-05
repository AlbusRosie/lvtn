import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../providers/ChatProvider.dart';
import '../../providers/BranchProvider.dart';
import '../../models/chat_message.dart';
import '../../models/branch.dart';
import 'ChatBubble.dart';
import '../reservation/ReservationMenuScreen.dart';
import '../branches/BranchMenuScreen.dart';
import '../takeaway/TakeawayBranchSelectionScreen.dart';
import '../takeaway/TakeawayMenuScreen.dart';
import '../widgets/AppBottomNav.dart';

class ChatScreen extends StatefulWidget {
  static const routeName = '/chat';

  final int? branchId;
  final String? branchName;

  const ChatScreen({
    Key? key,
    this.branchId,
    this.branchName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      
      chatProvider.onNavigate = (String routeName, {Map<String, dynamic>? arguments}) async {
        if (routeName == '/takeaway-branch-selection') {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return TakeawayBranchSelectionScreen();
              },
            ),
          );
          
          if (result is Map && result['orderCreated'] == true && mounted) {
          }
        }
        else if (routeName == '/takeaway-menu' && arguments != null && arguments['branchId'] != null) {
          final branchId = arguments['branchId'];
          final orderType = arguments['orderType'] ?? 'takeaway';
          final deliveryAddress = arguments['deliveryAddress'] as String?;
          final branchProvider = Provider.of<BranchProvider>(context, listen: false);
          
          Branch? branch = branchProvider.branches.firstWhere(
            (b) => b.id == branchId,
            orElse: () => Branch(
              id: branchId,
              name: 'Chi nhánh',
              addressDetail: '',
              status: 'active',
              phone: '',
              email: '',
              openingHours: 7,
              closeHours: 22,
              createdAt: DateTime.now(),
            ),
          );
          
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return TakeawayMenuScreen(
                  branch: branch,
                  orderType: orderType,
                  deliveryAddress: deliveryAddress,
                );
              },
            ),
          );
          
          if (result is Map && result['orderCreated'] == true && mounted) {
            final uuid = const Uuid();
            final isDelivery = result['orderType'] == 'delivery';
            final orderMessage = ChatMessage(
              id: uuid.v4(),
              content: isDelivery
                  ? '✅ **Đơn hàng giao hàng của bạn đã được tạo thành công!**\n\n'
                      '📋 **Mã đơn hàng:** #${result['orderId'] ?? 'N/A'}\n'
                      '📍 **Địa chỉ giao hàng:** ${result['deliveryAddress'] ?? deliveryAddress ?? 'N/A'}\n'
                      '💰 **Tổng tiền:** ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(result['total'] ?? 0)}\n\n'
                      '📦 Đơn hàng sẽ được chuẩn bị tại chi nhánh ${result['branchName'] ?? branch.name} và giao đến địa chỉ của bạn.'
                  : '✅ **Đơn hàng mang về của bạn đã được tạo thành công!**\n\n'
                      '📋 **Mã đơn hàng:** #${result['orderId'] ?? 'N/A'}\n'
                      '💰 **Tổng tiền:** ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(result['total'] ?? 0)}\n\n'
                      '📦 Đơn hàng sẽ được chuẩn bị tại chi nhánh ${result['branchName'] ?? branch.name} và sẵn sàng để bạn đến lấy.',
              isUser: false,
              timestamp: DateTime.now(),
              type: ChatMessageType.text,
              suggestions: [],
            );
            chatProvider.addMessage(orderMessage);
            chatProvider.clearSuggestions();
          }
        }
        else if (routeName == '/branch-menu' && arguments != null && arguments['branchId'] != null) {
          final branchId = arguments['branchId'];
          final reservationId = arguments['reservationId'];
          final branchProvider = Provider.of<BranchProvider>(context, listen: false);
          
          Branch? branch = branchProvider.branches.firstWhere(
            (b) => b.id == branchId,
            orElse: () => Branch(
              id: branchId,
              name: 'Chi nhánh',
              addressDetail: '',
              status: 'active',
              phone: '',
              email: '',
              openingHours: 7,
              closeHours: 22,
              createdAt: DateTime.now(),
            ),
          );
          
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                if (reservationId != null) {
                  return ReservationMenuScreen(
                    branch: branch,
                    reservationId: reservationId,
                  );
                } else {
                  return BranchMenuScreen(
                    branch: branch,
                    reservationId: null,
                  );
                }
              },
            ),
          );
          
          if (reservationId != null && mounted) {
            if (result is Map && result['orderCreated'] == true) {
              await _checkOrderStatusAfterReturn(reservationId);
            }
          }
        } else {
          Navigator.pushNamed(context, routeName, arguments: arguments);
        }
      };
      
      if (widget.branchId != null) {
        chatProvider.setCurrentBranch(widget.branchId!);
      }
      
      await chatProvider.loadChatHistory();
      
      if (chatProvider.messages.isEmpty) {
        chatProvider.startNewConversation();
      }
      
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _checkOrderStatusAfterReturn(int reservationId) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    try {
      await chatProvider.checkOrderStatus(reservationId);
      _scrollToBottom();
    } catch (e) {
      print('Error checking order status: $e');
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    _focusNode.unfocus();

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.sendMessage(content);
    _scrollToBottom();
  }

  void _handleBackNavigation() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context, 
        '/', 
        (route) => false,
      );
    }
  }

  void _showChatHistory() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    chatProvider.loadAllConversations();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.history, color: Colors.orange),
                  SizedBox(width: 12),
                  Text(
                    'Lịch sử trò chuyện',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  if (chatProvider.isLoading) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  
                  if (chatProvider.allConversations.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            'Chưa có cuộc trò chuyện nào',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: chatProvider.allConversations.length,
                    itemBuilder: (context, index) {
                      final conversation = chatProvider.allConversations[index];
                      final lastMessage = conversation['last_message'];
                      
                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 16,
                                  color: Colors.orange,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Cuộc trò chuyện ${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  lastMessage != null 
                                    ? DateFormat('dd/MM HH:mm').format(DateTime.parse(lastMessage['created_at']))
                                    : DateFormat('dd/MM HH:mm').format(DateTime.parse(conversation['created_at'])),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                            if (lastMessage != null) ...[
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    lastMessage['is_user'] ? Icons.person : Icons.smart_toy,
                                    size: 14,
                                    color: lastMessage['is_user'] ? Colors.orange : Colors.grey[600],
                                  ),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      lastMessage['content'],
                                      style: TextStyle(fontSize: 13),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _handleBackNavigation();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.grey[800]),
          onPressed: _handleBackNavigation,
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.smart_toy, color: Colors.white, size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Beast Bite Assistant',
                    style: TextStyle(
                      color: Colors.grey[900],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.branchName ?? 'AI Chatbot',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: Colors.grey[700]),
            onPressed: () {
              _showChatHistory();
            },
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          return Column(
            children: [
              Expanded(
                child: chatProvider.isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.orange),
                            SizedBox(height: 16),
                            Text(
                              'Loading chat...',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(16),
                        itemCount: chatProvider.messages.length +
                            (chatProvider.isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == chatProvider.messages.length) {
                            return ChatBubble(
                              message: ChatMessage(
                                id: 'typing',
                                content: 'Đang nhập...',
                                isUser: false,
                                timestamp: DateTime.now(),
                              ),
                              isTyping: true,
                            );
                          }
                          
                          final message = chatProvider.messages[index];
                          return ChatBubble(
                            message: message,
                            key: ValueKey(message.id),
                          );
                        },
                      ),
              ),

              if (chatProvider.suggestions.isNotEmpty && 
                  (chatProvider.messages.isEmpty || 
                   chatProvider.messages.last.suggestions == null || 
                   chatProvider.messages.last.suggestions!.isEmpty))
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: chatProvider.suggestions.map((suggestion) {
                        return Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text(suggestion.text),
                            onPressed: () {
                              chatProvider.handleSuggestionTap(suggestion);
                              _scrollToBottom();
                            },
                            backgroundColor: Colors.orange[50],
                            labelStyle: TextStyle(
                              color: Colors.orange[800],
                              fontSize: 13,
                            ),
                            side: BorderSide(color: Colors.orange[200]!),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _messageController,
                            focusNode: _focusNode,
                            decoration: InputDecoration(
                              hintText: 'Nhập tin nhắn...',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      GestureDetector(
                        onTap: chatProvider.isTyping ? null : _sendMessage,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: chatProvider.isTyping
                                ? Colors.grey[400]
                                : Colors.orange,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
      ),
    ),
    );
  }
}

