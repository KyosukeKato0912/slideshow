import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════
// アプリ全体の ThemeData 一元定義
//
// app.dart（MaterialApp）からのみ参照する。
// ══════════════════════════════════════════════════════════
abstract class AppTheme {
  AppTheme._();

  static final ThemeData light = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
    useMaterial3: true,
  );
}
