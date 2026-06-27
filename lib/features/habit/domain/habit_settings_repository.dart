import 'package:shared_preferences/shared_preferences.dart';
import 'habit_settings.dart';

// ══════════════════════════════════════════════════════════
// 習慣化サポート 設定の永続化リポジトリ
//
// SharedPreferences への直接アクセスをこのクラスに集約する。
// キーには 'habit_' プレフィックスを付与し、他機能との衝突を防ぐ。
// DrawingSettingsRepository と同じパターンを踏襲する。
// ══════════════════════════════════════════════════════════
class HabitSettingsRepository {
  HabitSettingsRepository._();

  // ── SharedPreferences キー ─────────────────────────────
  static const _keyTimerMinutes = 'habit_timer_minutes';

  // ── デフォルト値 ───────────────────────────────────────
  static const int defaultTimerMinutes = 25; // ポモドーロ標準値

  /// 設定を保存する
  static Future<void> save({
    required int timerMinutes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTimerMinutes, timerMinutes);
  }

  /// 設定を読み込む。未保存の場合は null を返す。
  static Future<HabitSettings?> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyTimerMinutes)) return null;
    return HabitSettings(
      timerMinutes: prefs.getInt(_keyTimerMinutes) ?? defaultTimerMinutes,
    );
  }
}
