import 'package:flutter/material.dart';
import 'main.dart' show AppBarHelper;
import 'app_assets.dart';
import 'slideshow_settings_model.dart';
import 'slideshow_screen.dart';

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

  /// 選択カテゴリに属するアセットのリスト
  List<AppAsset> get _selectedAssets => _allAssets
      .where((e) => _selectedCategories.contains(e.category))
      .toList();

  // ── アセット読み込みを initState で行い、build() 内の副作用を排除 ──
  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    try {
      final assets = await AppAssets.load();
      if (!mounted) return;
      setState(() {
        _allAssets = assets;
        _categories = AppAssets.categories(assets);
        _selectedCategories = Set.of(_categories); // 初期は全カテゴリ選択
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('画像の読み込みに失敗しました: $e')),
      );
    }
  }

  void _toggleAllCategories(bool select) {
    setState(() {
      if (select) {
        _selectedCategories = Set.of(_categories);
      } else {
        _selectedCategories.clear();
      }
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

  void _startSlideshow() {
    final settings = SlideshowSettings(
      slideDurationSec: _slideDurationSec,
      selectedAssets: _selectedAssets, // List<AppAsset> を渡す
      loop: _loop,
      shuffle: _shuffle,
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
                      // すべて選択
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
                                fontSize: 12,
                                color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      const Divider(),
                      // カテゴリごとのチェックボックス
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

                // ── 開始ボタン ────────────────────────────────
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
