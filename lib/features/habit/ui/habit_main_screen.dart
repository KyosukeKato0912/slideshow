import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_values.dart';
import '../../../shared/components/app_bar_widget.dart';
import 'habit_testdata.dart';

// ══════════════════════════════════════════════════════════
// 習慣化サポート メイン画面
//
// 継続カレンダー・ポモドーロタイマーボタン・設定ボタンを表示する。
// 現フェーズ：縦3行 × 横7列のカレンダーグリッドを実装。
//   1行目：曜日ラベル
//   2行目：日付（表示週に応じて動的に更新）
//   3行目：記録エリア（花丸・作業時間吹き出し）
// 行高比は 1 : 1 : 3。
// 余白・パディング・カラーは AppValues / AppColors の共通定数を使用。
// ⚠ テストデータ使用中：habit_testdata.dart を参照。
//   成長記録実装後は HabitRecord（Hive）からのデータ取得に差し替える。
// ══════════════════════════════════════════════════════════
class HabitMainScreen extends StatefulWidget {
  const HabitMainScreen({super.key});

  @override
  State<HabitMainScreen> createState() => _HabitMainScreenState();
}

class _HabitMainScreenState extends State<HabitMainScreen> {
  // ── 表示週の基準日（月曜日）────────────────────────────
  // 初期値：2026/6/1 が属する週の月曜日（= 2026/6/1）
  late DateTime _weekMonday;

  @override
  void initState() {
    super.initState();
    _weekMonday = _mondayOf(DateTime(2026, 6, 1));
  }

