import 'package:flutter/material.dart';

/// 成就 iconName（数据库 / mock 中的字符串）到 Material 图标的映射。
IconData achievementIconFor(String? iconName) {
  switch (iconName) {
    case 'book':
      return Icons.menu_book;
    case 'compass':
      return Icons.explore;
    case 'crown':
      return Icons.workspace_premium;
    case 'star':
      return Icons.star;
    case 'camera':
      return Icons.camera_alt;
    case 'quote':
      return Icons.format_quote;
    default:
      return Icons.emoji_events;
  }
}
