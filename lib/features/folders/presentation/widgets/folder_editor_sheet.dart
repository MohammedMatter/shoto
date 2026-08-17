import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/app_sheet.dart';
import 'package:shoto/core/services/biometric_auth_service.dart';
import 'package:shoto/core/services/haptics.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/app_switch.dart';
import 'package:shoto/core/widgets/glass_layer.dart';
import 'package:shoto/core/widgets/primary_button.dart';
import 'package:shoto/core/widgets/sheet_surface.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_card.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_colors.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_icons.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_name_limit.dart';

/// What a folder is called, what colour it is, and what it looks like.
///
/// **One sheet for making a folder and for editing one**, where there used to
/// be a creation sheet and a separate rename dialog holding a bare text field.
/// A folder now has three things about it worth choosing, and splitting them
/// across two surfaces meant the picture could only ever be set once — you
/// could rename "Recipes" forever and never fix the glyph you picked for it in
/// a hurry.
///
/// [onSave] receives the three values plus the private flag. The caller
/// decides what to do with them: the grid raises a create or an update event,
/// and neither of those decisions belongs to a sheet.
///
/// **The lock is offered on creation only.** Turning it *on* later is a fine
/// idea and turning it *off* is a removal of protection — one that should cost
/// a fingerprint at least, since anybody holding an unlocked phone could
/// otherwise strip the lock from a folder without ever proving they may see
/// inside it. That is its own piece of work with its own confirmation; quietly
/// putting the switch on this sheet would be doing it badly.
Future<void> showFolderEditorSheet(
  BuildContext context, {
  FolderEntity? existing,
  required void Function(
    String name,
    int color,
    String? iconKey,
    bool isPrivate,
  )
  onSave,
}) {
  return showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    // The tallest sheet in the app now shares this with the intent editor, and
    // the same trade applies: a big surface gets the shorter entrance, because
    // the distance it travels already reads as weight.
    enterDuration: AppMotion.normal,
    builder: (sheetContext) =>
        _FolderEditorContent(existing: existing, onSave: onSave),
  );
}

class _FolderEditorContent extends StatefulWidget {
  final FolderEntity? existing;
  final void Function(String name, int color, String? iconKey, bool isPrivate)
  onSave;

  const _FolderEditorContent({required this.existing, required this.onSave});

  @override
  State<_FolderEditorContent> createState() => _FolderEditorContentState();
}

