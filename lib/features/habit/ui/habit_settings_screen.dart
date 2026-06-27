import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_values.dart';
import '../../../shared/components/app_bar_widget.dart';
import '../domain/habit_settings_repository.dart';
import '../domain/habit_timer_notifier.dart';
import 'habit_timer_screen.dart';

// ══════════════════════════════════════════════════════════
// 習慣化サポート 設定画面
//
// メリハリタイマーのカウントダウン時間を設定する。
// DrawingSettingsScreen と同じ設計パターンを踏襲する。
//
// ── ボタン ──
//   [保存]         設定を保存して画面を閉じる
//   [保存して開始]  設定を保存してメリハリタイマー画面へ遷移
//                  ただしタイマーのカウントダウンは開始ボタン押下まで始まらない
//
// ⚠ 保存時はタイマーをリセットする（設定変更を即時反映させるため）
// ══════════════════════════════════════════════════════════
class HabitSettingsScreen extends ConsumerStatefulWidget {
  const HabitSettingsScreen({super.key});

  @override
  ConsumerState<HabitSettingsScreen> createState() =>
      _HabitSettingsScreenState();
}

class _HabitSettingsScreenState extends ConsumerState<HabitSettingsScreen> {
  int _timerMinutes = HabitSettingsRepository.defaultTimerMinutes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final saved = await HabitSettingsRepository.load();
    if (!mounted) return;
    setState(() {
      if (saved != null) _timerMinutes = saved.timerMinutes;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await HabitSettingsRepository.save(timerMinutes: _timerMinutes);
    // 設定変更を即時反映させるためタイマーをリセット・停止する
    ref.read(habitTimerProvider.notifier).resetWithMinutes(_timerMinutes);
  }

  Future<void> _onSaveOnly() async {
    await _saveSettings();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.habitSettingsSaved),
        duration: const Duration(seconds: 2),
      ),
    );
    // 画面は閉じない：SnackBar で保存完了を通知するのみ
  }

  Future<void> _onSaveAndStart() async {
    await _saveSettings();
    if (!mounted) return;
    // タイマー画面へ遷移（カウントダウンは開始ボタン押下まで始まらない）
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HabitTimerScreen(initialMinutes: _timerMinutes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: AppStrings.habitSettingsTitle,
        backgroundColor: AppColors.theme,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.theme))
          : LayoutBuilder(
              builder: (context, constraints) {
                final double outerPad =
                    (constraints.maxWidth * AppValues.outerPadRatio)
                        .clamp(AppValues.outerPadMin, AppValues.outerPadMax);

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                      horizontal: outerPad, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── メリハリタイマー時間設定 ──────────────
                      _SettingsSectionCard(
                        title: AppStrings.habitSettingsTimerTitle,
                        child: _TimerMinutesSetting(
                          minutes: _timerMinutes,
                          onChanged: (v) =>
                              setState(() => _timerMinutes = v),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── 保存 ／ 保存して開始 ──────────────────
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.theme,
                                side: const BorderSide(
                                    color: AppColors.theme),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                              ),
                              onPressed: _onSaveOnly,
                              icon: const Icon(Icons.save_outlined),
                              label: Text(
                                AppStrings.habitSettingsSaveButton,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.theme,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                              ),
                              onPressed: _onSaveAndStart,
                              icon: const Icon(Icons.play_arrow),
                              label: Text(
                                AppStrings.habitSettingsSaveAndStartButton,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// 設定セクションカード（DrawingSettingsScreen._SettingsSectionCard と同形式）
// ══════════════════════════════════════════════════════════
class _SettingsSectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsSectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// タイマー時間設定ウィジェット
//
// DrawingSettingsScreen の _DurationSetting と同パターン。
// ＋/－ボタン＋Sliderで分単位を設定する。
// ══════════════════════════════════════════════════════════
class _TimerMinutesSetting extends StatelessWidget {
  final int minutes;
  final ValueChanged<int> onChanged;

  // 設定範囲
  static const int _minMinutes = 1;
  static const int _maxMinutes = 120;
  static const int _stepMinutes = 1;

  const _TimerMinutesSetting({
    required this.minutes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: minutes > _minMinutes
                  ? () => onChanged(minutes - _stepMinutes)
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
              color: AppColors.theme,
              iconSize: 32,
            ),
            const SizedBox(width: 12),
            Text(
              '$minutes 分',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AppColors.theme,
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: minutes < _maxMinutes
                  ? () => onChanged(minutes + _stepMinutes)
                  : null,
              icon: const Icon(Icons.add_circle_outline),
              color: AppColors.theme,
              iconSize: 32,
            ),
          ],
        ),
        Slider(
          value: minutes.toDouble(),
          min: _minMinutes.toDouble(),
          max: _maxMinutes.toDouble(),
          divisions: _maxMinutes - _minMinutes,
          activeColor: AppColors.theme,
          label: '$minutes 分',
          onChanged: (v) => onChanged(v.round()),
        ),
        Text(
          '$_minMinutes 分〜$_maxMinutes 分',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}
