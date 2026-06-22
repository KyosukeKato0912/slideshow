import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/constants/app_strings.dart';

// ══════════════════════════════════════════════════════════
// アプリルートウィジェット
//
// MaterialApp の設定・テーマ注入・初期ルートを定義する。
// エントリポイント（main.dart）からのみ呼び出す。
//
// ⚠ 暫定実装：現フェーズは Navigator.push を使用。
//   go_router 導入時は MaterialApp.router + GoRouter に移行する。
//   ルート定義は app_router.dart に集約済み。コミットテスト2
// ══════════════════════════════════════════════════════════
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppStrings.appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      // DatePickerDialog 等の Material ダイアログに必須。
      // flutter_localizations は Flutter SDK に同梱されているため
      // pubspec.yaml への追加が必要（sdk: flutter 指定）。
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [
        Locale('ja'), // 日本語（ピッカーが日本語表示になる）
        Locale('en'), // 英語（フォールバック）
      ],
      home: AppRouter.home,
    );
  }
}
