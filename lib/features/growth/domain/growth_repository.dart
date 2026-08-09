import '../../../core/constants/app_values.dart';
import '../../../data/datasources/growth_datasource.dart';
import 'growth_record.dart';

// ══════════════════════════════════════════════════════════
// GrowthRepository
//
// 成長記録のCRUDと、300件超過時の自動削除ロジックを担当する。
// Hiveへのアクセスは GrowthDataSource 経由のみ（直接Boxを操作しない）。
// ══════════════════════════════════════════════════════════
class GrowthRepository {
  final GrowthDataSource _dataSource;

  GrowthRepository({GrowthDataSource? dataSource})
      : _dataSource = dataSource ?? GrowthDataSource();

  /// 全件取得（日付降順→連番降順の新しい順）
  Future<List<GrowthRecord>> getAll() async {
    final records = await _dataSource.getAll();
    records.sort((a, b) {
      final dateCompare = b.date.compareTo(a.date);
      if (dateCompare != 0) return dateCompare;
      return b.serialNumber.compareTo(a.serialNumber);
    });
    return records;
  }

  /// 指定日の次の連番（同一日内で1始まりの連番）を算出する
  Future<int> nextSerialNumberForDate(DateTime date) async {
    final all = await _dataSource.getAll();
    final sameDay = all.where((r) =>
        r.date.year == date.year &&
        r.date.month == date.month &&
        r.date.day == date.day);
    if (sameDay.isEmpty) return 1;
    final maxSerial =
        sameDay.map((r) => r.serialNumber).reduce((a, b) => a > b ? a : b);
    return maxSerial + 1;
  }

  /// 1件追加し、上限枚数（300件）を超えていれば古いものから自動削除する
  Future<void> add(GrowthRecord record) async {
    await _dataSource.add(record);
    await _enforceMaxCount();
  }

  /// 1件削除
  Future<void> delete(String id) async {
    await _dataSource.delete(id);
  }

  Future<void> _enforceMaxCount() async {
    final all = await _dataSource.getAll();
    if (all.length <= AppValues.growthMaxRecordCount) return;

    // 古い順（日付昇順→連番昇順）に並べ、超過分を削除する
    all.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      return a.serialNumber.compareTo(b.serialNumber);
    });
    final overflowCount = all.length - AppValues.growthMaxRecordCount;
    for (var i = 0; i < overflowCount; i++) {
      await _dataSource.delete(all[i].id);
    }
  }
}