class _FolderEditorContentState extends State<_FolderEditorContent> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.existing?.name ?? '',
  );

  /// Held so the field can put the keyboard *away* — never to call it up.
  ///
  /// **Nothing on this sheet focuses the field, and that is the fix for the
  /// bug that made most of the sheet invisible.** Creating a folder used to
  /// request focus a beat after the panel landed, which raised the keyboard
  /// over a sheet whose whole purpose is below it. Measured on a 393×873
  /// phone: the header alone — preview card, field, swatches, lock row — is
  /// about 444dp, and the keyboard leaves 416dp above the Create button. The
  /// glyph grid was not merely cut off; its slivers never reached the viewport
  /// and were never built. Somebody making their first folder could not tell
  /// there were pictures to choose from at all unless they happened to put the
  /// keyboard away.
  ///
  /// The argument against it was already written down here, and applied to
  /// the *editing* case only: raising the keyboard over the icon grid hides
  /// the reason most people came. It is just as true of a folder being made —
  /// the name is one of four choices on this sheet, and it is the only one of
  /// the four the user can still reach with a single tap.
  ///
  /// With the keyboard down, the sheet opens on all four at once: the preview,
  /// the name, the eight colours, the lock and the glyphs.
  final FocusNode _focusNode = FocusNode();

  /// The typed name, published to the preview **without a `setState`**.
  ///
  /// `onChanged: (_) => setState(() {})` is the obvious way to keep the card at
  /// the top of the sheet in step with the field, and on this particular sheet
  /// it is the most expensive line in the feature: a `setState` here rebuilds
  /// the whole editor on every keystroke — the header, the colour list, the
  /// builder behind ninety-eight icon tiles — and every one of those rebuilds
  /// happens inside a `BackdropFilter` that is frosting most of the screen,
  /// while the keyboard is up and the user is typing. The one widget that
  /// actually depends on the name is the preview card.
  ///
  /// So the name travels on its own: [_Preview] listens, and nothing else on
  /// the sheet hears a keystroke at all. The colour, the glyph and the lock
  /// stay on `setState` — they are three discrete taps a session, not thirty
  /// characters a minute.
  late final ValueNotifier<String> _name = ValueNotifier<String>(
    widget.existing?.name ?? '',
  );

  late int _color = widget.existing?.color ?? kFolderColors.first;
  late String _iconKey = widget.existing?.iconKey ?? FolderIcons.keys.first;
  late bool _isPrivate = widget.existing?.isPrivate ?? false;

  /// Starts at the widest claim and narrows once the device answers. The
  /// lookup is a platform round-trip, so the row would otherwise pop from
  /// blank to text a frame later; naming both and then dropping one is the
  /// quieter correction.
  BiometricKind _lockKind = BiometricKind.faceAndFingerprint;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _loadLockKind();
  }

  Future<void> _loadLockKind() async {
    final BiometricKind kind = await sl<BiometricAuthService>().enrolledKind();
    if (!mounted) return;
    setState(() => _lockKind = kind);
  }

  /// Says only what this phone can actually do. The label used to promise
  /// "face or fingerprint" everywhere, which reads as a bug on the many
  /// Androids whose face unlock never reaches BiometricPrompt — you turn the
  /// switch on, and the prompt that appears has no face in it.
  String get _privateLabel => switch (_lockKind) {
    BiometricKind.faceAndFingerprint => context.l10n.foldersPrivate,
    BiometricKind.face => context.l10n.foldersPrivateFace,
    BiometricKind.fingerprint => context.l10n.foldersPrivateFingerprint,
    BiometricKind.unknown => context.l10n.foldersPrivateGeneric,
  };

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    _name.dispose();
    super.dispose();
  }

  /// **Dismisses first, then saves.**
  ///
  /// The order was the other way round, and it put a database write, a re-read
  /// of every folder and a rebuild of the grid underneath onto the same frames
  /// as the sheet's exit — the tallest surface in the app sliding a phone's
  /// height off the screen while re-blurring everything behind it. Popping
  /// first hands those frames to the animation and lets the write land after
  /// it; nothing about the result depends on which happens first, since the
  /// sheet is on its way out either way.
  void _save() {
    final String name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop();
    widget.onSave(name, _color, _iconKey, _isPrivate);
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
            // A fraction of the *screen* rather than of the space left over,
            // for the reason the intent editor records: tying it to the
            // remaining space makes the whole sheet resize itself every time
            // the keyboard moves, and a surface that changes size while you
            // type is the least comfortable thing an editor can do.
            // 0.92 rather than 0.88. The four points are 35dp, and they are
            // spent on the one thing this sheet is short of: they are what
            // puts the *second* glyph section's tiles across the bottom edge
            // rather than its heading alone. What they cost is a sliver of the
            // page behind, which nobody is reading.
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.92,
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
                      color: context.colors.border,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Text(
                    _isEditing
                        ? context.l10n.foldersEditTitle
                        : context.l10n.foldersNew,
                    style: context.text.headlineMedium,
                  ),
                ),
                SizedBox(height: 14.h),
                // **Everything below the title scrolls, as one region.**
                //
                // It did not, and the phone showed why within a minute: the
                // preview, the field, the swatches and the lock row are about
                // 500dp of fixed content, the keyboard takes roughly 390dp of
                // an 873dp screen, and the icon grid was the only thing left
                // able to give. So it gave all of it — with the keyboard up
                // the picker collapsed to a sliver of the top row of tiles,
                // on the sheet whose whole point is picking a glyph.
                //
                // Slivers rather than a `Column` in a `SingleChildScrollView`,
                // because a scroll view lays out every child it is given and
                // that would build all ninety-eight tiles on the frame the
                // sheet starts sliding, while the same frame is re-blurring
                // most of the screen. A `SliverGrid` builds the dozen on
                // screen and the rest as they are scrolled to.
                Flexible(
                  child: CustomScrollView(
                    // Dragging the icons puts the keyboard away, which is the
                    // gesture somebody makes anyway the moment they go looking
                    // for a glyph — so the picker opens up under the finger
                    // that was already reaching for it.
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: <Widget>[
                      SliverToBoxAdapter(child: _header(context)),
                      // **A heading and a grid per group, rather than one grid
                      // of ninety-eight.**
                      //
                      // Still slivers, and still lazy: a `SliverGrid` per
                      // section builds only the tiles on screen, so the ten
                      // sections together cost what the single grid did. What
                      // changes is that the scroll now has landmarks — and
                      // the section people arrive looking for, the apps a
                      // screenshot came from, announces itself instead of
                      // being eighty tiles down an unlabelled run.
                      for (final FolderIconGroup group in FolderIcons.groups)
                        ..._iconSection(context, group),
                    ],
                  ),
                ),
                // **The lock is pinned down here, out of the scroll.**
                //
                // It used to sit between the swatches and the glyphs, inside
                // the scrolling region, and it was costing the picker the one
                // thing the picker needed: 64dp of the space directly under
                // the fold. With it there, the first glyph section opened with
                // a single row of tiles sitting flush against the Create
                // button — which reads as the bottom of the sheet, not as a
                // grid that continues. Nobody scrolls past what looks
                // finished, so most people never learned there were pictures
                // to choose from.
                //
                // Moving it here buys the grid that row and a half, and the
                // lock loses nothing by it: a decision that cannot be undone
                // by looking now sits beside the button that commits it, and
                // never scrolls away.
                if (!_isEditing)
                  Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 0),
                    child: _PrivateRow(
                      isPrivate: _isPrivate,
                      label: _privateLabel,
                      onChanged: (bool value) =>
                          setState(() => _isPrivate = value),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 20.h),
                  // **Off until the folder has a name, and lit by the
                  // keystroke that gives it one.**
                  //
                  // The refusal was already here — `_save` returns without
                  // doing anything on an empty name — and it was invisible:
                  // the button looked exactly as it does when it works, so
                  // pressing it did nothing and said nothing about why. A
                  // control that will not act should say so before it is
                  // pressed, not after.
                  //
                  // Listening to [_name] rather than reading it, so this stays
                  // out of the rule the notifier exists for: a keystroke
                  // rebuilds this button and the preview card, and nothing
                  // else on the sheet.
                  child: ValueListenableBuilder<String>(
                    valueListenable: _name,
                    builder: (BuildContext context, String name, Widget? _) =>
                        PrimaryButton(
                          label: _isEditing
                              ? context.l10n.commonSave
                              : context.l10n.foldersCreate,
                          // Already trimmed on its way in, so a field holding
                          // nothing but spaces leaves the button off.
                          onPressed: name.isEmpty ? null : _save,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The preview, the name and the colours — everything that scrolls away
  /// above the glyphs.
  ///
  /// Three things now, where there were four: the lock moved to the pinned
  /// strip at the foot of the sheet, so that what sits between the swatches
  /// and the first row of glyphs is a section heading and nothing else.

  /// One labelled run of glyphs: the heading, then its grid.
  ///
  /// Returns two slivers rather than wrapping them in one, because a heading
  /// inside the grid's own sliver would have to be a grid cell — and a cell is
  /// 62dp wide, which is not a place a word fits.
  List<Widget> _iconSection(BuildContext context, FolderIconGroup group) {
    return <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          // Generous above, tight below: the heading belongs to the grid under
          // it, and equal gaps would leave it floating between two sections
          // belonging to neither. 12 rather than 18 above — still twice what
          // is below it, and the six points go to the row of tiles that has to
          // reach across the bottom edge of the sheet.
          padding: EdgeInsetsDirectional.fromSTEB(24.w, 12.h, 24.w, 8.h),
          child: Text(group.label(context), style: context.text.sectionLabel),
        ),
      ),
      SliverPadding(
        padding: EdgeInsetsDirectional.fromSTEB(24.w, 0, 24.w, 4.h),
        sliver: SliverGrid.builder(
          // Sized by extent rather than by a column count, so the tiles keep
          // their size and the *number* of columns changes with the phone — a
          // count would stretch them into rectangles on a wide screen.
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 62.w,
            mainAxisSpacing: 10.h,
            crossAxisSpacing: 10.w,
          ),
          itemCount: group.keys.length,
          itemBuilder: (BuildContext context, int index) {
            final String key = group.keys[index];
            return _IconChoice(
              iconKey: key,
              isSelected: key == _iconKey,
              onTap: () {
                if (key == _iconKey) return;
                // Light, not the confirm weight: picking a glyph is browsing,
                // and the decision is the button below. A firm buzz on every
                // glyph would turn looking through ninety-eight of them into
                // being nudged ninety-eight times.
                Haptics.tap();
                setState(() => _iconKey = key);
              },
            );
          },
        ),
      ),
    ];
  }

  Widget _header(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // **The card and the field share a line.**
        //
        // Stacked, they were 227dp of the 456dp the sheet has between its
        // title and its buttons — half the surface spent before the glyph
        // picker got to start. Side by side they are 152dp, and the 75dp that
        // buys goes where it was missing: the grid, which is the only thing on
        // this sheet that cannot show what it is in one row.
        //
        // The card keeps its size. It is a hair larger than a real grid tile
        // and that is the point of it — shrinking it to make room would have
        // solved the same problem by breaking the reason the preview exists.
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _Preview(
                name: _name,
                color: _color,
                iconKey: _iconKey,
                isPrivate: _isPrivate,
                screenshotCount: widget.existing?.screenshotCount ?? 0,
              ),
              SizedBox(width: 16.w),
              Expanded(child: _nameField(context)),
            ],
          ),
        ),
        SizedBox(height: 14.h),
        _ColorRow(
          selected: _color,
          onSelected: (int value) => setState(() => _color = value),
        ),
      ],
    );
  }

  Widget _nameField(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      maxLength: kMaxFolderNameLength,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.done,
      style: context.text.bodyLarge,
      // Updates the preview on every keystroke, deliberately without an
      // animation on the text — see [_Preview] — and deliberately
      // without a `setState`, see [_name].
      onChanged: (String value) => _name.value = value.trim(),
      // Puts the keyboard away rather than saving. The name is the
      // *first* of three choices on this sheet, so finishing it is not
      // finishing the sheet — and a "done" key that created the folder
      // would mean the glyph and the colour were only ever reachable by
      // people who did not press it.
      onSubmitted: (_) => _focusNode.unfocus(),
      decoration: InputDecoration(
        hintText: context.l10n.foldersNameHint,
        hintStyle: context.text.bodyLarge.copyWith(
          color: context.colors.textDisabled,
        ),
        // Suppressed for the reason the intent editor gives: the limit
        // exists for the card's sake, not as a budget the user is meant
        // to be spending down, and a live count under a two-word field
        // reads as a warning.
        counterText: '',
        filled: true,
        fillColor: context.colors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      ),
    );
  }
}

