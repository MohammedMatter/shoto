import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/core/theme/app_colors.dart';

class ScreenshotThumbnail extends StatelessWidget {
  final AssetEntity asset;
  final bool isFavorite;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ScreenshotThumbnail({
    super.key,
    required this.asset,
    required this.isFavorite,
    required this.isSelected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: AppColors.surface),
            FutureBuilder<Uint8List?>(
              future: asset.thumbnailDataWithSize(
                const ThumbnailSize.square(300),
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                return Image.memory(snapshot.data!, fit: BoxFit.cover);
              },
            ),
            if (isFavorite)
              Positioned(
                top: 6.h,
                right: 6.w,
                child: Icon(
                  Icons.favorite_rounded,
                  color: AppColors.error,
                  size: 16.sp,
                  shadows: const [Shadow(blurRadius: 4, color: Colors.black54)],
                ),
              ),
            if (selectionMode)
              Positioned(
                top: 6.h,
                left: 6.w,
                child: Container(
                  width: 22.w,
                  height: 22.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppColors.primary
                        : Colors.black.withValues(alpha: 0.4),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
              ),
            if (isSelected)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary, width: 3),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
