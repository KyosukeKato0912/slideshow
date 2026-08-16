import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../features/growth/domain/growth_record.dart';
import '../constants/app_strings.dart';
import '../utils/date_utils.dart';

// ══════════════════════════════════════════════════════════
// GrowthPdfService
//
// 成長記録の画像一覧をPDF化する。
//
// ページ構成：
//   1ページ目 … 表紙（タイトル・対象期間・対象枚数）
//   2ページ目以降 … サムネグリッド（3列×4行 = 12枚/ページ、
//                   各サムネの上にファイル名を表示）
// 全ページ共通：
//   ヘッダー（上部）… growthPdfHeaderTitle固定文言
//   フッター（下部）… ページ番号（表紙を含めた通し番号）
//
// 日本語フォントは端末やビルド環境にフォントファイルを同梱する代わりに
// printing パッケージの PdfGoogleFonts（Noto Sans JP）を実行時に取得して
// 使用する（初回はネットワークアクセスが発生し、以降はキャッシュされる）。
//
// ⚠ header/footer は pw.Page には存在せず、pw.MultiPage 専用のパラメータ。
//   ドキュメント全体を単一の pw.MultiPage として組み立て、表紙とグリッド
//   ページの間は pw.NewPage() で明示的に改ページする（公式ドキュメントの
//   「複数セクションをそれぞれ1ページに収める」パターンに準拠）。
//   各セクションは pw.Expanded で包み、そのページの残り領域いっぱいに
//   広げる（表紙の縦中央寄せ・グリッド内部の pw.Expanded 行が正しく
//   高さを取得するために必要）。
//
// UIからは build() のみを呼び出し、Documentの組み立て・画像読み込みは
// このサービス内に閉じる。
// ══════════════════════════════════════════════════════════
abstract class GrowthPdfService {
  static const int _columns = 3;
  static const int _rows = 4;
  static const int _perPage = _columns * _rows;

  /// [records] は成長記録の全件をそのまま渡す想定（絞込の影響は受けない）。
  /// 内部で日付昇順に並び替えてから表紙の対象期間・グリッドの並びを決める。
  static Future<Uint8List> build(List<GrowthRecord> records) async {
    final regularFont = await PdfGoogleFonts.notoSansJPRegular();
    final boldFont = await PdfGoogleFonts.notoSansJPBold();
    final theme = pw.ThemeData.withFont(base: regularFont, bold: boldFont);

    final doc = pw.Document(theme: theme);

    final sorted = [...records]..sort((a, b) => a.date.compareTo(b.date));
    final periodLabel = sorted.isEmpty
        ? ''
        : '${AppDateUtils.formatYMD(sorted.first.date)} 〜 '
            '${AppDateUtils.formatYMD(sorted.last.date)}';
    final chunks = _chunk(sorted, _perPage);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 32, 28, 32),
        header: (context) => _buildHeader(),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.Expanded(
            child: _buildCover(
              periodLabel: periodLabel,
              count: sorted.length,
            ),
          ),
          for (final chunk in chunks) ...[
            pw.NewPage(),
            pw.Expanded(child: _buildGrid(chunk)),
          ],
        ],
      ),
    );

    return doc.save();
  }

  /// [Printing.sharePdf] に渡すファイル名（例：'成長記録_2026-06-01.pdf'）を組み立てる。
  static String buildFileName(DateTime now) {
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${AppStrings.growthPdfFileNamePrefix}$y-$m-$d.pdf';
  }

  static List<List<GrowthRecord>> _chunk(List<GrowthRecord> list, int size) {
    final result = <List<GrowthRecord>>[];
    for (var i = 0; i < list.length; i += size) {
      final end = (i + size < list.length) ? i + size : list.length;
      result.add(list.sublist(i, end));
    }
    return result;
  }

  // ── ヘッダー（全ページ共通） ─────────────────────────────
  static pw.Widget _buildHeader() {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Text(
        AppStrings.growthPdfHeaderTitle,
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  // ── フッター（全ページ共通：ページ番号） ─────────────────
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.only(top: 12),
      child: pw.Text(
        '${context.pageNumber}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
      ),
    );
  }

  // ── 表紙 ────────────────────────────────────────────────
  static pw.Widget _buildCover({
    required String periodLabel,
    required int count,
  }) {
    return pw.Center(
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            AppStrings.growthPdfHeaderTitle,
            style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 28),
          if (periodLabel.isNotEmpty) ...[
            pw.Text(periodLabel, style: const pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 8),
          ],
          pw.Text(
            '${AppStrings.growthPdfCoverCountPrefix}$count'
            '${AppStrings.growthPdfCoverCountSuffix}',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  // ── サムネグリッド（3列×4行、余りは空セルで埋める） ──────
  static pw.Widget _buildGrid(List<GrowthRecord> records) {
    final rowWidgets = <pw.Widget>[];
    for (var r = 0; r < _rows; r++) {
      final cells = <pw.Widget>[];
      for (var c = 0; c < _columns; c++) {
        final index = r * _columns + c;
        cells.add(
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: index < records.length
                  ? _buildCell(records[index])
                  : pw.Container(),
            ),
          ),
        );
      }
      rowWidgets.add(
        pw.Expanded(
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: cells,
          ),
        ),
      );
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: rowWidgets,
    );
  }

  // ── サムネ1件分（ファイル名 + 画像） ─────────────────────
  static pw.Widget _buildCell(GrowthRecord record) {
    final fileName = record.imagePath.split('/').last;
    final bytes = File(record.imagePath).readAsBytesSync();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          fileName,
          style: const pw.TextStyle(fontSize: 6),
          maxLines: 1,
          overflow: pw.TextOverflow.clip,
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 3),
        pw.Expanded(
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 0.5, color: PdfColors.grey400),
            ),
            child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.cover),
          ),
        ),
      ],
    );
  }
}
