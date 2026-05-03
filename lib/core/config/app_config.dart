// ══════════════════════════════════════════════════════════
// アプリ全体のフィーチャーフラグ・共通設定
//
// 機能のリリース管理はここで一元管理する。
// 新機能を実装したら対応するフラグを true に変更すること。
// ══════════════════════════════════════════════════════════
abstract class AppConfig {
  // ── 機能リリースフラグ ──────────────────────────────────
  // true  → ホームボタン有効（実装済み・リリース対象）
  // false → ホームボタン無効（未実装・準備中）
  static const bool featureXSecDrawing    = true;  // X秒ドローイング
  static const bool featureTopicGenerator = false; // お題ジェネレーター
  static const bool featureGrowthRecord   = false; // 成長記録
  static const bool featureHabitSupport   = false; // 習慣化サポート
  static const bool featureProLesson      = false; // プロ絵師解説
}
