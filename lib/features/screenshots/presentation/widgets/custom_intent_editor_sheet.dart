import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/app_sheet.dart';
import 'package:shoto/core/services/haptics.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/core/widgets/confirm_dialog.dart';
import 'package:shoto/core/widgets/glass_layer.dart';
import 'package:shoto/core/widgets/sheet_surface.dart';
import 'package:shoto/features/screenshots/presentation/bloc/intent_catalog.dart';
import 'package:shoto/features/screenshots/presentation/widgets/intent_visuals.dart';

/// Writes a verb, or edits one already written.
///
/// Returns the intent when one was **created**, so the caller can file the
/// screenshot under it immediately. Edits return null: the catalog has already
/// been updated and every list watching it has already redrawn, and handing
/// back the edited intent would tempt callers into re-selecting something the
/// user was only renaming.
///
/// Free and uncapped. The free tier used to allow three, which meant the app
/// invited people to name what a screenshot was for and then charged them the
/// moment they got good at it.
Future<CustomIntent?> showCustomIntentEditorSheet(
  BuildContext context, {
  CustomIntent? existing,
}) async {
  return showAppSheet<CustomIntent>(
    context: context,
    isScrollControlled: true,
    // The tallest sheet in the app, so it gets the shorter entrance — see the
    // parameter's own note on why size and duration pull against each other.
    enterDuration: AppMotion.normal,
    builder: (BuildContext sheetContext) =>
        _CustomIntentEditorContent(existing: existing),
  );
}

class _CustomIntentEditorContent extends StatefulWidget {
  final CustomIntent? existing;

  const _CustomIntentEditorContent({required this.existing});

  @override
  State<_CustomIntentEditorContent> createState() =>
      _CustomIntentEditorContentState();
}

