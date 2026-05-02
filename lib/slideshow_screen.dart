import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'app_bar_helper.dart';
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

  AppAsset get _currentAsset => _playlist[_currentIndex];
  String get _currentModelName => _currentAsset.modelName;
  String get _currentAuthor => _currentAsset.author;
  String get _currentCategory => _currentAsset.category;
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
      list.sort((a, b) => pairCategoryIndex(a.category)
          .compareTo(pairCategoryIndex(b.category)));
      return _PairEntry(list);
    }).toList();

    // ペア単位でシャッフル or 登録順（登録順は assets の出現順を維持）
    if (shuffle) {
      pairs.shuffle(Random());
    } else {
      // assets のソート順（= app_assets.dart のカテゴリ定義順）を維持するため
      // 各ペアの先頭アセットの assets 内インデックスを基準にソート
      final indexMap = {for (int i = 0; i < assets.length; i++) assets[i]: i};
      pairs.sort(
          (a, b) => (indexMap[a.first] ?? 0).compareTo(indexMap[b.first] ?? 0));
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
        _pausedRemaining = _slideDurationSec; // ループ先頭に戻る際もリセット
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
    // 手動移動時は残り時間をフルにリセット
    _pausedRemaining = _slideDurationSec;
    // ボタン操作ではラベルを表示しない（自動切り替え時のみ表示）
    if (_isPlaying) _showLabelThenStart(skipLabel: true);
  }

  // ── 次の画像 ───────────────────────────────────────────
  void _next() {
    final isLast = _currentIndex >= _playlist.length - 1;
    if (isLast && !_loop) return;
    _slideshowTimer?.cancel();
    // 手動移動時は残り時間をフルにリセット
    _pausedRemaining = _slideDurationSec;
    if (isLast && _loop) {
      // ループ時は先頭に戻る
      setState(() => _currentIndex = 0);
      // ボタン操作ではラベルを表示しない（自動切り替え時のみ表示）
      if (_isPlaying) _showLabelThenStart(skipLabel: true);
    } else {
      setState(() => _currentIndex++);
      // ボタン操作ではラベルを表示しない（自動切り替え時のみ表示）
      if (_isPlaying) _showLabelThenStart(skipLabel: true);
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
          // ── 画像表示エリア（情報・カウントダウンはオーバーレイ） ──
          Expanded(
            child: _isCounting
                ? Center(child: _buildStartCountdown())
                : _isFinished
                    ? Center(child: _buildEndScreen())
                    : _isShowingLabel
                        ? Center(child: _buildModelNameLabel())
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final double areaW = constraints.maxWidth;
                              final double areaH = constraints.maxHeight;

                              // ── パネルサイズ ──────────────────────────────
                              // 帯幅：全体幅の 10%。最小80・最大160px。
                              final double panelW =
                                  (areaW * 0.10).clamp(80.0, 160.0);
                              // タイマー：帯幅の 75%
                              final double timerSize =
                                  (panelW * 0.75).clamp(60.0, 120.0);

                              // ── 余白 ─────────────────────────────────────
                              // 外余白（帯の外側）：全体幅の 2%。最小8・最大24px。
                              final double outerPad =
                                  (areaW * 0.2).clamp(4.0, 240.0);
                              // 内余白（帯と画像の間）：全体幅の 1.5%。最小6・最大16px。
                              final double innerPad =
                                  (areaW * 0.015).clamp(6.0, 16.0);

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 外余白（左）
                                  SizedBox(width: outerPad),
                                  // ── 左帯：情報パネル ──────────────────
                                  SizedBox(
                                    width: panelW,
                                    height: areaH,
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child:
                                            _buildInfoOverlay(panelW: panelW),
                                      ),
                                    ),
                                  ),
                                  // 内余白（左パネル〜画像）
                                  SizedBox(width: innerPad),
                                  // ── 中央：画像 ───────────────────────
                                  Expanded(
                                    child: Image.asset(
                                      _currentAsset.path,
                                      fit: BoxFit.contain,
                                      height: areaH,
                                    ),
                                  ),
                                  // 内余白（画像〜右パネル）
                                  SizedBox(width: innerPad),
                                  // ── 右帯：タイマー ────────────────────
                                  SizedBox(
                                    width: panelW,
                                    height: areaH,
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: _buildCircularCountdown(
                                            size: timerSize),
                                      ),
                                    ),
                                  ),
                                  // 外余白（右）
                                  SizedBox(width: outerPad),
                                ],
                              );
                            },
                          ),
          ),

          if (!_isCounting && !_isFinished) ...[
            // ── ページ数 ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${_currentIndex + 1} / ${_playlist.length}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),

            // ── ドットインジケーター（20枚以下のみ） ──────────
            if (_playlist.length <= 20)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: List.generate(
                    _playlist.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _currentIndex ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
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
              padding: const EdgeInsets.symmetric(vertical: 12),
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

  // ── 左帯：カテゴリ・モデル名・作者・バッジ ──────────────
  // panelW: 帯の幅px。フォントサイズはこれを基準にする。
  Widget _buildInfoOverlay({required double panelW}) {
    // 帯幅の割合でフォントサイズを決定
    final double catFontSize = (panelW * 0.12).clamp(9.0, 15.0);
    final double nameFontSize = (panelW * 0.16).clamp(11.0, 20.0);
    final double authFontSize = (panelW * 0.12).clamp(9.0, 15.0);
    final double badgeFontSize = (panelW * 0.10).clamp(8.0, 13.0);
    final double badgeIconSize = (panelW * 0.12).clamp(9.0, 14.0);
    final double spacing = (panelW * 0.03).clamp(2.0, 5.0);
    final double badgeSpacing = (panelW * 0.04).clamp(3.0, 6.0);
    // 帯内に収めるための最大幅（左右 4px ずつパディング）
    final double maxTextW = panelW - 8;

    return SizedBox(
      width: panelW,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // カテゴリ
            SizedBox(
              width: maxTextW,
              child: Text(
                _currentCategory,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: catFontSize,
                  color: Colors.purple.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: spacing),
            // モデル名
            SizedBox(
              width: maxTextW,
              child: Text(
                _currentModelName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: nameFontSize,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // 作者
            if (_currentAuthor.isNotEmpty) ...[
              SizedBox(height: spacing),
              SizedBox(
                width: maxTextW,
                child: Text(
                  '作者：$_currentAuthor',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: authFontSize,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
            // ループ・シャッフルバッジ
            if (_loop || widget.settings.shuffle) ...[
              SizedBox(height: spacing * 2),
              Wrap(
                spacing: badgeSpacing,
                runSpacing: badgeSpacing,
                children: [
                  if (_loop)
                    _StatusBadge(
                      icon: Icons.repeat,
                      label: 'ループ',
                      fontSize: badgeFontSize,
                      iconSize: badgeIconSize,
                    ),
                  if (widget.settings.shuffle)
                    _StatusBadge(
                      icon: Icons.shuffle,
                      label: 'シャッフル',
                      fontSize: badgeFontSize,
                      iconSize: badgeIconSize,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── 右上オーバーレイ：円形カウントダウン ──────────────
  // size: 円のpxサイズ（LayoutBuilderから渡される）
  Widget _buildCircularCountdown({required double size}) {
    final double progress =
        _slideDurationSec > 0 ? _remaining / _slideDurationSec : 0.0;
    final bool paused = !_isPlaying;

    final double strokeWidth = (size * 0.07).clamp(4.0, 8.0);
    final double numFontSize = (size * 0.30).clamp(18.0, 36.0);
    final double labelFontSize = (size * 0.13).clamp(9.0, 15.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 背景円
          Container(
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.purple.shade100, width: 1),
            ),
          ),
          // 円形プログレスバー
          CircularProgressIndicator(
            value: progress,
            strokeWidth: strokeWidth,
            backgroundColor: Colors.purple.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(
              paused ? Colors.grey.shade400 : Colors.purple,
            ),
          ),
          // 残り秒数
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_remaining',
                  style: TextStyle(
                    fontSize: numFontSize,
                    fontWeight: FontWeight.bold,
                    color: paused ? Colors.grey.shade500 : Colors.purple,
                    height: 1.0,
                  ),
                ),
                Text(
                  paused ? '停止' : '秒',
                  style: TextStyle(
                    fontSize: labelFontSize,
                    color:
                        paused ? Colors.grey.shade400 : Colors.purple.shade300,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 0.5秒表示ラベル（モデル名のみ） ──────────────────
  Widget _buildModelNameLabel() {
    return Text(
      _currentModelName,
      style: const TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: Colors.purple,
      ),
      textAlign: TextAlign.center,
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
}

// ══════════════════════════════════════════════════════════
// ステータスバッジ（ループ・シャッフル表示用）
// ══════════════════════════════════════════════════════════
class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final double fontSize;
  final double iconSize;

  const _StatusBadge({
    required this.icon,
    required this.label,
    this.fontSize = 10,
    this.iconSize = 11,
  });

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
          Icon(icon, size: iconSize, color: Colors.purple),
          const SizedBox(width: 2),
          Text(label,
              style: TextStyle(fontSize: fontSize, color: Colors.purple)),
        ],
      ),
    );
  }
}
