import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_values.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/components/app_bar_widget.dart';
import '../domain/growth_record.dart';
import '../state/growth_provider.dart';

// ══════════════════════════════════════════════════════════
// 成長記録 メイン画面
//
// 登録済み画像のサムネグリッドとアップロードボタンを表示する。
// レイアウト・配色は features/drawing/ui/model_list_screen.dart に
// 準拠し、機能間でのUI一貫性を保つ。
//
// データは growthProvider（GrowthNotifier）経由でHiveから取得する。
// サムネを長押しすると選択モードに入り、指を離さずドラッグすると
// 長押し開始位置〜現在位置の範囲（一覧の並び順）を連続選択できる。
// 選択後はAppBarの削除ボタンでまとめて削除できる。
//
//   絞込・SNS投稿・ダウンロード・PDF等は次のステップで対応する。
//
// ⚠ 範囲選択の座標→インデックス変換は、GridViewのレイアウト定数
//   （crossAxisSpacing/mainAxisSpacing/childAspectRatio等）を
//   _GrowthThumbnailGrid 側と手動で一致させる方式（幾何計算）。
//   両者を変更する際は必ずセットで直すこと。
//   また、画面外（未スクロール領域）へのドラッグ時の自動スクロールは
//   現フェーズ未対応（表示中の範囲内でのドラッグ選択のみ）。
// ══════════════════════════════════════════════════════════
class GrowthMainScreen extends ConsumerStatefulWidget {
  const GrowthMainScreen({super.key});

  @override
  ConsumerState<GrowthMainScreen> createState() => _GrowthMainScreenState();
}

class _GrowthMainScreenState extends ConsumerState<GrowthMainScreen> {
  final Set<String> _selectedIds = {};
  final ScrollController _scrollController = ScrollController();

  /// ドラッグ選択の起点インデックス（長押し中のみ非null）
  int? _dragAnchorIndex;

  bool _isDownloading = false;

  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _cancelSelection() {
    setState(() {
      _selectedIds.clear();
      _dragAnchorIndex = null;
    });
  }

  void _onUploadTap(BuildContext context) {
    Navigator.push(context, AppRouter.growthUpload());
  }

