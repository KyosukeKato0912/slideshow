import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_values.dart';

// ══════════════════════════════════════════════════════════
// X秒ドローイング 設定の永続化リポジトリ
//
// SharedPreferences への直接アクセスをこのクラスに集約する。
// state/ 層（DrawingSettingsNotifier）からのみ呼び出すこと。
// ══════════════════════════════════════════════════════════
class DrawingSettingsRepository {
  DrawingSettingsRepository._();

  // ── SharedPreferences キー ─────────────────────────────
  static const _keyDurationSec = 'slide_duration_sec';
  static const _keyLoop = 'loop';
  static const _keyShuffle = 'shuffle';
  static const _keySelectedCategories = 'selected_categories';
  static const _keyMaxWorkTimeSec = 'max_work_time_sec';

  // ── デフォルト値 ───────────────────────────────────────
  static const int defaultDurationSec = AppValues.drawingDurationMinSec;
  static const bool defaultLoop = false;
  static const bool defaultShuffle = true;
  static const int defaultMaxWorkTimeSec = AppValues.drawingMaxWorkTimeUnlimited;
  // カテゴリのデフォルトは「全選択」のため null で表す（呼び出し側が解決する）

  /// 設定を保存する
  static Future<void> save({
    required int durationSec,
    required bool loop,
    required bool shuffle,
    required List<String> selectedCategories,
    required int maxWorkTimeSec,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDurationSec, durationSec);
    await prefs.setBool(_keyLoop, loop);
    await prefs.setBool(_keyShuffle, shuffle);
    await prefs.setStringList(_keySelectedCategories, selectedCategories);
    await prefs.setInt(_keyMaxWorkTimeSec, maxWorkTimeSec);
  }

  static Future<SavedDrawingSettings?> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyDurationSec)) return null;

    return SavedDrawingSettings(
      durationSec: prefs.getInt(_keyDurationSec) ?? defaultDurationSec,
      loop: prefs.getBool(_keyLoop) ?? defaultLoop,
      shuffle: prefs.getBool(_keyShuffle) ?? defaultShuffle,
      selectedCategories:
          prefs.getStringList(_keySelectedCategories) ?? [],
      maxWorkTimeSec:
          prefs.getInt(_keyMaxWorkTimeSec) ?? defaultMaxWorkTimeSec,
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDurationSec);
    await prefs.remove(_keyLoop);
    await prefs.remove(_keyShuffle);
    await prefs.remove(_keySelectedCategories);
    await prefs.remove(_keyMaxWorkTimeSec);
  }
}

// ══════════════════════════════════════════════════════════
// SharedPreferences から読み出した設定値のコンテナ
// ══════════════════════════════════════════════════════════
class SavedDrawingSettings {
  final int durationSec;
  final bool loop;
  final bool shuffle;
  final List<String> selectedCategories;
  final int maxWorkTimeSec;

  const SavedDrawingSettings({
    required this.durationSec,
    required this.loop,
    required this.shuffle,
    required this.selectedCategories,
    required this.maxWorkTimeSec,
  });
}
