import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
              padding: EdgeInsets.fromLTRB(20, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(0xFFFF8A00).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      color: Color(0xFFFF8A00),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Lịch sử trò chuyện',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[900],
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.grey[600],
                          size: 22,
                        ),
                      ),
                    ),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFF8A00).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 16,
                                    color: Color(0xFFFF8A00),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Cuộc trò chuyện ${index + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: Colors.grey[900],
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                Text(
                                  lastMessage != null 
                                    ? DateFormat('dd/MM HH:mm').format(DateTime.parse(lastMessage['created_at']))
                                    : DateFormat('dd/MM HH:mm').format(DateTime.parse(conversation['created_at'])),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (lastMessage != null) ...[
                              SizedBox(height: 12),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: lastMessage['is_user'] 
                                            ? Color(0xFFFF8A00).withOpacity(0.1)
                                            : Colors.grey[200],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        lastMessage['is_user'] 
                                            ? Icons.person_rounded 
                                            : Icons.smart_toy_rounded,
                                        size: 16,
                                        color: lastMessage['is_user'] 
                                            ? Color(0xFFFF8A00) 
                                            : Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        lastMessage['content'],
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[800],
                                          fontWeight: FontWeight.w500,
                                          height: 1.4,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: WillPopScope(
        onWillPop: () async {
          _handleBackNavigation();
          return false;
        },
        child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(100),
          child: SafeArea(
            bottom: false,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Color(0xFFFF8A00),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFF8A00).withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.smart_toy_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Beast Bite Assistant',
                            style: TextStyle(
                              color: Colors.grey[900],
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            widget.branchName ?? 'AI Chatbot',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _showChatHistory();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.history_rounded,
                            color: Colors.grey[700],
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
                            CircularProgressIndicator(
                              color: Color(0xFFFF8A00),
                              strokeWidth: 3,
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Đang tải cuộc trò chuyện...',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : chatProvider.messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFF8A00).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 40,
                                    color: Color(0xFFFF8A00),
                                  ),
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'Bắt đầu cuộc trò chuyện',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[900],
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Hỏi tôi bất cứ điều gì về menu,\nđặt bàn hoặc đơn hàng của bạn',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                                sectionIndex: index + 1,
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
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: chatProvider.suggestions.map((suggestion) {
                        return Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                chatProvider.handleSuggestionTap(suggestion);
                                _scrollToBottom();
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                                child: Text(
                                  suggestion.text,
                                  style: TextStyle(
                                    color: Color(0xFFFF8A00),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

              Container(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: Offset(0, -5),
                      spreadRadius: 0,
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
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _messageController,
                            focusNode: _focusNode,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Nhập tin nhắn...',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: chatProvider.isTyping ? null : _sendMessage,
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: chatProvider.isTyping
                                  ? Colors.grey[400]
                                  : Color(0xFFFF8A00),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFFFF8A00).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                  spreadRadius: 0,
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
      ),
    );
  }
}

