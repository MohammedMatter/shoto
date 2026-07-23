import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/primary_button.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_colors.dart';

Future<void> showCreateFolderSheet(
  BuildContext context, {
  required void Function(String name, int color) onCreate,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => _CreateFolderSheetContent(onCreate: onCreate),
  );
}

class _CreateFolderSheetContent extends StatefulWidget {
  final void Function(String name, int color) onCreate;
  const _CreateFolderSheetContent({required this.onCreate});

  @override
  State<_CreateFolderSheetContent> createState() =>
      _CreateFolderSheetContentState();
}

class _CreateFolderSheetContentState extends State<_CreateFolderSheetContent> {
  final TextEditingController _controller = TextEditingController();
  int _selectedColor = kFolderColors.first;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 32.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text('New Folder', style: AppTextStyles.headlineMedium),
            SizedBox(height: 16.h),
            TextField(
              controller: _controller,
              autofocus: true,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Folder name',
                hintStyle: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textDisabled,
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 14.h,
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              children: kFolderColors.map((colorValue) {
                final bool isSelected = colorValue == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = colorValue),
                  child: Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      color: Color(colorValue),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2.5)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 24.h),
            PrimaryButton(
              label: 'Create Folder',
              onPressed: () {
                final String name = _controller.text.trim();
                if (name.isEmpty) return;
                widget.onCreate(name, _selectedColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
