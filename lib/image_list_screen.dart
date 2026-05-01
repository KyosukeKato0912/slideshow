import 'package:flutter/material.dart';
import 'main.dart' show AppBarHelper;
import 'app_assets.dart';
import 'image_viewer_screen.dart';

// ══════════════════════════════════════════════════════════
// 画像一覧画面
// ══════════════════════════════════════════════════════════
class ImageListScreen extends StatefulWidget {
  const ImageListScreen({super.key});

  @override
  State<ImageListScreen> createState() => _ImageListScreenState();
}

class _ImageListScreenState extends State<ImageListScreen> {
  late final Future<List<AppAsset>> _assetsFuture;
  final TextEditingController _modelSearchController = TextEditingController();

  List<AppAsset> _all = [];
  List<String> _categories = [];
  String? _selectedCategory; // null = すべて
  List<AppAsset> _filtered = [];

  @override
  void initState() {
    super.initState();
    _assetsFuture = AppAssets.load();
    _modelSearchController.addListener(_onFilterChanged);
  }

  void _onAllLoaded(List<AppAsset> assets) {
    _all = assets;
    _categories = AppAssets.categories(assets);
    _onFilterChanged();
  }

  void _onFilterChanged() {
    final query = _modelSearchController.text.trim().toLowerCase();
    setState(() {
      _filtered = _all.where((img) {
        final categoryMatch =
            _selectedCategory == null || img.category == _selectedCategory;
        final modelMatch =
            query.isEmpty || img.modelName.toLowerCase().contains(query);
        return categoryMatch && modelMatch;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() => _selectedCategory = null);
    _modelSearchController.clear();
  }

  bool get _hasFilter =>
      _selectedCategory != null || _modelSearchController.text.isNotEmpty;

  @override
  void dispose() {
    _modelSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarHelper.build(context, '画像一覧', Colors.purple),
      body: FutureBuilder<List<AppAsset>>(
        future: _assetsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('画像の読み込みに失敗しました\n${snapshot.error}',
                  textAlign: TextAlign.center),
            );
          }

          final assets = snapshot.data!;
          if (_all.isEmpty && assets.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _onAllLoaded(assets);
            });
          }

          return Column(
            children: [
              // ── 検索エリア ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Column(
                  children: [
                    // カテゴリプルダウン
                    DropdownButtonFormField<String?>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'カテゴリ',
                        prefixIcon: const Icon(Icons.folder_outlined,
                            color: Colors.purple),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Colors.purple, width: 2),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('すべて'),
                        ),
                        ..._categories.map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedCategory = value);
                        _onFilterChanged();
                      },
                    ),

                    const SizedBox(height: 8),

                    // モデル名自由入力
                    TextField(
                      controller: _modelSearchController,
                      decoration: InputDecoration(
                        labelText: 'モデル名',
                        hintText: 'モデル名で絞り込み...',
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.purple),
                        suffixIcon: _modelSearchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _modelSearchController.clear,
                              )
                            : null,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Colors.purple, width: 2),
                        ),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),

              // ── 件数 ＋ フィルタークリア ────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${_filtered.length} 件',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const Spacer(),
                    if (_hasFilter)
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.filter_alt_off, size: 14),
                        label: const Text('フィルターをクリア',
                            style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.purple,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
              ),

              // ── サムネイルグリッド ──────────────────────────
              Expanded(
                child: _filtered.isEmpty
                    ? _buildEmptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final asset = _filtered[index];
                          return _ThumbnailCard(
                            asset: asset,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ImageViewerScreen(
                                  imagePath: asset.path,
                                  imageLabel: asset.modelName,
                                  author: asset.author,
                                  category: asset.category,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_search, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _hasFilter ? '条件に一致する画像が見つかりません' : '画像が見つかりません',
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// サムネイルカード
// ══════════════════════════════════════════════════════════
class _ThumbnailCard extends StatelessWidget {
  final AppAsset asset;
  final VoidCallback onTap;

  const _ThumbnailCard({required this.asset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: Colors.grey.shade100,
                child: Image.asset(
                  asset.path,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // カテゴリバッジ
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      asset.category,
                      style: TextStyle(
                          fontSize: 10, color: Colors.purple.shade700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // モデル名
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 13, color: Colors.purple),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          asset.modelName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.open_in_full,
                          size: 11, color: Colors.grey),
                    ],
                  ),
                  // 作者名
                  if (asset.author.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(Icons.brush_outlined,
                              size: 11, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              '作者：${asset.author}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
