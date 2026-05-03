// ══════════════════════════════════════════════════════════
// アプリ全体のUI文字列定数
//
// ハードコード文字列を排除し、将来の多言語化（l10n）に備える。
// ══════════════════════════════════════════════════════════
abstract class AppStrings {
  // ── アプリ共通 ──────────────────────────────────────────
  static const String appTitle = 'イラスト練習支援アプリ';

  // ── ホーム画面 ──────────────────────────────────────────
  static const String homeTitle = 'ホーム画面';
  static const String featureDrawing = 'X秒ドローイング';
  static const String featureTopic = 'お題ジェネレーター';
  static const String featureGrowth = '成長記録';
  static const String featureHabit = '習慣化サポート';
  static const String featureProLesson = 'プロ絵師解説';
  static const String featureComingSoon = '準備中';

  // ── X秒ドローイング ─────────────────────────────────────
  static const String drawingInitialTitle = 'X秒ドローイング準備';
  static const String drawingMainTitle = 'X秒ドローイング';
  static const String drawingSettingsTitle = 'X秒ドローイング設定';
  static const String drawingModelListTitle = 'X秒ドローイングモデル一覧';
  static const String enlargeViewTitle = '拡大表示';

  static const String drawingStartPrompt = 'X秒ドローイングを開始しますか？';
  static const String drawingStartDescription =
      '開始すると3秒のカウントダウン後に\n画像が自動再生されます';
  static const String drawingStartButton = 'すぐに開始';
  static const String drawingLoadingButton = '画像を読み込み中...';
  static const String drawingModelListButton = 'モデル一覧';
  static const String drawingSettingsButton = '設定';

  static const String drawingCountdownLabel = 'まもなく開始します';
  static const String drawingEndLabel = 'END';
  static const String drawingRestartButton = '最初から';
  static const String drawingPauseLabel = '停止';
  static const String drawingSecLabel = '秒';
  static const String drawingPinchHint = 'ピンチ操作で拡大・縮小できます';

  static const String drawingSavedSettings = '保存済みの設定';
  static const String drawingDefaultSettings = 'デフォルト設定';
  static const String drawingAllCategories = '全カテゴリ';
  static const String drawingLoopBadge = 'ループ';
  static const String drawingShuffleBadge = 'シャッフル';
  static const String drawingRandomOrder = 'ランダム';
  static const String drawingRegisteredOrder = '登録順';

  static const String drawingSettingsDurationTitle = '⏱ 画像切り替え時間';
  static const String drawingSettingsLoopTitle = '🔁 ループ再生';
  static const String drawingSettingsShuffleTitle = '🔀 再生順序';
  static const String drawingSettingsCategoryTitle = '🗂 表示するカテゴリ';
  static const String drawingSettingsSaveButton = '保存';
  static const String drawingSettingsSaveAndStartButton = '保存して開始';
  static const String drawingSettingsSaved = '設定を保存しました';
  static const String drawingSettingsReset = '設定を初期値に戻しました';
  static const String drawingSettingsResetTitle = '設定を初期値に戻す';
  static const String drawingSettingsResetMessage =
      'すべての設定をデフォルト値に戻します。よろしいですか？';
  static const String drawingSettingsCategoryWarning =
      '⚠ カテゴリを1つ以上選択してください';
  static const String drawingSettingsSelectAll = 'すべて選択';

  static const String drawingToggleHeightButton = '頭身切り替え';
  static const String drawingNoPairLabel = 'ペアなし';
  static const String drawingAuthorPrefix = '作者：';

  // ── モデル一覧 ──────────────────────────────────────────
  static const String modelListCategoryLabel = 'カテゴリ';
  static const String modelListCategoryAll = 'すべて';
  static const String modelListModelNameLabel = 'モデル名';
  static const String modelListModelNameHint = 'モデル名で絞り込み...';
  static const String modelListFilterClear = 'フィルターをクリア';
  static const String modelListEmptyFiltered = '条件に一致する画像が見つかりません';
  static const String modelListEmptyNoImages = '画像が見つかりません';
  static const String modelListLoadError = '画像の読み込みに失敗しました';

  // ── 未実装画面 ──────────────────────────────────────────
  static const String proLessonDescription = 'プロ絵師によるテクニックを学ぶ画面です';
  static const String topicDescription = 'ランダムなお題を生成する画面です';
  static const String growthDescription = '練習の成長を記録・確認する画面です';
  static const String habitDescription = '毎日の練習習慣をサポートする画面です';

  // ── 共通ダイアログ ──────────────────────────────────────
  static const String dialogCancel = 'キャンセル';
  static const String dialogReset = 'リセット';
}
