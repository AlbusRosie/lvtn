import 'package:flutter/material.dart';

import '../branches/BranchScreen.dart';
import '../home/HomeScreen.dart';
import '../profile/ProfileScreen.dart';
import '../orders/OrdersScreen.dart';
import '../chat/ChatScreen.dart';

// Constants for theming
class _NavConstants {
  static const double iconSize = 24.0;
  static const double fontSize = 12.0;
  static const double navItemWidth = 70.0;
  static const double indicatorHeight = 3.0;
  static const Duration animationDuration = Duration(milliseconds: 200);
  
  static const Color activeColor = Color(0xFFFF9800); // Orange
  static const Color inactiveColor = Color(0xFFBDBDBD);
  static const Color backgroundColor = Colors.white;
}

class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
  });

  void _handleTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, HomeScreen.routeName);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, BranchScreen.routeName);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, ChatScreen.routeName);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, OrdersScreen.routeName);
        break;
      case 4:
        Navigator.pushReplacementNamed(context, ProfileScreen.routeName);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _NavConstants.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: '',
                isActive: currentIndex == 0,
                onTap: () => _handleTap(context, 0),
              ),
              _NavItem(
                icon: Icons.store_rounded,
                label: '',
                isActive: currentIndex == 1,
                onTap: () => _handleTap(context, 1),
              ),
              _NavItem(
                icon: Icons.chat_bubble_rounded,
                label: '',
                isActive: currentIndex == 2,
                onTap: () => _handleTap(context, 2),
                isChatBot: true,
              ),
              _NavItem(
                icon: Icons.receipt_long_rounded,
                label: '',
                isActive: currentIndex == 3,
                onTap: () => _handleTap(context, 3),
                // badge: 3, // Optional: Uncomment to show badge
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: '',
                isActive: currentIndex == 4,
                onTap: () => _handleTap(context, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int? badge;
  final bool isChatBot;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge,
    this.isChatBot = false,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: _NavConstants.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: _NavConstants.navItemWidth,
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: _NavConstants.animationDuration,
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.all(widget.isChatBot ? 10 : 8),
                    decoration: BoxDecoration(
                      gradient: widget.isChatBot && widget.isActive
                          ? LinearGradient(
                              colors: [Colors.orange, Colors.deepOrange],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: widget.isChatBot && !widget.isActive
                          ? Colors.orange.withOpacity(0.1)
                          : widget.isActive
                              ? _NavConstants.activeColor.withOpacity(0.12)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(widget.isChatBot ? 14 : 12),
                      boxShadow: widget.isChatBot && widget.isActive
                          ? [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.isChatBot && widget.isActive
                          ? Colors.white
                          : widget.isChatBot
                              ? Colors.orange
                              : widget.isActive
                                  ? _NavConstants.activeColor
                                  : _NavConstants.inactiveColor,
                      size: widget.isChatBot ? 26 : _NavConstants.iconSize,
                    ),
                  ),
                  // Badge
                  if (widget.badge != null && widget.badge! > 0)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _NavConstants.backgroundColor,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          widget.badge! > 99 ? '99+' : '${widget.badge}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
               // Active indicator
               const SizedBox(height: 2),
              AnimatedContainer(
                duration: _NavConstants.animationDuration,
                curve: Curves.easeInOut,
                height: _NavConstants.indicatorHeight,
                width: widget.isActive ? 20 : 0,
                decoration: BoxDecoration(
                  color: _NavConstants.activeColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}