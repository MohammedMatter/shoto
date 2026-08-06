import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/utils/content_traits.dart';
import 'package:shoto/core/widgets/premium_gate.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/widgets/header_icon_button.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_sort.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/screenshots/presentation/pages/search_page.dart';
import 'package:shoto/features/screenshots/presentation/widgets/import_screenshots_action.dart';
import 'package:shoto/features/screenshots/presentation/widgets/library_view_sheet.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshots_body.dart';

/// The full grid of every screenshot.
///
/// This is what Home used to be. Moving it to its own tab is what let Home
/// become a hub instead of a duplicate of the system gallery — the grid is
/// still one tap away for anyone who wants to browse, it just no longer
/// *is* the app.
class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sl<ThemeController>(),
      builder: (context, child) => Scaffold(
        backgroundColor: context.colors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 10.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.navLibrary,
                            style: context.text.headlineLarge,
                          ),
                          BlocBuilder<ScreenshotsBloc, ScreenshotsState>(
                            buildWhen: (a, b) => true,
                            builder: (context, state) {
                              if (state is! ScreenshotsLoadedState) {
                                return const SizedBox.shrink();
                              }
                              final int count = state.screenshots.length;
                              return Text(
                                context.l10n.countScreenshots(count),
                                style: context.text.bodyMedium,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    // Three controls, not four. Grid density moved into the
                    // view sheet below — see the note there.
                    Builder(
                      builder: (context) => HeaderIconButton(
                        icon: Icons.add_photo_alternate_outlined,
                        tooltip: context.l10n.importTitle,
                        onTap: () => importScreenshots(
                          context,
                          bloc: context.read<ScreenshotsBloc>(),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    // Everything about how the library is being *looked at*:
                    // the order, the content traits, and now the grid density
                    // as well. None of them changes what is in the library.
                    //
                    // It opens a sheet rather than toggling in place. This was
                    // a bare ↓/↑ that flipped on tap, and the first person to
                    // meet it asked what it filtered — which is the answer:
                    // an unlabelled arrow says neither what it changes nor
                    // what is currently on.
                    //
                    // It now carries the content traits as well as the order,
                    // which is what let the second row of chips come off the
                    // top of the grid. A dot appears whenever a trait is
                    // narrowing what is shown: the row it replaced said so by
                    // having a chip lit, and a control that hides an active
                    // filter without saying so is worse than the row was.
                    BlocBuilder<ScreenshotsBloc, ScreenshotsState>(
                      builder: (context, state) {
                        if (state is! ScreenshotsLoadedState) {
                          return const SizedBox.shrink();
                        }

                        final ScreenshotsBloc bloc = context
                            .read<ScreenshotsBloc>();

                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HeaderIconButton(
                              icon: Icons.tune_rounded,
                              tooltip: context.l10n.librarySortLabel,
                              isMarked: state.lens != null,
                              // The bloc is handed over rather than its
                              // values: the sheet outlives this build, and a
                              // scan started from inside it changes the very
                              // numbers it is drawing.
                              onTap: () => showLibraryViewSheet(
                                context,
                                bloc: bloc,
                                onSort: (LibrarySort sort) =>
                                    bloc.add(SetLibrarySortEvent(sort)),
                                onSelectLens: (ContentTrait? lens) =>
                                    bloc.add(SetLibraryLensEvent(lens)),
                                onScan: () async {
                                  // Recognition is the paid feature behind
                                  // every trait, so the gate belongs on the
                                  // thing that starts it rather than on the
                                  // counts it eventually fills in.
                                  if (!await ensurePremium(context)) return;
                                  bloc.add(ScanUnreadForTraitsEvent());
                                },
                              ),
                            ),
                            SizedBox(width: 8.w),
                          ],
                        );
                      },
                    ),
                    Builder(
                      builder: (context) => HeaderIconButton(
                        icon: Icons.search_rounded,
                        onTap: () => openSearchPage(
                          context,
                          bloc: context.read<ScreenshotsBloc>(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ScreenshotsBody(
                  emptyTitle: context.l10n.libraryEmptyTitle,
                  emptyMessage: context.l10n.libraryEmptyMessage,
                  // Only here. A folder holds one subject rather than one
                  // stretch of time, so dated headings there would slice a
                  // small, deliberately curated set into runs of one.
                  groupByDate: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
