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

  const DrawingSettings({
    required this.durationSec,
    required this.selectedModels,
    this.loop = false,
    this.shuffle = true,
  });

  DrawingSettings copyWith({
    int? durationSec,
    List<DrawingModel>? selectedModels,
    bool? loop,
    bool? shuffle,
  }) {
    return DrawingSettings(
      durationSec: durationSec ?? this.durationSec,
      selectedModels: selectedModels ?? this.selectedModels,
      loop: loop ?? this.loop,
      shuffle: shuffle ?? this.shuffle,
    );
  }
}