  // ── 指定日が属する週の月曜日を返す ──────────────────────
  static DateTime _mondayOf(DateTime date) {
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));
  }

  // ── 表示週の日付リスト（月〜日、7日分）──────────────────
  List<DateTime> get _weekDays =>
      List.generate(7, (i) => _weekMonday.add(Duration(days: i)));

  // ── 期間ラベル文字列 ─────────────────────────────────────
  String get _dateRangeLabel {
    final end = _weekMonday.add(const Duration(days: 6));
    return '${_fmt(_weekMonday)}～${_fmt(end)}';
  }

  // YYYY/M/D 形式
  static String _fmt(DateTime d) => '${d.year}/${d.month}/${d.day}';

  // M/D 形式（日付セル表示用）
  static String _shortFmt(DateTime d) => '${d.month}/${d.day}';

  // ── 今日が属する週の月曜日 ───────────────────────────────
  static DateTime get _todayMonday => _mondayOf(DateTime.now());

  // ── 現在表示中の週が今週かどうか ────────────────────────
  bool get _isCurrentWeek =>
      _weekMonday.isAtSameMomentAs(_todayMonday);

  // ── 今日の週に戻る ───────────────────────────────────────
  void _goToToday() {
    setState(() {
      _weekMonday = _todayMonday;
    });
  }

  // ── カレンダーピッカーを開き、選択週に切り替える ──────────
  Future<void> _pickWeek() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _weekMonday,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: '週を選択してください',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.theme,
            onPrimary: Colors.white,
            onSurface: Colors.black87,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _weekMonday = _mondayOf(picked);
      });
    }
  }

  // ── テストデータから表示週の日付ごとの作業時間合計を集計 ──
  // 戻り値：キー＝"yyyy-MM-dd"、値＝その日の作業時間合計(分)
  // データがない日はマップに含まれない（= 花丸なし）。
  Map<String, int> _buildDailyTotals(List<DateTime> weekDays) {
    final weekSet = {
      for (final d in weekDays) _dateKey(d),
    };
    final Map<String, int> totals = {};
    for (final r in HabitTestData.records) {
      final key = _dateKey(r.date);
      if (weekSet.contains(key)) {
        totals[key] = (totals[key] ?? 0) + r.workMinutes;
      }
    }
    return totals;
  }

  // "yyyy-MM-dd" キー生成（時刻差による不一致を防ぐ）
  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final weekDays = _weekDays;
    final dailyTotals = _buildDailyTotals(weekDays);

    return Scaffold(
      appBar: AppBarWidget(
        title: AppStrings.habitTitle,
        backgroundColor: AppColors.theme,
      ),
      body: LayoutBuilder(
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
                // ── 表題（中央揃え）──────────────────────────
                Text(
                  AppStrings.habitCalendarTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),

                // ── 期間ラベル＋今日に戻るボタン ─────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _pickWeek,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _dateRangeLabel,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.theme,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.theme,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.calendar_today,
                              size: 14, color: AppColors.theme),
                        ],
                      ),
                    ),
                    if (!_isCurrentWeek) ...[
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _goToToday,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.themeLight,
                            border: Border.all(
                                color: AppColors.themeBorder, width: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.today,
                                  size: 12, color: AppColors.themeDark),
                              const SizedBox(width: 3),
                              Text(
                                AppStrings.habitGoToToday,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.themeDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // ── カレンダーグリッド ────────────────────────
                _ContinuityCalendar(
                  weekDays: weekDays,
                  dailyTotals: dailyTotals,
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
// 継続カレンダー
//
// 縦3行 × 横7列のグリッド。
// 行高比：曜日 : 日付 : 記録 = 1 : 1 : 3
// ══════════════════════════════════════════════════════════
class _ContinuityCalendar extends StatelessWidget {
  final List<DateTime> weekDays;       // 7要素（月〜日）
  final Map<String, int> dailyTotals;  // キー="yyyy-MM-dd", 値=作業時間合計(分)

  const _ContinuityCalendar({
    required this.weekDays,
    required this.dailyTotals,
  });

  static const double _recordH = 120.0;
  static const double _headerH = _recordH / 3; // = 40.0

  // "yyyy-MM-dd" キー生成
  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 1行目：曜日ラベル ─────────────────────────────
        SizedBox(
          height: _headerH,
          child: Row(
            children: List.generate(7, (i) => Expanded(
              child: _HeaderCell(
                text: AppStrings.habitWeekdays[i],
                isWeekday: true,
              ),
            )),
          ),
        ),
        // ── 2行目：日付 ───────────────────────────────────
        SizedBox(
          height: _headerH,
          child: Row(
            children: List.generate(7, (i) => Expanded(
              child: _HeaderCell(
                text: '${weekDays[i].month}/${weekDays[i].day}',
                isWeekday: false,
              ),
            )),
          ),
        ),
        // ── 3行目：記録エリア（花丸・吹き出し）──────────────
        SizedBox(
          height: _recordH,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(7, (i) {
              final key = _dateKey(weekDays[i]);
              final hasRecord = dailyTotals.containsKey(key);
              final totalMin = dailyTotals[key] ?? 0;
              return Expanded(
                child: _RecordCell(
                  hasRecord: hasRecord,
                  totalMinutes: totalMin,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════
// ヘッダーセル（曜日・日付行 共用）
// ══════════════════════════════════════════════════════════
class _HeaderCell extends StatelessWidget {
  final String text;
  final bool isWeekday;

  const _HeaderCell({required this.text, required this.isWeekday});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: isWeekday ? AppColors.themeLight : Colors.white,
        border: Border.all(color: AppColors.themeBorder, width: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isWeekday ? FontWeight.w600 : FontWeight.normal,
            color: isWeekday ? AppColors.themeDark : Colors.black87,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// 記録セル（3行目）
//
// hasRecord=true のとき花丸（◎）を表示。
// 花丸タップで作業時間合計の吹き出しをトグル表示する。
// 別のセルをタップしても吹き出しは自動的に閉じない仕様
//（仕様書「別の花丸をタップすれば今表示している吹き出しを消して
//  新しい吹き出しを表示」は成長記録との統合時に対応予定）。
// ══════════════════════════════════════════════════════════
class _RecordCell extends StatefulWidget {
  final bool hasRecord;
  final int totalMinutes;

  const _RecordCell({
    required this.hasRecord,
    required this.totalMinutes,
  });

  @override
  State<_RecordCell> createState() => _RecordCellState();
}

class _RecordCellState extends State<_RecordCell> {
  bool _showTooltip = false;

  void _toggle() {
    setState(() {
      _showTooltip = !_showTooltip;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.themeBorder, width: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: widget.hasRecord
          ? Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // ── 花丸ボタン ───────────────────────────
                GestureDetector(
                  onTap: _toggle,
                  child: Text(
                    AppStrings.habitFlowerCircle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      color: AppColors.theme,
                      height: 1.0,
                    ),
                  ),
                ),
                // ── 吹き出し ─────────────────────────────
                if (_showTooltip)
                  Positioned(
                    bottom: 58,
                    child: GestureDetector(
                      onTap: _toggle, // 吹き出しタップで閉じる
                      child: _TooltipBubble(
                        label: widget.totalMinutes == 0
                            ? AppStrings.habitTooltipNoTime
                            : '${widget.totalMinutes}${AppStrings.habitTooltipMinSuffix}',
                      ),
                    ),
                  ),
              ],
            )
          : null, // データなし：空白
    );
  }
}

// ══════════════════════════════════════════════════════════
// 吹き出しウィジェット
// ══════════════════════════════════════════════════════════
class _TooltipBubble extends StatelessWidget {
  final String label;

  const _TooltipBubble({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── 吹き出し本体 ──────────────────────────────────
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.themeDark,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // ── 吹き出しの三角形（下向き）────────────────────
        CustomPaint(
          size: const Size(10, 6),
          painter: _TrianglePainter(color: AppColors.themeDark),
        ),
      ],
    );
  }
}

// ── 下向き三角形の CustomPainter ────────────────────────
class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}
