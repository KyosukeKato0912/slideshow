import 'package:flutter/material.dart';
import 'main.dart' show buildAppBar;

// ══════════════════════════════════════════════════════════
// 画像全体表示画面
// ══════════════════════════════════════════════════════════
class ImageViewerScreen extends StatelessWidget {
  final String imagePath;
  final String imageLabel;

  const ImageViewerScreen({
    super.key,
    required this.imagePath,
    required this.imageLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(imageLabel),
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
