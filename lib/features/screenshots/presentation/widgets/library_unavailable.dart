import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/widgets/empty_state.dart';
import 'package:shoto/core/widgets/primary_button.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';

/// The three ways the library can fail to be a library, drawn once.
///
/// Every screen that reads [ScreenshotsState] has the same four cases and only
/// one of them is its own: *loaded* is the screen's job, and the other three
/// are the same everywhere — still reading, not allowed to read, tried and
/// failed. Each screen was answering them separately, and each answered
/// differently:
///
/// * [ScreenshotsBody] wrote all three out properly.
/// * `HomePage` folded them into "loading" and drew a spinner forever behind
///   a refused permission, until that was fixed.
/// * `IntentPage` folded them into *empty*, which is worse than blank — an
///   empty waiting list there renders a green tick and "you're all done", so
///   a screen that could not read the gallery **congratulated the user** for
///   clearing a list it had never seen.
///
/// Three copies produce three behaviours, and the wrong one is not visibly
/// wrong. This is the fourth copy and the last: it exists so a new screen
/// gets the answer by asking rather than by remembering.
///
/// ## Using it
///
/// [maybeOf] returns null exactly when there is a library to draw, so the
/// caller reads as a sentence:
///
/// ```dart
/// final Widget? blocked = LibraryUnavailable.maybeOf(state);
/// if (blocked != null) return blocked;
/// ```
///
/// The `null` is deliberate rather than a widget the caller stacks behind its
/// own content: these states have no content to sit behind, and returning
/// something drawable for a loaded library would invite exactly the layering
/// that hid the problem in the first place.
class LibraryUnavailable extends StatelessWidget {
  final ScreenshotsState state;

  const LibraryUnavailable({super.key, required this.state});

  /// The view for [state], or null when the library loaded and the caller
  /// should draw its own content.
  static Widget? maybeOf(ScreenshotsState state) =>
      state is ScreenshotsLoadedState
      ? null
      : LibraryUnavailable(state: state);

  @override
  Widget build(BuildContext context) {
    // Exhaustive on purpose — no `default`. [ScreenshotsState] is sealed, so
    // a sixth state added to the bloc stops this file compiling until it is
    // given something to draw. That failure is the whole point: the states
    // this screen family gets wrong are the ones nobody remembered existed.
    return switch (state) {
      ScreenshotsInitialState() || ScreenshotsLoadingState() => Center(
        child: CircularProgressIndicator(color: context.colors.primary),
      ),

      // **Never asked is not refused, and the two need opposite buttons.**
      //
      // This screen is now the first thing a new install shows, so it says
      // what is being asked for before Android's dialog says "photos and
      // videos" with no context at all: one album, only to list it, nothing
      // uploaded, nothing added without a tap. The button raises the dialog —
      // it is the only thing in the app that does — which is why it reads
      // "Allow access" rather than "Continue".
      //
      // Sending this user to system settings, as the refusal case does and as
      // both cases used to, would open the app on an instruction to go and
      // repair it.
      ScreenshotsPermissionUnaskedState() => EmptyState(
        icon: Icons.photo_library_outlined,
        title: context.l10n.permissionAskTitle,
        message: context.l10n.permissionAskMessage,
        action: PrimaryButton(
          label: context.l10n.permissionAllow,
          onPressed: () =>
              context.read<ScreenshotsBloc>().add(RequestPhotoAccessEvent()),
        ),
      ),

      // Partial access is refusal, not permission. "Select photos…" exposes
      // only the handful the user hand-picked, so the Screenshots album this
      // app is built around is not visible at all — and a library that comes
      // back empty for that reason must say so rather than look tidy.
      //
      // Settings, not the dialog: this user has answered, and Android will
      // not put the question a second time.
      ScreenshotsPermissionDeniedState(:final bool isPartialAccess) =>
        EmptyState(
          icon: Icons.photo_library_outlined,
          title: isPartialAccess
              ? context.l10n.permissionPartialTitle
              : context.l10n.permissionNeededTitle,
          message: isPartialAccess
              ? context.l10n.permissionPartialMessage
              : context.l10n.permissionNeededMessage,
          action: PrimaryButton(
            label: context.l10n.permissionOpenSettings,
            onPressed: PhotoManager.openSetting,
          ),
        ),

      // Retry rather than an apology. The read failing is usually transient,
      // and a dead end on a screen the user opened on purpose is what sends
      // them to the app switcher.
      ScreenshotsErrorState(:final message) => EmptyState(
        icon: Icons.error_outline_rounded,
        title: context.l10n.commonSomethingWentWrong,
        message: message.resolve(context),
        action: PrimaryButton(
          label: context.l10n.commonRetry,
          onPressed: () =>
              context.read<ScreenshotsBloc>().add(LoadScreenshotsEvent()),
        ),
      ),

      // Unreachable through [maybeOf], which is the only way in. Spelled out
      // rather than left to a `default` so the switch stays exhaustive and
      // keeps its compile-time guarantee.
      ScreenshotsLoadedState() => const SizedBox.shrink(),
    };
  }
}
