import 'package:flutter/material.dart';

import '../branches/BranchScreen.dart';
import '../home/HomeScreen.dart';
import '../profile/ProfileScreen.dart';
import '../orders/OrdersScreen.dart';
import '../chat/ChatScreen.dart';

class _NavConstants {
  static const double iconSize = 24.0;
  static const double activeIconSize = 26.0;
  static const double navItemWidth = 70.0;
  static const double navBarHeight = 68.0;
  static const double indicatorHeight = 3.0;
  static const double indicatorWidth = 28.0;
  static const double chatIconPadding = 11.0;
  static const double regularIconPadding = 9.0;
  static const double chatBorderRadius = 16.0;
  static const double homeBorderRadius = 14.0;
  
  static const Duration animationDuration = Duration(milliseconds: 250);
  static const Curve animationCurve = Curves.easeOutCubic;
  
  static const Color activeColor = Color(0xFFFF8A00);
  static const Color activeColorDark = Color(0xFFFF6B00);
  static const Color inactiveColor = Color(0xFF9E9E9E);
  static const Color backgroundColor = Colors.white;
  static const Color borderColor = Color(0xFFF5F5F5);
  static const Color badgeColor = Color(0xFFFF3B30);
  
  static const List<BoxShadow> navBarShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 12,
      offset: Offset(0, -4),
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> getActiveShadow(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.25),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: color.withOpacity(0.15),
      blurRadius: 6,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];
}

class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
  });

  void _handleTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    final mainRoutes = [
      HomeScreen.routeName,
      BranchScreen.routeName,
      ChatScreen.routeName,
      OrdersScreen.routeName,
      ProfileScreen.routeName,
    ];

    String targetRoute;
    switch (index) {
      case 0:
        targetRoute = HomeScreen.routeName;
        break;
      case 1:
        targetRoute = BranchScreen.routeName;
        break;
      case 2:
        targetRoute = ChatScreen.routeName;
        break;
      case 3:
        targetRoute = OrdersScreen.routeName;
        break;
      case 4:
        targetRoute = ProfileScreen.routeName;
        break;
      default:
        return;
    }

    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isCurrentRouteMainTab = currentRoute != null && mainRoutes.contains(currentRoute);

    if (isCurrentRouteMainTab) {
      Navigator.pushReplacementNamed(context, targetRoute);
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        targetRoute,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _NavConstants.backgroundColor,
        border: Border(
          top: BorderSide(
            color: _NavConstants.borderColor,
            width: 1,
          ),
        ),
        boxShadow: _NavConstants.navBarShadow,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: _NavConstants.navBarHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                isActive: currentIndex == 0,
                onTap: () => _handleTap(context, 0),
                isSpecial: true,
              ),
              _NavItem(
                icon: Icons.store_rounded,
                isActive: currentIndex == 1,
                onTap: () => _handleTap(context, 1),
              ),
              _NavItem(
                icon: Icons.chat_bubble_rounded,
                isActive: currentIndex == 2,
                onTap: () => _handleTap(context, 2),
                isChatBot: true,
              ),
              _NavItem(
                icon: Icons.receipt_long_rounded,
                isActive: currentIndex == 3,
                onTap: () => _handleTap(context, 3),
              ),
              _NavItem(
                icon: Icons.person_rounded,
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
  final bool isActive;
  final VoidCallback onTap;
  final int? badge;
  final bool isChatBot;
  final bool isSpecial;

  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.badge,
    this.isChatBot = false,
    this.isSpecial = false,
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _controller,
        curve: _NavConstants.animationCurve,
      ),
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

  Color _getIconColor() {
    if (widget.isChatBot && widget.isActive) {
      return Colors.white;
    }
    if (widget.isChatBot && !widget.isActive) {
      return _NavConstants.activeColor;
    }
    return widget.isActive
        ? _NavConstants.activeColor
        : _NavConstants.inactiveColor;
  }

  double _getIconSize() {
    if (widget.isChatBot) {
      return _NavConstants.activeIconSize;
    }
    if (widget.isSpecial && widget.isActive) {
      return _NavConstants.activeIconSize;
    }
    return _NavConstants.iconSize;
  }

  double _getPadding() {
    if (widget.isChatBot) {
      return _NavConstants.chatIconPadding;
    }
    if (widget.isSpecial && widget.isActive) {
      return _NavConstants.chatIconPadding;
    }
    return _NavConstants.regularIconPadding;
  }

  double _getBorderRadius() {
    if (widget.isChatBot) {
      return _NavConstants.chatBorderRadius;
    }
    if (widget.isSpecial) {
      return _NavConstants.homeBorderRadius;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _getIconColor();
    final iconSize = _getIconSize();
    final padding = _getPadding();
    final borderRadius = _getBorderRadius();

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: _NavConstants.navItemWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: _NavConstants.animationDuration,
                    curve: _NavConstants.animationCurve,
                    padding: EdgeInsets.all(padding),
                    decoration: BoxDecoration(
                      gradient: widget.isChatBot && widget.isActive
                          ? const LinearGradient(
                              colors: [
                                _NavConstants.activeColor,
                                _NavConstants.activeColorDark,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: widget.isChatBot && !widget.isActive
                          ? _NavConstants.activeColor.withOpacity(0.1)
                          : widget.isSpecial && widget.isActive
                              ? _NavConstants.activeColor.withOpacity(0.15)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(borderRadius),
                      boxShadow: (widget.isChatBot && widget.isActive) ||
                              (widget.isSpecial && widget.isActive)
                          ? _NavConstants.getActiveShadow(
                              _NavConstants.activeColor)
                          : null,
                    ),
                    child: Icon(
                      widget.icon,
                      color: iconColor,
                      size: iconSize,
                    ),
                  ),
                  if (widget.badge != null && widget.badge! > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        decoration: BoxDecoration(
                          color: _NavConstants.badgeColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _NavConstants.backgroundColor,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _NavConstants.badgeColor.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.badge! > 99 ? '99+' : '${widget.badge}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                            letterSpacing: -0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: _NavConstants.animationDuration,
                curve: _NavConstants.animationCurve,
                height: _NavConstants.indicatorHeight,
                width: widget.isActive ? _NavConstants.indicatorWidth : 0,
                decoration: BoxDecoration(
                  gradient: widget.isActive
                      ? const LinearGradient(
                          colors: [
                            _NavConstants.activeColor,
                            _NavConstants.activeColorDark,
                          ],
                        )
                      : null,
                  color: widget.isActive ? null : Colors.transparent,
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