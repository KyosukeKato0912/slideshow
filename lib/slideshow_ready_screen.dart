import 'package:flutter/material.dart';
import 'app_bar_helper.dart';
import 'app_assets.dart';
import 'slideshow_screen.dart';
import 'slideshow_settings.dart';
import 'slideshow_settings_model.dart';
import 'settings_repository.dart';
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
  // アセット一覧と保存済み設定を並行ロード
  Future<_ReadyData> _readyFuture =
      Future.value(_ReadyData(assets: [], saved: null));

  @override
  void initState() {
    super.initState();
    _readyFuture = _loadReadyData();
  }

  // 設定画面から戻ったときにサマリーを最新化する
  Future<void> _refreshSettings() async {
    final saved = await SettingsRepository.load();
    if (!mounted) return;
    // アセットはキャッシュ済みなので再取得コストはゼロ
    final assets = await AppAssets.load();
    if (!mounted) return;
    setState(() {
      _readyFuture = Future.value(_ReadyData(assets: assets, saved: saved));
    });
  }

  static Future<_ReadyData> _loadReadyData() async {
    final results = await Future.wait([
      AppAssets.load(),
      SettingsRepository.load(),
    ]);
    return _ReadyData(
      assets: results[0] as List<AppAsset>,
      saved: results[1] as SavedSettings?,
    );
  }

  /// 保存済み設定（または初期値）を使ってスライドショーを開始する
  void _startWithSavedSettings(_ReadyData data) {
    final saved = data.saved;
    final allAssets = data.assets;
    final categories = AppAssets.categories(allAssets);

    // 保存済みカテゴリを検証し、存在しないものは除外
    final List<AppAsset> selectedAssets;
    if (saved != null && saved.selectedCategories.isNotEmpty) {
      final valid = saved.selectedCategories.where(categories.contains).toSet();
      selectedAssets = valid.isNotEmpty
          ? allAssets.where((a) => valid.contains(a.category)).toList()
          : allAssets; // 全カテゴリが無効なら全件
    } else {
      selectedAssets = allAssets; // 未保存 → 全件
    }

    final settings = SlideshowSettings(
      slideDurationSec:
          saved?.slideDurationSec ?? SettingsRepository.defaultSlideDurationSec,
      selectedAssets: selectedAssets,
      loop: saved?.loop ?? SettingsRepository.defaultLoop,
      shuffle: saved?.shuffle ?? SettingsRepository.defaultShuffle,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SlideshowScreen(settings: settings)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarHelper.build(context, 'X秒ドローイング準備', Colors.purple),
      body: FutureBuilder<_ReadyData>(
        future: _readyFuture,
        builder: (context, snapshot) {
          final isReady = snapshot.connectionState == ConnectionState.done &&
              !snapshot.hasError &&
              (snapshot.data?.assets.isNotEmpty ?? false);

          final data = snapshot.data;

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
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '開始すると3秒のカウントダウン後に\n画像が自動再生されます',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // ── 現在の設定サマリー ──────────────────────
                  if (isReady && data != null)
                    _SettingsSummaryCard(
                      assets: data.assets,
                      saved: data.saved,
                    ),

                  const SizedBox(height: 24),

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
                    onPressed:
                        isReady ? () => _startWithSavedSettings(data!) : null,
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

                  // ── モデル一覧 ──────────────────────────────
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
                    label: const Text('モデル一覧', style: TextStyle(fontSize: 16)),
                  ),

                  const SizedBox(height: 12),

                  // ── 設定 ────────────────────────────────────
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purple,
                      side: const BorderSide(color: Colors.purple),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SlideshowSettingsScreen()),
                      );
                      // 設定画面から戻ったら設定サマリーを更新する
                      await _refreshSettings();
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('設定', style: TextStyle(fontSize: 16)),
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

// ── ロードデータコンテナ ─────────────────────────────────
class _ReadyData {
  final List<AppAsset> assets;
  final SavedSettings? saved;
  const _ReadyData({required this.assets, required this.saved});
}

// ══════════════════════════════════════════════════════════
// 秒数表示ヘルパー（設定サマリーで使用）
// ══════════════════════════════════════════════════════════
String _formatDuration(int sec) {
  if (sec < 60) return '$sec 秒';
  final m = sec ~/ 60;
  final s = sec % 60;
  return s == 0 ? '$m 分' : '$m 分 $s 秒';
}

// ══════════════════════════════════════════════════════════
// 設定サマリーカード（準備画面に表示）
// ══════════════════════════════════════════════════════════
class _SettingsSummaryCard extends StatelessWidget {
  final List<AppAsset> assets;
  final SavedSettings? saved;

  const _SettingsSummaryCard({required this.assets, required this.saved});

  @override
  Widget build(BuildContext context) {
    final categories = AppAssets.categories(assets);
    final duration =
        saved?.slideDurationSec ?? SettingsRepository.defaultSlideDurationSec;
    final loop = saved?.loop ?? SettingsRepository.defaultLoop;
    final shuffle = saved?.shuffle ?? SettingsRepository.defaultShuffle;

    // 選択カテゴリ
    final Set<String> selectedCats;
    if (saved == null || saved!.selectedCategories.isEmpty) {
      selectedCats = categories.toSet();
    } else {
      selectedCats =
          saved!.selectedCategories.where(categories.contains).toSet();
      if (selectedCats.isEmpty) selectedCats.addAll(categories);
    }
    final isAllCategories = selectedCats.length == categories.length;
    final imageCount =
        assets.where((a) => selectedCats.contains(a.category)).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, size: 14, color: Colors.purple.shade400),
              const SizedBox(width: 4),
              Text(
                saved != null ? '保存済みの設定' : 'デフォルト設定',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.purple.shade400,
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
                label: _formatDuration(duration),
              ),
              _SummaryChip(
                icon: Icons.image_outlined,
                label: '$imageCount 枚',
              ),
              _SummaryChip(
                icon: Icons.folder_outlined,
                label: isAllCategories ? '全カテゴリ' : selectedCats.join(' / '),
              ),
              if (loop)
                const _SummaryChip(
                  icon: Icons.repeat,
                  label: 'ループ',
                ),
              _SummaryChip(
                icon: shuffle ? Icons.shuffle : Icons.sort,
                label: shuffle ? 'ランダム' : '登録順',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.purple),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.purple),
          ),
        ],
      ),
    );
  }
}
