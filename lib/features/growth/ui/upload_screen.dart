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
// 現フェーズの割り切り：
//   ・「ファイルでアップロード」…機能する（ギャラリーから画像選択→保存）
//   ・「カメラでアップロード」　…レイアウトのみ（押下しても保存されない）
//   ・所要時間（任意）入力　　　…レイアウトのみ（入力しても保存されない。
//     durationSecは常にnullとして保存される）
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

  // TODO: カメラでの撮影→アップロードは image_picker の ImageSource.camera
  //   実装後に差し替える
  void _onCameraTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.growthCameraComingSoon)),
    );
  }

  Future<void> _onFileUploadTap() async {
    setState(() => _isUploading = true);
    try {
      final uploaded =
          await ref.read(growthProvider.notifier).uploadFromGallery();
      if (!mounted) return;
      if (uploaded) {
        Navigator.pushReplacement(context, AppRouter.growthUploadComplete());
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

              // ── カメラでアップロード：レイアウトのみ ──
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
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(
                  AppStrings.growthCameraUploadButton,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),

              // ── ファイルでアップロード：機能する ──
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
