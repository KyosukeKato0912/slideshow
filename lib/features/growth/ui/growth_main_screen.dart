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
// サムネを長押しすると選択モードに入り、複数選択→AppBarの削除ボタンで
// まとめて削除できる（構成設計の「長押し選択・ゴミ箱ボタン」仕様に対応）。
//
//   絞込・SNS投稿・ダウンロード・PDF等は次のステップで対応する。
// ══════════════════════════════════════════════════════════
class GrowthMainScreen extends ConsumerStatefulWidget {
  const GrowthMainScreen({super.key});

  @override
  ConsumerState<GrowthMainScreen> createState() => _GrowthMainScreenState();
}

class _GrowthMainScreenState extends ConsumerState<GrowthMainScreen> {
  final Set<String> _selectedIds = {};

  bool get _isSelectionMode => _selectedIds.isNotEmpty;

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
    setState(() => _selectedIds.clear());
  }

  void _onUploadTap(BuildContext context) {
    Navigator.push(context, AppRouter.growthUpload());
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

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(growthProvider);

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBarWidget(
              title: '${_selectedIds.length}${AppStrings.growthSelectionCountSuffix}',
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

              // ── サムネグリッド ────────────────────────────
              Expanded(
                child: records.isEmpty
                    ? const _GrowthEmptyState()
                    : _GrowthThumbnailGrid(
                        records: records,
                        outerPad: outerPad,
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

              // ── アップロードボタン ────────────────────────
              // 選択モード中は誤操作防止のため非表示にする
              if (!_isSelectionMode)
                Padding(
                  padding: EdgeInsets.fromLTRB(outerPad, 12, outerPad, 20),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.theme,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _onUploadTap(context),
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(
                      AppStrings.growthUploadButton,
                      style: const TextStyle(fontSize: 16),
                    ),
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
// （列数計算・余白・アスペクト比を踏襲）。
// ══════════════════════════════════════════════════════════
class _GrowthThumbnailGrid extends StatelessWidget {
  final List<GrowthRecord> records;
  final double outerPad;
  final bool isSelectionMode;
  final Set<String> selectedIds;
  final void Function(String id) onToggleSelect;
  final void Function(GrowthRecord record) onOpenFullImage;

  const _GrowthThumbnailGrid({
    required this.records,
    required this.outerPad,
    required this.isSelectionMode,
    required this.selectedIds,
    required this.onToggleSelect,
    required this.onOpenFullImage,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // スマホ（幅600未満）は2列固定、タブレット以上は幅に応じて増やす
        final int crossAxisCount = constraints.maxWidth < 600
            ? 2
            : (constraints.maxWidth / 280.0).floor().clamp(2, 8);

        // 情報エリア（日付バッジ・連番・所要時間）の高さを考慮してアスペクト比を調整
        const double childAspectRatio = 0.75;

        return GridView.builder(
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
              onLongPress: () => onToggleSelect(record.id),
            );
          },
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
// ・長押しで選択モードに入り、選択中はチェックマーク＋テーマカラー枠を表示
// ══════════════════════════════════════════════════════════
class _GrowthThumbnailCard extends StatelessWidget {
  final GrowthRecord record;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _GrowthThumbnailCard({
    required this.record,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
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
      onLongPress: onLongPress,
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
