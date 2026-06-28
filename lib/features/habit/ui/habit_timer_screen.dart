import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_values.dart';
import '../../../shared/components/app_bar_widget.dart';
import '../../../shared/components/banner_ad_widget.dart';
import '../domain/habit_timer_notifier.dart';

// ══════════════════════════════════════════════════════════
// メリハリタイマー画面
//
// 上段：カウントダウン（作業中 or 休憩中）
// 下段：カウントアップ（0から経過作業時間を計測）
//
// ── フェーズ切替 ──
//   作業タイマーが 0 → 自動で休憩タイマーに切替（バナー通知）
//   休憩タイマーが 0 → 自動で作業タイマーに切替（バナー通知）
//   いずれもバックグラウンド時はシステム通知
//
// ── リセット ──
//   作業中リセットボタン：作業中・休憩中どちらでも作業開始時間に戻る
// ══════════════════════════════════════════════════════════
class HabitTimerScreen extends ConsumerStatefulWidget {
  final int? initialMinutes;
  final int? initialBreakMinutes;

  const HabitTimerScreen({
    super.key,
    this.initialMinutes,
    this.initialBreakMinutes,
  });

  @override
  ConsumerState<HabitTimerScreen> createState() => _HabitTimerScreenState();
}

class _HabitTimerScreenState extends ConsumerState<HabitTimerScreen> {
  HabitTimerNotifier? _notifier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifier = ref.read(habitTimerProvider.notifier);
      _notifier!.setTimerScreenVisible(true);
      _notifier!.init(
        initialMinutes: widget.initialMinutes,
        initialBreakMinutes: widget.initialBreakMinutes,
      );
    });
  }

  @override
  void dispose() {
    _notifier?.setTimerScreenVisible(false);
    super.dispose();
  }

  // ── 総作業時間リセット確認ダイアログ ─────────────────
  Future<void> _confirmResetCountUp() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppStrings.habitCountUpResetDialogTitle,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(AppStrings.habitCountUpResetDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.habitCountUpResetDialogCancel,
                style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.theme,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppStrings.habitCountUpResetDialogConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref.read(habitTimerProvider.notifier).resetAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(habitTimerProvider);

    // justSwitched フラグは通知サービスが発行済みなのでここでは消費のみ
    ref.listen(habitTimerProvider, (prev, next) {
      if (next.justSwitched && !(prev?.justSwitched ?? false)) {
        ref.read(habitTimerProvider.notifier).consumeSwitched();
      }
    });

    // 現フェーズのラベルと色
    final phaseLabel = s.isBreak
        ? AppStrings.habitPhaseBreak
        : AppStrings.habitPhaseWork;
    // パネル：休憩中は緑系、作業中はテーマ色
    final phaseColor = s.isBreak ? Colors.green.shade800 : AppColors.themeDark;
    final phaseBgColor =
        s.isBreak ? Colors.green.shade50 : AppColors.themeLight;
    final phaseBorderColor =
        s.isBreak ? Colors.green.shade200 : AppColors.themeBorder;
    // ボタン色は常に紫（AppColors.theme）
    const phaseButtonColor = AppColors.theme;

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

          return SingleChildScrollView(
            padding:
                EdgeInsets.symmetric(horizontal: outerPad, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── カウントダウン ──────────────────────────
                _TimerPanel(
                  label: phaseLabel,
                  largeLabel: true,
                  displayText: s.isReady ? s.displayTime : '--:--',
                  bgColor: phaseBgColor,
                  borderColor: phaseBorderColor,
                  textColor: phaseColor,
                  onReset: s.isReady
                      ? () => ref
                          .read(habitTimerProvider.notifier)
                          .resetCountDown()
                      : null,
                ),
                const SizedBox(height: 20),

                // ── カウントアップ ──────────────────────────
                _TimerPanel(
                  label: AppStrings.habitCountUpLabel,
                  largeLabel: true,
                  displayText: s.displayCountUp,
                  bgColor: AppColors.themeLight,
                  borderColor: AppColors.themeBorder,
                  textColor: AppColors.themeDark,
                  onReset: s.countUpSeconds > 0
                      ? () => _confirmResetCountUp()
                      : null,
                ),
                const SizedBox(height: 32),

                // ── 開始 / 一時停止 / 再開ボタン ─────────────
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !s.isReady
                          ? Colors.grey.shade300
                          : phaseButtonColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: !s.isReady
                        ? null
                        : s.isRunning
                            ? () => ref
                                .read(habitTimerProvider.notifier)
                                .pause()
                            : () => ref
                                .read(habitTimerProvider.notifier)
                                .start(),
                    icon: Icon(
                      s.isRunning ? Icons.pause : Icons.play_arrow,
                      size: 28,
                    ),
                    label: Text(
                      s.isRunning
                          ? AppStrings.habitTimerPause
                          : (s.remainingSeconds <
                                  (s.isBreak
                                      ? s.breakTotalSeconds
                                      : s.totalSeconds)
                              ? AppStrings.habitTimerResume
                              : AppStrings.habitTimerStart),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // ── バナー広告 ────────────────────────────────
                const Center(child: BannerAdWidget()),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// タイマーパネル（カウントダウン・カウントアップ共用）
// ══════════════════════════════════════════════════════════
class _TimerPanel extends StatelessWidget {
  final String label;
  final bool largeLabel;
  final String displayText;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback? onReset;

  const _TimerPanel({
    required this.label,
    this.largeLabel = false,
    required this.displayText,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          largeLabel ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        // ラベル
        Text(
          label,
          textAlign: largeLabel ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: largeLabel ? 20 : 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 6),
        // パネル本体
        Row(
          children: [
            // 時間表示
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Text(
                  displayText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
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
                onPressed: onReset,
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
      ],
    );
  }
}
