// ══════════════════════════════════════════════════════════
// スライドショー設定データクラス
// ══════════════════════════════════════════════════════════
import 'app_assets.dart';

class SlideshowSettings {
  final int slideDurationSec;
  final List<AppAsset> selectedAssets; // String → AppAsset に変更
  final bool loop;
  final bool shuffle;

  const SlideshowSettings({
    required this.slideDurationSec,
    required this.selectedAssets,
    this.loop = false,
    this.shuffle = true,
  });

  SlideshowSettings copyWith({
    int? slideDurationSec,
    List<AppAsset>? selectedAssets,
    bool? loop,
    bool? shuffle,
  }) {
    return SlideshowSettings(
      slideDurationSec: slideDurationSec ?? this.slideDurationSec,
      selectedAssets: selectedAssets ?? this.selectedAssets,
      loop: loop ?? this.loop,
      shuffle: shuffle ?? this.shuffle,
    );
  }
}
