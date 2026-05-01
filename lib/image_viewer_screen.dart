import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════
// 画像全体表示画面
// ══════════════════════════════════════════════════════════
class ImageViewerScreen extends StatelessWidget {
  final String imagePath;
  final String imageLabel;  // モデル名
  final String author;      // 作者名
  final String category;    // カテゴリ名

  const ImageViewerScreen({
    super.key,
    required this.imagePath,
    required this.imageLabel,
    this.author = '',
    this.category = '',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (category.isNotEmpty)
              Text(
                category,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.purple.shade200,
                ),
              ),
            Text(imageLabel, style: const TextStyle(fontSize: 16)),
            if (author.isNotEmpty)
              Text(
                '作者：$author',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'ピンチ操作で拡大・縮小できます',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
      ),
    );
  }
}
