import 'package:flutter/material.dart';
import 'app_assets.dart';

// ══════════════════════════════════════════════════════════
// モデル全体表示画面
// ペアモデル（同名・異カテゴリ）が存在する場合は「頭身切り替え」ボタンを表示。
// ══════════════════════════════════════════════════════════
class ImageViewerScreen extends StatefulWidget {
  /// 最初に表示するアセット
  final AppAsset initialAsset;

  /// 全アセット一覧（ペア検索に使用）
  final List<AppAsset> allAssets;

  const ImageViewerScreen({
    super.key,
    required this.initialAsset,
    required this.allAssets,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late AppAsset _current;

  // 同じモデル名で異なるカテゴリのアセット（ペア）一覧
  // 自分自身も含めてカテゴリ順に並べる
  late final List<AppAsset> _pairs;

  // ペアが存在する（自分以外に同名モデルがある）かどうか
  bool get _hasPair => _pairs.length >= 2;

  @override
  void initState() {
    super.initState();
    _current = widget.initialAsset;

    // ペア定義の優先カテゴリ順
    const pairOrder = ['全身頭身高', '全身頭身低'];
    int pairCategoryIndex(String cat) {
      final i = pairOrder.indexOf(cat);
      return i == -1 ? pairOrder.length : i;
    }

    // 同じモデル名を持つアセットをカテゴリ順に並べる
    _pairs = widget.allAssets
        .where((a) => a.modelName == widget.initialAsset.modelName)
        .toList()
      ..sort((a, b) =>
          pairCategoryIndex(a.category).compareTo(pairCategoryIndex(b.category)));
  }

  /// ペアの中で現在表示していない方に切り替える
  void _togglePair() {
    if (!_hasPair) return;
    final nextIndex =
        (_pairs.indexOf(_current) + 1) % _pairs.length;
    setState(() => _current = _pairs[nextIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_current.category.isNotEmpty)
              Text(
                _current.category,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.purple.shade200,
                ),
              ),
            Text(_current.modelName,
                style: const TextStyle(fontSize: 16)),
            if (_current.author.isNotEmpty)
              Text(
                '作者：${_current.author}',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade400),
              ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: Image.asset(
            _current.path,
            fit: BoxFit.contain,
          ),
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
                    _hasPair ? Colors.purple : Colors.grey.shade700,
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
                    ? '頭身切り替え（${_current.category}）'
                    : '頭身切り替え（ペアなし）',
                style: const TextStyle(fontSize: 14),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'ピンチ操作で拡大・縮小できます',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
