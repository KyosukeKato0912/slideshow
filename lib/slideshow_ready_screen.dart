import 'package:flutter/material.dart';
import 'main.dart' show AppBarHelper;
import 'app_assets.dart';
import 'slideshow_screen.dart';
import 'slideshow_settings.dart';
import 'slideshow_settings_model.dart';
import 'image_list_screen.dart';

// ══════════════════════════════════════════════════════════
// X秒ドローイング準備画面
// ══════════════════════════════════════════════════════════
class SlideshowReadyScreen extends StatefulWidget {
  const SlideshowReadyScreen({super.key});

  @override
  State<SlideshowReadyScreen> createState() => _SlideshowReadyScreenState();
}

class _SlideshowReadyScreenState extends State<SlideshowReadyScreen> {
  late final Future<List<AppAsset>> _assetsFuture;

  @override
  void initState() {
    super.initState();
    _assetsFuture = AppAssets.load();
  }

  void _startDefault(List<AppAsset> assets) {
    final settings = SlideshowSettings(
      slideDurationSec: 5,
      selectedAssets: assets, // List<AppAsset> を渡す
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SlideshowScreen(settings: settings)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarHelper.build(context, 'X秒ドローイング', Colors.purple),
      body: FutureBuilder<List<AppAsset>>(
        future: _assetsFuture,
        builder: (context, snapshot) {
          final isReady = snapshot.connectionState == ConnectionState.done &&
              !snapshot.hasError &&
              (snapshot.data?.isNotEmpty ?? false);

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.slideshow, size: 100, color: Colors.purple),
                  const SizedBox(height: 24),
                  const Text(
                    'X秒ドローイングを開始しますか？',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '開始すると3秒のカウントダウン後に\n画像が自動再生されます',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // ── すぐに開始 ──────────────────────────────
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isReady ? Colors.purple : Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isReady
                        ? () => _startDefault(snapshot.data!)
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
                      isReady ? 'すぐに開始' : '画像を読み込み中...',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── 設定して開始 ────────────────────────────
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
                    label: const Text('設定して開始',
                        style: TextStyle(fontSize: 16)),
                  ),

                  const SizedBox(height: 12),

                  // ── 画像一覧 ────────────────────────────────
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
                          builder: (_) => const ImageListScreen()),
                    ),
                    icon: const Icon(Icons.photo_library_outlined),
                    label:
                        const Text('画像一覧', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
