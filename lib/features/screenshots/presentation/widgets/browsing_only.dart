import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';

/// Header chrome that stands down while a selection is on.
///
/// **The header stays; only its buttons leave.** Both pages that show a grid
/// of screenshots used to have their whole header torn out the moment a
/// selection began, and a `SliverAppBar` is also what holds the first row of
/// thumbnails clear of the status bar — so long-pressing a tile slid the grid
/// up under the clock and made the page look like it had collapsed. A mode
/// should add its own controls, not demolish the screen it is a mode *of*.
///
/// What is genuinely wrong mid-selection is the *browsing* controls, and for
/// a reason stronger than tidiness: the library's view options can switch the
/// lens, which hides tiles that are still picked, and a folder's options can
/// delete the folder being triaged. So they go, and the title they sat beside
/// does not move a pixel.
///
/// Wrapped rather than removed. A button that vanishes takes its width with
/// it and drags the title across the bar; this fades in place, and the layout
/// underneath never learns anything happened.
///
/// Must be built somewhere under the [ScreenshotsBloc] that owns the grid —
/// which, for a header passed as `ScreenshotsBody.leadingSlivers`, it is.
class BrowsingOnly extends StatelessWidget {
  final Widget child;

  const BrowsingOnly({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScreenshotsBloc, ScreenshotsState>(
      // The only thing this asks of the state. Without it every tap on a
      // thumbnail — every change to the selected set — would rebuild the page
      // header along with the grid.
      buildWhen: (ScreenshotsState previous, ScreenshotsState current) =>
          _selecting(previous) != _selecting(current),
      builder: (BuildContext context, ScreenshotsState state) {
        final bool selecting = _selecting(state);
        return AnimatedOpacity(
          opacity: selecting ? 0 : 1,
          duration: AppMotion.duration(context, AppMotion.instant),
          curve: AppMotion.standard,
          // Not merely invisible: a control at zero opacity still answers a
          // tap, and a search page opening from a bar you cannot see is the
          // worst version of this.
          child: IgnorePointer(ignoring: selecting, child: child),
        );
      },
    );
  }

  static bool _selecting(ScreenshotsState state) =>
      state is ScreenshotsLoadedState && state.isSelectionMode;
}
