import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_values.dart';
import '../../../shared/components/app_bar_widget.dart';
import '../domain/habit_timer_notifier.dart';

// ══════════════════════════════════════════════════════════
// メリハリタイマー画面
//
// タイマー状態は HabitTimerNotifier（Riverpod）で管理する。
// 画面を離れても Notifier が生きているためカウントダウンは継続する。
// 画面に戻ると最新の残り秒数が即座に反映される。
//
// ライフサイクル：
//   画面を開く → Notifier.init() で設定値を読み込み（実行中は再初期化しない）
//   [開始] 押下 → カウントダウン開始
//   [一時停止] 押下 → タイマー停止（残り秒数保持）
//   [再開] 押下 → タイマー再開
//   [リセット] 押下 → 残り秒数を初期値に戻し停止
//   0秒到達 → justFinished フラグで終了ダイアログを表示
// ══════════════════════════════════════════════════════════
class HabitTimerScreen extends ConsumerStatefulWidget {
  /// 設定画面の「保存して開始」から渡される初期分数。
  /// null の場合は SharedPreferences から読み込む。
  final int? initialMinutes;

  const HabitTimerScreen({super.key, this.initialMinutes});

  @override
  ConsumerState<HabitTimerScreen> createState() => _HabitTimerScreenState();
}

class _HabitTimerScreenState extends ConsumerState<HabitTimerScreen> {
  @override
  void initState() {
    super.initState();
    // タイマー画面が表示されたことを Notifier に通知（通知制御のため）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(habitTimerProvider.notifier).setTimerScreenVisible(true);
      ref
          .read(habitTimerProvider.notifier)
          .init(initialMinutes: widget.initialMinutes);
    });
  }

  @override
  void dispose() {
    // タイマー画面が非表示になったことを Notifier に通知
    ref.read(habitTimerProvider.notifier).setTimerScreenVisible(false);
    super.dispose();
  }

  // ── 終了ダイアログ ────────────────────────────────────
  Future<void> _showFinishedDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('タイマー終了',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('設定時間が経過しました。\nお疲れさまでした！'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.theme,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(habitTimerProvider.notifier).reset();
            },
            child: const Text('リセットして戻る'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(habitTimerProvider);

    // justFinished フラグが立ったらダイアログを表示し、フラグを消費する
    ref.listen(habitTimerProvider, (prev, next) {
      if (next.justFinished && !(prev?.justFinished ?? false)) {
        ref.read(habitTimerProvider.notifier).consumeFinished();
        _showFinishedDialog();
      }
    });

    return Scaffold(
      appBar: AppBarWidget(
        title: AppStrings.habitTimerTitle,
        backgroundColor: AppColors.theme,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double outerPad =
              (constraints.maxWidth * AppValues.outerPadRatio)
                  .clamp(AppValues.outerPadMin, AppValues.outerPadMax);

          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: outerPad, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── 時間表示パネル＋リセットボタン（横並び）───
                  Row(
                    children: [
                      // 時間表示パネル
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 20),
                          decoration: BoxDecoration(
                            color: AppColors.themeLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.themeBorder, width: 1.5),
                          ),
                          child: Text(
                            timerState.isReady
                                ? timerState.displayTime
                                : '--:--',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              color: AppColors.themeDark,
                              fontFeatures: [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // リセットボタン
                      SizedBox(
                        width: 80,
                        height: 90,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.theme,
                            side: const BorderSide(
                                color: AppColors.theme, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: timerState.isReady
                              ? () => ref
                                  .read(habitTimerProvider.notifier)
                                  .reset()
                              : null,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.replay, size: 28),
                              const SizedBox(height: 4),
                              Text(
                                AppStrings.habitTimerReset,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── 開始 / 一時停止 / 再開ボタン ─────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !timerState.isReady
                            ? Colors.grey.shade300
                            : AppColors.theme,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: !timerState.isReady || timerState.isFinished
                          ? null
                          : timerState.isRunning
                              ? () => ref
                                  .read(habitTimerProvider.notifier)
                                  .pause()
                              : () => ref
                                  .read(habitTimerProvider.notifier)
                                  .start(),
                      icon: Icon(
                        timerState.isRunning
                            ? Icons.pause
                            : Icons.play_arrow,
                        size: 28,
                      ),
                      label: Text(
                        timerState.isRunning
                            ? AppStrings.habitTimerPause
                            : (timerState.isFinished
                                ? AppStrings.habitTimerReset
                                : (timerState.remainingSeconds <
                                        timerState.totalSeconds
                                    ? AppStrings.habitTimerResume
                                    : AppStrings.habitTimerStart)),
                        style: const TextStyle(fontSize: 18),
                      ),
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