  Future<void> _onDownloadTap(BuildContext context) async {
    if (_selectedIds.isEmpty || _isDownloading) return;
    setState(() => _isDownloading = true);
    try {
      final successCount = await ref
          .read(growthProvider.notifier)
          .downloadRecords(_selectedIds.toList());
      if (!mounted) return;
      final failureCount = _selectedIds.length - successCount;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failureCount > 0
                ? AppStrings.growthDownloadFailure
                : '$successCount${AppStrings.growthDownloadSuccessSuffix}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _onDeleteTap(BuildContext context) async {
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.growthDeleteDialogTitle),
        content:
            Text('$count${AppStrings.growthDeleteDialogMessageSuffix}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(AppStrings.growthDeleteDialogCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              AppStrings.growthDeleteDialogConfirm,
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ids = _selectedIds.toList();
    setState(() => _selectedIds.clear());
    await ref.read(growthProvider.notifier).deleteRecords(ids);
  }

  // ── ローカル座標 → サムネイルのインデックス変換（幾何計算） ──
  // _GrowthThumbnailGrid のGridView設定（列数・余白・アスペクト比）と
  // 必ず一致させること。
  int? _indexFromLocalPosition({
    required Offset localPosition,
    required int crossAxisCount,
    required double outerPad,
    required double gridBoxWidth,
    required int itemCount,
  }) {
    if (itemCount == 0) return null;

    const double crossSpacing = 10;
    const double mainSpacing = 10;
    const double childAspectRatio = 0.75;
    const double topPad = 12;

    final double contentWidth = gridBoxWidth - outerPad * 2;
    final double colWidth =
        (contentWidth - (crossAxisCount - 1) * crossSpacing) /
            crossAxisCount;
    final double rowHeight = colWidth / childAspectRatio;

    final double scrollOffset =
        _scrollController.hasClients ? _scrollController.offset : 0.0;

    final double adjX = localPosition.dx - outerPad;
    final double adjY = localPosition.dy - topPad + scrollOffset;

    int col = (adjX / (colWidth + crossSpacing)).floor();
    col = col.clamp(0, crossAxisCount - 1);

    int row = (adjY / (rowHeight + mainSpacing)).floor();
    if (row < 0) row = 0;

    int index = row * crossAxisCount + col;
    if (index < 0) index = 0;
    if (index > itemCount - 1) index = itemCount - 1;
    return index;
  }

  void _onDragSelectStart(
    Offset localPosition,
    int crossAxisCount,
    double outerPad,
    double gridBoxWidth,
    List<GrowthRecord> records,
  ) {
    final index = _indexFromLocalPosition(
      localPosition: localPosition,
      crossAxisCount: crossAxisCount,
      outerPad: outerPad,
      gridBoxWidth: gridBoxWidth,
      itemCount: records.length,
    );
    if (index == null) return;
    setState(() {
      _dragAnchorIndex = index;
      _selectedIds
        ..clear()
        ..add(records[index].id);
    });
  }

  void _onDragSelectUpdate(
    Offset localPosition,
    int crossAxisCount,
    double outerPad,
    double gridBoxWidth,
    List<GrowthRecord> records,
  ) {
    if (_dragAnchorIndex == null) return;
    final index = _indexFromLocalPosition(
      localPosition: localPosition,
      crossAxisCount: crossAxisCount,
      outerPad: outerPad,
      gridBoxWidth: gridBoxWidth,
      itemCount: records.length,
    );
    if (index == null) return;

    final start = _dragAnchorIndex!;
    final lo = start < index ? start : index;
    final hi = start < index ? index : start;

    setState(() {
      _selectedIds
        ..clear()
        ..addAll(records.sublist(lo, hi + 1).map((r) => r.id));
    });
  }

  void _onDragSelectEnd() {
    _dragAnchorIndex = null;
  }

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(growthProvider);

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBarWidget(
              title:
                  '${_selectedIds.length}${AppStrings.growthSelectionCountSuffix}',
              backgroundColor: AppColors.theme,
              onBackPressed: _cancelSelection,
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _onDeleteTap(context),
                ),
              ],
            )
          : AppBarWidget(
              title: AppStrings.growthTitle,
              backgroundColor: AppColors.theme,
            ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double outerPad =
              (constraints.maxWidth * AppValues.outerPadRatio)
                  .clamp(AppValues.outerPadMin, AppValues.outerPadMax);
          final int crossAxisCount = constraints.maxWidth < 600
              ? 2
              : (constraints.maxWidth / 280.0).floor().clamp(2, 8);

          return Column(
            children: [
              // ── 件数 ─────────────────────────────────────
              Padding(
                padding:
                    EdgeInsets.fromLTRB(outerPad, 12, outerPad, 4),
                child: Row(
                  children: [
                    Text(
                      '${records.length} 件',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),

              // ── サムネグリッド（長押し開始→ドラッグで範囲選択） ──
              Expanded(
                child: records.isEmpty
                    ? const _GrowthEmptyState()
                    : GestureDetector(
                        onLongPressStart: (details) => _onDragSelectStart(
                          details.localPosition,
                          crossAxisCount,
                          outerPad,
                          constraints.maxWidth,
                          records,
                        ),
                        onLongPressMoveUpdate: (details) =>
                            _onDragSelectUpdate(
                          details.localPosition,
                          crossAxisCount,
                          outerPad,
                          constraints.maxWidth,
                          records,
                        ),
                        onLongPressEnd: (_) => _onDragSelectEnd(),
                        child: _GrowthThumbnailGrid(
                          records: records,
                          outerPad: outerPad,
                          crossAxisCount: crossAxisCount,
                          scrollController: _scrollController,
                          isSelectionMode: _isSelectionMode,
                          selectedIds: _selectedIds,
                          onToggleSelect: _toggleSelection,
                          onOpenFullImage: (record) => Navigator.push(
                            context,
                            AppRouter.growthFullImage(
                              initialRecord: record,
                              allRecords: records,
                            ),
                          ),
                        ),
                      ),
              ),

              // ── イラストを追加／イラストを保存ボタン ──────────
              Padding(
                padding: EdgeInsets.fromLTRB(outerPad, 12, outerPad, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.theme,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _onUploadTap(context),
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(
                          AppStrings.growthUploadButton,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.theme,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade500,
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: (_selectedIds.isEmpty || _isDownloading)
                            ? null
                            : () => _onDownloadTap(context),
                        icon: _isDownloading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.download_outlined),
                        label: Text(
                          AppStrings.growthDownloadButton,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// データなし空状態
//
// model_list_screen.dart の _ModelListEmptyState に準拠。
// ══════════════════════════════════════════════════════════
class _GrowthEmptyState extends StatelessWidget {
  const _GrowthEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_search, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            AppStrings.growthEmptyState,
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// サムネグリッド
//
// model_list_screen.dart の _ModelThumbnailGrid に準拠
// （余白・アスペクト比を踏襲）。
//
// ⚠ crossAxisCount は親（_GrowthMainScreenState）で計算した値を
//   受け取る。親のドラッグ選択の座標計算と必ず同じ値を使うため、
//   このWidget内では独自に再計算しない。
// ══════════════════════════════════════════════════════════
class _GrowthThumbnailGrid extends StatelessWidget {
  final List<GrowthRecord> records;
  final double outerPad;
  final int crossAxisCount;
  final ScrollController scrollController;
  final bool isSelectionMode;
  final Set<String> selectedIds;
  final void Function(String id) onToggleSelect;
  final void Function(GrowthRecord record) onOpenFullImage;

  const _GrowthThumbnailGrid({
    required this.records,
    required this.outerPad,
    required this.crossAxisCount,
    required this.scrollController,
    required this.isSelectionMode,
    required this.selectedIds,
    required this.onToggleSelect,
    required this.onOpenFullImage,
  });

  @override
  Widget build(BuildContext context) {
    // 情報エリア（日付バッジ・連番・所要時間）の高さを考慮してアスペクト比を調整
    // ⚠ 親の座標計算（_indexFromLocalPosition）と同じ値にすること
    const double childAspectRatio = 0.75;

    return GridView.builder(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(outerPad, 12, outerPad, 12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return _GrowthThumbnailCard(
          record: record,
          isSelected: selectedIds.contains(record.id),
          onTap: () => isSelectionMode
              ? onToggleSelect(record.id)
              : onOpenFullImage(record),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════
// 成長記録サムネイルカード
//
// model_list_screen.dart の _ModelThumbnailCard に準拠。
// ・画像エリア（Expanded・grey.shade100背景、Image.fileで実画像を表示）
// ・情報エリア（高さ68固定・白背景）
//   - 日付バッジ（テーマカラーの薄色ピル）
//   - 連番（アイコン＋太字）
//   - 所要時間（アイコン＋グレー文字、未入力時は非表示）
//
// ⚠ 長押し（範囲選択の開始）は親の _GrowthMainScreenState 側で
//   グリッド全体に対して一括処理している。このカード自体は
//   onTapのみを持つ（選択トグル or 拡大表示）。
// ══════════════════════════════════════════════════════════
class _GrowthThumbnailCard extends StatelessWidget {
  final GrowthRecord record;
  final bool isSelected;
  final VoidCallback onTap;

  const _GrowthThumbnailCard({
    required this.record,
    required this.isSelected,
    required this.onTap,
  });

  String get _dateBadgeLabel {
    final d = record.date;
    return '${d.month}/${d.day}';
  }

  String get _serialLabel =>
      '${record.serialNumber}${AppStrings.growthSerialSuffix}';

  String? get _durationLabel => record.durationSec != null
      ? '${record.durationSec}${AppStrings.growthDurationSecSuffix}'
      : null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? const BorderSide(color: AppColors.theme, width: 3)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 画像 ──
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: Colors.grey.shade100,
                    child: Image.file(
                      File(record.imagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                  // 選択中の半透明オーバーレイ＋チェックマーク
                  if (isSelected)
                    Container(
                      color: AppColors.theme.withOpacity(0.25),
                      child: const Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: EdgeInsets.all(6),
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.theme,
                            child: Icon(Icons.check,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // ── 情報エリア ──（高さ固定でサムネイル領域を確保）
            SizedBox(
              height: 68,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 日付バッジ
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.themeLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _dateBadgeLabel,
                        style: TextStyle(
                            fontSize: 10, color: AppColors.themeDark),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // 連番
                    Row(
                      children: [
                        const Icon(Icons.confirmation_number_outlined,
                            size: 13, color: AppColors.theme),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            _serialLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    // 所要時間（未入力時は非表示）
                    if (_durationLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Row(
                          children: [
                            Icon(Icons.timer_outlined,
                                size: 11, color: Colors.grey.shade500),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                _durationLabel!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
