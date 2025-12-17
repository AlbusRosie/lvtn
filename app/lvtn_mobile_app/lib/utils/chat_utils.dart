import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Utility functions for chat UI components
/// Removes duplicate code from ChatScreen and ChatBubble
class ChatUtils {
  /// Get icon for suggestion action
  static IconData? getSuggestionIcon(String? action) {
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

  /// Remove emojis from text
  static String removeEmoji(String text) {
    return text
        .replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{2600}-\u{26FF}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{2700}-\u{27BF}]', unicode: true), '')
        .trim();
  }

  /// Format timestamp for chat messages
  static String formatTime(DateTime timestamp) {
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

