import 'package:flutter/material.dart';
import '../../features/drawing/ui/drawing_initial_screen.dart';
import '../../features/home/ui/home_screen.dart';

// ══════════════════════════════════════════════════════════
// ルート定義
//
// 現フェーズは Navigator.push による画面遷移を使用。
// go_router 導入時はここに集約する。
//
// 各機能の画面クラスをここでのみ import し、
// 画面間の依存を一本化する。
// ══════════════════════════════════════════════════════════
abstract class AppRouter {
  /// ホーム画面（アプリ起動時のルート）
  static Widget get home => const HomeScreen();

  /// X秒ドローイング準備画面へのルート
  static Route<void> drawing() => MaterialPageRoute(
        builder: (_) => const DrawingInitialScreen(),
      );

  // ── 将来実装予定 ─────────────────────────────────────────
  // static Route<void> topic()     => MaterialPageRoute(builder: (_) => const TopicMainScreen());
  // static Route<void> growth()    => MaterialPageRoute(builder: (_) => const GrowthMainScreen());
  // static Route<void> habit()     => MaterialPageRoute(builder: (_) => const HabitMainScreen());
  // static Route<void> proLesson() => MaterialPageRoute(builder: (_) => const ProLessonSelectScreen());
}
