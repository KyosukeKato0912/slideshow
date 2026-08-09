import 'package:hive/hive.dart';
import '../../features/growth/domain/growth_record.dart';

// ══════════════════════════════════════════════════════════
// HiveAdapters
//
// main.dart から呼び出す、全HiveAdapterの登録窓口。
// typeIdの重複管理は core/constants/app_values.dart のコメントで一元管理する。
// 新規Hiveモデル追加時はここに登録を追加すること。
// ══════════════════════════════════════════════════════════
abstract class HiveAdapters {
  static void registerAll() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(GrowthRecordAdapter());
    }
  }
}
