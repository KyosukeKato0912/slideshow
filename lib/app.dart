import 'package:flutter/material.dart';
import 'core/router/app_router.dart';

// ══════════════════════════════════════════════════════════
// アプリルートウィジェット
//
// MaterialApp の設定・テーマ注入・初期ルートを定義する。
// エントリポイント（main.dart）からのみ呼び出す。
// ══════════════════════════════════════════════════════════
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'イラスト練習支援アプリ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: AppRouter.home,
    );
  }
}
