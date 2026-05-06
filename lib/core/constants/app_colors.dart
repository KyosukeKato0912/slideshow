import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════
// アプリ全体のカラー定数
//
// 全機能で共通利用するカラーを定義する。
// 機能固有のカラーは各 feature 内で定義する。
// ══════════════════════════════════════════════════════════
abstract class AppColors {
  // アプリ全体のテーマカラー（AppBar・アクセント・ボタン等に共通適用）
  static const Color theme       = Colors.purple;
  static const Color themeLight  = Color(0xFFF3E5F5); // purple.shade50
  static const Color themeBorder = Color(0xFFCE93D8); // purple.shade200
  static const Color themeDark   = Color(0xFF6A1B9A); // purple.shade700

  // 未実装機能のグレー
  static const Color disabled = Color(0xFFBDBDBD); // grey.shade300
  static const Color disabledText = Color(0xFF9E9E9E); // grey.shade500

  // ホーム画面 各機能ボタンカラー
  static const Color topicGenerator = Colors.teal;
  static const Color growthRecord = Colors.orange;
  static const Color habitSupport = Colors.pink;
  static const Color proArtistLesson = Colors.indigo;
}
