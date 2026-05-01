import 'package:flutter/material.dart';
import 'main.dart' show AppBarHelper;
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
  List<AppAsset> _allAssets = [];
  List<String> _categories = [];
  Set<String> _selectedCategories = {};

  int _slideDurationSec = 5;
  bool _loop = false;
  bool _shuffle = true;

  bool get _allCategoriesSelected =>
      _selectedCategories.length == _categories.length;
  bool get _canStart => _selectedCategories.isNotEmpty;

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
    // 設定を保存してからスライドショーへ
    await SettingsRepository.save(
      slideDurationSec:    _slideDurationSec,
      loop:                _loop,
      shuffle:             _shuffle,
      selectedCategories:  _selectedCategories.toList(),
    );

    if (!mounted) return;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarHelper.build(context, 'X秒ドローイング設定', Colors.purple),
      body: _allAssets.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
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
                            onPressed: _slideDurationSec > 1
                                ? () => setState(() => _slideDurationSec--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                            color: Colors.purple,
                            iconSize: 32,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$_slideDurationSec 秒',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: _slideDurationSec < 30
                                ? () => setState(() => _slideDurationSec++)
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                            color: Colors.purple,
                            iconSize: 32,
                          ),
                        ],
                      ),
                      Slider(
                        value: _slideDurationSec.toDouble(),
                        min: 1,
                        max: 30,
                        divisions: 29,
                        activeColor: Colors.purple,
                        label: '$_slideDurationSec 秒',
                        onChanged: (v) =>
                            setState(() => _slideDurationSec = v.round()),
                      ),
                      Text(
                        '1秒〜30秒の範囲で設定できます',
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
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canStart ? Colors.purple : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _canStart ? _startSlideshow : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('X秒ドローイングを開始',
                      style: TextStyle(fontSize: 16)),
                ),
              ],
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
