import 'package:flutter/material.dart';
import 'app_bar_helper.dart';
import 'slideshow_ready_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter ナビゲーションサンプル',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// ══════════════════════════════════════════════════════════
// 機能の活性／非活性フラグ
// true  → ボタン有効（実装済み）
// false → ボタン無効（未実装・準備中）
// ══════════════════════════════════════════════════════════
class _FeatureFlags {
  static const bool xSecDrawing    = true;  // X秒ドローイング
  static const bool topicGenerator = false; // お題ジェネレーター
  static const bool growthRecord   = false; // 成長記録
  static const bool habitSupport   = false; // 習慣化サポート
  static const bool proArtistTips  = false; // プロ絵師解説
}

// ══════════════════════════════════════════════════════════
// ホーム画面
// ══════════════════════════════════════════════════════════
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('ホーム画面'),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double outerPad =
              (constraints.maxWidth * 0.2).clamp(4.0, 240.0);
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: outerPad, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _NavButton(
                label: 'X秒ドローイング',
                color: Colors.purple,
                enabled: _FeatureFlags.xSecDrawing,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SlideshowReadyScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _NavButton(
                label: 'お題ジェネレーター',
                color: Colors.teal,
                enabled: _FeatureFlags.topicGenerator,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Screen2()),
                ),
              ),
              const SizedBox(height: 12),
              _NavButton(
                label: '成長記録',
                color: Colors.orange,
                enabled: _FeatureFlags.growthRecord,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Screen3()),
                ),
              ),
              const SizedBox(height: 12),
              _NavButton(
                label: '習慣化サポート',
                color: Colors.pink,
                enabled: _FeatureFlags.habitSupport,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Screen4()),
                ),
              ),
              const SizedBox(height: 12),
              _NavButton(
                label: 'プロ絵師解説',
                color: Colors.indigo,
                enabled: _FeatureFlags.proArtistTips,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Screen1()),
                ),
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

// ══════════════════════════════════════════════════════════
// 共通ナビゲーションボタン
// ══════════════════════════════════════════════════════════
class _NavButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  const _NavButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? color : Colors.grey.shade300,
        foregroundColor: enabled ? Colors.white : Colors.grey.shade500,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: enabled ? 2 : 0,
      ),
      onPressed: enabled ? onTap : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          if (!enabled) ...[
            const SizedBox(width: 8),
            const Text(
              '準備中',
              style: TextStyle(fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// 共通サブ画面ベース（画面1〜4用）
// ══════════════════════════════════════════════════════════
class _SubScreen extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final String description;

  const _SubScreen({
    required this.title,
    required this.color,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarHelper.build(context, title, color),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: color),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(description, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// 画面1〜4
// ══════════════════════════════════════════════════════════
class Screen1 extends StatelessWidget {
  const Screen1({super.key});
  @override
  Widget build(BuildContext context) => const _SubScreen(
        title: 'プロ絵師解説',
        color: Colors.indigo,
        icon: Icons.menu_book,
        description: 'プロ絵師によるテクニックを学ぶ画面です',
      );
}

class Screen2 extends StatelessWidget {
  const Screen2({super.key});
  @override
  Widget build(BuildContext context) => const _SubScreen(
        title: 'お題ジェネレーター',
        color: Colors.teal,
        icon: Icons.casino_outlined,
        description: 'ランダムなお題を生成する画面です',
      );
}

class Screen3 extends StatelessWidget {
  const Screen3({super.key});
  @override
  Widget build(BuildContext context) => const _SubScreen(
        title: '成長記録',
        color: Colors.orange,
        icon: Icons.trending_up,
        description: '練習の成長を記録・確認する画面です',
      );
}

class Screen4 extends StatelessWidget {
  const Screen4({super.key});
  @override
  Widget build(BuildContext context) => const _SubScreen(
        title: '習慣化サポート',
        color: Colors.pink,
        icon: Icons.task_alt,
        description: '毎日の練習習慣をサポートする画面です',
      );
}
