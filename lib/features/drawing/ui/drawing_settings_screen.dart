import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_values.dart';
import '../../../core/extensions/int_ext.dart';
import '../../../shared/components/app_bar_widget.dart';
import '../domain/drawing_model.dart';
import '../domain/drawing_settings.dart';
import '../domain/drawing_settings_repository.dart';
import 'drawing_main_screen.dart';

// ══════════════════════════════════════════════════════════
// X秒ドローイング 設定画面
// ══════════════════════════════════════════════════════════
class DrawingSettingsScreen extends StatefulWidget {
  const DrawingSettingsScreen({super.key});

  @override
  State<DrawingSettingsScreen> createState() => _DrawingSettingsScreenState();
}

class _DrawingSettingsScreenState extends State<DrawingSettingsScreen> {
  List<DrawingModel> _allModels = [];
  List<String> _categories = [];
  Set<String> _selectedCategories = {};

  int _durationSec = DrawingSettingsRepository.defaultDurationSec;
  bool _loop = DrawingSettingsRepository.defaultLoop;
  bool _shuffle = DrawingSettingsRepository.defaultShuffle;

  bool get _allCategoriesSelected =>
      _selectedCategories.length == _categories.length;

  bool get _canStart => _selectedCategories.isNotEmpty;

  List<DrawingModel> get _selectedModels => _allModels
      .where((m) => _selectedCategories.contains(m.category))
      .toList();

  @override
  void initState() {
    super.initState();
    _loadModelsAndSettings();
  }

  Future<void> _loadModelsAndSettings() async {
    try {
      final results = await Future.wait([
        DrawingModelLoader.load(),
        DrawingSettingsRepository.load(),
      ]);

      if (!mounted) return;

      final models = results[0] as List<DrawingModel>;
      final saved = results[1] as SavedDrawingSettings?;

      setState(() {
        _allModels = models;
        _categories = DrawingModelLoader.categories(models);

        if (saved != null) {
          _durationSec = saved.durationSec;
          _loop = saved.loop;
          _shuffle = saved.shuffle;
          final validCategories =
              saved.selectedCategories.where(_categories.contains).toSet();
          _selectedCategories = validCategories.isNotEmpty
              ? validCategories
              : Set.of(_categories);
        } else {
          _selectedCategories = Set.of(_categories);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('読み込みに失敗しました: $e')),
      );
    }
  }

  void _toggleAllCategories(bool select) {
    setState(() {
      _selectedCategories = select ? Set.of(_categories) : {};
    });
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  Future<void> _saveSettings() async {
    await DrawingSettingsRepository.save(
      durationSec: _durationSec,
      loop: _loop,
      shuffle: _shuffle,
      selectedCategories: _selectedCategories.toList(),
    );
  }

  Future<void> _onSaveOnly() async {
    await _saveSettings();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.drawingSettingsSaved),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _onSaveAndStart() async {
    await _saveSettings();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.drawingSettingsSaved),
        duration: const Duration(seconds: 2),
      ),
    );

