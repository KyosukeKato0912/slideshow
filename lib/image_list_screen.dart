import 'package:flutter/material.dart';
import 'main.dart' show buildAppBar;
import 'image_viewer_screen.dart';

// ══════════════════════════════════════════════════════════
// 画像情報データクラス
// ══════════════════════════════════════════════════════════
class ImageItem {
  final String path;
  final String label;

  const ImageItem({required this.path, required this.label});
}

// ══════════════════════════════════════════════════════════
// 画像一覧画面
// ══════════════════════════════════════════════════════════
class ImageListScreen extends StatefulWidget {
  const ImageListScreen({super.key});

  @override
  State<ImageListScreen> createState() => _ImageListScreenState();
}

class _ImageListScreenState extends State<ImageListScreen> {
  // assetに登録されているすべての画像
  static const List<ImageItem> _allImages = [
    ImageItem(path: 'assets/START.png', label: 'START'),
    ImageItem(path: 'assets/A.png', label: 'A'),
    ImageItem(path: 'assets/B.png', label: 'B'),
    ImageItem(path: 'assets/C.png', label: 'C'),
    ImageItem(path: 'assets/END.png', label: 'END'),
  ];

  final TextEditingController _searchController = TextEditingController();
  List<ImageItem> _filtered = List.of(_allImages);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? List.of(_allImages)
          : _allImages
              .where((img) => img.label.toLowerCase().contains(query))
              .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, '画像一覧', Colors.purple),
      body: Column(
        children: [
          // ── 検索バー ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '画像名で検索...',
                prefixIcon: const Icon(Icons.search, color: Colors.purple),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.purple, width: 2),
                ),
                isDense: true,
              ),
            ),
          ),

          // ── 件数表示 ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_filtered.length} 件',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (_searchController.text.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    '（"${_searchController.text}" の検索結果）',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ),

          // ── サムネイルグリッド ────────────────────────────
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
                      final img = _filtered[index];
                      return _ThumbnailCard(
                        item: img,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ImageViewerScreen(
                              imagePath: img.path,
                              imageLabel: img.label,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
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
            '「${_searchController.text}」に一致する画像が見つかりません',
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
  final ImageItem item;
  final VoidCallback onTap;

  const _ThumbnailCard({required this.item, required this.onTap});

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
            // サムネイル画像
            Expanded(
              child: Container(
                color: Colors.grey.shade100,
                child: Image.asset(
                  item.path,
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
            // ラベル
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: Colors.white,
              child: Row(
                children: [
                  const Icon(Icons.image_outlined,
                      size: 14, color: Colors.purple),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.open_in_full, size: 12, color: Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
