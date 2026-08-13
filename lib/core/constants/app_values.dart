// ══════════════════════════════════════════════════════════
// アプリ全体の数値・設定値定数
//
// 仕様変更時の修正箇所をここに集約する。
// ══════════════════════════════════════════════════════════
abstract class AppValues {
  // ── レイアウト ──────────────────────────────────────────
  /// 外側パディングの割合（画面幅に対する比率）
  static const double outerPadRatio = 0.05;

  /// 外側パディングの最小値（px）
  static const double outerPadMin = 8.0;

  /// 外側パディングの最大値（px）
  static const double outerPadMax = 240.0;

  // ── X秒ドローイング ─────────────────────────────────────
  /// 開始カウントダウン秒数
  static const int drawingCountdownSec = 3;

  /// 設定：切り替え時間の下限（秒）
  static const int drawingDurationMinSec = 30;

  /// 設定：切り替え時間の上限（秒）
  static const int drawingDurationMaxSec = 600;

  /// 設定：切り替え時間の変更単位（秒）
  static const int drawingDurationStepSec = 30;

  /// 設定：最大作業時間の下限（分）
  static const int drawingMaxWorkTimeMinMin = 1;

  /// 設定：最大作業時間の上限（分）
  static const int drawingMaxWorkTimeMaxMin = 100;

  /// 設定：最大作業時間の変更単位（分）
  static const int drawingMaxWorkTimeStepMin = 1;

  /// 最大作業時間「無制限」を表す値
  static const int drawingMaxWorkTimeUnlimited = 0;

  /// ドットインジケーターを表示する最大枚数
  static const int drawingDotIndicatorMaxCount = 20;

  // ── アセットパス ────────────────────────────────────────
  /// ポーズモデル画像の格納フォルダ
  static const String modelAssetFolder = 'assets/images/models/';

  // ── モデルカテゴリ ──────────────────────────────────────
  // NOTE: カテゴリ定義順は DrawingConfig.categories のリスト順で管理する

  // ── 習慣化サポート ───────────────────────────────────────
  /// 設定：メリハリタイマー 作業時間の下限（分）
  static const int habitTimerMinMinutes = 1;

  /// 設定：メリハリタイマー 作業時間の上限（分）
  static const int habitTimerMaxMinutes = 120;

  /// 設定：メリハリタイマー 休憩時間の下限（分）
  static const int habitBreakMinMinutes = 1;

  /// 設定：メリハリタイマー 休憩時間の上限（分）
  static const int habitBreakMaxMinutes = 60;

  /// 継続カレンダー：連続記録が濃い黄色になる日数のしきい値
  static const int habitStreakDarkThresholdDays = 21;

  // ── Hive typeId 一覧（重複登録防止のため一元管理） ─────
  // GrowthRecord   : typeId = 0  （実装済み）
  // HabitRecord    : typeId = 1  （未実装）
  // TopicHistory   : typeId = 2  （未実装）
  // AppSettings    : typeId = 3  （未実装）
}
