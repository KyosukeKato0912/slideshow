// ══════════════════════════════════════════════════════════
// 習慣化サポート テストデータ
//
// 成長記録機能が実装されるまでの仮データ。
// 成長記録実装後はこのファイルを削除し、
// HabitRecord（Hive）から取得したデータに差し替える。
//
// ■ データ追加方法
//   HabitTestRecord(id: 'xxx', date: DateTime(yyyy, m, d), workMinutes: nn)
//   を HabitTestData.records リストに追記する。
//   同一日付を複数登録すると作業時間合計に加算される。
// ══════════════════════════════════════════════════════════

// ── テストデータ 1件分のモデル ────────────────────────────
class HabitTestRecord {
  final String id;
  final DateTime date;

  /// 作業時間（分）。0 以上の整数。
  final int workMinutes;

  HabitTestRecord({
    required this.id,
    required this.date,
    required this.workMinutes,
  });
}

// ── テストデータ一覧 ──────────────────────────────────────
abstract class HabitTestData {
  static final List<HabitTestRecord> records = [
    HabitTestRecord(
      id: 'test_001',
      date: DateTime(2026, 6, 1),
      workMinutes: 30,
    ),
    HabitTestRecord(
      id: 'test_002',
      date: DateTime(2026, 6, 1),
      workMinutes: 15,
    ),
    HabitTestRecord(
      id: 'test_003',
      date: DateTime(2026, 6, 2),
      workMinutes: 20,
    ),
    HabitTestRecord(
      id: 'test_004',
      date: DateTime(2026, 6, 4),
      workMinutes: 0, // 作業時間未入力の場合は 0 を登録
    ),
    HabitTestRecord(
      id: 'test_005',
      date: DateTime(2026, 6, 5),
      workMinutes: 45,
    ),
    HabitTestRecord(
      id: 'test_006',
      date: DateTime(2026, 6, 5),
      workMinutes: 30,
    ),
    HabitTestRecord(
      id: 'test_007',
      date: DateTime(2026, 6, 7),
      workMinutes: 10,
    ),
    HabitTestRecord(
      id: 'test_008',
      date: DateTime(2026, 5, 31),
      workMinutes: 10,
    ),
  ];
}
