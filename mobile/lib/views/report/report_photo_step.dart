import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/report_request_viewmodel.dart';

/// Frame 13: up to 3 photos, then Submit.
class ReportPhotoStep extends StatelessWidget {
  const ReportPhotoStep({super.key});

  /// Asks "Camera or Gallery?", then passes the choice to the ViewModel.
  Future<void> _choosePhoto(
      BuildContext context, ReportRequestViewModel vm) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera, color: AppColors.navy),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.navy),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) await vm.pickPhoto(source);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportRequestViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Add Photo (Optional)',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),

                // Large "Tap to add photos" box
                _AddPhotoBox(
                  canAdd: vm.canAddPhoto,
                  onTap: () => _choosePhoto(context, vm),
                ),
                const SizedBox(height: 16),

                // Thumbnails + "Add More"
                if (vm.hasPhotos)
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (var i = 0; i < vm.photos.length; i++)
                        _Thumbnail(
                          bytes: vm.photos[i].bytes,
                          onRemove: () => vm.removePhoto(i),
                        ),
                      if (vm.canAddPhoto)
                        _AddMoreTile(onTap: () => _choosePhoto(context, vm)),
                    ],
                  ),
                const SizedBox(height: 8),
                Text(
                  '${vm.photos.length}/${ReportRequestViewModel.maxPhotos} photos',
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                // Error from the ViewModel
                if (vm.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(vm.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
        ),

        // Submit, pinned to the bottom like the design
        Center(
          child: SizedBox(
            width: 220,
            child: ElevatedButton(
              onPressed: () => vm.submit(),
              child: vm.isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: AppColors.white),
                    )
                  : const Text('Submit'),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// The big outlined box with the camera icon.
class _AddPhotoBox extends StatelessWidget {
  final bool canAdd;
  final VoidCallback onTap;

  const _AddPhotoBox({required this.canAdd, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: canAdd ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.navy, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_camera,
                size: 36,
                color: canAdd ? AppColors.navy : AppColors.inactive),
            const SizedBox(height: 8),
            Text(
              canAdd ? 'Tap to add photos' : 'Maximum of 3 photos reached',
              style: const TextStyle(color: AppColors.navy),
            ),
          ],
        ),
      ),
    );
  }
}

/// A chosen photo with a small ✕ to remove it.
class _Thumbnail extends StatelessWidget {
  final Uint8List bytes;
  final VoidCallback onRemove;

  const _Thumbnail({required this.bytes, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(bytes, width: 80, height: 80, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: const CircleAvatar(
                radius: 11,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, size: 14, color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The "+ Add More" tile next to the thumbnails.
class _AddMoreTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddMoreTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.navy, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 28, color: AppColors.navy),
            Text('Add More',
                style: TextStyle(color: AppColors.navy, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}