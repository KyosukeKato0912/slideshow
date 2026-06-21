import 'package:flutter/material.dart';
import '../../../core/config/habit_config.dart';
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

  // ── 現在吹き出しを表示中の日付キー（"yyyy-MM-dd"）────────
  // null のときはどの吹き出しも表示していない。
  // 単一値で管理することで「別の花丸をタップしたら
  // 表示中の吹き出しを閉じて新しい吹き出しを開く」を実現する。
  String? _openTooltipKey;

  @override
  void initState() {
    super.initState();
    _weekMonday = _todayMonday; // 画面を開いたら常に今日が属する週を表示
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
      _openTooltipKey = null; // 週が変わるので開いていた吹き出しは閉じる
    });
  }

  // ── 前の週に切り替える ───────────────────────────────────
  void _goToPreviousWeek() {
    setState(() {
      _weekMonday = _weekMonday.subtract(const Duration(days: 7));
      _openTooltipKey = null;
    });
  }

  // ── 次の週に切り替える ───────────────────────────────────
  void _goToNextWeek() {
    setState(() {
      _weekMonday = _weekMonday.add(const Duration(days: 7));
      _openTooltipKey = null;
    });
  }

  // ── 吹き出しの開閉をトグル ───────────────────────────────
  // 同じセルを再タップ：閉じる
  // 別のセルをタップ：表示中の吹き出しを閉じて新しいセルを開く
  void _toggleTooltip(String dateKey) {
    setState(() {
      _openTooltipKey = (_openTooltipKey == dateKey) ? null : dateKey;
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
        _openTooltipKey = null; // 週が変わるので開いていた吹き出しは閉じる
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

  // ── テストデータ全体から「記録のある日付」の集合を作成 ──
  // 連続日数の判定には表示週外のデータも必要なため、
  // 表示週で絞り込む前の全期間データから集合を作る。
  late final Set<String> _recordedDateKeys = {
    for (final r in HabitTestData.records) _dateKey(r.date),
  };

  // ── 指定日が属する連続記録区間の「総日数」を計算する ────
  // 指定日自体に記録がない場合は 0 を返す。
  // 前後両方向に記録が途切れるまで辿り、区間全体の長さを返す。
  //
  // 「21日目以降は1日目からその日までが濃い黄色になる」仕様のため、
  // 色判定は「その日までの連続日数」ではなく
  // 「その日が含まれる連続区間が現時点で何日続いているか」で行う。
  // 例：6/1〜6/25まで毎日記録がある場合、6/21時点で区間長が21に達するため
  //     6/1〜6/21までのセルが一斉に濃い黄色になる。
  int _streakSpanAt(DateTime date) {
    final key = _dateKey(date);
    if (!_recordedDateKeys.contains(key)) return 0;

    // 過去方向の連続日数（指定日を含む）
    int backCount = 0;
    DateTime cursor = date;
    while (_recordedDateKeys.contains(_dateKey(cursor))) {
      backCount++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    // 未来方向の連続日数（指定日翌日から、ただし「今日」より先は数えない）
    // ※ 今日以降の未確定な日付まで連続とみなさないようにするため。
    int forwardCount = 0;
    cursor = date.add(const Duration(days: 1));
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    while (!cursor.isAfter(todayDate) &&
        _recordedDateKeys.contains(_dateKey(cursor))) {
      forwardCount++;
      cursor = cursor.add(const Duration(days: 1));
    }

    return backCount + forwardCount;
  }

  // ── 連続区間の長さに応じたセル背景色を返す ─────────────
  // 記録なし、または連続1日のみ：白
  // 区間長 2〜20：薄い黄色
  // 区間長 21以上：濃い黄色（区間全体が濃い黄色になる）
  Color _streakColor(DateTime date) {
    final span = _streakSpanAt(date);
    if (span < 2) return Colors.white;
    if (span <= 20) return AppColors.habitStreakLight;
    return AppColors.habitStreakDark;
  }

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

                // ── 期間ラベル＋週切り替え＋今日に戻るボタン ──
                // Stack で「中央：前週/日付/次週」と「右寄り：今日に戻る」
                // を独立配置することで、今日に戻るボタンの表示有無に
                // よって日付ラベルの位置がズレないようにする。
                SizedBox(
                  height: 36,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // ── 中央：前週ボタン／日付ラベル／次週ボタン ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _WeekNavButton(
                            icon: Icons.chevron_left,
                            onPressed: _goToPreviousWeek,
                          ),
                          const SizedBox(width: 8),
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
                          const SizedBox(width: 8),
                          _WeekNavButton(
                            icon: Icons.chevron_right,
                            onPressed: _goToNextWeek,
                          ),
                        ],
                      ),
                      // ── 右寄り：今日に戻るボタン（離れた位置に独立配置）──
                      if (!_isCurrentWeek)
                        Positioned(
                          right: 0,
                          child: GestureDetector(
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
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── カレンダーグリッド ────────────────────────
                _ContinuityCalendar(
                  weekDays: weekDays,
                  dailyTotals: dailyTotals,
                  streakColors: {
                    for (final d in weekDays) _dateKey(d): _streakColor(d),
                  },
                  todayKey: _dateKey(DateTime.now()),
                  openTooltipKey: _openTooltipKey,
                  onToggleTooltip: _toggleTooltip,
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
  final Map<String, Color> streakColors; // キー="yyyy-MM-dd", 値=記録セル背景色
  final String todayKey;               // 今日の日付キー（強調表示の判定用）
  final String? openTooltipKey;        // 現在開いている吹き出しの日付キー
  final void Function(String dateKey) onToggleTooltip;

  const _ContinuityCalendar({
    required this.weekDays,
    required this.dailyTotals,
    required this.streakColors,
    required this.todayKey,
    required this.openTooltipKey,
    required this.onToggleTooltip,
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
                isToday: _dateKey(weekDays[i]) == todayKey,
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
                isToday: _dateKey(weekDays[i]) == todayKey,
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
                  backgroundColor: streakColors[key] ?? Colors.white,
                  isToday: key == todayKey,
                  isOpen: openTooltipKey == key,
                  onTap: () => onToggleTooltip(key),
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
// 週切り替えボタン（前週／次週）
//
// shared/patterns/full_image_screen.dart の _NavButton と
// 同じデザイン（角丸・テーマカラー背景・白アイコン）を踏襲。
// こちらは期間ラベル横に置く小型サイズで使用する。
// ══════════════════════════════════════════════════════════
class _WeekNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _WeekNavButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.theme,
        foregroundColor: Colors.white,
        minimumSize: const Size(32, 32),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Icon(icon, size: 18),
    );
  }
}

// ══════════════════════════════════════════════════════════
// ヘッダーセル（曜日・日付行 共用）
// ══════════════════════════════════════════════════════════
class _HeaderCell extends StatelessWidget {
  final String text;
  final bool isWeekday;
  final bool isToday;

  const _HeaderCell({
    required this.text,
    required this.isWeekday,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: isWeekday ? AppColors.themeLight : Colors.white,
        border: Border.all(
          color: isToday ? AppColors.theme : AppColors.themeBorder,
          width: isToday ? 2.5 : 0.8,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isWeekday ? 11 : 16,
            fontWeight: isWeekday ? FontWeight.w600 : FontWeight.bold,
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
// 花丸タップで親（_HabitMainScreenState）の onTap を呼び出し、
// どのセルの吹き出しを開くかを親で一元管理する。
// これにより、別のセルをタップすると表示中の吹き出しは自動的に
// 閉じ、新しいセルの吹き出しに切り替わる。
// ══════════════════════════════════════════════════════════
class _RecordCell extends StatelessWidget {
  final bool hasRecord;
  final int totalMinutes;
  final Color backgroundColor;
  final bool isToday;
  final bool isOpen;
  final VoidCallback onTap;

  const _RecordCell({
    required this.hasRecord,
    required this.totalMinutes,
    required this.backgroundColor,
    required this.isToday,
    required this.isOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(
          color: isToday ? AppColors.theme : AppColors.themeBorder,
          width: isToday ? 2.5 : 0.8,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: hasRecord
          ? Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // ── 花丸ボタン ───────────────────────────
                // セル高さ(120)の概ね65%相当の80pxで表示
                GestureDetector(
                  onTap: onTap,
                  child: Image.asset(
                    HabitConfig.currentFlowerCircleAssetPath,
                    width: 80,
                    height: 80,
                  ),
                ),
                // ── 吹き出し ─────────────────────────────
                // 花丸の上端（中心から半径40px上）のすぐ上に配置
                if (isOpen)
                  Positioned(
                    bottom: 40 + 38, // セル中央 + 花丸半径 + 適度な余白
                    child: GestureDetector(
                      onTap: onTap, // 吹き出しタップで閉じる
                      child: _TooltipBubble(
                        label: totalMinutes == 0
                            ? AppStrings.habitTooltipNoTime
                            : '$totalMinutes${AppStrings.habitTooltipMinSuffix}',
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
              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.themeDark,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // ── 吹き出しの三角形（下向き）────────────────────
        CustomPaint(
          size: const Size(14, 8),
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
