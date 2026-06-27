// ══════════════════════════════════════════════════════════
// 習慣化サポート 設定データクラス
//
// SharedPreferences から読み出した設定値のコンテナ。
// HabitSettingsRepository のみが生成する。
// ══════════════════════════════════════════════════════════
class HabitSettings {
  /// メリハリタイマーのカウントダウン時間（分）
  final int timerMinutes;

  const HabitSettings({
    required this.timerMinutes,
  });
}
