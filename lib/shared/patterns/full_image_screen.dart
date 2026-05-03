import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_values.dart';
import '../../core/config/drawing_config.dart';
import '../../features/drawing/domain/drawing_model.dart';
import '../components/app_bar_widget.dart';

// ══════════════════════════════════════════════════════════
// 拡大表示画面（shared パターン）
//
// X秒ドローイング モデル一覧から遷移する拡大表示画面。
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

  /// AppBar・アクセントカラー（呼び出し機能のカラーに合わせる）
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

  /// _pairs 内の現在表示インデックス。
  /// indexOf によるオブジェクト参照比較を避けるためインデックスで管理する。
  late int _currentPairIndex;

  /// ペアが2件以上ある（= 切り替え可能）か
  bool get _hasPair => _pairs.length >= 2;

  // ペア内のカテゴリ表示優先順は DrawingConfig.categorySortIndex に従う

  @override
  void initState() {
    super.initState();
    _current = widget.initialAsset;

    _pairs = widget.allAssets
        .where((a) => a.modelName == widget.initialAsset.modelName)
        .toList()
      ..sort((a, b) => DrawingConfig.categorySortIndex(a.categoryId)
          .compareTo(DrawingConfig.categorySortIndex(b.categoryId)));

    // initialAsset に対応するインデックスをパスで特定する
    final idx = _pairs.indexWhere((a) => a.path == widget.initialAsset.path);
    _currentPairIndex = idx != -1 ? idx : 0;
  }

  /// ペアリスト内で次のモデルに切り替える
  void _togglePair() {
    if (!_hasPair) return;
    _currentPairIndex = (_currentPairIndex + 1) % _pairs.length;
    setState(() => _current = _pairs[_currentPairIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: AppStrings.enlargeViewTitle,
        backgroundColor: widget.appBarColor,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double outerPad =
              (constraints.maxWidth * AppValues.outerPadRatio)
                  .clamp(AppValues.outerPadMin, AppValues.outerPadMax);

          return Column(
            children: [
              // ── 情報バー（カテゴリ・モデル名・作者） ──────────────
              _InfoBar(
                model: _current,
                accentColor: widget.appBarColor,
                outerPad: outerPad,
              ),

              // ── 画像表示エリア ──────────────────────────────────
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: outerPad),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5.0,
                    child: Image.asset(_current.path, fit: BoxFit.contain),
                  ),
                ),
              ),

              // ── 頭身切り替えボタン ──────────────────────────────
              if (_hasPair)
                Padding(
                  padding:
                      EdgeInsets.fromLTRB(outerPad, 8, outerPad, 4),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.appBarColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _togglePair,
                    icon: const Icon(Icons.swap_vert, size: 18),
                    label: Text(
                      '${AppStrings.drawingToggleHeightButton}（${_current.categoryShortName}）',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),

              // ── ピンチヒント ────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                    outerPad, _hasPair ? 4 : 8, outerPad, 16),
                child: Text(
                  AppStrings.drawingPinchHint,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── 情報バー ───────────────────────────────────────────────
class _InfoBar extends StatelessWidget {
  final DrawingModel model;
  final Color accentColor;
  final double outerPad;

  const _InfoBar({
    required this.model,
    required this.accentColor,
    required this.outerPad,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: accentColor.withAlpha(20),
      padding: EdgeInsets.fromLTRB(outerPad, 8, outerPad, 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 2,
        children: [
          if (model.categoryName.isNotEmpty)
            _InfoChip(
              icon: Icons.folder_outlined,
              label: model.categoryName,
              color: accentColor,
            ),
          _InfoChip(
            icon: Icons.image_outlined,
            label: model.modelName,
            color: accentColor,
          ),
          if (model.authorName.isNotEmpty)
            _InfoChip(
              icon: Icons.brush_outlined,
              label: '${AppStrings.drawingAuthorPrefix}${model.authorName}',
              color: accentColor,
            ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color.withAlpha(180)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

