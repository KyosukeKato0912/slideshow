import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

// ══════════════════════════════════════════════════════════
// アップロード完了画面（仮実装）
//
// 現フェーズでは「アップロードが完了しました」の表示と
// 成長記録メイン画面へ戻るボタンのみを備えた簡易版とする。
//
// ⚠ 未対応（次のステップ以降）：
//   ・今日の作業時間合計表示（所要時間入力が未接続のため）
//   ・21日連続お祝いメッセージ
//   ・300枚達成お祝いメッセージ + PDFダウンロード導線
// ══════════════════════════════════════════════════════════
class UploadCompleteScreen extends StatelessWidget {
  const UploadCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 72,
                  color: AppColors.theme,
                ),
                const SizedBox(height: 20),
                const Text(
                  AppStrings.growthUploadCompleteTitle,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.theme,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // アップロード完了画面・アップロード画面の2枚を閉じ、
                    // 成長記録メイン画面まで戻る
                    Navigator.of(context)
                      ..pop()
                      ..pop();
                  },
                  child: const Text(
                    AppStrings.growthUploadCompleteBackButton,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
