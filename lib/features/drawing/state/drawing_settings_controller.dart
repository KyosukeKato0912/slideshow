import '../domain/drawing_settings_repository.dart';

// UI から SavedDrawingSettings 型を参照できるよう re-export する。
// ui/ 層は domain/drawing_settings_repository.dart を直接 import しない。
export '../domain/drawing_settings_repository.dart' show SavedDrawingSettings;

// ══════════════════════════════════════════════════════════
// X秒ドローイング 設定 コントローラー（state/ 層）
//
// ui/ → state/ のみ参照というレイヤー依存ルールに沿って、
// DrawingSettingsRepository（domain/）への直接アクセスを
// この薄いラッパーに集約する。
//
// ⚠ Riverpodは使わない：
//   X秒ドローイングの設定は単一画面（設定画面・初期画面）内で
//   完結し、習慣化サポートのメリハリタイマーのように「画面を
//   離れても状態を保持し続ける」必然性がない。そのため
//   StateNotifier化はせず、Repositoryの呼び出し口を1枚挟む
//   だけのシンプルなControllerとして提供する。
//   （Riverpod化 vs 非Riverpodの使い分け基準は
//     構成設計④命名規則・設計指針を参照）
// ══════════════════════════════════════════════════════════
class DrawingSettingsController {
  DrawingSettingsController._();

  // ── デフォルト値（UI初期表示用にそのまま転送）────────────
  static const int defaultDurationSec =
      DrawingSettingsRepository.defaultDurationSec;
  static const bool defaultLoop = DrawingSettingsRepository.defaultLoop;
  static const bool defaultShuffle = DrawingSettingsRepository.defaultShuffle;
  static const int defaultMaxWorkTimeSec =
      DrawingSettingsRepository.defaultMaxWorkTimeSec;

  /// 保存済み設定を読み込む
  static Future<SavedDrawingSettings?> load() =>
      DrawingSettingsRepository.load();

  /// 設定を保存する
  static Future<void> save({
    required int durationSec,
    required bool loop,
    required bool shuffle,
    required List<String> selectedCategories,
    required int maxWorkTimeSec,
  }) =>
      DrawingSettingsRepository.save(
        durationSec: durationSec,
        loop: loop,
        shuffle: shuffle,
        selectedCategories: selectedCategories,
        maxWorkTimeSec: maxWorkTimeSec,
      );

  /// 設定をクリア（デフォルトに戻す）
  static Future<void> clear() => DrawingSettingsRepository.clear();
}
