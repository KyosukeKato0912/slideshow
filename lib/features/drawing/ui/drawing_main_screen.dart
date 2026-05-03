import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_values.dart';
import '../../../core/extensions/int_ext.dart';
import '../../../shared/components/app_bar_widget.dart';
import '../../../core/config/drawing_config.dart';
import '../domain/drawing_model.dart';
import '../domain/drawing_settings.dart';

// ══════════════════════════════════════════════════════════
// ペアエントリ
//
// 同じモデル名を持つアセットを DrawingConfig.categories の定義順にまとめた
// 再生単位。単独の場合は models.length == 1。
// ペア内のソート順は DrawingConfig.categorySortIndex に従う。
// ══════════════════════════════════════════════════════════
class _PairEntry {
  /// ペア内のモデルリスト（DrawingConfig.categories の定義順）
  final List<DrawingModel> models;

  const _PairEntry(this.models);

  bool get hasPair => models.length >= 2;
  DrawingModel get first => models[0];
}

// ══════════════════════════════════════════════════════════
// X秒ドローイング メイン画面
//
// タイマーカウントダウン・ポーズ自動切り替えを行う本体画面。
// ── コントロール ──
//   [前へ]  前のモデルに戻る（最初のモデルでは非活性）
//   [一時停止/再開]  タイマーを停止・再開する
//   [次へ]  次のモデルに進む（ループなし・最後のモデルでは非活性）
// ══════════════════════════════════════════════════════════
class DrawingMainScreen extends StatefulWidget {
  final DrawingSettings settings;

  const DrawingMainScreen({super.key, required this.settings});

  @override
  State<DrawingMainScreen> createState() => _DrawingMainScreenState();
}

class _DrawingMainScreenState extends State<DrawingMainScreen> {
  late final int _durationSec;
  late final bool _loop;
  late final bool _shuffle;
  late final int _maxWorkTimeSec; // 0 = 無制限

  // ── プレイリスト ────────────────────────────────────────
  // ループ時に周ごとに再シャッフルできるよう、元のモデルリストを保持する
  late final List<DrawingModel> _sourceModels;

  late List<DrawingModel> _playlist;
  late List<bool> _isPairTransition;

  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isCounting = true;
  bool _isFinished = false;
  bool _isTimeUp = false; // 最大作業時間超過による終了
  bool _isShowingLabel = false;
  int _countdown = AppValues.drawingCountdownSec;

  int _remaining = 0;
  int _pausedRemaining = 0;
  DateTime? _slideStartTime;

  // 最大作業時間：スライドショー稼働中の経過秒数を積算する
  // 一時停止・ラベル表示・開始カウントダウン中はカウントしない
  int _workElapsedSec = 0;
  // 現在の画像が表示された時点の作業経過秒数。
  // ボタン切り替え時にここまで巻き戻すことで、途中切り替え分をなかったことにする。
  int _slideStartWorkElapsed = 0;
  Timer? _workElapsedTimer;

  Timer? _countdownTimer;
  Timer? _slideshowTimer;
  Timer? _remainingTimer;
  Timer? _labelTimer;

  DrawingModel get _currentModel => _playlist[_currentIndex];
  bool get _currentIsPairTransition => _isPairTransition[_currentIndex];

  int get _computedRemaining {
    if (_slideStartTime == null) return _durationSec;
    final elapsed = DateTime.now().difference(_slideStartTime!).inSeconds;
    return (_durationSec - elapsed).clamp(0, _durationSec);
  }

  // ── プレイリスト構築 ─────────────────────────────────────
  // 1. モデル名でグループ化してペアを作る
  // 2. ペア単位でシャッフル or 登録順を適用
  // 3. ペア内は DrawingConfig.categories の定義順に固定
  // 4. フラットに展開してペア内遷移フラグを付与
  static ({List<DrawingModel> playlist, List<bool> isPairTransition})
      _buildPlaylist(List<DrawingModel> models, bool shuffle) {
    // モデル名でグループ化
    final Map<String, List<DrawingModel>> grouped = {};
    for (final m in models) {
      grouped.putIfAbsent(m.modelName, () => []).add(m);
    }

    // ペアエントリを生成（ペア内は DrawingConfig.categorySortIndex 順にソート）
    final pairs = grouped.values.map((list) {
      list.sort((a, b) => DrawingConfig.categorySortIndex(a.categoryId)
          .compareTo(DrawingConfig.categorySortIndex(b.categoryId)));
      return _PairEntry(list);
    }).toList();

    // ペア単位でシャッフル or 登録順
    if (shuffle) {
      pairs.shuffle(Random());
    } else {
      final indexMap = {for (int i = 0; i < models.length; i++) models[i]: i};
      pairs.sort(
          (a, b) => (indexMap[a.first] ?? 0).compareTo(indexMap[b.first] ?? 0));
    }

    // フラット展開してペア内遷移フラグを付与
    final playlist = <DrawingModel>[];
    final isPairTransition = <bool>[];
    for (final pair in pairs) {
      for (int i = 0; i < pair.models.length; i++) {
        playlist.add(pair.models[i]);
        isPairTransition.add(i > 0); // 2枚目以降はペア内遷移
      }
    }

    return (playlist: playlist, isPairTransition: isPairTransition);
  }

