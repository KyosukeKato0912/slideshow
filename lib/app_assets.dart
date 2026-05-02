import 'package:flutter/services.dart';

// ══════════════════════════════════════════════════════════
// アセット定義_
//
// ファイル名規則: {カテゴリ}_{パターン番号}_{作者名}_{モデル名}.{拡張子}
// 例: 全身頭身高_01_山田_太郎.png
//     → category=全身頭身高, pattern=01, author=山田, modelName=太郎
// ══════════════════════════════════════════════════════════
class AppAsset {
  final String path;
  final String category; // カテゴリ名
  final String pattern; // パターン番号
  final String author; // 作者名
  final String modelName; // モデル名

  const AppAsset({
    required this.path,
    required this.category,
    required this.pattern,
    required this.author,
    required this.modelName,
  });

  /// サムネイルや一覧で表示するラベル（モデル名）
  String get label => modelName;

  /// ファイル名から AppAsset を生成する。
  /// 規則外のファイル名はファイル名全体をモデル名として扱う。
  factory AppAsset.fromPath(String path) {
    final fileName = path.split('/').last;
    final nameWithoutExt = fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;

    final parts = nameWithoutExt.split('_');
    if (parts.length >= 4) {
      return AppAsset(
        path: path,
        category: parts[0],
        pattern: parts[1],
        author: parts[2],
        modelName: parts.sublist(3).join('_'), // モデル名に_が含まれる場合も考慮
      );
    }

    // 規則外ファイル：カテゴリ・パターン・作者なし
    return AppAsset(
      path: path,
      category: '未分類',
      pattern: '',
      author: '',
      modelName: nameWithoutExt,
    );
  }
}

// ══════════════════════════════════════════════════════════
// カテゴリのソート順定義
// ══════════════════════════════════════════════════════════
const _categoryOrder = ['全身頭身高', '全身頭身低', '顔', '手'];

int _categoryIndex(String category) {
  final idx = _categoryOrder.indexOf(category);
  return idx == -1 ? _categoryOrder.length : idx; // 未定義カテゴリは末尾
}

// ══════════════════════════════════════════════════════════
// アセット一覧ローダー（AssetManifest ベース）
//
// pubspec.yaml で assets/model/ フォルダを登録しておけば
// 追加した画像ファイルが自動的にリストに反映される。
//
// 使い方:
//   final assets = await AppAssets.load();
// ══════════════════════════════════════════════════════════
class AppAssets {
  AppAssets._();

  // ロード結果をキャッシュし、複数画面からの二重呼び出しを防ぐ
  static Future<List<AppAsset>>? _cache;

  /// assets/model/ フォルダ内の画像を AssetManifest から動的に取得する。
  /// 2回目以降はキャッシュを返す。
  static Future<List<AppAsset>> load() => _cache ??= _loadInternal();

  static Future<List<AppAsset>> _loadInternal() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final paths = manifest
        .listAssets()
        .where((p) =>
            p.startsWith('assets/model/') &&
            (p.endsWith('.png') ||
                p.endsWith('.jpg') ||
                p.endsWith('.jpeg') ||
                p.endsWith('.webp')))
        .toList();

    final assets = paths.map(AppAsset.fromPath).toList();

    // カテゴリ定義順 → パターン番号 → モデル名 の順でソート
    assets.sort((a, b) {
      final catCmp =
          _categoryIndex(a.category).compareTo(_categoryIndex(b.category));
      if (catCmp != 0) return catCmp;
      final patCmp = a.pattern.compareTo(b.pattern);
      if (patCmp != 0) return patCmp;
      return a.modelName.compareTo(b.modelName);
    });

    return assets;
  }

  /// ロード済みリストからカテゴリ一覧を取得（定義順・重複なし）
  static List<String> categories(List<AppAsset> assets) {
    final seen = <String>{};
    final result = <String>[];
    for (final a in assets) {
      if (seen.add(a.category)) result.add(a.category);
    }
    return result; // assets がソート済みなので挿入順 = 定義順
  }
}
