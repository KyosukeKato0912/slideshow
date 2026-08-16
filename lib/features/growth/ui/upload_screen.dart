import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../state/growth_provider.dart';

// ══════════════════════════════════════════════════════════
// アップロード画面
//
// 「戻る」はAppBarの標準戻るボタンで対応。
//
// 「写真で追加」（ギャラリー選択）・「カメラで追加」（撮影）ともに
// GrowthNotifier（growthProvider）経由で保存する。picker種別が
// 異なるだけで、以降の保存フロー・エラーハンドリングは共通。
//
// 所要時間（任意）入力：
//   ・半角数字のみ許可（空欄も可）。写真で追加／カメラで追加
//     いずれのボタン押下時にもバリデーションし、半角数字以外が
//     入力されていればエラーを表示して処理を中断する。
//   ・入力値（分）はそのままGrowthRecord.durationMinとして保存され、
//     保存ファイル名にも反映される（例：2026-06-01-2枚目-3分.png）。
//
// 保持上限枚数（GrowthConfig.maxRecordCount）：
//   ・上限を超えてアップロードすると最古の1件が自動削除される。
//   ・「ちょうど上限に到達したアップロード」の場合のみ、完了画面に
//     特別メッセージを表示する（isMaxCountReached をルートへ渡す）。
// ══════════════════════════════════════════════════════════
class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final TextEditingController _durationController = TextEditingController();
  bool _isUploading = false;

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  /// 所要時間欄が半角数字のみ（または空欄）かどうかを判定する。
  /// 空欄は「未入力」として許可する。
  bool _isDurationInputValid(String input) {
    if (input.isEmpty) return true;
    return RegExp(r'^[0-9]+$').hasMatch(input);
  }

  void _showDurationInvalidError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.growthDurationInvalidError)),
    );
  }

  Future<void> _onCameraTap() async {
    final input = _durationController.text.trim();
    if (!_isDurationInputValid(input)) {
      _showDurationInvalidError();
      return;
    }
    final durationMin = input.isEmpty ? null : int.parse(input);

    setState(() => _isUploading = true);
    try {
      final result = await ref
          .read(growthProvider.notifier)
          .uploadFromCamera(durationMin: durationMin);
      if (!mounted) return;
      if (result != null) {
        Navigator.pushReplacement(
          context,
          AppRouter.growthUploadComplete(isMaxCountReached: result),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.growthCameraError)),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _onFileUploadTap() async {
    final input = _durationController.text.trim();
    if (!_isDurationInputValid(input)) {
      _showDurationInvalidError();
      return;
    }
    final durationMin = input.isEmpty ? null : int.parse(input);

    setState(() => _isUploading = true);
    try {
      final result = await ref
          .read(growthProvider.notifier)
          .uploadFromGallery(durationMin: durationMin);
      if (!mounted) return;
      if (result != null) {
        Navigator.pushReplacement(
          context,
          AppRouter.growthUploadComplete(isMaxCountReached: result),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.growthUploadScreenTitle),
        backgroundColor: AppColors.theme,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 所要時間（任意）：レイアウトのみ ──
              TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppStrings.growthDurationInputLabel,
                  suffixText: AppStrings.growthDurationInputUnit,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.theme, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // ── カメラで追加：撮影→保存する ──
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.theme,
                  side: const BorderSide(color: AppColors.theme),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isUploading ? null : _onCameraTap,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.theme),
                        ),
                      )
                    : const Icon(Icons.photo_camera_outlined),
                label: Text(
                  AppStrings.growthCameraUploadButton,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),

              // ── 写真で追加：ギャラリーから選択して保存する ──
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.theme,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isUploading ? null : _onFileUploadTap,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.folder_open_outlined),
                label: Text(
                  AppStrings.growthFileUploadButton,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
