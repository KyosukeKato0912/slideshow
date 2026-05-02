import 'package:shared_preferences/shared_preferences.dart';

// ══════════════════════════════════════════════════════════
// 設定の永続化（SharedPreferences ラッパー）
// ══════════════════════════════════════════════════════════
class SettingsRepository {
  SettingsRepository._();

  static const _keySlideDuration      = 'slide_duration_sec';
  static const _keyLoop               = 'loop';
  static const _keyShuffle            = 'shuffle';
  static const _keySelectedCategories = 'selected_categories';

  // ── デフォルト値（設定リセット・初回起動時に使う） ────────
  static const int  defaultSlideDurationSec = 30;
  static const bool defaultLoop             = false;
  static const bool defaultShuffle          = true;
  // カテゴリのデフォルトは「全選択」のため null で表す（呼び出し側が解決する）

  /// 設定を保存する
  static Future<void> save({
    required int    slideDurationSec,
    required bool   loop,
    required bool   shuffle,
    required List<String> selectedCategories,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySlideDuration, slideDurationSec);
    await prefs.setBool(_keyLoop, loop);
    await prefs.setBool(_keyShuffle, shuffle);
    await prefs.setStringList(_keySelectedCategories, selectedCategories);
  }

  /// 保存済み設定を読み込む。
  /// 未保存の場合は null を返すのでデフォルト値は呼び出し側で対応する。
  static Future<SavedSettings?> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keySlideDuration)) return null;

    return SavedSettings(
      slideDurationSec:   prefs.getInt(_keySlideDuration)         ?? defaultSlideDurationSec,
      loop:               prefs.getBool(_keyLoop)                  ?? defaultLoop,
      shuffle:            prefs.getBool(_keyShuffle)               ?? defaultShuffle,
      selectedCategories: prefs.getStringList(_keySelectedCategories) ?? [],
    );
  }

  /// 保存済み設定をすべて削除する（デフォルト値に戻す）
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySlideDuration);
    await prefs.remove(_keyLoop);
    await prefs.remove(_keyShuffle);
    await prefs.remove(_keySelectedCategories);
  }
}

/// SharedPreferences から読み出した設定値のコンテナ
class SavedSettings {
  final int    slideDurationSec;
  final bool   loop;
  final bool   shuffle;
  final List<String> selectedCategories;

  const SavedSettings({
    required this.slideDurationSec,
    required this.loop,
    required this.shuffle,
    required this.selectedCategories,
  });
}
