import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum NotificationType {
  success,
  error,
  info,
  warning,
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  OverlayEntry? _overlayEntry;
  OverlayState? _overlayState;

  /// Hiển thị thông báo overlay ở top màn hình
  void showTopNotification({
    required BuildContext context,
    required String title,
    String? message,
    IconData? icon,
    Color? backgroundColor,
    Color? iconColor,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    // Ẩn thông báo cũ nếu có
    hideNotification();

    final overlayState = Overlay.of(context);
    if (overlayState == null) return;

    _overlayState = overlayState;

    // Tạo overlay entry
    _overlayEntry = OverlayEntry(
      builder: (context) => _TopNotificationWidget(
        title: title,
        message: message,
        icon: icon ?? Icons.notifications_active,
        backgroundColor: backgroundColor ?? Color(0xFF4CAF50),
        iconColor: iconColor ?? Colors.white,
        duration: duration,
        onTap: onTap,
        onDismiss: hideNotification,
      ),
    );

    // Hiển thị overlay
    overlayState.insert(_overlayEntry!);

    // Phát haptic feedback
    HapticFeedback.mediumImpact();

    // Tự động ẩn sau duration
    Future.delayed(duration, () {
      hideNotification();
    });
  }

  /// Hiển thị thông báo thành công
  void showSuccess({
    required BuildContext context,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    showTopNotification(
      context: context,
      title: title ?? 'Thành công',
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: Color(0xFF4CAF50),
      iconColor: Colors.white,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Hiển thị thông báo lỗi
  void showError({
    required BuildContext context,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    showTopNotification(
      context: context,
      title: title ?? 'Lỗi',
      message: message,
      icon: Icons.error_rounded,
      backgroundColor: Color(0xFFEF5350),
      iconColor: Colors.white,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Hiển thị thông báo thông tin
  void showInfo({
    required BuildContext context,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    showTopNotification(
      context: context,
      title: title ?? 'Thông báo',
      message: message,
      icon: Icons.info_rounded,
      backgroundColor: Color(0xFF2196F3),
      iconColor: Colors.white,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Hiển thị thông báo cảnh báo
  void showWarning({
    required BuildContext context,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    showTopNotification(
      context: context,
      title: title ?? 'Cảnh báo',
      message: message,
      icon: Icons.warning_rounded,
      backgroundColor: Color(0xFFFF9800),
      iconColor: Colors.white,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Ẩn thông báo hiện tại
  void hideNotification() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }
}

class _TopNotificationWidget extends StatefulWidget {
  final String title;
  final String? message;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final Duration duration;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const _TopNotificationWidget({
    required this.title,
    this.message,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.duration,
    this.onTap,
    this.onDismiss,
  });

  @override
  State<_TopNotificationWidget> createState() => _TopNotificationWidgetState();
}

class _TopNotificationWidgetState extends State<_TopNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, -1),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {
                widget.onTap?.call();
                _handleDismiss();
              },
              onVerticalDragStart: (_) => _handleDismiss(),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.iconColor,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.message != null) ...[
                            SizedBox(height: 4),
                            Text(
                              widget.message!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: _handleDismiss,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

