// ══════════════════════════════════════════════════════════
// X秒ドローイング コンフィグ
//
// ファイル名規則: draw-{categoryId}-{authorId}-{modelId}.{拡張子}
// 例: draw-c01-a01-mb00001.png
//
// ・カテゴリ・作者・モデルの表示名はここで一元管理する。
// ・ファイル名に特殊文字や日本語を含めないことでバグを防止。
// ・新しい画像を追加する際はこのファイルに定義を追加してから
//   assets/images/models/ に画像ファイルを配置すること。
//
// ■ ペアの扱いについて
//   同じモデル名を持つ異カテゴリのモデルが自動的にペアとして扱われる。
//   （例: mb00001「立ち」と md00001「立ち」は自動でペアになる）
//   ペアが存在しない場合は独立したモデルとして扱われる。
//   configにペア設定は不要。
// ══════════════════════════════════════════════════════════

// ── カテゴリ定義 ──────────────────────────────────────────

/// X秒ドローイングで使用するモデルのカテゴリ定義。
///
/// [id]        ファイル名に使用するID（例: 'c01'）
/// [name]      画面に表示するカテゴリ名（例: 'ベーシック(6頭身)'）
/// [shortName] フィルタチップ等、スペースが限られた箇所での短縮表示名
class DrawingCategoryDef {
  final String id;
  final String name;
  final String shortName;

  const DrawingCategoryDef({
    required this.id,
    required this.name,
    required this.shortName,
  });
}

// ── 作者定義 ──────────────────────────────────────────────

/// X秒ドローイングで使用するモデルの作者定義。
///
/// [id]          ファイル名に使用するID（例: 'a01'）
/// [displayName] 画面に表示する作者名（例: 'Tyu☆'）
///               特殊文字・日本語を含んでよい（ファイル名には使わないため）
class DrawingAuthorDef {
  final String id;
  final String displayName;

  const DrawingAuthorDef({
    required this.id,
    required this.displayName,
  });
}

// ── モデル定義 ────────────────────────────────────────────

/// X秒ドローイングで使用する個々のモデル定義。
///
/// [id]   ファイル名に使用するID（例: 'mb00001'）
///        先頭2文字がカテゴリを示す（mb=ベーシック, md=デフォルメ, mf=顔, mh=手）
///        カテゴリ情報はファイル名の categoryId から取得するため、ここには持たない。
/// [name] 画面に表示するモデル名（例: '立ち'）
class DrawingModelDef {
  final String id;
  final String name;

  const DrawingModelDef({
    required this.id,
    required this.name,
  });
}

// ══════════════════════════════════════════════════════════
// 定義データ（新しい画像追加時はここに追記する）
// ══════════════════════════════════════════════════════════
abstract class DrawingConfig {
  // ── カテゴリ一覧 ────────────────────────────────────────
  // リストの並び順 = 設定画面・モデル一覧でのカテゴリ表示順
  static const List<DrawingCategoryDef> categories = [
    DrawingCategoryDef(id: 'c01', name: 'ベーシック(6頭身)', shortName: 'ベーシック'),
    DrawingCategoryDef(id: 'c02', name: 'デフォルメ(2頭身)', shortName: 'デフォルメ'),
    DrawingCategoryDef(id: 'c03', name: '顔',               shortName: '顔'),
    DrawingCategoryDef(id: 'c04', name: '手',               shortName: '手'),
  ];

  // ── 作者一覧 ────────────────────────────────────────────
  static const List<DrawingAuthorDef> authors = [
    DrawingAuthorDef(id: 'a01', displayName: 'Tyu☆'),
  ];

  // ── モデル一覧 ──────────────────────────────────────────
  static const List<DrawingModelDef> models = [
    // ベーシック(6頭身)
    DrawingModelDef(id: 'mb00001', name: '立ち'),
    DrawingModelDef(id: 'mb00002', name: '座る'),
    DrawingModelDef(id: 'mb00003', name: '走る'),
    DrawingModelDef(id: 'mb00004', name: 'アイドル風'),
    DrawingModelDef(id: 'mb00005', name: '振り向く'),
    // デフォルメ(2頭身)
    DrawingModelDef(id: 'md00001', name: '立ち'),
    DrawingModelDef(id: 'md00002', name: '座る'),
    DrawingModelDef(id: 'md00003', name: '走る'),
    DrawingModelDef(id: 'md00004', name: 'アイドル風'),
    DrawingModelDef(id: 'md00005', name: '振り向く'),
    // 顔
    DrawingModelDef(id: 'mf00001', name: '女性通常'),
    DrawingModelDef(id: 'mf00002', name: '男性通常'),
    DrawingModelDef(id: 'mf00003', name: '笑顔'),
    DrawingModelDef(id: 'mf00004', name: '泣き顔'),
    DrawingModelDef(id: 'mf00005', name: '怒り'),
    // 手
    DrawingModelDef(id: 'mh00001', name: 'てのひら'),
    DrawingModelDef(id: 'mh00002', name: 'ピース'),
    DrawingModelDef(id: 'mh00003', name: '握りこぶし'),
    DrawingModelDef(id: 'mh00004', name: '指さす'),
    DrawingModelDef(id: 'mh00005', name: 'グッド'),
  ];

  // ══════════════════════════════════════════════════════════
  // ルックアップヘルパー
  // ══════════════════════════════════════════════════════════

  /// カテゴリIDから [DrawingCategoryDef] を返す。未定義IDの場合は null。
  static DrawingCategoryDef? findCategory(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// 作者IDから [DrawingAuthorDef] を返す。未定義IDの場合は null。
  static DrawingAuthorDef? findAuthor(String id) {
    for (final a in authors) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// モデルIDから [DrawingModelDef] を返す。未定義IDの場合は null。
  static DrawingModelDef? findModel(String modelId) {
    for (final m in models) {
      if (m.id == modelId) return m;
    }
    return null;
  }

  /// カテゴリのソート順インデックスを返す。
  /// [categories] リストの並び順がそのまま表示順になる。
  static int categorySortIndex(String categoryId) {
    for (var i = 0; i < categories.length; i++) {
      if (categories[i].id == categoryId) return i;
    }
    return categories.length; // 未定義IDは末尾
  }
}
