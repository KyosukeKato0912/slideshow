import 'package:flutter/material.dart';
import 'main.dart' show buildAppBar;
import 'slideshow_screen.dart';

// ══════════════════════════════════════════════════════════
// スライドショー設定データクラス
// ══════════════════════════════════════════════════════════
class SlideshowSettings {
  final int slideDurationSec;
  final List<String> selectedImages;
  final bool loop;

  const SlideshowSettings({
    required this.slideDurationSec,
    required this.selectedImages,
    this.loop = false,
  });
}

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
  static const List<Map<String, String>> _allImages = [
    {'path': 'assets/START.png', 'label': 'START'},
    {'path': 'assets/A.png', 'label': 'A'},
    {'path': 'assets/B.png', 'label': 'B'},
    {'path': 'assets/C.png', 'label': 'C'},
    {'path': 'assets/END.png', 'label': 'END'},
  ];

  int _slideDurationSec = 5;
  bool _loop = false;
  final Set<String> _selectedPaths = {
    'assets/START.png',
    'assets/A.png',
    'assets/B.png',
    'assets/C.png',
    'assets/END.png',
  };

  bool get _allSelected => _selectedPaths.length == _allImages.length;
  bool get _canStart => _selectedPaths.isNotEmpty;

  void _toggleAll(bool select) {
    setState(() {
      if (select) {
        _selectedPaths.addAll(_allImages.map((e) => e['path']!));
      } else {
        _selectedPaths.clear();
      }
    });
  }

  void _toggleImage(String path) {
    setState(() {
      if (_selectedPaths.contains(path)) {
        _selectedPaths.remove(path);
      } else {
        _selectedPaths.add(path);
      }
    });
  }

  void _startSlideshow() {
    final ordered = _allImages
        .map((e) => e['path']!)
        .where((p) => _selectedPaths.contains(p))
        .toList();

    final settings = SlideshowSettings(
      slideDurationSec: _slideDurationSec,
      selectedImages: ordered,
      loop: _loop,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SlideshowScreen(settings: settings)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, 'スライドショー設定', Colors.purple),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── 切り替え時間 ────────────────────────────────
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
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── ループ設定 ──────────────────────────────────
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
                _loop ? '最後の画像の後、最初に戻って繰り返します' : '最後の画像で停止します',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              secondary: Icon(
                _loop ? Icons.repeat : Icons.trending_flat,
                color: _loop ? Colors.purple : Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── 表示画像選択 ────────────────────────────────
          _SectionCard(
            title: '🖼 表示する画像',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _allSelected,
                      tristate: true,
                      activeColor: Colors.purple,
                      onChanged: (_) => _toggleAll(!_allSelected),
                    ),
                    const Text(
                      'すべて選択',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '${_selectedPaths.length} / ${_allImages.length} 枚',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                const Divider(),
                ..._allImages.map((img) {
                  final path = img['path']!;
                  final label = img['label']!;
                  final selected = _selectedPaths.contains(path);
                  return CheckboxListTile(
                    value: selected,
                    activeColor: Colors.purple,
                    title: Text(label),
                    subtitle: Text(
                      path,
                      style: const TextStyle(fontSize: 11),
                    ),
                    secondary: Icon(
                      Icons.image_outlined,
                      color: selected ? Colors.purple : Colors.grey,
                    ),
                    onChanged: (_) => _toggleImage(path),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── 開始ボタン ──────────────────────────────────
          if (!_canStart)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                '⚠ 画像を1枚以上選択してください',
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
            label: const Text('スライドショーを開始', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

// ── セクションカード共通ウィジェット ──────────────────────
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
