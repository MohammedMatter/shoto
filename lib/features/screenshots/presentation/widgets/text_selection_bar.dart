import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/glass_layer.dart';
import 'package:shoto/features/screenshots/presentation/widgets/photo_chrome.dart';
import 'package:shoto/features/smart_actions/data/services/action_extractor.dart';
import 'package:shoto/features/smart_actions/domain/entities/detected_action.dart';
import 'package:shoto/features/smart_actions/presentation/widgets/action_options.dart';

/// What the bottom of the viewer becomes while text is selected.
///
/// **It replaces the action bar rather than floating beside the selection.**
/// Every desktop and most phones put this menu next to what you selected,
/// which works when the pointer is a mouse and the content is a page that can
/// scroll out from under it. Here the content is a fixed picture and the
/// pointer is a thumb: a menu next to the selection covers the very words
/// being selected, and on the bottom third of a tall screenshot it would have
/// nowhere to go. The bar the user's thumb is already resting near has neither
/// problem, and it is the shape this screen already speaks in.
///
/// The preview line above it exists for the same reason. The finger doing the
/// selecting is covering the text it selected, so the one thing this bar can
/// do that the picture cannot is *say what is about to be copied*.
class TextSelectionBar extends StatelessWidget {
  final String selection;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onSelectAll;
  final VoidCallback onClose;

  /// Runs a detected action — opening a link, starting directions. The bar
  /// finds the action; the page decides whether it is allowed to run.
  final ValueChanged<ActionOption> onAction;

  const TextSelectionBar({
    super.key,
    required this.selection,
    required this.onCopy,
    required this.onShare,
    required this.onSelectAll,
    required this.onClose,
    required this.onAction,
  });

  /// The one thing worth offering to *do* with this selection, if there is
  /// one.
  ///
  /// Reuses the extractor the smart-actions sheet is built on rather than
  /// asking the same question a second way — which is the rule that file
  /// already states about itself, pointed at a new caller: two features
  /// disagreeing about whether the same digits are a tracking number is worse
  /// than neither offering anything.
  ///
  /// Only when the selection is **exactly one** detection, and never for the
  /// kinds whose only option is copying. A chip that appears for half a
  /// paragraph, or that offers "Copy" beside the Copy button, is noise on a
  /// bar with four things on it already.
  _Suggestion? _suggest(BuildContext context) {
    final String text = selection.trim();
    if (text.isEmpty || text.length > 200) return null;

    final List<DetectedAction> found = ActionExtractor.extract(text);
    if (found.length != 1) return null;

    // `options` always ends with Copy and Share, so anything longer than those
    // two starts with a real verb — see [DetectedActionOptions.options].
    final List<ActionOption> options = found.first.options(context);
    if (options.length <= 2) return null;

    return _Suggestion(found.first, options.first);
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    final _Suggestion? suggestion = _suggest(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
          child: Row(
            children: <Widget>[
              Flexible(child: _Preview(text: selection)),
              SizedBox(width: 8.w),
              // The way out, in the same place and the same shape as the
              // intent tick this bar is standing in for.
              PhotoGlassCircle(icon: Icons.close_rounded, onTap: onClose),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            16.w,
            0,
            16.w,
            bottomInset > 0 ? bottomInset + 6.h : 18.h,
          ),
          child: GlassLayer(
            radius: 26.r,
            sigma: AppBlur.overPhoto,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 10.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26.r),
                gradient: PhotoChromePalette.barFill,
                border: Border.all(color: PhotoChromePalette.rim),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: PhotoBarAction(
                      icon: Icons.copy_rounded,
                      label: context.l10n.actionsCopy,
                      onTap: onCopy,
                      enabled: selection.isNotEmpty,
                    ),
                  ),
                  Expanded(
                    child: PhotoBarAction(
                      icon: Icons.select_all_rounded,
                      label: context.l10n.copyTextSelectAll,
                      onTap: onSelectAll,
                    ),
                  ),
                  Expanded(
                    child: PhotoBarAction(
                      icon: Icons.ios_share_rounded,
                      label: context.l10n.commonShare,
                      onTap: onShare,
                      enabled: selection.isNotEmpty,
                    ),
                  ),
                  if (suggestion != null)
                    Expanded(
                      child: PhotoBarAction(
                        icon: suggestion.option.icon,
                        label: suggestion.option.label,
                        onTap: () => onAction(suggestion.option),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Suggestion {
  final DetectedAction action;
  final ActionOption option;

  const _Suggestion(this.action, this.option);
}

/// What is currently selected, in one line.
class _Preview extends StatelessWidget {
  final String text;

  const _Preview({required this.text});

  @override
  Widget build(BuildContext context) {
    return GlassLayer(
      radius: 20.r,
      sigma: AppBlur.overPhoto,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          gradient: PhotoChromePalette.barFill,
          border: Border.all(color: PhotoChromePalette.rim),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.text_fields_rounded,
              size: 16.sp,
              color: Colors.white.withValues(alpha: 0.95),
            ),
            SizedBox(width: 9.w),
            Flexible(
              child: Text(
                // Newlines are what a multi-line selection is *for*, and they
                // would each open a new line in a pill that has room for one.
                text.isEmpty
                    ? context.l10n.copyTextPrompt
                    : text.replaceAll('\n', ' '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall.asMedium.copyWith(
                  color: Colors.white.withValues(
                    alpha: text.isEmpty ? 0.7 : 0.95,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
