import 'package:flutter/services.dart';
import '../../../core/constants/app_values.dart';

// ══════════════════════════════════════════════════════════
// X秒ドローイング モデルアセット
//
// ファイル名規則: {カテゴリ}_{パターン番号}_{作者名}_{モデル名}.{拡張子}
// 例: ベーシック(6頭身)_01_山田_太郎.png
//     → category=ベーシック(6頭身), pattern=01, author=山田, modelName=太郎
// ══════════════════════════════════════════════════════════
class DrawingModel {
  final String path;
  final String category;
  final String pattern;
  final String author;
  final String modelName;

  const DrawingModel({
    required this.path,
    required this.category,
    required this.pattern,
    required this.author,
    required this.modelName,
  });

  /// サムネイルや一覧で表示するラベル
  String get label => modelName;

  // ── カテゴリのソート順定義 ─────────────────────────────
  static const List<String> categoryOrder = [
    'ベーシック(6頭身)',
    'デフォルメ(2頭身)',
    '顔',
    '手',
  ];

  static int _categoryIndex(String category) {
    final index = categoryOrder.indexOf(category);
    return index == -1 ? categoryOrder.length : index; // 未定義は末尾
  }

  /// ファイルパスから [DrawingModel] を生成する。
  /// ファイル名規則に合わない場合はファイル名全体をモデル名として扱う。
  factory DrawingModel.fromPath(String path) {
    final fileName = path.split('/').last;
    final nameWithoutExt = fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;

    final parts = nameWithoutExt.split('_');
    if (parts.length >= 4) {
      return DrawingModel(
        path: path,
        category: parts[0],
        pattern: parts[1],
        author: parts[2],
        modelName: parts.sublist(3).join('_'), // モデル名に _ が含まれる場合も考慮
      );
    }

    // 規則外ファイル：カテゴリ・パターン・作者を空扱いにする
    return DrawingModel(
      path: path,
      category: '未分類',
      pattern: '',
      author: '',
      modelName: nameWithoutExt,
    );
  }
}

// ══════════════════════════════════════════════════════════
// モデルアセット一覧ローダー
//
// pubspec.yaml に assets/model/ フォルダを登録しておけば
// 追加した画像ファイルが自動的にリストに反映される。
//
// 使い方:
//   final models = await DrawingModelLoader.load();
// ══════════════════════════════════════════════════════════
class DrawingModelLoader {
  DrawingModelLoader._();

  // ── ロード結果をキャッシュし、複数画面からの二重呼び出しを防ぐ ──
  static Future<List<DrawingModel>>? _cache;

  /// assets/model/ 配下の画像を AssetManifest から動的に取得する。
  /// 2回目以降はキャッシュを返す。
  static Future<List<DrawingModel>> load() => _cache ??= _loadInternal();

  static Future<List<DrawingModel>> _loadInternal() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final paths = manifest
        .listAssets()
        .where((p) =>
            p.startsWith(AppValues.modelAssetFolder) &&
            (p.endsWith('.png') ||
                p.endsWith('.jpg') ||
                p.endsWith('.jpeg') ||
                p.endsWith('.webp')))
        .toList();

    final models = paths.map(DrawingModel.fromPath).toList();

    // カテゴリ定義順 → パターン番号 → モデル名 の順でソート
    models.sort((a, b) {
      final categoryCmp = DrawingModel._categoryIndex(a.category)
          .compareTo(DrawingModel._categoryIndex(b.category));
      if (categoryCmp != 0) return categoryCmp;
      final patternCmp = a.pattern.compareTo(b.pattern);
      if (patternCmp != 0) return patternCmp;
      return a.modelName.compareTo(b.modelName);
    });

    return models;
  }

  /// ロード済みリストからカテゴリ一覧を取得（定義順・重複なし）
  static List<String> categories(List<DrawingModel> models) {
    final seen = <String>{};
    final result = <String>[];
    for (final m in models) {
      if (seen.add(m.category)) result.add(m.category);
    }
    return result; // models がソート済みなので挿入順 = 定義順
  }
}
