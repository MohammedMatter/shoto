import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/app_message.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/fade_slide_page_route.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/features/home/presentation/widgets/home_blocked_headline.dart';
import 'package:shoto/features/home/presentation/widgets/home_entrance.dart';
import 'package:shoto/features/home/presentation/widgets/home_greeting.dart';
import 'package:shoto/features/home/presentation/widgets/home_recent_strip.dart';
import 'package:shoto/features/home/presentation/widgets/home_search_field.dart';
import 'package:shoto/features/home/presentation/widgets/home_section_title.dart';
import 'package:shoto/features/home/presentation/widgets/home_stat_line.dart';
import 'package:shoto/features/home/presentation/widgets/home_tool_list.dart';
import 'package:shoto/features/home/presentation/widgets/unsorted_headline.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_filter.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_intent.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/screenshots/presentation/pages/intent_page.dart';
import 'package:shoto/features/screenshots/presentation/widgets/import_screenshots_action.dart';
import 'package:shoto/features/screenshots/presentation/widgets/waiting_on_you.dart';

class HomePage extends StatefulWidget {
  final ValueChanged<LibraryFilter> onOpenLibrary;
  final ValueChanged<LibraryIntent> onOpenLibraryForIntent;
  final VoidCallback onOpenFolders;

  const HomePage({
    super.key,
    required this.onOpenLibrary,
    required this.onOpenLibraryForIntent,
    required this.onOpenFolders,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: HomeEnter.total,
  )..forward();

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  /// The one block Home leads with, whatever the library turned out to be.
  ///
  /// Every state gets a sentence here — that is the point of the switch. Home
  /// is the first screen and the tab the app opens on, so a state it cannot
  /// draw is a blank first impression with no way out of it: a refused photo
  /// permission and a failed read both used to land in [UnsortedHeadline]'s
  /// loading branch and disappear, taking the count, the sentence and the
  /// import button with them. Only the genuinely transient states — initial
  /// and loading — still draw nothing, and they are the only ones that fix
  /// themselves.
  Widget _headline(
    BuildContext context,
    ScreenshotsState state,
    List<ScreenshotEntity> all,
  ) => switch (state) {
    ScreenshotsPermissionDeniedState(:final bool isPartialAccess) =>
      HomeBlockedHeadline.permission(partial: isPartialAccess),
    ScreenshotsErrorState(:final AppMessage message) =>
      HomeBlockedHeadline.failure(
        message,
        onRetry: () =>
            context.read<ScreenshotsBloc>().add(LoadScreenshotsEvent()),
      ),
    _ => UnsortedHeadline(
      unsortedCount: all.where((s) => s.isUnsorted).length,
      hasLibrary: all.isNotEmpty,
      isLoading: state is! ScreenshotsLoadedState,
      onTap: widget.onOpenLibrary,
      onImport: () =>
          importScreenshots(context, bloc: context.read<ScreenshotsBloc>()),
    ),
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sl<ThemeController>(),
      builder: (context, child) => Scaffold(
        backgroundColor: context.colors.background,
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<ScreenshotsBloc, ScreenshotsState>(
            builder: (context, state) {
              final ScreenshotsLoadedState? loaded =
                  state is ScreenshotsLoadedState ? state : null;
              final List<ScreenshotEntity> all =
                  loaded?.screenshots ?? const [];

              return ListView(
                padding: EdgeInsets.only(top: 10.h, bottom: 130.h),
                children: [
                  HomeEnter(
                    parent: _entrance,
                    index: 0,
                    child: const HomeGutter(child: HomeGreeting()),
                  ),
                  SizedBox(height: 18.h),
                  if (all.isNotEmpty) ...[
                    HomeEnter(
                      parent: _entrance,
                      index: 1,
                      child: const HomeGutter(child: HomeSearchField()),
                    ),
                    SizedBox(height: 26.h),
                  ],
                  HomeEnter(
                    parent: _entrance,
                    index: 2,
                    child: HomeGutter(child: _headline(context, state, all)),
                  ),
                  SizedBox(height: 16.h),
                  if (loaded != null && loaded.waitingByIntent.isNotEmpty) ...[
                    HomeEnter(
                      parent: _entrance,
                      index: 3,
                      child: HomeGutter(
                        child: WaitingOnYou(
                          waiting: loaded.waitingByIntent,
                          onOpen: (IntentRef intent) =>
                              Navigator.of(context).push(
                                FadeSlidePageRoute(
                                  builder: (_) =>
                                      BlocProvider<ScreenshotsBloc>.value(
                                        value: context.read<ScreenshotsBloc>(),
                                        child: IntentPage(intent: intent),
                                      ),
                                ),
                              ),
                        ),
                      ),
                    ),
                    SizedBox(height: 22.h),
                  ],
                  if (all.isNotEmpty)
                    HomeEnter(
                      parent: _entrance,
                      index: 3,
                      child: HomeGutter(
                        child: HomeStatLine(
                          total: all.length,
                          favorites: all.where((s) => s.isFavorite).length,
                          onOpenLibrary: widget.onOpenLibrary,
                          onOpenFolders: widget.onOpenFolders,
                        ),
                      ),
                    ),
                  if (all.isNotEmpty) ...[
                    SizedBox(height: 34.h),
                    HomeEnter(
                      parent: _entrance,
                      index: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          HomeGutter(
                            child: HomeSectionTitle(
                              context.l10n.homeRecent,
                              onSeeAll: () =>
                                  widget.onOpenLibrary(LibraryFilter.all),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          HomeRecentStrip(screenshots: all.take(12).toList()),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 34.h),
                  HomeEnter(
                    parent: _entrance,
                    index: 5,
                    child: HomeGutter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          HomeSectionTitle(
                            all.isEmpty
                                ? context.l10n.homeToolsTitleEmpty
                                : context.l10n.homeToolsTitle,
                          ),
                          SizedBox(height: 4.h),
                          HomeToolList(
                            hasLibrary: all.isNotEmpty,
                            onOpenLibraryForIntent:
                                widget.onOpenLibraryForIntent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
