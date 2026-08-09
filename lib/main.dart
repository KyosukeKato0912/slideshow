import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/services/hive_adapters.dart';

// ══════════════════════════════════════════════════════════
// エントリポイント
//
// 初期化処理を行い App を起動する。
// ══════════════════════════════════════════════════════════
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  HiveAdapters.registerAll();
  await NotificationService.initialize();
  runApp(const ProviderScope(child: App()));
}
