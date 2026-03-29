import 'dart:async';
import 'package:flutter/material.dart';
import 'main.dart' show buildAppBar;
import 'slideshow_settings.dart' show SlideshowSettings;

// ══════════════════════════════════════════════════════════
// スライドショー画面
// ══════════════════════════════════════════════════════════
class SlideshowScreen extends StatefulWidget {
  final SlideshowSettings settings;

  const SlideshowScreen({super.key, required this.settings});

  @override
  State<SlideshowScreen> createState() => _SlideshowScreenState();
}

class _SlideshowScreenState extends State<SlideshowScreen> {
  late final int _slideDurationSec;
  late final List<String> _imagePaths;
  late final bool _loop;

  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isCounting = true;
  int _countdown = 3;
  int _remaining = 0;

  Timer? _countdownTimer;
  Timer? _slideshowTimer;
  Timer? _remainingTimer;

  String get _currentFileName => _imagePaths[_currentIndex].split('/').last;

  @override
  void initState() {
    super.initState();
    _slideDurationSec = widget.settings.slideDurationSec;
    _imagePaths = widget.settings.selectedImages;
    _loop = widget.settings.loop;
    _remaining = _slideDurationSec;
    _startCountdown();
  }

  // ── 開始カウントダウン ──────────────────────────────────
  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 1) {
        timer.cancel();
        setState(() {
          _isCounting = false;
          _isPlaying = true;
          _remaining = _slideDurationSec;
        });
        _startSlideshow();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  // ── スライドショー開始 ──────────────────────────────────
  void _startSlideshow() {
    _slideshowTimer?.cancel();
    _remainingTimer?.cancel();

    setState(() => _remaining = _slideDurationSec);

    _remainingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remaining > 1) _remaining--;
      });
    });

    _slideshowTimer = Timer.periodic(
      Duration(seconds: _slideDurationSec),
      (timer) {
        final isLast = _currentIndex >= _imagePaths.length - 1;

        if (isLast) {
          if (_loop) {
            // ループあり：最初に戻る
            _remainingTimer?.cancel();
            setState(() {
              _currentIndex = 0;
              _remaining = _slideDurationSec;
            });
            _remainingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
              if (!mounted) return;
              setState(() {
                if (_remaining > 1) _remaining--;
              });
            });
          } else {
            // ループなし：停止
            timer.cancel();
            _remainingTimer?.cancel();
            setState(() {
              _isPlaying = false;
              _remaining = 0;
            });
          }
          return;
        }

        // 通常の次画像への切り替え
        _remainingTimer?.cancel();
        setState(() {
          _currentIndex++;
          _remaining = _slideDurationSec;
        });
        _remainingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          setState(() {
            if (_remaining > 1) _remaining--;
          });
        });
      },
    );
  }

  // ── 一時停止 ───────────────────────────────────────────
  void _pause() {
    _slideshowTimer?.cancel();
    _remainingTimer?.cancel();
    setState(() => _isPlaying = false);
  }

  // ── 再開 ───────────────────────────────────────────────
  void _resume() {
    // ループなしの場合は最後の画像で再開不可
    if (!_loop && _currentIndex >= _imagePaths.length - 1) return;
    setState(() => _isPlaying = true);
    _startSlideshow();
  }

  // ── 前の画像 ───────────────────────────────────────────
  void _prev() {
    if (_currentIndex <= 0) return;
    setState(() => _currentIndex--);
    if (_isPlaying) _startSlideshow();
  }

  // ── 次の画像 ───────────────────────────────────────────
  void _next() {
    if (_currentIndex >= _imagePaths.length - 1) return;
    setState(() => _currentIndex++);
    if (_isPlaying) _startSlideshow();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _slideshowTimer?.cancel();
    _remainingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isFirst = _currentIndex == 0;
    // ループありの場合は最後の画像でも停止扱いにしない
    final bool isLast = !_loop && _currentIndex == _imagePaths.length - 1;

    return Scaffold(
      appBar: buildAppBar(context, 'スライドショー', Colors.purple),
      body: Column(
        children: [
          // ── 画像表示エリア ────────────────────────────────
          Expanded(
            child: Center(
              child: _isCounting
                  ? _buildStartCountdown()
                  : Image.asset(
                      _imagePaths[_currentIndex],
                      fit: BoxFit.contain,
                    ),
            ),
          ),

          if (!_isCounting) ...[
            // ── ファイル名表示 ────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.insert_drive_file_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _currentFileName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontFamily: 'monospace',
                    ),
                  ),
                  // ループバッジ
                  if (_loop) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.repeat, size: 11, color: Colors.purple),
                          SizedBox(width: 2),
                          Text('ループ',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.purple)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── 残り時間バー ────────────────────────────────
            _buildRemainingTimer(isLast),

            const SizedBox(height: 12),

            // ── ドットインジケーター ────────────────────────
            Text(
              '${_currentIndex + 1} / ${_imagePaths.length}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _imagePaths.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _currentIndex ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _currentIndex
                        ? Colors.purple
                        : Colors.purple.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            // ── コントロールボタン ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filled(
                    onPressed: isFirst ? null : _prev,
                    icon: const Icon(Icons.skip_previous),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          isFirst ? Colors.grey.shade300 : Colors.purple,
                      foregroundColor: Colors.white,
                      iconSize: 32,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton.filled(
                    onPressed: isLast ? null : (_isPlaying ? _pause : _resume),
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          isLast ? Colors.grey.shade300 : Colors.purple,
                      foregroundColor: Colors.white,
                      iconSize: 36,
                      padding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton.filled(
                    onPressed: isLast ? null : _next,
                    icon: const Icon(Icons.skip_next),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          isLast ? Colors.grey.shade300 : Colors.purple,
                      foregroundColor: Colors.white,
                      iconSize: 32,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStartCountdown() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('まもなく開始します',
            style: TextStyle(fontSize: 18, color: Colors.grey)),
        const SizedBox(height: 24),
        TweenAnimationBuilder<double>(
          key: ValueKey(_countdown),
          tween: Tween(begin: 1.2, end: 0.8),
          duration: const Duration(milliseconds: 800),
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Text(
            '$_countdown',
            style: const TextStyle(
              fontSize: 120,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRemainingTimer(bool isLast) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isLast ? '最後の画像です' : (_isPlaying ? '次の画像まで' : '一時停止中'),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                isLast ? '' : '$_remaining 秒',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: isLast
                  ? 1.0
                  : ((_slideDurationSec - _remaining) / _slideDurationSec),
              minHeight: 8,
              backgroundColor: Colors.purple.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
          ),
        ],
      ),
    );
  }
}
