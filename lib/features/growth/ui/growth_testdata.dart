// ══════════════════════════════════════════════════════════
// 成長記録 テストデータ
//
// GrowthRepository（Hive）が実装されるまでの仮データ。
// 本実装後はこのファイルを削除し、
// GrowthRecord（Hive）から取得したデータに差し替える。
//
// ■ データ追加方法
//   GrowthTestRecord(id: 'xxx', date: DateTime(yyyy, m, d),
//                     serialNumber: n, durationSec: ss)
//   を GrowthTestData.records リストに追記する。
//   durationSec は任意入力項目のため null を許容する。
// ══════════════════════════════════════════════════════════

// ── テストデータ 1件分のモデル ────────────────────────────
class GrowthTestRecord {
  final String id;
  final DateTime date;

  /// 同一日内でのアップロード連番（1始まり）
  final int serialNumber;

  /// 所要時間（秒）。任意入力のため未入力時は null。
  final int? durationSec;

  GrowthTestRecord({
    required this.id,
    required this.date,
    required this.serialNumber,
    this.durationSec,
  });
}

// ── テストデータ一覧 ──────────────────────────────────────
abstract class GrowthTestData {
  static final List<GrowthTestRecord> records = [
    GrowthTestRecord(
      id: 'test_001',
      date: DateTime(2026, 6, 1),
      serialNumber: 1,
      durationSec: 180,
    ),
    GrowthTestRecord(
      id: 'test_002',
      date: DateTime(2026, 6, 1),
      serialNumber: 2,
      durationSec: null, // 所要時間未入力の場合は null を登録
    ),
    GrowthTestRecord(
      id: 'test_003',
      date: DateTime(2026, 6, 3),
      serialNumber: 1,
      durationSec: 300,
    ),
    GrowthTestRecord(
      id: 'test_004',
      date: DateTime(2026, 6, 5),
      serialNumber: 1,
      durationSec: 90,
    ),
    GrowthTestRecord(
      id: 'test_005',
      date: DateTime(2026, 6, 5),
      serialNumber: 2,
      durationSec: 240,
    ),
  ];
}