/// The folder as it will actually appear on the grid, while it is being made.
///
/// **The real [FolderCard], not a drawing of one.** A preview that is its own
/// widget is a second implementation of the card that starts identical and
/// drifts — the swatch you pick is not quite the swatch you get, the glyph
/// sits a little differently, and nobody finds out until it is on the grid.
/// This builds a throwaway [FolderEntity] and hands it to the same widget the
/// grid uses, at the size the grid uses, so what is on the sheet *is* the
/// answer.
///
/// The two halves update differently on purpose, and the difference is the
/// whole feel of it — the same split the intent editor's preview makes: the
/// text appears exactly as fast as it is typed, because it is the user's own
/// keystrokes and anything that lags one reads as the phone struggling, while
/// the colour and the glyph are discrete choices made from a grid and are
/// worth animating.
class _Preview extends StatelessWidget {
  /// Listened to rather than passed by value, which is what keeps a keystroke
  /// from reaching the rest of the sheet — see [_FolderEditorContentState._name].
  final ValueListenable<String> name;

  final int color;
  final String iconKey;
  final bool isPrivate;
  final int screenshotCount;

  const _Preview({
    required this.name,
    required this.color,
    required this.iconKey,
    required this.isPrivate,
    required this.screenshotCount,
  });

  @override
  Widget build(BuildContext context) {
    // No `Center` any more: the card shares a line with the name field, and
    // the row it sits in is what places it.
    //
    // The card is two `CustomPaint`s and a gradient sitting on top of a
    // near-full-screen backdrop blur. Its own layer, so a name being typed
    // repaints the card and not the frosted panel behind it.
    return RepaintBoundary(
      child: SizedBox(
        // Wider than a grid tile, and in the grid's own proportion. The card
        // has to be readable here — this is the only place it is ever looked
        // *at* rather than scanned past.
        width: 116.w,
        height: 116.w / 0.76,
        child: AnimatedSwitcher(
          duration: AppMotion.duration(context, AppMotion.press),
          switchInCurve: AppMotion.standard,
          switchOutCurve: AppMotion.standard,
          // Crossfades the card whenever the colour or the glyph changes, and
          // never when only the name does — the key is what decides that,
          // and the name is below it rather than in it. A keystroke rebuilds
          // inside this builder without ever handing the switcher a new
          // child, so there is nothing for it to cross-fade.
          child: ValueListenableBuilder<String>(
            key: ValueKey<String>('$color-$iconKey-$isPrivate'),
            valueListenable: name,
            builder: (BuildContext context, String value, Widget? child) =>
                FolderCard(
                  folder: FolderEntity(
                    id: -1,
                    name: value.isEmpty ? context.l10n.foldersNameLabel : value,
                    color: color,
                    createdAt: DateTime(2026),
                    screenshotCount: screenshotCount,
                    isPrivate: isPrivate,
                    iconKey: iconKey,
                  ),
                  onTap: () {},
                ),
          ),
        ),
      ),
    );
  }
}