  @override
  void initState() {
    super.initState();
    _durationSec = widget.settings.durationSec;
    _loop = widget.settings.loop;
    _shuffle = widget.settings.shuffle;
    _maxWorkTimeSec = widget.settings.maxWorkTimeSec;
    _sourceModels = List.of(widget.settings.selectedModels);
    _remaining = _durationSec;
    _pausedRemaining = _durationSec;

    final result = _buildPlaylist(_sourceModels, _shuffle);
    _playlist = result.playlist;
    _isPairTransition = result.isPairTransition;

    _startCountdown();
    // 最大作業時間の積算タイマーはスライドショー開始時に起動する
  }

  // ── 最大作業時間超過 ───────────────────────────────────
  void _onTimeUp() {
    if (!mounted || _isFinished || _isTimeUp) return;
    _workElapsedTimer?.cancel();
    _slideshowTimer?.cancel();
    _remainingTimer?.cancel();
    _labelTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _isTimeUp = true;
    });
  }

  // ── 作業経過タイマー起動 ──────────────────────────────
  // 画面全体で1本だけ動かす。呼び出し元：最初の _showLabelThenStart 完了後と _resume のみ。
  // 一時停止中・開始カウントダウン中・ラベル表示中は動かさない（_stopWorkElapsedTimer で止める）。
  // ボタン切り替え時はタイマーを止めず、消費分だけ _workElapsedSec を手動加算する。
  void _startWorkElapsedTimer() {
    if (_maxWorkTimeSec == 0) return; // 無制限は不要
    _workElapsedTimer?.cancel();
    _workElapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _workElapsedSec++;
      if (_workElapsedSec >= _maxWorkTimeSec) {
        _onTimeUp();
      }
    });
  }

  // ── 作業経過タイマー停止 ──────────────────────────────
  void _stopWorkElapsedTimer() {
    _workElapsedTimer?.cancel();
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
    final startSec = from ?? _durationSec;
    _slideStartTime = DateTime.now().subtract(
      Duration(seconds: _durationSec - startSec),
    );
    setState(() => _remaining = startSec);

    _remainingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining = _computedRemaining);
    });
  }

  // ── 0.5秒モデル名ラベルを表示してからスライド開始 ────────
  // [skipLabel] がtrueの場合（ペア内遷移・手動ボタン操作）はラベルをスキップ
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
    // 作業タイマー：まだ起動していない場合（初回）のみ起動する。
    // ボタン切り替え時は再起動せず、_workElapsedSec の手動加算で時間を管理する。
    if (_workElapsedTimer == null || !(_workElapsedTimer!.isActive)) {
      _startWorkElapsedTimer();
    }
    // この画像の表示開始時点の作業経過を記録（ボタン切り替え時の巻き戻し基準）
    _slideStartWorkElapsed = _workElapsedSec;
    _slideshowTimer = Timer.periodic(
      Duration(seconds: _durationSec),
      (_) => _advanceSlide(),
    );
  }

  // ── 自動で次のモデルに進む ──────────────────────────────
  void _advanceSlide() {
    final isLast = _currentIndex >= _playlist.length - 1;

    if (isLast) {
      if (_loop) {
        // 周が変わるごとに再シャッフルしてプレイリストを再構築
        final result = _buildPlaylist(_sourceModels, _shuffle);
        setState(() {
          _playlist = result.playlist;
          _isPairTransition = result.isPairTransition;
          _currentIndex = 0;
        });
        _pausedRemaining = _durationSec;
        _slideshowTimer?.cancel();
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
    _showLabelThenStart(skipLabel: _currentIsPairTransition);
  }

  // ── 一時停止 ───────────────────────────────────────────
  void _pause() {
    _slideshowTimer?.cancel();
    _remainingTimer?.cancel();
    _stopWorkElapsedTimer(); // 一時停止中は作業時間を進めない
    _pausedRemaining = _computedRemaining;
    setState(() => _isPlaying = false);
  }

  // ── 再開 ───────────────────────────────────────────────
  void _resume() {
    setState(() => _isPlaying = true);
    _restartRemainingTimer(from: _pausedRemaining);
    _startWorkElapsedTimer(); // 一時停止から再開するので作業タイマーも再開
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
    _workElapsedTimer?.cancel();
    _slideshowTimer?.cancel();
    _remainingTimer?.cancel();
    // 再スタート時は再シャッフルしてプレイリストを再構築
    final result = _buildPlaylist(_sourceModels, _shuffle);
    setState(() {
      _playlist = result.playlist;
      _isPairTransition = result.isPairTransition;
      _currentIndex = 0;
      _isFinished = false;
      _isTimeUp = false;
      _workElapsedSec = 0; // 経過秒数リセット
      _slideStartWorkElapsed = 0;
      _isPlaying = true;
    });
    _showLabelThenStart();
  }

  // ── 前のモデルへ ───────────────────────────────────────
  // ループ+シャッフル時：先頭で「前へ」を押したら周をまたいで1つ前に戻る
  void _prev() {
    _slideshowTimer?.cancel();
    // ボタン切り替え：この画像を見た時間をなかったことにするため、
    // 作業経過をこの画像が表示された時点（_slideStartWorkElapsed）に巻き戻す。
    _workElapsedSec = _slideStartWorkElapsed;
    _pausedRemaining = _durationSec;
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    } else if (_loop) {
      // 先頭で前へ → 前周の最後に戻る（再シャッフルして末尾へ）
      final result = _buildPlaylist(_sourceModels, _shuffle);
      setState(() {
        _playlist = result.playlist;
        _isPairTransition = result.isPairTransition;
        _currentIndex = _playlist.length - 1;
      });
    } else {
      return; // ループなし先頭は何もしない
    }
    if (_isPlaying) _showLabelThenStart(skipLabel: true);
  }

  // ── 次のモデルへ ───────────────────────────────────────
  void _next() {
    final isLast = _currentIndex >= _playlist.length - 1;
    if (isLast && !_loop) return;
    _slideshowTimer?.cancel();
    // ボタン切り替え：この画像を見た時間をなかったことにするため、
    // 作業経過をこの画像が表示された時点（_slideStartWorkElapsed）に巻き戻す。
    _workElapsedSec = _slideStartWorkElapsed;
    _pausedRemaining = _durationSec;
    if (isLast && _loop) {
      final result = _buildPlaylist(_sourceModels, _shuffle);
      setState(() {
        _playlist = result.playlist;
        _isPairTransition = result.isPairTransition;
        _currentIndex = 0;
      });
    } else {
      setState(() => _currentIndex++);
    }
    if (_isPlaying) _showLabelThenStart(skipLabel: true);
  }

  @override
  void dispose() {
    _workElapsedTimer?.cancel();
    _countdownTimer?.cancel();
    _slideshowTimer?.cancel();
    _remainingTimer?.cancel();
    _labelTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ループ時は先頭でも「前へ」を有効にする（前周末尾へ戻る）
    final bool isFirst = !_loop && _currentIndex == 0;
    final bool isLast = !_loop && _currentIndex == _playlist.length - 1;

    return Scaffold(
      appBar: AppBarWidget(
        title: AppStrings.drawingMainTitle,
        backgroundColor: AppColors.drawing,
      ),
      body: Column(
        children: [
          // ── 画像表示エリア ────────────────────────────────
          Expanded(
            child: _isCounting
                ? Center(child: _StartCountdownDisplay(countdown: _countdown))
                : (_isFinished || _isTimeUp)
                    ? Center(
                        child: _EndScreen(
                          totalCount: _playlist.length,
                          isTimeUp: _isTimeUp,
                          onRestart: _restart,
                        ),
                      )
                    : _isShowingLabel
                        ? Center(
                            child: _ModelNameLabelDisplay(
                                modelName: _currentModel.modelName),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final double areaW = constraints.maxWidth;
                              final double areaH = constraints.maxHeight;

                              // パネル幅：全体幅の10%、80〜160px
                              final double panelW =
                                  (areaW * 0.10).clamp(80.0, 160.0);
                              // タイマーサイズ：パネル幅の75%
                              final double timerSize =
                                  (panelW * 0.75).clamp(60.0, 120.0);
                              // 外余白
                              final double outerPad =
                                  (areaW * AppValues.outerPadRatio).clamp(
                                      AppValues.outerPadMin,
                                      AppValues.outerPadMax);
                              // 内余白（パネルと画像の間）
                              final double innerPad =
                                  (areaW * 0.015).clamp(6.0, 16.0);

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(width: outerPad),
                                  // ── 左帯：モデル情報パネル ──────
                                  SizedBox(
                                    width: panelW,
                                    height: areaH,
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: _ModelInfoPanel(
                                          model: _currentModel,
                                          loop: _loop,
                                          shuffle: widget.settings.shuffle,
                                          maxWorkTimeSec: _maxWorkTimeSec,
                                          workElapsedSec: _workElapsedSec,
                                          panelW: panelW,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: innerPad),
                                  // ── 中央：モデル画像 ────────────
                                  Expanded(
                                    child: Image.asset(
                                      _currentModel.path,
                                      fit: BoxFit.contain,
                                      height: areaH,
                                    ),
                                  ),
                                  SizedBox(width: innerPad),
                                  // ── 右帯：タイマー ──────────────
                                  SizedBox(
                                    width: panelW,
                                    height: areaH,
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: _CircularCountdownTimer(
                                          remaining: _remaining,
                                          durationSec: _durationSec,
                                          isPaused: !_isPlaying,
                                          size: timerSize,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: outerPad),
                                ],
                              );
                            },
                          ),
          ),

          if (!_isCounting && !_isFinished && !_isTimeUp) ...[
            // ── ページ数 ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${_currentIndex + 1} / ${_playlist.length}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),

            // ── ドットインジケーター（20枚以下のみ） ──────
            if (_playlist.length <= AppValues.drawingDotIndicatorMaxCount)
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
                            ? AppColors.drawing
                            : _isPairTransition[i]
                                ? AppColors.drawingLight
                                : AppColors.drawingBorder,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

            // ── コントロールボタン ──────────────────────
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
                          isFirst ? Colors.grey.shade300 : AppColors.drawing,
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
                      backgroundColor: AppColors.drawing,
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
                          isLast ? Colors.grey.shade300 : AppColors.drawing,
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
}

// ══════════════════════════════════════════════════════════
// 左帯：モデル情報パネル（カテゴリ・モデル名・作者・バッジ）
// ══════════════════════════════════════════════════════════
class _ModelInfoPanel extends StatelessWidget {
  final DrawingModel model;
  final bool loop;
  final bool shuffle;
  /// 最大作業時間（秒）。0 = 無制限。
  final int maxWorkTimeSec;
  /// 現在の作業経過秒数（スライドショー稼働中のみ加算）。
  final int workElapsedSec;
  final double panelW;

  const _ModelInfoPanel({
    required this.model,
    required this.loop,
    required this.shuffle,
    required this.maxWorkTimeSec,
    required this.workElapsedSec,
    required this.panelW,
  });

  @override
  Widget build(BuildContext context) {
    final double catFontSize = (panelW * 0.12).clamp(9.0, 15.0);
    final double nameFontSize = (panelW * 0.16).clamp(11.0, 20.0);
    final double authFontSize = (panelW * 0.12).clamp(9.0, 15.0);
    final double badgeFontSize = (panelW * 0.10).clamp(8.0, 13.0);
    final double badgeIconSize = (panelW * 0.12).clamp(9.0, 14.0);
    final double spacing = (panelW * 0.03).clamp(2.0, 5.0);
    final double badgeSpacing = (panelW * 0.04).clamp(3.0, 6.0);
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
                model.categoryName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: catFontSize,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: spacing),
            // モデル名
            SizedBox(
              width: maxTextW,
              child: Text(
                model.modelName,
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
            if (model.authorName.isNotEmpty) ...[
              SizedBox(height: spacing),
              SizedBox(
                width: maxTextW,
                child: Text(
                  '${AppStrings.drawingAuthorPrefix}${model.authorName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: authFontSize,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
            // ループ・シャッフル・最大作業時間バッジ
            if (loop || shuffle || maxWorkTimeSec > 0) ...[
              SizedBox(height: spacing * 2),
              Wrap(
                spacing: badgeSpacing,
                runSpacing: badgeSpacing,
                children: [
                  if (loop)
                    _StatusBadge(
                      icon: Icons.repeat,
                      label: AppStrings.drawingLoopBadge,
                      fontSize: badgeFontSize,
                      iconSize: badgeIconSize,
                    ),
                  if (shuffle)
                    _StatusBadge(
                      icon: Icons.shuffle,
                      label: AppStrings.drawingShuffleBadge,
                      fontSize: badgeFontSize,
                      iconSize: badgeIconSize,
                    ),
                  if (maxWorkTimeSec > 0)
                    _StatusBadge(
                      icon: Icons.hourglass_bottom,
                      label: (maxWorkTimeSec - workElapsedSec)
                          .clamp(0, maxWorkTimeSec)
                          .toDisplayDuration(),
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
}

// ══════════════════════════════════════════════════════════
// 右帯：円形タイマー
// ══════════════════════════════════════════════════════════
class _CircularCountdownTimer extends StatelessWidget {
  final int remaining;
  final int durationSec;
  final bool isPaused;
  final double size;

  const _CircularCountdownTimer({
    required this.remaining,
    required this.durationSec,
    required this.isPaused,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = durationSec > 0 ? remaining / durationSec : 0.0;
    final double strokeWidth = (size * 0.07).clamp(4.0, 8.0);
    final double numFontSize = (size * 0.30).clamp(18.0, 36.0);
    final double labelFontSize = (size * 0.13).clamp(9.0, 15.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.drawingLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.drawingBorder, width: 1),
            ),
          ),
          CircularProgressIndicator(
            value: progress,
            strokeWidth: strokeWidth,
            backgroundColor: AppColors.drawingBorder,
            valueColor: AlwaysStoppedAnimation<Color>(
              isPaused ? Colors.grey.shade400 : AppColors.drawing,
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$remaining',
                  style: TextStyle(
                    fontSize: numFontSize,
                    fontWeight: FontWeight.bold,
                    color: isPaused ? Colors.grey.shade500 : AppColors.drawing,
                    height: 1.0,
                  ),
                ),
                Text(
                  isPaused
                      ? AppStrings.drawingPauseLabel
                      : AppStrings.drawingSecLabel,
                  style: TextStyle(
                    fontSize: labelFontSize,
                    color: isPaused
                        ? Colors.grey.shade400
                        : AppColors.drawing.withAlpha(153),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// 開始カウントダウン表示
// ══════════════════════════════════════════════════════════
class _StartCountdownDisplay extends StatelessWidget {
  final int countdown;

  const _StartCountdownDisplay({required this.countdown});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppStrings.drawingCountdownLabel,
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        TweenAnimationBuilder<double>(
          key: ValueKey(countdown),
          tween: Tween(begin: 1.2, end: 0.8),
          duration: const Duration(milliseconds: 800),
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Text(
            '$countdown',
            style: const TextStyle(
              fontSize: 120,
              fontWeight: FontWeight.bold,
              color: AppColors.drawing,
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════
// 0.5秒表示モデル名ラベル
// ══════════════════════════════════════════════════════════
class _ModelNameLabelDisplay extends StatelessWidget {
  final String modelName;

  const _ModelNameLabelDisplay({required this.modelName});

  @override
  Widget build(BuildContext context) {
    return Text(
      modelName,
      style: const TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: AppColors.drawing,
      ),
      textAlign: TextAlign.center,
    );
  }
}

// ══════════════════════════════════════════════════════════
// 終了画面
// ══════════════════════════════════════════════════════════
class _EndScreen extends StatelessWidget {
  final int totalCount;
  final bool isTimeUp;
  final VoidCallback onRestart;

  const _EndScreen({
    required this.totalCount,
    required this.onRestart,
    this.isTimeUp = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppStrings.drawingEndLabel,
          style: const TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.bold,
            color: AppColors.drawing,
            letterSpacing: 8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.drawingEndSubLabel,
          style: TextStyle(
            fontSize: 18,
            color: AppColors.drawing.withAlpha(180),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isTimeUp ? '最大作業時間に達しました' : '全 $totalCount 枚 完了',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 48),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.drawing,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onRestart,
          icon: const Icon(Icons.replay),
          label: Text(
            AppStrings.drawingRestartButton,
            style: const TextStyle(fontSize: 16),
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
        color: AppColors.drawingLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.drawingBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: AppColors.drawing),
          const SizedBox(width: 2),
          Text(label,
              style: TextStyle(fontSize: fontSize, color: AppColors.drawing)),
        ],
      ),
    );
  }
}