    final settings = DrawingSettings(
      durationSec: _durationSec,
      selectedModels: _selectedModels,
      loop: _loop,
      shuffle: _shuffle,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => DrawingMainScreen(settings: settings)),
    );
  }

  Future<void> _onResetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.drawingSettingsResetTitle),
        content: Text(AppStrings.drawingSettingsResetMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.dialogCancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.dialogReset),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await DrawingSettingsRepository.clear();
    if (!mounted) return;

    setState(() {
      _durationSec = DrawingSettingsRepository.defaultDurationSec;
      _loop = DrawingSettingsRepository.defaultLoop;
      _shuffle = DrawingSettingsRepository.defaultShuffle;
      _selectedCategories = Set.of(_categories);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.drawingSettingsReset)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: AppStrings.drawingSettingsTitle,
        backgroundColor: AppColors.drawing,
        actions: [
          IconButton(
            tooltip: AppStrings.drawingSettingsResetTitle,
            icon: const Icon(Icons.restart_alt),
            onPressed: _allModels.isEmpty ? null : _onResetToDefaults,
          ),
        ],
      ),
      body: _allModels.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final double outerPad =
                    (constraints.maxWidth * AppValues.outerPadRatio)
                        .clamp(AppValues.outerPadMin, AppValues.outerPadMax);

                return ListView(
                  padding:
                      EdgeInsets.fromLTRB(outerPad, 24, outerPad, 24),
                  children: [
                    // ── 切り替え時間 ──────────────────────────
                    _SettingsSectionCard(
                      title: AppStrings.drawingSettingsDurationTitle,
                      child: _DurationSetting(
                        durationSec: _durationSec,
                        onDecrement: _durationSec > AppValues.drawingDurationMinSec
                            ? () => setState(() =>
                                _durationSec -= AppValues.drawingDurationStepSec)
                            : null,
                        onIncrement: _durationSec < AppValues.drawingDurationMaxSec
                            ? () => setState(() =>
                                _durationSec += AppValues.drawingDurationStepSec)
                            : null,
                        onSliderChanged: (v) => setState(() =>
                            _durationSec = (v.round() ~/
                                    AppValues.drawingDurationStepSec) *
                                AppValues.drawingDurationStepSec),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── ループ設定 ────────────────────────────
                    _SettingsSectionCard(
                      title: AppStrings.drawingSettingsLoopTitle,
                      child: SwitchListTile(
                        value: _loop,
                        activeColor: AppColors.drawing,
                        onChanged: (v) => setState(() => _loop = v),
                        title: Text(
                          _loop ? 'ループあり' : 'ループなし',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          _loop
                              ? '最後の画像の後、最初に戻って繰り返します'
                              : '最後の画像で停止します',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                        ),
                        secondary: Icon(
                          _loop ? Icons.repeat : Icons.trending_flat,
                          color: _loop ? AppColors.drawing : Colors.grey,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── 再生順序 ──────────────────────────────
                    _SettingsSectionCard(
                      title: AppStrings.drawingSettingsShuffleTitle,
                      child: SwitchListTile(
                        value: _shuffle,
                        activeColor: AppColors.drawing,
                        onChanged: (v) => setState(() => _shuffle = v),
                        title: Text(
                          _shuffle
                              ? AppStrings.drawingRandomOrder
                              : AppStrings.drawingRegisteredOrder,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          _shuffle
                              ? '画像をランダムな順番で再生します'
                              : '画像を登録された順番で再生します',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                        ),
                        secondary: Icon(
                          _shuffle ? Icons.shuffle : Icons.sort,
                          color: _shuffle ? AppColors.drawing : Colors.grey,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── カテゴリ選択 ──────────────────────────
                    _SettingsSectionCard(
                      title: AppStrings.drawingSettingsCategoryTitle,
                      child: _CategorySelector(
                        categories: _categories,
                        selectedCategories: _selectedCategories,
                        allModels: _allModels,
                        allCategoriesSelected: _allCategoriesSelected,
                        onToggleAll: _toggleAllCategories,
                        onToggleCategory: _toggleCategory,
                        selectedModelsCount: _selectedModels.length,
                      ),
                    ),

                    const SizedBox(height: 24),

                    if (!_canStart)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          AppStrings.drawingSettingsCategoryWarning,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),

                    // ── 保存 ／ 保存して開始 ──────────────────
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.drawing,
                              side: const BorderSide(color: AppColors.drawing),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _onSaveOnly,
                            icon: const Icon(Icons.save_outlined),
                            label: Text(
                              AppStrings.drawingSettingsSaveButton,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _canStart ? AppColors.drawing : Colors.grey,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _canStart ? _onSaveAndStart : null,
                            icon: const Icon(Icons.play_arrow),
                            label: Text(
                              AppStrings.drawingSettingsSaveAndStartButton,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
    );
  }
}

// ── 設定セクションカード ────────────────────────────────────
class _SettingsSectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsSectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

// ── 切り替え時間設定ウィジェット ────────────────────────────
class _DurationSetting extends StatelessWidget {
  final int durationSec;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final ValueChanged<double> onSliderChanged;

  const _DurationSetting({
    required this.durationSec,
    required this.onDecrement,
    required this.onIncrement,
    required this.onSliderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: onDecrement,
              icon: const Icon(Icons.remove_circle_outline),
              color: AppColors.drawing,
              iconSize: 32,
            ),
            const SizedBox(width: 12),
            Text(
              durationSec.toDisplayDuration(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.drawing,
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: onIncrement,
              icon: const Icon(Icons.add_circle_outline),
              color: AppColors.drawing,
              iconSize: 32,
            ),
          ],
        ),
        Slider(
          value: durationSec.toDouble(),
          min: AppValues.drawingDurationMinSec.toDouble(),
          max: AppValues.drawingDurationMaxSec.toDouble(),
          divisions: (AppValues.drawingDurationMaxSec -
                  AppValues.drawingDurationMinSec) ~/
              AppValues.drawingDurationStepSec,
          activeColor: AppColors.drawing,
          label: durationSec.toDisplayDuration(),
          onChanged: onSliderChanged,
        ),
        Text(
          '${AppValues.drawingDurationMinSec.toDisplayDuration()}〜'
          '${AppValues.drawingDurationMaxSec.toDisplayDuration()}'
          '（${AppValues.drawingDurationStepSec.toDisplayDuration()}単位）',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}

// ── カテゴリ選択ウィジェット ────────────────────────────────
class _CategorySelector extends StatelessWidget {
  final List<String> categories;
  final Set<String> selectedCategories;
  final List<DrawingModel> allModels;
  final bool allCategoriesSelected;
  final ValueChanged<bool> onToggleAll;
  final ValueChanged<String> onToggleCategory;
  final int selectedModelsCount;

  const _CategorySelector({
    required this.categories,
    required this.selectedCategories,
    required this.allModels,
    required this.allCategoriesSelected,
    required this.onToggleAll,
    required this.onToggleCategory,
    required this.selectedModelsCount,
  });

  /// 全選択 → true / 部分選択 → null（インジケーター） / 全解除 → false
  bool? get _checkboxValue {
    if (selectedCategories.isEmpty) return false;
    if (allCategoriesSelected) return true;
    return null; // 部分選択
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _checkboxValue,
              tristate: true,
              activeColor: AppColors.drawing,
              // null（部分選択）をタップ → 全選択、それ以外 → 現在値を反転
              onChanged: (_) => onToggleAll(!allCategoriesSelected),
            ),
            Text(
              AppStrings.drawingSettingsSelectAll,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '${selectedCategories.length} / ${categories.length} カテゴリ'
              '  （$selectedModelsCount 枚）',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        const Divider(),
        ...categories.map((category) {
          final selected = selectedCategories.contains(category);
          final count =
              allModels.where((m) => m.category == category).length;
          return CheckboxListTile(
            value: selected,
            activeColor: AppColors.drawing,
            title: Text(category),
            subtitle: Text('$count 枚', style: const TextStyle(fontSize: 11)),
            secondary: Icon(
              Icons.folder_outlined,
              color: selected ? AppColors.drawing : Colors.grey,
            ),
            onChanged: (_) => onToggleCategory(category),
          );
        }),
      ],
    );
  }
}