/// The eight filing colours, on one line.
///
/// Scrolls sideways rather than wrapping onto a second row. Eight swatches at a
/// comfortable tap size are a few pixels wider than a phone, and a `Wrap` would
/// answer that by spending a whole extra row of a sheet that has an icon grid
/// to fit — with one swatch alone on it.
class _ColorRow extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const _ColorRow({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38.w,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        itemCount: kFolderColors.length,
        separatorBuilder: (_, _) => SizedBox(width: 12.w),
        itemBuilder: (BuildContext context, int index) {
          final int value = kFolderColors[index];
          final bool isSelected = value == selected;

          return PressableScale(
            scale: 0.9,
            onTap: () => onSelected(value),
            // Picking a colour used to be a hard cut: a ring and a tick
            // appeared on one swatch and vanished from another in the same
            // frame, which reads as two unrelated events rather than as the
            // choice moving.
            child: AnimatedContainer(
              duration: AppMotion.duration(context, AppMotion.press),
              curve: AppMotion.standard,
              width: 36.w,
              height: 36.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Color(value),
                shape: BoxShape.circle,
                // The ring was white, which is invisible in light mode — a
                // white ring, on a swatch, on a white sheet. Text colour
                // instead: it flips with the mode, so the ring is always drawn
                // against its opposite whichever surface the sheet is on.
                border: Border.all(
                  color: isSelected
                      ? context.colors.textPrimary
                      : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: AnimatedScale(
                scale: isSelected ? 1 : 0.4,
                duration: AppMotion.duration(context, AppMotion.press),
                curve: AppMotion.standard,
                child: AnimatedOpacity(
                  opacity: isSelected ? 1 : 0,
                  duration: AppMotion.duration(context, AppMotion.press),
                  curve: AppMotion.standard,
                  child: Icon(
                    Icons.check,
                    color: onFolderColor(value),
                    size: 18,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// **The whole row answers, not just the switch.**
///
/// Even with the thumb finally legible (see AppSwitch), a 12px knob sliding
/// 20px is a very quiet way to report the one decision on this sheet that
/// cannot be undone by looking — you cannot tell a locked folder from an
/// unlocked one without trying to open it. So the row it lives in carries the
/// state too: it lifts onto the accent, draws an edge, and the fingerprint
/// lights up. Three signals for one bit, which is the right ratio when the bit
/// is "is this private".
///
/// The border is always 1.5px and only its *colour* animates, so switching it
/// on cannot nudge the sheet's layout.
class _PrivateRow extends StatelessWidget {
  final bool isPrivate;
  final String label;
  final ValueChanged<bool> onChanged;

  const _PrivateRow({
    required this.isPrivate,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.98,
      onTap: () => onChanged(!isPrivate),
      child: AnimatedContainer(
        duration: AppMotion.duration(context, AppMotion.press),
        curve: AppMotion.standard,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          // A wash of the accent rather than a hue. The accent is achromatic
          // in both modes, so "on" reads as the row being lifted off the sheet
          // instead of as a colour arriving — and colour in this app has to
          // mean something more specific than "selected".
          color: isPrivate
              ? context.colors.primary.withValues(alpha: 0.10)
              : context.colors.surfaceVariant,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isPrivate ? context.colors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: <Widget>[
            // The glyph swaps as well as re-tints. A fingerprint is how you
            // *open* the folder; whether it is locked at all is a padlock, and
            // the two states now differ in shape rather than only in shade —
            // which is the half of this that survives being colour-blind.
            AnimatedSwitcher(
              duration: AppMotion.duration(context, AppMotion.press),
              switchInCurve: AppMotion.standard,
              switchOutCurve: AppMotion.standard,
              child: Icon(
                isPrivate ? Icons.lock_rounded : Icons.lock_open_rounded,
                // Keyed, or AnimatedSwitcher sees one Icon widget of one type
                // and cross-fades nothing.
                key: ValueKey<bool>(isPrivate),
                color: isPrivate
                    ? context.colors.textPrimary
                    : context.colors.textSecondary,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                // bodyLarge, matching every other switch row in the app.
                style: context.text.bodyLarge,
              ),
            ),
            SizedBox(width: 8.w),
            AppSwitch(value: isPrivate, onChanged: onChanged),
          ],
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
      // Shallower than the colour swatches' 0.9. These tiles are square and
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
          color: isSelected
              ? context.colors.primary
              : context.colors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isSelected ? Colors.transparent : context.colors.border,
          ),
        ),
        // The chosen glyph sits slightly larger as well as lit. Two signals for
        // one bit, which is the right ratio in a grid this long, where the
        // selected one has to be findable without hunting.
        child: AnimatedScale(
          scale: isSelected ? 1.12 : 1,
          duration: AppMotion.duration(context, AppMotion.press),
          curve: AppMotion.standard,
          child: FolderGlyph(
            iconKey: iconKey,
            size: 20.sp,
            color: isSelected
                ? context.colors.onPrimary
                : context.colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
