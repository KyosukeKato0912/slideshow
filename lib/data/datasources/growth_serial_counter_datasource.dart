import 'package:hive/hive.dart';

// ══════════════════════════════════════════════════════════
// GrowthSerialCounterDataSource
//
// 成長記録のファイル名（YYYY-MM-DD-NN枚目）に使う「NN」を、日付ごとに
// 発行するための独立したカウンタ。GrowthRecordの生存件数からではなく
// このカウンタから採番することで、削除された連番が再利用されず、
// ファイル名が常に一意になることを保証する。
//
// 例：同日に1〜10枚目をアップロード後、10枚目を削除して再度
//     アップロードしても、新しい画像は10枚目ではなく11枚目になる。
//
// Hiveへの直接アクセスのみを担当する（採番ロジック自体は
// GrowthRepository側が持つ）。
// ══════════════════════════════════════════════════════════
class GrowthSerialCounterDataSource {
  static const String boxName = 'growth_serial_counters';

  Future<Box<int>> _openBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<int>(boxName);
    }
    return Hive.openBox<int>(boxName);
  }

  String _keyFor(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// 指定日の現在のカウンタ値を返す。未設定（＝一度もこのカウンタから
  /// 採番したことがない日）の場合は null。
  Future<int?> peek(DateTime date) async {
    final box = await _openBox();
    return box.get(_keyFor(date));
  }

  /// カウンタ値を直接設定する（既存データからの初回シード用）。
  Future<void> seed(DateTime date, int value) async {
    final box = await _openBox();
    await box.put(_keyFor(date), value);
  }

  /// カウンタをインクリメントし、新しい値を返す。
  Future<int> increment(DateTime date) async {
    final box = await _openBox();
    final key = _keyFor(date);
    final next = (box.get(key) ?? 0) + 1;
    await box.put(key, next);
    return next;
  }
}
