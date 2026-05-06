import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════
// 共通 AppBar ウィジェット
//
// アプリ全体で利用する標準 AppBar。
// タイトル・背景色を外部から受け取り、戻るボタンを共通化する。
// ══════════════════════════════════════════════════════════
class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color backgroundColor;

  /// [actions] を渡すと AppBar 右端にアイコンボタンを追加できる
  final List<Widget>? actions;

  /// false にすると戻るボタンを非表示にする（ホーム画面など最上位画面で使用）
  final bool showBackButton;

  const AppBarWidget({
    super.key,
    required this.title,
    required this.backgroundColor,
    this.actions,
    this.showBackButton = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      title: Text(title),
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      actions: actions,
    );
  }
}
