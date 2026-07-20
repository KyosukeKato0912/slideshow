import '../../../core/services/notification_service.dart';
import '../domain/habit_settings.dart';
import '../domain/habit_settings_repository.dart';

// ══════════════════════════════════════════════════════════
// 習慣化サポート 設定 コントローラー（state/ 層）
//
// ui/ → state/ のみ参照というレイヤー依存ルールに沿って、
// HabitSettingsRepository（domain/）とNotificationService（data/services/相当）
// への直接アクセスをこの薄いラッパーに集約する。
// 設定の保存・リセットに伴う通知スケジュールの更新もここで完結させ、
// ui/ 側は保存/リセットを呼ぶだけでよい形にする。
//
// ⚠ Riverpodは使わない：
//   設定値の読み書きは設定画面内で完結し、メリハリタイマー
//   （HabitTimerNotifier）のように画面をまたいで状態を維持し
//   続ける必要がない。そのため habit_timer_notifier.dart と
//   異なりStateNotifier化はせず、Repositoryの呼び出し口を
//   1枚挟むだけのシンプルなControllerとして提供する。
//   （Riverpod化 vs 非Riverpodの使い分け基準は
//     構成設計④命名規則・設計指針を参照）
// ══════════════════════════════════════════════════════════
class HabitSettingsController {
  HabitSettingsController._();

  // ── デフォルト値（UI初期表示用にそのまま転送）────────────
  static const bool defaultIsPreset = HabitSettingsRepository.defaultIsPreset;
  static const int defaultTimerMinutes =
      HabitSettingsRepository.defaultTimerMinutes;
  static const int defaultBreakMinutes =
      HabitSettingsRepository.defaultBreakMinutes;
  static const int defaultCustomTimerMinutes =
      HabitSettingsRepository.defaultCustomTimerMinutes;
  static const int defaultCustomBreakMinutes =
      HabitSettingsRepository.defaultCustomBreakMinutes;
  static const bool defaultReminderEnabled =
      HabitSettingsRepository.defaultReminderEnabled;
  static const int defaultReminderHour =
      HabitSettingsRepository.defaultReminderHour;
  static const int defaultReminderMinute =
      HabitSettingsRepository.defaultReminderMinute;
  static const bool defaultComebackEnabled =
      HabitSettingsRepository.defaultComebackEnabled;
  static const HabitComebackPeriod defaultComebackPeriod =
      HabitSettingsRepository.defaultComebackPeriod;

  /// 保存済み設定を読み込む
  static Future<HabitSettings?> load() => HabitSettingsRepository.load();

  /// 設定を保存し、通知スケジュールも合わせて更新する
  static Future<void> save({
    required bool isPreset,
    required int timerMinutes,
    required int breakMinutes,
    required bool reminderEnabled,
    required int reminderHour,
    required int reminderMinute,
    required bool comebackEnabled,
    required HabitComebackPeriod comebackPeriod,
  }) async {
    await HabitSettingsRepository.save(
      isPreset: isPreset,
      timerMinutes: timerMinutes,
      breakMinutes: breakMinutes,
      reminderEnabled: reminderEnabled,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
      comebackEnabled: comebackEnabled,
      comebackPeriod: comebackPeriod,
    );
    await _syncNotifications(
      reminderEnabled: reminderEnabled,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
      comebackEnabled: comebackEnabled,
    );
  }

  /// 設定をクリアし（デフォルトに戻す）、通知スケジュールもデフォルトで更新する
  static Future<void> clear() async {
    await HabitSettingsRepository.clear();
    await _syncNotifications(
      reminderEnabled: defaultReminderEnabled,
      reminderHour: defaultReminderHour,
      reminderMinute: defaultReminderMinute,
      comebackEnabled: defaultComebackEnabled,
    );
  }

  // ── 通知スケジュールの同期 ────────────────────────────
  static Future<void> _syncNotifications({
    required bool reminderEnabled,
    required int reminderHour,
    required int reminderMinute,
    required bool comebackEnabled,
  }) async {
    // 作業開始促進通知スケジュールを更新
    if (reminderEnabled) {
      await NotificationService.scheduleReminder(
          hour: reminderHour, minute: reminderMinute);
    } else {
      await NotificationService.cancelReminder();
    }
    // 復帰促進通知スケジュールを更新
    // カレンダーデータ永続化実装後は最終練習日を渡す形に差し替え。
    // 現時点では通知ON/OFFのみ反映（スケジュール自体はカレンダー記録時に登録される）。
    if (!comebackEnabled) {
      await NotificationService.cancelComeback();
    }
  }
}
