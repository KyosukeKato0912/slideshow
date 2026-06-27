import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/notification_service.dart';
import 'habit_settings_repository.dart';

// ══════════════════════════════════════════════════════════
// メリハリタイマー 状態
// ══════════════════════════════════════════════════════════
class HabitTimerState {
  final int totalSeconds;     // 設定時間（秒）
  final int remainingSeconds; // 残り秒数
  final bool isRunning;       // カウントダウン中か
  final bool isFinished;      // 0秒到達済みか
  final bool justFinished;    // 今まさに0秒到達した瞬間か（UI通知用フラグ）

  const HabitTimerState({
    this.totalSeconds = 0,
    this.remainingSeconds = 0,
    this.isRunning = false,
    this.isFinished = false,
    this.justFinished = false,
  });

  bool get isReady => totalSeconds > 0;

  HabitTimerState copyWith({
    int? totalSeconds,
    int? remainingSeconds,
    bool? isRunning,
    bool? isFinished,
    bool? justFinished,
  }) =>
      HabitTimerState(
        totalSeconds: totalSeconds ?? this.totalSeconds,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        isRunning: isRunning ?? this.isRunning,
        isFinished: isFinished ?? this.isFinished,
        justFinished: justFinished ?? this.justFinished,
      );

  // ── 表示用フォーマット（MM:SS）────────────────────────
  String get displayTime {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// ══════════════════════════════════════════════════════════
// メリハリタイマー StateNotifier
//
// Timer をここで保持することで、画面（HabitTimerScreen）が
// dispose されてもカウントダウンが継続する。
// ProviderScope の生存中（= アプリ起動中）は状態が維持される。
// ══════════════════════════════════════════════════════════
class HabitTimerNotifier extends StateNotifier<HabitTimerState> {
  HabitTimerNotifier() : super(const HabitTimerState());

  Timer? _timer;

  // ── タイマー画面の表示状態 ────────────────────────────
  // true のとき = HabitTimerScreen が表示中
  // 終了時にこのフラグが false なら通知を発行する
  bool _isTimerScreenVisible = false;

  void setTimerScreenVisible(bool visible) {
    _isTimerScreenVisible = visible;
  }

  // ── 初期化 ────────────────────────────────────────────
  // 設定画面から渡された分数、または SharedPreferences の保存値を使う。
  // すでにカウントダウン中の場合は何もしない（画面再表示時の多重初期化防止）。
  Future<void> init({int? initialMinutes}) async {
    // カウントダウン中は再初期化しない
    if (state.isRunning) return;

    int minutes;
    if (initialMinutes != null) {
      minutes = initialMinutes;
    } else {
      final saved = await HabitSettingsRepository.load();
      minutes = saved?.timerMinutes ?? HabitSettingsRepository.defaultTimerMinutes;
    }

    // すでに同じ設定で初期化済みなら残り秒数を保持
    final totalSec = minutes * 60;
    if (state.totalSeconds == totalSec && !state.isFinished) return;

    state = HabitTimerState(
      totalSeconds: totalSec,
      remainingSeconds: totalSec,
    );
  }

  // ── 開始 ─────────────────────────────────────────────
  void start() {
    if (state.isRunning || state.remainingSeconds <= 0) return;
    state = state.copyWith(isRunning: true, isFinished: false, justFinished: false);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingSeconds <= 1) {
        _timer?.cancel();
        state = state.copyWith(
          remainingSeconds: 0,
          isRunning: false,
          isFinished: true,
          justFinished: true,
        );
        // タイマー画面が表示されていない場合のみプッシュ通知を発行する
        if (!_isTimerScreenVisible) {
          NotificationService.showTimerFinished();
        }
      } else {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      }
    });
  }

  // ── 一時停止 ──────────────────────────────────────────
  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  // ── リセット（現在の totalSeconds ベース）────────────────
  void reset() {
    _timer?.cancel();
    state = HabitTimerState(
      totalSeconds: state.totalSeconds,
      remainingSeconds: state.totalSeconds,
    );
  }

  // ── 設定変更時のリセット（新しい分数を反映）──────────────
  // 設定画面で保存した際に呼ぶ。タイマーを停止し、
  // 新しい設定時間で初期状態に戻す。
  void resetWithMinutes(int minutes) {
    _timer?.cancel();
    final totalSec = minutes * 60;
    state = HabitTimerState(
      totalSeconds: totalSec,
      remainingSeconds: totalSec,
    );
  }

  // ── justFinished フラグを消費（ダイアログ表示後に呼ぶ）──
  void consumeFinished() {
    state = state.copyWith(justFinished: false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ── Provider 定義 ─────────────────────────────────────────
final habitTimerProvider =
    StateNotifierProvider<HabitTimerNotifier, HabitTimerState>(
  (ref) => HabitTimerNotifier(),
);
