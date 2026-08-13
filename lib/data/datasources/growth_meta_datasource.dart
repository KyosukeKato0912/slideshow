import 'package:hive/hive.dart';

// ══════════════════════════════════════════════════════════
// GrowthMetaDataSource
//
// 成長記録の「現在の一覧件数」には依存しない、永続的なフラグ等の
// メタ情報を保持する。
//
// 現在の用途：
//   ・保持上限枚数（GrowthConfig.maxRecordCount）に一度でも到達した
//     ことがあるかどうかのフラグ。アップロード完了画面の特別メッセージ
//     を「初めて上限に達した回」だけ表示するために使う。
//     削除によって件数が上限を下回り、その後再度上限に達しても
//     このフラグは一度trueになった後は変化しない
//     （＝特別メッセージは二度と出さない）。
// ══════════════════════════════════════════════════════════
class GrowthMetaDataSource {
  static const String boxName = 'growth_meta';
  static const String _keyHasReachedMaxCountOnce =
      'has_reached_max_count_once';

  Future<Box> _openBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    return Hive.openBox(boxName);
  }

  /// 保持上限枚数に一度でも到達したことがあるか
  Future<bool> hasReachedMaxCountOnce() async {
    final box = await _openBox();
    return (box.get(_keyHasReachedMaxCountOnce) as bool?) ?? false;
  }

  /// 保持上限枚数に到達済みであることを記録する
  Future<void> markReachedMaxCountOnce() async {
    final box = await _openBox();
    await box.put(_keyHasReachedMaxCountOnce, true);
  }

  /// 【検証用】保持上限枚数の到達フラグをリセットする。
  /// アップロード完了画面の特別メッセージを再度表示させたい場合に使う。
  Future<void> resetHasReachedMaxCountOnce() async {
    final box = await _openBox();
    await box.delete(_keyHasReachedMaxCountOnce);
  }
}
