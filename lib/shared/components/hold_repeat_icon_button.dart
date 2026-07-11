import 'dart:async';
import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════
// 長押しで自動増減するアイコンボタン
//
// ・タップ           : 1 ステップだけ即時実行
// ・長押し           : 初動ディレイの後、一定間隔で自動リピート
// ・約1秒長押し継続  : リピート間隔を短縮（加速）
//
// 数値のインクリメント／デクリメント用の +/- ボタン全般で共通利用する。
// ══════════════════════════════════════════════════════════
class HoldRepeatIconButton extends StatefulWidget {
  /// 1 ステップ分の処理。null の場合はボタンが無効化される
  /// （境界値に達した場合など、呼び出し側で null を渡す）。
  final VoidCallback? onStep;
  final IconData icon;
  final Color? color;
  final double iconSize;
  final String? tooltip;

  const HoldRepeatIconButton({
    super.key,
    required this.onStep,
    required this.icon,
    this.color,
    this.iconSize = 32,
    this.tooltip,
  });

  @override
  State<HoldRepeatIconButton> createState() => _HoldRepeatIconButtonState();
}

class _HoldRepeatIconButtonState extends State<HoldRepeatIconButton> {
  Timer? _timer;
  DateTime? _holdStartedAt;

  // ── 挙動パラメータ ──────────────────────────────────────
  // 長押し開始後、自動リピートが始まるまでの待ち時間
  static const Duration _initialDelay = Duration(milliseconds: 350);
  // 加速前（ゆっくり）のリピート間隔
  static const Duration _slowInterval = Duration(milliseconds: 220);
  // 加速後（速い）のリピート間隔
  static const Duration _fastInterval = Duration(milliseconds: 45);
  // このデュレーションを超えて長押しし続けたら加速する
  static const Duration _accelerateAfter = Duration(milliseconds: 1000);

  bool get _enabled => widget.onStep != null;

  void _fireStep() {
    if (!_enabled) return;
    widget.onStep!();
  }

  void _handleTapDown(TapDownDetails _) {
    if (!_enabled) return;
    _cancelTimer();
    _holdStartedAt = DateTime.now();
    // タップ即時分：1 ステップ実行
    _fireStep();
    // 長押しが続く場合に備えて自動リピートをスケジュール
    _timer = Timer(_initialDelay, _autoRepeatTick);
  }

  void _autoRepeatTick() {
    if (!_enabled) {
      _cancelTimer();
      return;
    }
    _fireStep();
    final elapsed = DateTime.now().difference(_holdStartedAt!);
    final nextInterval =
        elapsed >= _accelerateAfter ? _fastInterval : _slowInterval;
    _timer = Timer(nextInterval, _autoRepeatTick);
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        _enabled ? (widget.color ?? Theme.of(context).colorScheme.primary) : Colors.grey.shade400;

    final button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _enabled ? _handleTapDown : null,
      onTapUp: (_) => _cancelTimer(),
      onTapCancel: _cancelTimer,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(widget.icon, size: widget.iconSize, color: effectiveColor),
      ),
    );

    if (widget.tooltip == null) return button;
    return Tooltip(message: widget.tooltip!, child: button);
  }
}
