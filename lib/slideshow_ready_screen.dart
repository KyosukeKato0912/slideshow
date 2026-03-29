import 'package:flutter/material.dart';
import 'main.dart' show buildAppBar;
import 'slideshow_screen.dart';
import 'slideshow_settings.dart';
import 'image_list_screen.dart';

// ══════════════════════════════════════════════════════════
// スライドショー準備画面
// ══════════════════════════════════════════════════════════
class SlideshowReadyScreen extends StatelessWidget {
  const SlideshowReadyScreen({super.key});

  static const _defaultSettings = SlideshowSettings(
    slideDurationSec: 5,
    selectedImages: [
      'assets/START.png',
      'assets/A.png',
      'assets/B.png',
      'assets/C.png',
      'assets/END.png',
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, 'スライドショー準備', Colors.purple),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.slideshow, size: 100, color: Colors.purple),
              const SizedBox(height: 24),
              const Text(
                'スライドショーを開始しますか？',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                '開始すると3秒のカウントダウン後に\n画像が自動再生されます',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // すぐに開始（デフォルト設定）
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const SlideshowScreen(settings: _defaultSettings),
                  ),
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text('すぐに開始', style: TextStyle(fontSize: 16)),
              ),

              const SizedBox(height: 12),

              // 設定して開始
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.purple,
                  side: const BorderSide(color: Colors.purple),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SlideshowSettingsScreen()),
                ),
                icon: const Icon(Icons.settings),
                label: const Text('設定して開始', style: TextStyle(fontSize: 16)),
              ),

              const SizedBox(height: 12),

              // 画像一覧
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.purple,
                  side: const BorderSide(color: Colors.purple),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ImageListScreen()),
                ),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('画像一覧', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
