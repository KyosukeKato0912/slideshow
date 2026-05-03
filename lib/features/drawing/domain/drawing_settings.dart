import 'drawing_model.dart';

// ══════════════════════════════════════════════════════════
// X秒ドローイング 設定値オブジェクト
//
// DrawingInitialScreen → DrawingMainScreen に渡す不変な設定データ。
// 状態（タイマー残り秒数など）はここに含まない。
// ══════════════════════════════════════════════════════════
class DrawingSettings {
  /// 1枚あたりの表示時間（秒）
  final int durationSec;

  /// 表示対象のモデルアセット一覧
  final List<DrawingModel> selectedModels;

  /// ループ再生するか
  final bool loop;

  /// シャッフル再生するか
  final bool shuffle;

  /// 最大作業時間（秒）。0 = 無制限。
  final int maxWorkTimeSec;

  const DrawingSettings({
    required this.durationSec,
    required this.selectedModels,
    this.loop = false,
    this.shuffle = true,
    this.maxWorkTimeSec = 0,
  });

  DrawingSettings copyWith({
    int? durationSec,
    List<DrawingModel>? selectedModels,
    bool? loop,
    bool? shuffle,
    int? maxWorkTimeSec,
  }) {
    return DrawingSettings(
      durationSec: durationSec ?? this.durationSec,
      selectedModels: selectedModels ?? this.selectedModels,
      loop: loop ?? this.loop,
      shuffle: shuffle ?? this.shuffle,
      maxWorkTimeSec: maxWorkTimeSec ?? this.maxWorkTimeSec,
    );
  }
}
