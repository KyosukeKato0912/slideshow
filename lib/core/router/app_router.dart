import 'package:flutter/material.dart';
import '../../features/drawing/domain/drawing_settings.dart';
import '../../features/drawing/ui/drawing_initial_screen.dart';
import '../../features/drawing/ui/drawing_main_screen.dart';
import '../../features/habit/ui/habit_main_screen.dart';
import '../../features/home/ui/home_screen.dart';

// ══════════════════════════════════════════════════════════
// ルート定義
//
// ⚠ 暫定実装：現フェーズは Navigator.push による画面遷移を使用。
//   go_router 導入時はここに GoRouter を集約する。
//
// 各機能の画面クラスをここでのみ import し、
// 画面間の依存を一本化する。
// DrawingSettingsScreen → DrawingMainScreen のような
// feature 内での遷移もここを経由することで、
// 画面間の直接 import を防ぐ。
// ══════════════════════════════════════════════════════════
abstract class AppRouter {
  /// ホーム画面（アプリ起動時のルート）
  static Widget get home => const HomeScreen();

  /// X秒ドローイング準備画面へのルート
  static Route<void> drawing() => MaterialPageRoute(
        builder: (_) => const DrawingInitialScreen(),
      );

  /// X秒ドローイング メイン画面へのルート
  ///
  /// [DrawingInitialScreen] および [DrawingSettingsScreen] から呼び出す。
  /// [settings] に確定済みの設定値を渡すこと。
  static Route<void> drawingMain(DrawingSettings settings) => MaterialPageRoute(
        builder: (_) => DrawingMainScreen(settings: settings),
      );

  /// 習慣化サポート メイン画面へのルート
  static Route<void> habit() => MaterialPageRoute(
        builder: (_) => const HabitMainScreen(),
      );

  // ── 将来実装予定 ─────────────────────────────────────────
  // static Route<void> topic()     => MaterialPageRoute(builder: (_) => const TopicMainScreen());
  // static Route<void> growth()    => MaterialPageRoute(builder: (_) => const GrowthMainScreen());
  // static Route<void> proLesson() => MaterialPageRoute(builder: (_) => const ProLessonSelectScreen());
}
