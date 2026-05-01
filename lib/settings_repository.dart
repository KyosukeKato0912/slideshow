import 'package:shared_preferences/shared_preferences.dart';

// ══════════════════════════════════════════════════════════
// 設定の永続化（SharedPreferences ラッパー）
// ══════════════════════════════════════════════════════════
class SettingsRepository {
  SettingsRepository._();

  static const _keySlideDuration   = 'slide_duration_sec';
  static const _keyLoop            = 'loop';
  static const _keyShuffle         = 'shuffle';
  static const _keySelectedCategories = 'selected_categories';

  /// 設定を保存する
  static Future<void> save({
    required int slideDurationSec,
    required bool loop,
    required bool shuffle,
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
      slideDurationSec:     prefs.getInt(_keySlideDuration) ?? 5,
      loop:                 prefs.getBool(_keyLoop) ?? false,
      shuffle:              prefs.getBool(_keyShuffle) ?? true,
      selectedCategories:   prefs.getStringList(_keySelectedCategories) ?? [],
    );
  }
}

/// SharedPreferences から読み出した設定値のコンテナ
class SavedSettings {
  final int slideDurationSec;
  final bool loop;
  final bool shuffle;
  final List<String> selectedCategories;

  const SavedSettings({
    required this.slideDurationSec,
    required this.loop,
    required this.shuffle,
    required this.selectedCategories,
  });
}
