import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/header_icon_button.dart';

/// Narrows the folder grid by name, as you type.
///
/// **Not `autofocus`, and never focused by the page.** The keyboard coming up
/// on arrival would cover two of the three rows of folders on the screen the
/// user just asked to see — and most visits to this tab are to open a folder
/// that is already visible, not to look for one. It is a field that waits.
///
/// Owns its [TextEditingController] rather than taking one, because the value
/// it starts from is a plain string held by the page. [value] is used to seed
/// the controller and to keep the clear button honest; it is deliberately not
/// pushed back into the field on every rebuild, which would fight the user's
/// own cursor.
class FolderSearchField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const FolderSearchField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<FolderSearchField> createState() => _FolderSearchFieldState();
}

class _FolderSearchFieldState extends State<FolderSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
    // Takes the keyboard down with it. A cleared field with the caret still
    // blinking in it says the search is still happening.
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasText = widget.value.isNotEmpty;

    return SizedBox(
      // Read from the button beside it rather than repeated, so the two ends
      // of the row cannot end up a couple of pixels apart on some screen size.
      height: HeaderIconButton.size,
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        textInputAction: TextInputAction.search,
        style: context.text.bodyMedium.copyWith(
          color: context.colors.textPrimary,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: context.l10n.foldersSearchHint,
          hintStyle: context.text.bodyMedium.copyWith(
            color: context.colors.textDisabled,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 19.sp,
            color: context.colors.textSecondary,
          ),
          prefixIconConstraints: BoxConstraints(minWidth: 40.w),
          suffixIcon: hasText
              ? PressableScale(
                  scale: 0.85,
                  onTap: _clear,
                  child: Icon(
                    Icons.close_rounded,
                    size: 18.sp,
                    color: context.colors.textSecondary,
                  ),
                )
              : null,
          suffixIconConstraints: BoxConstraints(minWidth: 40.w),
          filled: true,
          fillColor: context.colors.surface,
          contentPadding: EdgeInsets.symmetric(vertical: 10.h),
          // A pill, matching the button beside it, and bordered for the same
          // reason [HeaderIconButton] is: on the light canvas a `surface` fill
          // is eleven values off the page and needs the hairline to have an
          // edge at all.
          border: _border(context.colors.border),
          enabledBorder: _border(context.colors.border),
          focusedBorder: _border(context.colors.borderSelected),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.pill),
    borderSide: BorderSide(color: color),
  );
}
