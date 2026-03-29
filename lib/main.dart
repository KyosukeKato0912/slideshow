import 'package:flutter/material.dart';
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _NavButton(
                label: '🏠 画面 1：プロフィール',
                color: Colors.indigo,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Screen1()),
                ),
              ),
              const SizedBox(height: 12),
              _NavButton(
                label: '📋 画面 2：タスク一覧',
                color: Colors.teal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Screen2()),
                ),
              ),
              const SizedBox(height: 12),
              _NavButton(
                label: '📊 画面 3：ダッシュボード',
                color: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Screen3()),
                ),
              ),
              const SizedBox(height: 12),
              _NavButton(
                label: '💬 画面 4：メッセージ',
                color: Colors.pink,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Screen4()),
                ),
              ),
              const SizedBox(height: 12),
              _NavButton(
                label: '🖼️ 画面 5：スライドショー',
                color: Colors.purple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SlideshowReadyScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// 共通：AppBar ビルダー
// ══════════════════════════════════════════════════════════
AppBar buildAppBar(BuildContext context, String title, Color color) {
  return AppBar(
    backgroundColor: color,
    foregroundColor: Colors.white,
    title: Text(title),
    centerTitle: true,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.pop(context),
    ),
  );
}

// ══════════════════════════════════════════════════════════
// 共通ナビゲーションボタン
// ══════════════════════════════════════════════════════════
class _NavButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _NavButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(fontSize: 16)),
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
      appBar: buildAppBar(context, title, color),
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
        title: 'プロフィール',
        color: Colors.indigo,
        icon: Icons.person,
        description: 'ユーザー情報を表示する画面です',
      );
}

class Screen2 extends StatelessWidget {
  const Screen2({super.key});
  @override
  Widget build(BuildContext context) => const _SubScreen(
        title: 'タスク一覧',
        color: Colors.teal,
        icon: Icons.check_circle_outline,
        description: 'タスクを管理する画面です',
      );
}

class Screen3 extends StatelessWidget {
  const Screen3({super.key});
  @override
  Widget build(BuildContext context) => const _SubScreen(
        title: 'ダッシュボード',
        color: Colors.orange,
        icon: Icons.bar_chart,
        description: '統計・グラフを表示する画面です',
      );
}

class Screen4 extends StatelessWidget {
  const Screen4({super.key});
  @override
  Widget build(BuildContext context) => const _SubScreen(
        title: 'メッセージ',
        color: Colors.pink,
        icon: Icons.chat_bubble_outline,
        description: 'チャット・メッセージ画面です',
      );
}
