import 'package:hive/hive.dart';
import '../../features/growth/domain/growth_record.dart';

// ══════════════════════════════════════════════════════════
// GrowthDataSource
//
// Hive Box 'growth_records' への直接CRUDのみを担当する。
// ビジネスロジック（300件上限・連番採番など）は持たない
// （それらは features/growth/domain/growth_repository.dart の責務）。
// ══════════════════════════════════════════════════════════
class GrowthDataSource {
  static const String boxName = 'growth_records';

  Future<Box<GrowthRecord>> _openBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<GrowthRecord>(boxName);
    }
    return Hive.openBox<GrowthRecord>(boxName);
  }

  /// 全件取得
  Future<List<GrowthRecord>> getAll() async {
    final box = await _openBox();
    return box.values.toList();
  }

  /// 1件追加（idをキーとして保存）
  Future<void> add(GrowthRecord record) async {
    final box = await _openBox();
    await box.put(record.id, record);
  }

  /// idを指定して1件削除
  Future<void> delete(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }
}
