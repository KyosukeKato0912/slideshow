import 'package:flutter/material.dart';
import 'app_bar_helper.dart';
import 'app_assets.dart';
import 'slideshow_settings_model.dart';
import 'slideshow_screen.dart';
import 'settings_repository.dart';

export 'slideshow_settings_model.dart';

// ══════════════════════════════════════════════════════════
// スライドショー設定画面
// ══════════════════════════════════════════════════════════
class SlideshowSettingsScreen extends StatefulWidget {
  const SlideshowSettingsScreen({super.key});

  @override
  State<SlideshowSettingsScreen> createState() =>
      _SlideshowSettingsScreenState();
}

class _SlideshowSettingsScreenState extends State<SlideshowSettingsScreen> {
  // ══════════════════════════════════════════════════════
  // 画像切り替え時間の設定定数
  // ここを書き換えるだけで下限・上限・ステップが変わります
  // ══════════════════════════════════════════════════════
  static const int _durationMin  = 30;   // 下限（秒）
  static const int _durationMax  = 600;  // 上限（秒）
  static const int _durationStep = 30;   // 変更単位（秒）

  List<AppAsset> _allAssets = [];
  List<String> _categories = [];
  Set<String> _selectedCategories = {};

  int _slideDurationSec = SettingsRepository.defaultSlideDurationSec;
  bool _loop = false;
  bool _shuffle = true;

  bool get _allCategoriesSelected =>
      _selectedCategories.length == _categories.length;
  bool get _canStart => _selectedCategories.isNotEmpty;

  /// 秒数を「X秒」または「X分Y秒」に整形する
  static String _formatDuration(int sec) {
    if (sec < 60) return '$sec 秒';
    final m = sec ~/ 60;
    final s = sec % 60;
    return s == 0 ? '$m 分' : '$m 分 $s 秒';
  }

  List<AppAsset> get _selectedAssets => _allAssets
      .where((e) => _selectedCategories.contains(e.category))
      .toList();

  @override
  void initState() {
    super.initState();
    _loadAssetsAndSettings();
  }

