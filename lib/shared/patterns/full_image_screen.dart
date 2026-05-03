import 'package:flutter/material.dart';
import '../../features/drawing/domain/drawing_model.dart';
import '../components/app_bar_widget.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

// ══════════════════════════════════════════════════════════
// モデル全体表示画面（shared パターン）
//
// 成長記録・X秒ドローイング モデル一覧から共用する画像全体表示画面。
// 現フェーズは DrawingModel のみ対応。
// 他機能が利用する際は [displaySource] 等で表示情報を切り替える。
//
// 機能：
//   - ピンチ操作による拡大・縮小（InteractiveViewer）
//   - ペアモデル（同名・異カテゴリ）がある場合は頭身切り替えボタンを表示
// ══════════════════════════════════════════════════════════
class FullImageScreen extends StatefulWidget {
  /// 最初に表示するモデルアセット
  final DrawingModel initialAsset;

  /// ペア検索に使用する全アセット一覧
  final List<DrawingModel> allAssets;

  /// AppBar の背景色（呼び出し機能のカラーに合わせる）
  final Color appBarColor;

  const FullImageScreen({
    super.key,
    required this.initialAsset,
    required this.allAssets,
    this.appBarColor = AppColors.drawing,
  });

  @override
  State<FullImageScreen> createState() => _FullImageScreenState();
}

class _FullImageScreenState extends State<FullImageScreen> {
  late DrawingModel _current;

  /// 同名モデルをカテゴリ順に並べたペアリスト（自身を含む）
  late final List<DrawingModel> _pairs;

  /// ペアが2件以上ある（= 切り替え可能）か
  bool get _hasPair => _pairs.length >= 2;

  // ペア内のカテゴリ表示優先順
  static const _pairCategoryOrder = ['ベーシック', 'デフォルメ'];

  static int _pairCategoryIndex(String category) {
    final index = _pairCategoryOrder.indexOf(category);
    return index == -1 ? _pairCategoryOrder.length : index;
  }

  @override
  void initState() {
    super.initState();
    _current = widget.initialAsset;

    _pairs = widget.allAssets
        .where((a) => a.modelName == widget.initialAsset.modelName)
        .toList()
      ..sort((a, b) => _pairCategoryIndex(a.category)
          .compareTo(_pairCategoryIndex(b.category)));
  }

  /// ペアリスト内で次のモデルに切り替える
  void _togglePair() {
    if (!_hasPair) return;
    final nextIndex = (_pairs.indexOf(_current) + 1) % _pairs.length;
    setState(() => _current = _pairs[nextIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_current.category.isNotEmpty)
              Text(
                _current.category,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.drawing.withAlpha(204),
                ),
              ),
            Text(_current.modelName, style: const TextStyle(fontSize: 16)),
            if (_current.author.isNotEmpty)
              Text(
                '${AppStrings.drawingAuthorPrefix}${_current.author}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
          ],
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: Image.asset(_current.path, fit: BoxFit.contain),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 頭身切り替えボタン ──────────────────────────
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _hasPair ? AppColors.drawing : Colors.grey.shade700,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade800,
                disabledForegroundColor: Colors.grey.shade600,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _hasPair ? _togglePair : null,
              icon: const Icon(Icons.swap_vert, size: 18),
              label: Text(
                _hasPair
                    ? '${AppStrings.drawingToggleHeightButton}（${_current.category}）'
                    : '${AppStrings.drawingToggleHeightButton}（${AppStrings.drawingNoPairLabel}）',
                style: const TextStyle(fontSize: 14),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              AppStrings.drawingPinchHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
