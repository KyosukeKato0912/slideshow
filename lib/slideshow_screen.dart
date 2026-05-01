import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'main.dart' show AppBarHelper;
import 'app_assets.dart';
import 'slideshow_settings_model.dart';

// ══════════════════════════════════════════════════════════
// ペアエントリ
// 同じモデル名を持つアセットを「全身頭身高 → 全身頭身低」順にまとめた
// 再生単位。単独の場合は assets.length == 1。
// ══════════════════════════════════════════════════════════
class _PairEntry {
  final List<AppAsset> assets; // 全身頭身高が[0]、全身頭身低が[1]（あれば）

  const _PairEntry(this.assets);

  bool get hasPair => assets.length >= 2;
  AppAsset get first => assets[0];
}

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
  late final bool _loop;

  // ── プレイリスト ────────────────────────────────────────
  // ペア単位のリスト（シャッフルはペア単位で行う）
  late final List<_PairEntry> _pairs;

  // フラット展開した再生リスト（実際に表示する順序）
  // ペア内は 全身頭身高→全身頭身低 固定。ペア間はシャッフル or 登録順。
  late final List<AppAsset> _playlist;

  // _playlist 上の各インデックスがペア内遷移かどうか
  // true = 直前と同じモデル名（ペア内の2枚目）
  late final List<bool> _isPairTransition;

  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isCounting = true;
  bool _isFinished = false;
  bool _isShowingLabel = false;
  int _countdown = 3;

  int _remaining = 0;
  int _pausedRemaining = 0;
  DateTime? _slideStartTime;

  Timer? _countdownTimer;
  Timer? _slideshowTimer;
  Timer? _remainingTimer;
  Timer? _labelTimer;

  AppAsset get _currentAsset    => _playlist[_currentIndex];
  String get _currentModelName  => _currentAsset.modelName;
  String get _currentAuthor     => _currentAsset.author;
  String get _currentCategory   => _currentAsset.category;
  bool get _currentIsPairTransition => _isPairTransition[_currentIndex];

  int get _computedRemaining {
    if (_slideStartTime == null) return _slideDurationSec;
    final elapsed = DateTime.now().difference(_slideStartTime!).inSeconds;
    return (_slideDurationSec - elapsed).clamp(0, _slideDurationSec);
  }

  // ── プレイリスト構築 ─────────────────────────────────────
  // 1. モデル名でグループ化してペアを作る
  // 2. ペア単位でシャッフル or 登録順を適用
  // 3. ペア内は 全身頭身高→全身頭身低 の順に固定
  // 4. フラットに展開してペア内遷移フラグを付与
  static ({List<AppAsset> playlist, List<bool> isPairTransition})
      _buildPlaylist(List<AppAsset> assets, bool shuffle) {
    // カテゴリの優先順（ペア内の表示順）
    const pairOrder = ['全身頭身高', '全身頭身低'];
    int pairCategoryIndex(String cat) {
      final i = pairOrder.indexOf(cat);
      return i == -1 ? pairOrder.length : i;
    }

    // モデル名でグループ化
    final Map<String, List<AppAsset>> grouped = {};
    for (final a in assets) {
      grouped.putIfAbsent(a.modelName, () => []).add(a);
    }

    // ペアエントリを生成（ペア内はカテゴリ順にソート）
    final pairs = grouped.values.map((list) {
      list.sort((a, b) =>
          pairCategoryIndex(a.category).compareTo(pairCategoryIndex(b.category)));
      return _PairEntry(list);
    }).toList();

    // ペア単位でシャッフル or 登録順（登録順は assets の出現順を維持）
    if (shuffle) {
      pairs.shuffle(Random());
    } else {
      // assets のソート順（= app_assets.dart のカテゴリ定義順）を維持するため
      // 各ペアの先頭アセットの assets 内インデックスを基準にソート
      final indexMap = {for (int i = 0; i < assets.length; i++) assets[i]: i};
      pairs.sort((a, b) =>
          (indexMap[a.first] ?? 0).compareTo(indexMap[b.first] ?? 0));
    }

    // フラットに展開してペア内遷移フラグを付与
    final playlist = <AppAsset>[];
    final isPairTransition = <bool>[];
    for (final pair in pairs) {
      for (int i = 0; i < pair.assets.length; i++) {
        playlist.add(pair.assets[i]);
        isPairTransition.add(i > 0); // 2枚目以降はペア内遷移
      }
    }

    return (playlist: playlist, isPairTransition: isPairTransition);
  }

  @override
  void initState() {
    super.initState();
    _slideDurationSec = widget.settings.slideDurationSec;
    _loop = widget.settings.loop;
    _remaining = _slideDurationSec;
    _pausedRemaining = _slideDurationSec;

    final result = _buildPlaylist(
      widget.settings.selectedAssets,
      widget.settings.shuffle,
    );
    _playlist = result.playlist;
    _isPairTransition = result.isPairTransition;

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
        });
        _showLabelThenStart();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  // ── 残り時間タイマーを指定秒数からリセット・再開 ─────────
  void _restartRemainingTimer({int? from}) {
    _remainingTimer?.cancel();
    final startSec = from ?? _slideDurationSec;
    _slideStartTime = DateTime.now().subtract(
      Duration(seconds: _slideDurationSec - startSec),
    );
    setState(() => _remaining = startSec);

    _remainingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining = _computedRemaining);
    });
  }

  // ── ラベル表示してからスライドショー開始 ────────────────
  // ペア内遷移の場合はラベルを表示せず即スタート
  void _showLabelThenStart({bool skipLabel = false}) {
    _labelTimer?.cancel();
    if (skipLabel) {
      _startSlideshow();
      return;
    }
    setState(() => _isShowingLabel = true);
    _labelTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _isShowingLabel = false);
      _startSlideshow();
    });
  }

  // ── スライドショー開始（フル秒数から） ──────────────────
  void _startSlideshow() {
    _slideshowTimer?.cancel();
    _restartRemainingTimer();

    _slideshowTimer = Timer.periodic(
      Duration(seconds: _slideDurationSec),
      (_) => _advanceSlide(),
    );
  }

  // ── スライドを1枚進める ──────────────────────────────────
  void _advanceSlide() {
    final isLast = _currentIndex >= _playlist.length - 1;

    if (isLast) {
      if (_loop) {
        setState(() => _currentIndex = 0);
        _slideshowTimer?.cancel();
        // ループ先頭はペア内遷移ではないのでラベルあり
        _showLabelThenStart();
      } else {
        _slideshowTimer?.cancel();
        _remainingTimer?.cancel();
        setState(() {
          _isPlaying = false;
          _remaining = 0;
          _isFinished = true;
        });
      }
      return;
    }

    setState(() => _currentIndex++);
    _slideshowTimer?.cancel();
    // 次がペア内遷移ならラベルをスキップ
    _showLabelThenStart(skipLabel: _currentIsPairTransition);
  }

  // ── 一時停止 ───────────────────────────────────────────
  void _pause() {
    _slideshowTimer?.cancel();
    _remainingTimer?.cancel();
    _pausedRemaining = _remaining;
    setState(() => _isPlaying = false);
  }

  // ── 再開 ───────────────────────────────────────────────
  void _resume() {
    setState(() => _isPlaying = true);
    _restartRemainingTimer(from: _pausedRemaining);

    _slideshowTimer?.cancel();
    _slideshowTimer = Timer(
      Duration(seconds: _pausedRemaining),
      () {
        if (!mounted) return;
        _advanceSlide();
      },
    );
  }

  // ── 最初から ───────────────────────────────────────────
  void _restart() {
    _slideshowTimer?.cancel();
    _remainingTimer?.cancel();
    setState(() {
      _currentIndex = 0;
      _isFinished = false;
      _isPlaying = true;
    });
    _showLabelThenStart();
  }

  // ── 前の画像 ───────────────────────────────────────────
  void _prev() {
    if (_currentIndex <= 0) return;
    _slideshowTimer?.cancel();
    setState(() => _currentIndex--);
    if (_isPlaying) _showLabelThenStart(skipLabel: _currentIsPairTransition);
  }

  // ── 次の画像 ───────────────────────────────────────────
  void _next() {
    final isLast = _currentIndex >= _playlist.length - 1;
    if (isLast && !_loop) return;
    _slideshowTimer?.cancel();
    if (isLast && _loop) {
      // ループ時は先頭に戻る
      setState(() => _currentIndex = 0);
      if (_isPlaying) _showLabelThenStart();
    } else {
      setState(() => _currentIndex++);
      if (_isPlaying) _showLabelThenStart(skipLabel: _currentIsPairTransition);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _slideshowTimer?.cancel();
    _remainingTimer?.cancel();
    _labelTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isFirst = _currentIndex == 0;
    final bool isLast = !_loop && _currentIndex == _playlist.length - 1;

    return Scaffold(
      appBar: AppBarHelper.build(context, 'X秒ドローイング', Colors.purple),
      body: Column(
        children: [
          // ── 画像表示エリア ────────────────────────────────
          Expanded(
            child: Center(
              child: _isCounting
                  ? _buildStartCountdown()
                  : _isFinished
                      ? _buildEndScreen()
                      : _isShowingLabel
                          ? _buildModelNameLabel()
                          : Image.asset(
                              _currentAsset.path,
                              fit: BoxFit.contain,
                            ),
            ),
          ),

          if (!_isCounting && !_isFinished) ...[
            // ── 情報表示エリア ────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  Text(
                    _currentCategory,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.purple.shade300,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _currentModelName,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_currentAuthor.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '作者：$_currentAuthor',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  if (_loop || widget.settings.shuffle) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_loop) const _StatusBadge(icon: Icons.repeat, label: 'ループ'),
                        if (_loop && widget.settings.shuffle) const SizedBox(width: 8),
                        if (widget.settings.shuffle)
                          const _StatusBadge(icon: Icons.shuffle, label: 'シャッフル'),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // ── 残り時間バー ────────────────────────────────
            _buildRemainingTimer(),

            const SizedBox(height: 12),

            // ── ページ数 ────────────────────────────────────
            Text(
              '${_currentIndex + 1} / ${_playlist.length}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 6),

            // ── ドットインジケーター（20枚以下のみ） ──────────
            if (_playlist.length <= 20)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: List.generate(
                    _playlist.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _currentIndex ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        // ペア内の画像は少し薄い色で区別
                        color: i == _currentIndex
                            ? Colors.purple
                            : _isPairTransition[i]
                                ? Colors.purple.shade100
                                : Colors.purple.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
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
                    onPressed: _isPlaying ? _pause : _resume,
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.purple,
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

  // ── 0.5秒表示ラベル（モデル名のみ・カテゴリなし） ─────────
  Widget _buildModelNameLabel() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _currentModelName,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
          textAlign: TextAlign.center,
        ),
        if (_currentAuthor.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '作者：$_currentAuthor',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildEndScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'END',
          style: TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
            letterSpacing: 8,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '全 ${_playlist.length} 枚 完了',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 48),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _restart,
          icon: const Icon(Icons.replay),
          label: const Text('最初から', style: TextStyle(fontSize: 16)),
        ),
      ],
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

  Widget _buildRemainingTimer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isPlaying ? '次の画像まで' : '一時停止中',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                '$_remaining 秒',
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
              value: (_slideDurationSec - _remaining) / _slideDurationSec,
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

// ══════════════════════════════════════════════════════════
// ステータスバッジ（ループ・シャッフル表示用）
// ══════════════════════════════════════════════════════════
class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatusBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.purple),
          const SizedBox(width: 2),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.purple)),
        ],
      ),
    );
  }
}