  Future<void> _loadAssetsAndSettings() async {
    try {
      // アセットと保存済み設定を並行取得
      final results = await Future.wait([
        AppAssets.load(),
        SettingsRepository.load(),
      ]);

      if (!mounted) return;

      final assets = results[0] as List<AppAsset>;
      final saved  = results[1] as SavedSettings?;

      setState(() {
        _allAssets   = assets;
        _categories  = AppAssets.categories(assets);

        if (saved != null) {
          // 保存済み設定を復元（存在しないカテゴリは除外）
          _slideDurationSec    = saved.slideDurationSec;
          _loop                = saved.loop;
          _shuffle             = saved.shuffle;
          final validCategories = saved.selectedCategories
              .where(_categories.contains)
              .toSet();
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
      _selectedCategories =
          select ? Set.of(_categories) : {};
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

  Future<void> _startSlideshow() async {
    // 設定を保存してスナックバーで通知してからスライドショーへ
    await _saveSettings();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('設定を保存しました'),
        duration: Duration(seconds: 2),
      ),
    );

    final settings = SlideshowSettings(
      slideDurationSec: _slideDurationSec,
      selectedAssets:   _selectedAssets,
      loop:             _loop,
      shuffle:          _shuffle,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SlideshowScreen(settings: settings)),
    );
  }

  /// 設定を保存する（スライドショー開始せずに保存のみ）
  Future<void> _saveSettings() async {
    await SettingsRepository.save(
      slideDurationSec:   _slideDurationSec,
      loop:               _loop,
      shuffle:            _shuffle,
      selectedCategories: _selectedCategories.toList(),
    );
  }

  /// 設定を保存してスナックバーで通知する
  Future<void> _saveSettingsOnly() async {
    await _saveSettings();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('設定を保存しました'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 設定を初期値に戻す
  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('設定を初期値に戻す'),
        content: const Text('すべての設定をデフォルト値に戻します。よろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('リセット'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await SettingsRepository.clear();
    if (!mounted) return;

    setState(() {
      _slideDurationSec   = SettingsRepository.defaultSlideDurationSec;
      _loop               = SettingsRepository.defaultLoop;
      _shuffle            = SettingsRepository.defaultShuffle;
      _selectedCategories = Set.of(_categories); // 全カテゴリ選択
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('設定を初期値に戻しました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        title: const Text('X秒ドローイング設定'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: '初期値に戻す',
            icon: const Icon(Icons.restart_alt),
            onPressed: _allAssets.isEmpty ? null : _resetToDefaults,
          ),
        ],
      ),
      body: _allAssets.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final double outerPad =
                    (constraints.maxWidth * 0.2).clamp(4.0, 240.0);
                return ListView(
                  padding: EdgeInsets.fromLTRB(outerPad, 24, outerPad, 24),
              children: [
                // ── 切り替え時間 ──────────────────────────────
                _SectionCard(
                  title: '⏱ 画像切り替え時間',
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _slideDurationSec > _durationMin
                                ? () => setState(() =>
                                    _slideDurationSec -= _durationStep)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                            color: Colors.purple,
                            iconSize: 32,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _formatDuration(_slideDurationSec),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: _slideDurationSec < _durationMax
                                ? () => setState(() =>
                                    _slideDurationSec += _durationStep)
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                            color: Colors.purple,
                            iconSize: 32,
                          ),
                        ],
                      ),
                      Slider(
                        value: _slideDurationSec.toDouble(),
                        min: _durationMin.toDouble(),
                        max: _durationMax.toDouble(),
                        divisions: (_durationMax - _durationMin) ~/ _durationStep,
                        activeColor: Colors.purple,
                        label: _formatDuration(_slideDurationSec),
                        onChanged: (v) => setState(() =>
                            _slideDurationSec =
                                (v.round() ~/ _durationStep) * _durationStep),
                      ),
                      Text(
                        '${_formatDuration(_durationMin)}〜${_formatDuration(_durationMax)}'
                        '（${_formatDuration(_durationStep)}単位）',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── ループ設定 ────────────────────────────────
                _SectionCard(
                  title: '🔁 ループ再生',
                  child: SwitchListTile(
                    value: _loop,
                    activeColor: Colors.purple,
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
                      color: _loop ? Colors.purple : Colors.grey,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── 再生順序 ──────────────────────────────────
                _SectionCard(
                  title: '🔀 再生順序',
                  child: SwitchListTile(
                    value: _shuffle,
                    activeColor: Colors.purple,
                    onChanged: (v) => setState(() => _shuffle = v),
                    title: Text(
                      _shuffle ? 'ランダム順' : '登録順',
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
                      color: _shuffle ? Colors.purple : Colors.grey,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── カテゴリ選択 ──────────────────────────────
                _SectionCard(
                  title: '🗂 表示するカテゴリ',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _allCategoriesSelected,
                            tristate: true,
                            activeColor: Colors.purple,
                            onChanged: (_) =>
                                _toggleAllCategories(!_allCategoriesSelected),
                          ),
                          const Text(
                            'すべて選択',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Text(
                            '${_selectedCategories.length} / ${_categories.length} カテゴリ'
                            '  （${_selectedAssets.length} 枚）',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      const Divider(),
                      ..._categories.map((category) {
                        final selected =
                            _selectedCategories.contains(category);
                        final count = _allAssets
                            .where((e) => e.category == category)
                            .length;
                        return CheckboxListTile(
                          value: selected,
                          activeColor: Colors.purple,
                          title: Text(category),
                          subtitle: Text(
                            '$count 枚',
                            style: const TextStyle(fontSize: 11),
                          ),
                          secondary: Icon(
                            Icons.folder_outlined,
                            color: selected ? Colors.purple : Colors.grey,
                          ),
                          onChanged: (_) => _toggleCategory(category),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                if (!_canStart)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      '⚠ カテゴリを1つ以上選択してください',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                // ── 保存 ／ 開始（左右配置） ─────────────────
                Row(
                  children: [
                    // 左：保存
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.purple,
                          side: const BorderSide(color: Colors.purple),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _saveSettingsOnly,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('保存',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 右：開始
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _canStart ? Colors.purple : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _canStart ? _startSlideshow : null,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('保存して開始',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
              ],
            );
          },
        ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

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
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
