import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/config/drawing_config.dart';

// ══════════════════════════════════════════════════════════
// フィードバックリンクウィジェット（Webサンプル版専用）
//
// DrawingConfig.showFeedbackLink が false の場合は SizedBox.shrink() を返す。
// 正式リリース時はフラグを false にするだけで全画面から非表示になる。
// ══════════════════════════════════════════════════════════
class FeedbackLinkWidget extends StatelessWidget {
  /// リンクの上に表示する誘導テキスト。null の場合は表示しない。
  final String? prompt;

  /// タップ可能なリンクラベル
  final String label;

  const FeedbackLinkWidget({
    super.key,
    this.prompt,
    required this.label,
  });

  Future<void> _openUrl() async {
    final uri = Uri.parse(DrawingConfig.feedbackUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!DrawingConfig.showFeedbackLink) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (prompt != null) ...[
          Text(
            prompt!,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
        ],
        InkWell(
          onTap: _openUrl,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.open_in_new, size: 14, color: AppColors.theme),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.theme,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.theme,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
