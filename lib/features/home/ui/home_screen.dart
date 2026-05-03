import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_values.dart';
import '../../../core/router/app_router.dart';

// ══════════════════════════════════════════════════════════
// ホーム画面
//
// 5機能へのナビゲーションボタンを表示する。
// 未実装機能は [enabled: false] で「準備中」グレーボタンになる。
// ══════════════════════════════════════════════════════════
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text(AppStrings.homeTitle),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double outerPad =
              (constraints.maxWidth * AppValues.outerPadRatio)
                  .clamp(AppValues.outerPadMin, AppValues.outerPadMax);

          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: outerPad, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FeatureNavButton(
                    label: AppStrings.featureDrawing,
                    color: AppColors.drawing,
                    enabled: _FeatureFlags.xSecDrawing,
                    onTap: () =>
                        Navigator.push(context, AppRouter.drawing()),
                  ),
                  const SizedBox(height: 12),
                  _FeatureNavButton(
                    label: AppStrings.featureTopic,
                    color: AppColors.topicGenerator,
                    enabled: _FeatureFlags.topicGenerator,
                    onTap: () {}, // TODO: AppRouter.topic() に差し替える
                  ),
                  const SizedBox(height: 12),
                  _FeatureNavButton(
                    label: AppStrings.featureGrowth,
                    color: AppColors.growthRecord,
                    enabled: _FeatureFlags.growthRecord,
                    onTap: () {}, // TODO: AppRouter.growth() に差し替える
                  ),
                  const SizedBox(height: 12),
                  _FeatureNavButton(
                    label: AppStrings.featureHabit,
                    color: AppColors.habitSupport,
                    enabled: _FeatureFlags.habitSupport,
                    onTap: () {}, // TODO: AppRouter.habit() に差し替える
                  ),
                  const SizedBox(height: 12),
                  _FeatureNavButton(
                    label: AppStrings.featureProLesson,
                    color: AppColors.proArtistLesson,
                    enabled: _FeatureFlags.proArtistLesson,
                    onTap: () {}, // TODO: AppRouter.proLesson() に差し替える
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
// 機能の活性／非活性フラグ
// true  → ボタン有効（実装済み）
// false → ボタン無効（未実装・準備中）
// ══════════════════════════════════════════════════════════
abstract class _FeatureFlags {
  static const bool xSecDrawing = true; // X秒ドローイング
  static const bool topicGenerator = false; // お題ジェネレーター
  static const bool growthRecord = false; // 成長記録
  static const bool habitSupport = false; // 習慣化サポート
  static const bool proArtistLesson = false; // プロ絵師解説
}

// ══════════════════════════════════════════════════════════
// 機能ナビゲーションボタン
// ══════════════════════════════════════════════════════════
class _FeatureNavButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  const _FeatureNavButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            enabled ? color : AppColors.disabled,
        foregroundColor:
            enabled ? Colors.white : AppColors.disabledText,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: enabled ? 2 : 0,
      ),
      onPressed: enabled ? onTap : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          if (!enabled) ...[
            const SizedBox(width: 8),
            Text(
              AppStrings.featureComingSoon,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}
