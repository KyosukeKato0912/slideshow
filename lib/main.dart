import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

// ══════════════════════════════════════════════════════════
// エントリポイント
//
// 初期化処理（将来：Hive.initFlutter・通知初期化など）を行い、
// App を起動する。
// ── 将来の拡張例 ──
//   WidgetsFlutterBinding.ensureInitialized();
//   await Hive.initFlutter();
//   await HiveAdapters.registerAll();
//   await NotificationService.initialize();
// ══════════════════════════════════════════════════════════
void main() {
  runApp(const ProviderScope(child: App()));
}
