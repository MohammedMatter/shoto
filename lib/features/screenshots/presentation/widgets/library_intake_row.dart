import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_new_captures_use_case.dart';
import 'package:shoto/features/screenshots/presentation/pages/open_triage_page.dart';

/// What the phone has captured since the user last looked, offered at the top
/// of the Library.
///
/// **It lives here rather than on Home, and that is the second placement.**
/// On Home it was the first thing on the first screen of every launch, above
/// the one number that screen exists for — an interruption at the moment
/// somebody is only checking in. The Library is the screen opened to deal
/// with screenshots, which is when an inbox is welcome rather than in the way.
///
/// Settings was considered and rejected for the opposite reason: a feature
/// reachable only from a preferences list is a feature nobody opens, and the
/// empty room it exists to solve comes straight back.
class LibraryIntakeRow extends StatefulWidget {
  const LibraryIntakeRow({super.key});

  /// Below this it says nothing at all.
  ///
  /// One new screenshot is not an inbox, it is an interruption with a count on
  /// it — the row asks for a decision every time it appears, so it has to be
  /// worth one.
  ///
  /// **Three, not five.** Five was tried first and was wrong for a reason
  /// worth keeping: with the dismiss doing the work of stopping the nagging,
  /// the threshold's only remaining job is to filter out a stray capture or
  /// two. Set high enough to also hide a genuine morning's worth, the feature
  /// simply never appeared — which is indistinguishable from broken, and is
  /// how it was found.
  static const int minimum = 3;

  @override
  State<LibraryIntakeRow> createState() => _LibraryIntakeRowState();
}

class _LibraryIntakeRowState extends State<LibraryIntakeRow>
    with WidgetsBindingObserver {
  int _waiting = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PhotoManager.addChangeCallback(_onGalleryChanged);
    PhotoManager.startChangeNotify();
    _count();
  }

  @override
  void dispose() {
    PhotoManager.removeChangeCallback(_onGalleryChanged);
    PhotoManager.stopChangeNotify();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// **Because taking a screenshot does not background the app.**
  ///
  /// The lifecycle hook below covers the ordinary route — capture something
  /// in another app, come back to SHOTO — and it is not enough on its own.
  /// Android leaves the foreground app resumed while a screenshot is taken,
  /// so anyone capturing *this* app, or capturing from a floating window or
  /// split screen, gets no `resumed` at all and the count never moves. The
  /// row then says nothing with five screenshots waiting, which is
  /// indistinguishable from a feature that does not work — it was found
  /// exactly that way, three times over.
  ///
  /// This was left out at first on the grounds that a gallery listener costs
  /// something all session. It does, and the estimate was too pessimistic:
  /// the callback fires when the gallery changes rather than continuously,
  /// and [_count] repaints one row only when the number it holds is actually
  /// different.
  void _onGalleryChanged(MethodCall _) => _count();

  /// **Counted again every time the app comes back to the foreground**, and
  /// this is the whole flow rather than a refinement.
  ///
  /// Taking a screenshot means leaving SHOTO, capturing something in another
  /// app, and coming back. The Library is kept alive inside the shell's stack
  /// for the whole session, so a count read once at mount is read *before the
  /// screenshots exist* — open the Library, go and capture five things,
  /// return, and the row would still say nothing until the app was killed and
  /// relaunched. Which looks exactly like a feature that does not work.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _count();
  }

  /// The one place the number is read — on mount, on resume, and on a gallery
  /// change.
  ///
  /// Returns without touching state when the answer has not moved, which is
  /// what keeps the gallery listener cheap: most changes are not screenshots,
  /// and a change that leaves the count alone costs one query and no frame.
  Future<void> _count() async {
    final List<AssetEntity> captures = await sl<GetNewCapturesUseCase>()();
    if (!mounted || captures.length == _waiting) return;
    setState(() => _waiting = captures.length);
  }

  Future<void> _review() async {
    await openTriagePage(context);
    // Back to nought, not to the new count: the queue has been answered, so
    // the next time it fills up it should be allowed to say so.
    await sl<AppPreferences>().snoozeTriage(0);
    if (!mounted) return;
    await _count();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sl<AppPreferences>(),
      builder: (BuildContext context, Widget? _) {
        final AppPreferences prefs = sl<AppPreferences>();

        if (_waiting < LibraryIntakeRow.minimum) {
          return const SizedBox.shrink();
        }
        // Strictly greater: dismissing at eleven and finding eleven again is
        // the same eleven.
        if (_waiting <= prefs.triageSnoozedAt) return const SizedBox.shrink();

        return Padding(
          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 8.h),
          child: PressableScale(
            scale: 0.99,
            onTap: _review,
            child: Container(
              padding: EdgeInsetsDirectional.fromSTEB(14.w, 11.h, 6.w, 11.h),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: context.colors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.inbox_rounded,
                    size: 19.sp,
                    color: context.colors.textSecondary,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      context.l10n.triageNewCount(_waiting),
                      style: context.text.bodyMedium.asMedium,
                    ),
                  ),
                  Text(
                    context.l10n.triageReview,
                    style: context.text.bodyMedium.copyWith(
                      color: context.colors.primary,
                    ),
                  ),
                  // The way to put it down, which the Home version never had.
                  // Without this the only route to a quiet screen was to
                  // answer every capture in the queue.
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18.sp,
                      color: context.colors.textSecondary,
                    ),
                    tooltip: context.l10n.triageInviteDecline,
                    onPressed: () => prefs.snoozeTriage(_waiting),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
