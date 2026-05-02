import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════
// 共通 AppBar ヘルパー
// ══════════════════════════════════════════════════════════
class AppBarHelper {
  AppBarHelper._();

  static AppBar build(BuildContext context, String title, Color color) {
    return AppBar(
      backgroundColor: color,
      foregroundColor: Colors.white,
      title: Text(title),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }
}
