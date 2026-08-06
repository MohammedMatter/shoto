import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/services/haptics.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/asset_thumbnail_image.dart';
import 'package:shoto/features/screenshots/domain/use_cases/keep_captures_use_case.dart';

/// The inbox: one capture at a time, keep or skip.
///
/// **This is the answer to the empty room.** Making the library opt-in was
/// right — a library that mirrors the gallery is the gallery — but it left a
/// new install empty, and the people with four hundred unfindable screenshots
/// are exactly the people who will never file them by hand. So the app is
/// full on day one *without* keeping anything the user has not said yes to:
/// what you captured is offered, one decision each, and the queue has a
/// bottom.
///
/// **One card at a time rather than a grid of checkboxes**, and the difference
/// is whether the queue gets finished. A grid asks you to hold a policy in
/// your head and apply it forty times; a single picture asks one question you
/// can answer by looking. The count in the corner is what makes it bearable —
/// it is the only number in this app that is *supposed* to run out.
///
/// Nothing here deletes. Skip means "not for SHOTO", never "remove from my
/// phone", and the original stays in the gallery either way — including the
/// ones that are kept, which are copied rather than moved.
class TriagePage extends StatefulWidget {
  final List<AssetEntity> captures;

  const TriagePage({super.key, required this.captures});

  @override
  State<TriagePage> createState() => _TriagePageState();
}

class _TriagePageState extends State<TriagePage> {
  final AppPreferences _preferences = sl<AppPreferences>();

  /// Decided yes, and not yet written. Collected rather than imported one at a
  /// time because an import is a file copy plus a database write, and putting
  /// one of those between the user's tap and the next picture makes a queue of
  /// forty feel like forty small waits.
  final List<String> _keeping = <String>[];

  int _index = 0;
  bool _finishing = false;

  AssetEntity get _current => widget.captures[_index];

  bool get _isDone => _index >= widget.captures.length;

  Future<void> _decide({required bool keep}) async {
    final AssetEntity decided = _current;
    if (keep) {
      Haptics.confirm();
      _keeping.add(decided.id);
    } else {
      Haptics.tap();
    }

    // The watermark moves on every decision, not at the end. Somebody who
    // answers six of forty and closes the app has genuinely answered six, and
    // being asked about them again on the next launch is the thing that would
    // teach them to ignore the queue.
    await _preferences.advanceTriageSince(decided.createDateTime);

    if (!mounted) return;
    setState(() => _index++);
    if (_isDone) await _finish();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);

    final int kept = await sl<KeepCapturesUseCase>()(_keeping);
    if (!mounted) return;
    Navigator.of(context).pop(kept);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isDone
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: <Widget>[
                  _Header(
                    index: _index + 1,
                    total: widget.captures.length,
                    onClose: _finish,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 8.h,
                      ),
                      child: _Capture(asset: _current),
                    ),
                  ),
                  _Choices(
                    onKeep: () => _decide(keep: true),
                    onSkip: () => _decide(keep: false),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int index;
  final int total;
  final VoidCallback onClose;

  const _Header({
    required this.index,
    required this.total,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 12.w, 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.l10n.triageTitle,
                  style: AppTextStyles.headlineMedium,
                ),
                SizedBox(height: 2.h),
                Text(
                  context.l10n.triageBody,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          // The count is mono, like every other character-by-character string
          // in this app, so the digits do not shuffle sideways as it counts.
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text(
              context.l10n.triageProgress(index, total),
              style: AppTextStyles.mono,
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(
              Icons.close_rounded,
              size: 22.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// The capture, as large as the screen will allow.
///
/// Deliberately the whole picture rather than a cropped tile: the question is
/// "is this worth keeping", and a square crop of a tall screenshot throws away
/// most of what the answer depends on.
class _Capture extends StatelessWidget {
  final AssetEntity asset;

  const _Capture({required this.asset});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.duration(context, AppMotion.normal),
      switchInCurve: AppMotion.standard,
      switchOutCurve: AppMotion.standard,
      // Rounded, **not** clipped, and that is a rule rather than a choice:
      // the corner is a filing mark and it only survives on surfaces the app
      // drew itself. On a photograph a missing corner reads as a rendering
      // fault — see the same note in `screenshot_thumbnail.dart`, where it
      // was tried and taken back out. It is doubly wrong here, on a capture
      // the user has not decided to keep yet: the mark would be claiming
      // exactly the thing the screen is asking about.
      child: ClipRRect(
        // Keyed by asset, or the switcher sees one thumbnail widget of one
        // type and cross-fades nothing as the queue advances.
        key: ValueKey<String>(asset.id),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: double.infinity,
          color: AppColors.surfaceVariant,
          child: AssetThumbnailImage(asset: asset, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

/// Skip and Keep, and Keep is the heavier of the two.
///
/// Not because keeping is better — most captures are not worth keeping, which
/// is the point of a queue — but because Keep is the one that *does* something
/// and Skip is the one that leaves everything alone. A pair of identical
/// buttons makes the user read both every time.
class _Choices extends StatelessWidget {
  final VoidCallback onKeep;
  final VoidCallback onSkip;

  const _Choices({required this.onKeep, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(color: AppColors.border),
                ),
              ),
              child: Text(
                context.l10n.triageSkip,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            flex: 2,
            child: TextButton(
              onPressed: onKeep,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(vertical: 15.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Text(
                context.l10n.triageKeep,
                style: AppTextStyles.bodyLarge.asMedium.copyWith(
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
