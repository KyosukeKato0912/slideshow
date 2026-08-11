import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import '../../../core/utils/file_utils.dart';
import '../domain/growth_record.dart';
import '../domain/growth_repository.dart';

// ══════════════════════════════════════════════════════════
// GrowthNotifier / growthProvider
//
// 成長記録リストの状態管理。GrowthMainScreen・UploadScreenの
// 両方から参照されるため（画面をまたいで一覧を保持する必要があるため）
// Riverpod StateNotifierとして実装する。
//
// ui/ からは本Providerのみを参照し、GrowthRepository・
// GrowthDataSource・Hiveを直接操作しない。
//
// ⚠ 現フェーズ：
//   ・「ファイルでアップロード」（ギャラリー選択）のみ実装
//   ・カメラでのアップロードは uploadScreen 側でレイアウトのみ
//   ・所要時間入力は uploadScreen 側でレイアウトのみ（未接続のため
//     durationSec は常に null で保存する）
// ══════════════════════════════════════════════════════════
class GrowthNotifier extends StateNotifier<List<GrowthRecord>> {
  final GrowthRepository _repository;
  final ImagePicker _picker = ImagePicker();

  GrowthNotifier({GrowthRepository? repository})
      : _repository = repository ?? GrowthRepository(),
        super(const []) {
    _loadAll();
  }

  Future<void> _loadAll() async {
    state = await _repository.getAll();
  }

  /// ギャラリー（ファイル）から画像を選択してアップロードする。
  /// 選択がキャンセルされた場合は false を返す。
  Future<bool> uploadFromGallery() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return false;
    await _saveRecord(picked);
    return true;
  }

  Future<void> _saveRecord(XFile picked) async {
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day);
    final serialNumber = await _repository.nextSerialNumberForDate(date);

    final dotIndex = picked.path.lastIndexOf('.');
    final extension =
        dotIndex != -1 ? picked.path.substring(dotIndex + 1) : 'jpg';

    final savedPath = await AppFileUtils.growthImageFilePath(
      date: date,
      serialNumber: serialNumber,
      extension: extension,
    );
    await File(picked.path).copy(savedPath);

    final record = GrowthRecord(
      id: '${now.microsecondsSinceEpoch}',
      imagePath: savedPath,
      date: date,
      serialNumber: serialNumber,
      durationSec: null, // 所要時間入力は現フェーズ未接続
    );

    await _repository.add(record);
    await _loadAll();
  }

  /// 指定したidの成長記録をまとめて削除する。
  /// Hiveのレコード削除に加え、端末ローカルの画像ファイルも削除する。
  Future<void> deleteRecords(List<String> ids) async {
    final idsToDelete = ids.toSet();
    final targets = state.where((r) => idsToDelete.contains(r.id)).toList();

    for (final record in targets) {
      await _repository.delete(record.id);
      final file = File(record.imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _loadAll();
  }

  /// 指定したidの成長記録画像を端末のギャラリーに保存する。
  /// 保存に成功した件数を返す（失敗したものはスキップして続行する）。
  Future<int> downloadRecords(List<String> ids) async {
    final idsToDownload = ids.toSet();
    final targets = state.where((r) => idsToDownload.contains(r.id)).toList();

    var successCount = 0;
    for (final record in targets) {
      try {
        await Gal.putImage(record.imagePath, album: 'GrowthRecord');
        successCount++;
      } catch (_) {
        // 個別の失敗はスキップし、残りの保存を続行する
      }
    }
    return successCount;
  }
}

final growthProvider =
    StateNotifierProvider<GrowthNotifier, List<GrowthRecord>>((ref) {
  return GrowthNotifier();
});
