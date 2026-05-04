import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_values.dart';
import '../../../core/extensions/int_ext.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/components/app_bar_widget.dart';
import '../../../core/config/drawing_config.dart';
import '../domain/drawing_model.dart';
import '../domain/drawing_settings.dart';
import '../domain/drawing_settings_repository.dart';
import 'drawing_settings_screen.dart';
import 'model_list_screen.dart';

// ══════════════════════════════════════════════════════════
// X秒ドローイング 初期画面（準備画面）
//
// アセット一覧と保存済み設定を並行ロードし、
// 現在の設定サマリーを表示する。
// ── ボタン ──
//   [すぐに開始]  保存済み設定（または初期値）でドローイング開始
//   [モデル一覧]  ModelListScreen へ遷移
//   [設定]        DrawingSettingsScreen へ遷移し、戻り次第サマリーを更新
// ══════════════════════════════════════════════════════════
class DrawingInitialScreen extends StatefulWidget {
  const DrawingInitialScreen({super.key});

  @override
  State<DrawingInitialScreen> createState() => _DrawingInitialScreenState();
}

class _DrawingInitialScreenState extends State<DrawingInitialScreen> {
  Future<_InitialScreenData> _dataFuture =
      Future.value(_InitialScreenData(models: [], saved: null));

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadInitialData();
  }

  // ── データロード ──────────────────────────────────────
  static Future<_InitialScreenData> _loadInitialData() async {
    final results = await Future.wait([
      DrawingModelLoader.load(),
      DrawingSettingsRepository.load(),
    ]);
    return _InitialScreenData(
      models: results[0] as List<DrawingModel>,
      saved: results[1] as SavedDrawingSettings?,
    );
  }

  /// 設定画面から戻ったときにサマリーを最新化する
  Future<void> _refreshSettings() async {
    // モデルはキャッシュ済みなので再取得コストはゼロ
    final results = await Future.wait([
      DrawingModelLoader.load(),
      DrawingSettingsRepository.load(),
    ]);
    if (!mounted) return;
    setState(() {
      _dataFuture = Future.value(_InitialScreenData(
        models: results[0] as List<DrawingModel>,
        saved: results[1] as SavedDrawingSettings?,
      ));
    });
  }

  // ── ドローイング開始 ──────────────────────────────────
  void _startWithSavedSettings(_InitialScreenData data) {
    final saved = data.saved;
    final allModels = data.models;
    final categories = DrawingModelLoader.categories(allModels);

    // 保存済みカテゴリを検証し、存在しないものは除外
    final List<DrawingModel> selectedModels;
    if (saved != null && saved.selectedCategories.isNotEmpty) {
      final validIds = categories.map((c) => c.id).toSet();
      final valid =
          saved.selectedCategories.where(validIds.contains).toSet();
      selectedModels = valid.isNotEmpty
          ? allModels.where((m) => valid.contains(m.categoryId)).toList()
          : allModels; // 全カテゴリ無効なら全件
    } else {
      selectedModels = allModels; // 未保存 → 全件
    }

    final settings = DrawingSettings(
      durationSec:
          saved?.durationSec ?? DrawingSettingsRepository.defaultDurationSec,
      selectedModels: selectedModels,
      loop: saved?.loop ?? DrawingSettingsRepository.defaultLoop,
      shuffle: saved?.shuffle ?? DrawingSettingsRepository.defaultShuffle,
      maxWorkTimeSec: saved?.maxWorkTimeSec ??
          DrawingSettingsRepository.defaultMaxWorkTimeSec,
    );

    Navigator.push(context, AppRouter.drawingMain(settings));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: AppStrings.drawingInitialTitle,
        backgroundColor: AppColors.drawing,
      ),
      body: FutureBuilder<_InitialScreenData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          final isReady = snapshot.connectionState == ConnectionState.done &&
              !snapshot.hasError &&
              (snapshot.data?.models.isNotEmpty ?? false);
          final data = snapshot.data;

          return LayoutBuilder(
            builder: (context, constraints) {
              final double outerPad =
                  (constraints.maxWidth * AppValues.outerPadRatio)
                      .clamp(AppValues.outerPadMin, AppValues.outerPadMax);

              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: outerPad, vertical: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.slideshow,
                          size: 100, color: AppColors.drawing),
                      const SizedBox(height: 24),
                      Text(
                        AppStrings.drawingStartPrompt,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.drawingStartDescription,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // ── 設定サマリーカード ──────────────────
                      if (isReady && data != null)
                        DrawingSettingsSummaryCard(
                          models: data.models,
                          saved: data.saved,
                        ),

                      const SizedBox(height: 24),

                      // ── すぐに開始 ──────────────────────────
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isReady
                              ? AppColors.drawing
                              : Colors.grey.shade300,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isReady
                            ? () => _startWithSavedSettings(data!)
                            : null,
                        icon: isReady
                            ? const Icon(Icons.play_arrow)
                            : const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                        label: Text(
                          isReady
                              ? AppStrings.drawingStartButton
                              : AppStrings.drawingLoadingButton,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── モデル一覧 ──────────────────────────
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.drawing,
                          side: const BorderSide(color: AppColors.drawing),
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ModelListScreen()),
                        ),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(
                          AppStrings.drawingModelListButton,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── 設定 ────────────────────────────────
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.drawing,
                          side: const BorderSide(color: AppColors.drawing),
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const DrawingSettingsScreen()),
                          );
                          await _refreshSettings();
                        },
                        icon: const Icon(Icons.settings),
                        label: Text(
                          AppStrings.drawingSettingsButton,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── ロードデータコンテナ ─────────────────────────────────────
class _InitialScreenData {
  final List<DrawingModel> models;
  final SavedDrawingSettings? saved;

  const _InitialScreenData({required this.models, required this.saved});
}

// ══════════════════════════════════════════════════════════
// 設定サマリーカード（初期画面に表示）
// ══════════════════════════════════════════════════════════
class DrawingSettingsSummaryCard extends StatelessWidget {
  final List<DrawingModel> models;
  final SavedDrawingSettings? saved;

  const DrawingSettingsSummaryCard({
    super.key,
    required this.models,
    required this.saved,
  });

  @override
  Widget build(BuildContext context) {
    final categories = DrawingModelLoader.categories(models);
    final duration =
        saved?.durationSec ?? DrawingSettingsRepository.defaultDurationSec;
    final loop = saved?.loop ?? DrawingSettingsRepository.defaultLoop;
    final shuffle =
        saved?.shuffle ?? DrawingSettingsRepository.defaultShuffle;
    final maxWorkTimeSec =
        saved?.maxWorkTimeSec ?? DrawingSettingsRepository.defaultMaxWorkTimeSec;

    // 選択カテゴリの解決（selectedCats はカテゴリIDのSet）
    final categoryIds = categories.map((c) => c.id).toSet();
    final Set<String> selectedCats;
    if (saved == null || saved!.selectedCategories.isEmpty) {
      selectedCats = Set.of(categoryIds);
    } else {
      selectedCats =
          saved!.selectedCategories.where(categoryIds.contains).toSet();
      if (selectedCats.isEmpty) selectedCats.addAll(categoryIds);
    }
    final isAllCategories = selectedCats.length == categories.length;
    final imageCount =
        models.where((m) => selectedCats.contains(m.categoryId)).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.drawingLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.drawingBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, size: 14, color: AppColors.drawing.withAlpha(153)),
              const SizedBox(width: 4),
              Text(
                saved != null
                    ? AppStrings.drawingSavedSettings
                    : AppStrings.drawingDefaultSettings,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.drawing.withAlpha(153),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _SummaryChip(
                icon: Icons.timer_outlined,
                label: '${AppStrings.drawingSummaryDurationPrefix}: ${duration.toDisplayDuration()}',
              ),
              _SummaryChip(
                icon: Icons.image_outlined,
                label: '$imageCount 枚',
              ),
              _SummaryChip(
                icon: Icons.folder_outlined,
                label: isAllCategories
                    ? AppStrings.drawingAllCategories
                    : selectedCats
                        .map((id) =>
                            DrawingConfig.findCategory(id)?.shortName ?? id)
                        .join(' / '),
              ),
              if (loop)
                const _SummaryChip(
                  icon: Icons.repeat,
                  label: AppStrings.drawingLoopBadge,
                ),
              _SummaryChip(
                icon: shuffle ? Icons.shuffle : Icons.sort,
                label: shuffle
                    ? AppStrings.drawingShuffleBadge
                    : AppStrings.drawingRegisteredOrder,
              ),
              _SummaryChip(
                icon: Icons.hourglass_bottom_outlined,
                label: maxWorkTimeSec == AppValues.drawingMaxWorkTimeUnlimited
                    ? '${AppStrings.drawingSummaryMaxTimePrefix}: ${AppStrings.drawingSettingsMaxTimeUnlimited}'
                    : '${AppStrings.drawingSummaryMaxTimePrefix}: ${maxWorkTimeSec.toDisplayDuration()}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 設定チップ ──────────────────────────────────────────────
class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.drawingBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.drawing),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.drawing),
          ),
        ],
      ),
    );
  }
}
