import 'package:flutter/material.dart';
import '../../features/drawing/domain/drawing_model.dart';
import '../../features/drawing/domain/drawing_settings.dart';
import '../../features/drawing/ui/drawing_initial_screen.dart';
import '../../features/drawing/ui/drawing_main_screen.dart';
import '../../features/drawing/ui/drawing_settings_screen.dart';
import '../../features/drawing/ui/model_list_screen.dart';
import '../../features/habit/ui/habit_main_screen.dart';
import '../../features/habit/ui/habit_settings_screen.dart';
import '../../features/habit/ui/habit_timer_screen.dart';
import '../../features/home/ui/home_screen.dart';
import '../../shared/patterns/full_image_screen.dart';

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

  /// モデル一覧画面へのルート
  ///
  /// [DrawingInitialScreen] から呼び出す。
  static Route<void> drawingModelList() => MaterialPageRoute(
        builder: (_) => const ModelListScreen(),
      );

  /// X秒ドローイング 設定画面へのルート
  ///
  /// [DrawingInitialScreen] から呼び出す。
  static Route<void> drawingSettings() => MaterialPageRoute(
        builder: (_) => const DrawingSettingsScreen(),
      );

  /// 拡大表示画面へのルート
  ///
  /// [ModelListScreen] から呼び出す。[initialAsset] に最初に表示するモデル、
  /// [allAssets] にペア検索用の全モデル一覧を渡すこと。
  static Route<void> drawingFullImage({
    required DrawingModel initialAsset,
    required List<DrawingModel> allAssets,
  }) =>
      MaterialPageRoute(
        builder: (_) => FullImageScreen(
          initialAsset: initialAsset,
          allAssets: allAssets,
        ),
      );

  /// 習慣化サポート メイン画面へのルート
  static Route<void> habit() => MaterialPageRoute(
        builder: (_) => const HabitMainScreen(),
      );

  /// メリハリタイマー画面へのルート
  ///
  /// [initialMinutes] / [initialBreakMinutes] を指定した場合、その値で
  /// タイマーを初期化する（習慣化サポート設定画面の「保存して開始」から使用）。
  /// 省略時は保存済み設定（HabitSettingsRepository）から読み込まれる。
  static Route<void> habitTimer({
    int? initialMinutes,
    int? initialBreakMinutes,
  }) =>
      MaterialPageRoute(
        builder: (_) => HabitTimerScreen(
          initialMinutes: initialMinutes,
          initialBreakMinutes: initialBreakMinutes,
        ),
      );

  /// 習慣化サポート設定画面へのルート
  static Route<void> habitSettings() => MaterialPageRoute(
        builder: (_) => const HabitSettingsScreen(),
      );

  // ── 将来実装予定 ─────────────────────────────────────────
  // static Route<void> topic()     => MaterialPageRoute(builder: (_) => const TopicMainScreen());
  // static Route<void> growth()    => MaterialPageRoute(builder: (_) => const GrowthMainScreen());
  // static Route<void> proLesson() => MaterialPageRoute(builder: (_) => const ProLessonSelectScreen());
}
