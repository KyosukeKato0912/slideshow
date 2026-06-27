import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/notification_service.dart';

// ══════════════════════════════════════════════════════════
// エントリポイント
//
// 初期化処理を行い App を起動する。
// ── 将来の拡張例 ──
//   await Hive.initFlutter();
//   await HiveAdapters.registerAll();
// ══════════════════════════════════════════════════════════
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  runApp(const ProviderScope(child: App()));
}