class _CustomIntentEditorContentState
    extends State<_CustomIntentEditorContent> {
  final IntentCatalog _catalog = sl<IntentCatalog>();
  late final TextEditingController _controller = TextEditingController(
    text: widget.existing?.label ?? '',
  );
  late String _iconKey = widget.existing?.iconKey ?? IntentIcons.keys.first;
  final FocusNode _focusNode = FocusNode();

  /// Guards against a second tap while the write is in flight — the sheet
  /// closes on completion, and a double tap would otherwise create the verb
  /// twice.
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  /// Longer than this stops being a verb and starts being a note.
  ///
  /// Not an arbitrary tidiness rule: the label has to fit in a chip beside an
  /// icon, and a chip that has to ellipsize its own label is unreadable at the
  /// exact moment it matters — mid-save, at a glance.
  static const int _maxLabelLength = 24;

  /// How long the keyboard waits before coming up.
  ///
  /// **`autofocus: true` was costing this sheet its entrance.** It raises the
  /// keyboard on the same frames the sheet is sliding, so the phone is
  /// simultaneously animating a tall panel, re-blurring everything behind it,
  /// and resizing the whole layout as the inset grows — and the entrance is
  /// what drops frames, because it is the one the user is watching.
  ///
  /// Matched to this sheet's own entrance so the keyboard starts as the panel
  /// lands — see the `enterDuration` passed above.
  /// Not read through `AppMotion.duration`: with reduced motion the sheet
  /// simply appears, and a fifth of a second before the keyboard follows is
  /// not motion — it is two things happening in a sensible order.
  static const Duration _focusDelay = AppMotion.normal;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(_focusDelay, () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SheetSurface(
        sigma: AppBlur.tallSheet,
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            // **Tall, and the same height whether the keyboard is up or not.**
            //
            // The first version sized itself to its content and then hid the
            // icons in a 108px window with its own scrollbar, so choosing a
            // glyph meant dragging a letterbox — a scroll view inside a sheet
            // that also scrolls, which is the specific arrangement that reads
            // as "not smooth" no matter how well each part is tuned.
            //
            // Now the sheet claims most of the screen and the icons simply
            // fit. The keyboard eats into it from below through the padding
            // above, which is why this is a fraction of the *screen* rather
            // than of the space left over: tying it to the remaining space
            // would make the whole sheet resize itself every time the keyboard
            // moved, and a surface that changes size while you type is the
            // least comfortable thing an editor can do.
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.82,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: 12.h),
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
                SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          _isEditing
                              ? context.l10n.intentEditTitle
                              : context.l10n.intentNewTitle,
                          style: AppTextStyles.headlineMedium,
                        ),
                      ),
                      if (_isEditing)
                        IconButton(
                          onPressed: _delete,
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.error,
                            size: 22.sp,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: _Preview(
                    iconKey: _iconKey,
                    label: _controller.text.trim(),
                  ),
                ),
                SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLength: _maxLabelLength,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    style: AppTextStyles.bodyLarge,
                    // Rebuilds the preview on every keystroke, deliberately
                    // without an animation on the text — see _Preview.
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _save(),
                    decoration: InputDecoration(
                      hintText: context.l10n.intentNameHint,
                      hintStyle: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textDisabled,
                      ),
                      // The character counter is suppressed: it is a limit that
                      // exists for the chip's sake, not a budget the user is
                      // meant to be spending down, and a live count under a
                      // two-word field reads as a warning.
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsetsDirectional.fromSTEB(
                        16.w,
                        14.h,
                        6.w,
                        14.h,
                      ),
                      // **The save button lives in the field it saves.**
                      //
                      // It used to be a full-width bar pinned along the bottom,
                      // which is the right control for a form and the wrong one
                      // for a single short word: it spent a whole row of the
                      // sheet, put the confirmation as far from the text as the
                      // screen allows, and made naming a verb look like a
                      // multi-step commitment. Here it sits under the thumb
                      // that has just finished typing, and the row it used to
                      // occupy went to the icons.
                      suffixIcon: _ConfirmButton(
                        isEnabled:
                            _controller.text.trim().isNotEmpty && !_isSaving,
                        onTap: _save,
                      ),
                      suffixIconConstraints: BoxConstraints(
                        minWidth: 48.w,
                        minHeight: 48.w,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                // **The one scrolling region on the sheet**, and it takes every
                // pixel left over rather than a number picked in advance.
                //
                // A builder rather than a `Wrap` in a scroll view, which is
                // what this was: a Wrap lays out every child it is given, so
                // all sixty tiles — sixty stateful press handlers and sixty
                // implicitly animated containers — were being built on the
                // frame the sheet started sliding, while the same frame was
                // re-blurring most of the screen. The grid builds the dozen or
                // so on screen and the rest as they are scrolled to.
                Flexible(
                  child: GridView.builder(
                    padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 16.h),
                    // Sized by extent rather than by a fixed column count, so
                    // the tiles keep their size and the *number* of columns
                    // changes with the phone — a count would stretch them into
                    // rectangles on a wide screen.
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 62.w,
                      mainAxisSpacing: 12.h,
                      crossAxisSpacing: 12.w,
                    ),
                    itemCount: IntentIcons.keys.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String key = IntentIcons.keys[index];
                      return _IconChoice(
                        iconKey: key,
                        isSelected: key == _iconKey,
                        onTap: () {
                          if (key == _iconKey) return;
                          // Light, not the confirm weight: picking a glyph is
                          // browsing, and the decision is the tick in the
                          // field. A firm buzz on every glyph would turn
                          // looking through sixty of them into being nudged
                          // sixty times.
                          Haptics.tap();
                          setState(() => _iconKey = key);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final String label = _controller.text.trim();
    if (label.isEmpty || _isSaving) return;
    setState(() => _isSaving = true);

    final CustomIntent? existing = widget.existing;
    if (existing == null) {
      final CustomIntent created = await _catalog.create(
        label: label,
        iconKey: _iconKey,
      );
      if (!mounted) return;
      Haptics.confirm();
      Navigator.of(context).pop(created);
      return;
    }

    await _catalog.update(id: existing.id, label: label, iconKey: _iconKey);
    if (!mounted) return;
    Haptics.confirm();
    // Renaming is not re-answering the question, so nothing comes back — see
    // the doc on showCustomIntentEditorSheet.
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final CustomIntent? existing = widget.existing;
    if (existing == null) return;

    final bool confirmed = await showConfirmDialog(
      context,
      title: context.l10n.intentDeleteTitle(existing.label),
      // Says out loud what the screenshots lose, because it is not obvious
      // that deleting a word touches pictures at all.
      message: context.l10n.intentDeleteMessage,
      confirmLabel: context.l10n.commonDelete,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    await _catalog.remove(existing.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}

/// The verb as it will actually appear, updating while it is being made.
///
/// **This is the part that was missing, and the reason the sheet felt like
/// filling in a form.** A name and a glyph are two abstract choices until you
/// see the thing they add up to; with the chip on screen the whole sheet
/// becomes direct manipulation of one object.
///
/// The two halves animate differently on purpose, and the difference is the
/// whole feel of it:
///
/// * **The text does not animate.** It is direct manipulation — the user's own
///   keystrokes — and anything that lags a keystroke reads as the phone
///   struggling. It appears exactly as fast as it is typed.
/// * **The glyph does.** Choosing an icon is a discrete decision made from
///   fifty options, and a swap that crossfades and scales says *this replaced
///   that* where an instant cut just leaves a different picture sitting there.
class _Preview extends StatelessWidget {
  final String iconKey;
  final String label;

  const _Preview({required this.iconKey, required this.label});

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = label.isEmpty;

    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(21.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedSwitcher(
              duration: AppMotion.duration(context, AppMotion.press),
              switchInCurve: AppMotion.standard,
              switchOutCurve: AppMotion.standard,
              transitionBuilder: (Widget child, Animation<double> animation) =>
                  FadeTransition(
                    opacity: animation,
                    // From 0.7, never from zero — a glyph that grows out of a
                    // point reads as being drawn rather than as arriving.
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.7,
                        end: 1,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
              child: Icon(
                IntentIcons.resolve(iconKey),
                // Keyed, or AnimatedSwitcher sees one Icon of one type and
                // crossfades nothing.
                key: ValueKey<String>(iconKey),
                size: 17.sp,
                color: AppColors.onPrimary,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              // The hint stands in until there is a word, so the chip is never
              // a lone glyph with a gap where its name goes.
              isEmpty ? context.l10n.intentNameLabel : label,
              style: AppTextStyles.bodyMedium.asMedium.copyWith(
                color: AppColors.onPrimary.withValues(alpha: isEmpty ? 0.5 : 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Saves the verb, from inside the field that names it.
///
/// **It never leaves and never greys out into a dead slab.** A full-width
/// button that sits disabled under an empty field is a promise the sheet is
/// not keeping yet; this one is simply quiet until there is a word, and then
/// it lights. The state is carried by fill and by scale together, so the
/// moment the first letter lands the tick visibly arrives rather than merely
/// becoming tappable.
class _ConfirmButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onTap;

  const _ConfirmButton({required this.isEnabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(end: 6.w),
      child: PressableScale(
        scale: 0.9,
        // Null rather than a no-op, so a tap on an empty field does not
        // animate as though something happened.
        onTap: isEnabled ? onTap : null,
        child: AnimatedScale(
          scale: isEnabled ? 1 : 0.82,
          duration: AppMotion.duration(context, AppMotion.press),
          curve: AppMotion.standard,
          child: AnimatedContainer(
            duration: AppMotion.duration(context, AppMotion.press),
            curve: AppMotion.standard,
            width: 38.w,
            height: 38.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isEnabled
                  ? AppColors.primary
                  : AppColors.textDisabled.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              size: 20.sp,
              color: isEnabled ? AppColors.onPrimary : AppColors.textDisabled,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconChoice extends StatelessWidget {
  final String iconKey;
  final bool isSelected;
  final VoidCallback onTap;

  const _IconChoice({
    required this.iconKey,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      // Shallower than the folder swatches' 0.9. These tiles are square and
      // close together, and at 0.9 a press reads as the tile flinching away
      // from the finger.
      scale: 0.93,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.duration(context, AppMotion.press),
        curve: AppMotion.standard,
        // No size of its own: the grid cell is the size, so the tiles stay on
        // the same rhythm as the spacing around them on every screen width.
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.border,
          ),
        ),
        // The chosen glyph sits slightly larger as well as lit. Two signals
        // for one bit, which is the right ratio in a grid of fifty where the
        // selected one has to be findable without hunting.
        child: AnimatedScale(
          scale: isSelected ? 1.12 : 1,
          duration: AppMotion.duration(context, AppMotion.press),
          curve: AppMotion.standard,
          child: Icon(
            IntentIcons.resolve(iconKey),
            size: 21.sp,
            color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
