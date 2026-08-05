import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/theme/grid_density_controller.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/widgets/header_icon_button.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_sort.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/screenshots/presentation/pages/search_page.dart';
import 'package:shoto/features/screenshots/presentation/widgets/import_screenshots_action.dart';
import 'package:shoto/features/screenshots/presentation/widgets/library_sort_sheet.dart';
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
        backgroundColor: AppColors.background,
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
                            style: AppTextStyles.headlineLarge,
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
                                style: AppTextStyles.bodyMedium,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    // Wrapped so the button actually hears the change it
                    // causes: it used to be a fixed grid_view icon that
                    // never rebuilt, so cycling the density rearranged the
                    // whole grid while the control that did it sat there
                    // looking untouched.
                    ListenableBuilder(
                      listenable: sl<GridDensityController>(),
                      builder: (context, _) {
                        final int columns = sl<GridDensityController>().columns;
                        return HeaderIconButton(
                          icon: GridDensityController.iconFor(columns),
                          tooltip: GridDensityController.labelFor(
                            context,
                            columns,
                          ),
                          onTap: () => sl<GridDensityController>().cycle(),
                        );
                      },
                    ),
                    SizedBox(width: 8.w),
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
                    // Next to grid density on purpose: both answer "how do I
                    // want to look at this", neither changes what is in the
                    // library.
                    //
                    // It opens a sheet rather than toggling in place. This was
                    // a bare ↓/↑ that flipped on tap, and the first person to
                    // meet it asked what it filtered — which is the answer:
                    // an unlabelled arrow says neither what it changes nor
                    // what is currently on. See showLibrarySortSheet.
                    BlocBuilder<ScreenshotsBloc, ScreenshotsState>(
                      builder: (context, state) {
                        if (state is! ScreenshotsLoadedState) {
                          return const SizedBox.shrink();
                        }
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HeaderIconButton(
                              // The conventional "reorder" glyph, and stable:
                              // the sheet is where the current order is
                              // stated, so the button only has to say what
                              // tapping it is about.
                              icon: Icons.swap_vert_rounded,
                              tooltip: context.l10n.librarySortLabel,
                              onTap: () => showLibrarySortSheet(
                                context,
                                current: state.sort,
                                onSelected: (LibrarySort sort) => context
                                    .read<ScreenshotsBloc>()
                                    .add(SetLibrarySortEvent(sort)),
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
