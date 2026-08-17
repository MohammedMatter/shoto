import 'dart:async';

import 'package:shoto/features/screenshots/presentation/bloc/library_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/services/capture_alerts.dart';
import 'package:shoto/core/services/library_quota.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/widgets/app_bottom_nav_bar.dart';
import 'package:shoto/core/widgets/lazy_indexed_stack.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_bloc.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_event.dart';
import 'package:shoto/features/folders/presentation/pages/folders_page.dart';
import 'package:shoto/features/folders/presentation/widgets/default_folders.dart';
import 'package:shoto/features/home/presentation/pages/home_page.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_filter.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';
import 'package:shoto/features/screenshots/presentation/pages/library_page.dart';
import 'package:shoto/features/screenshots/presentation/widgets/share_intent_listener.dart';
import 'package:shoto/features/settings/presentation/pages/settings_page.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage>
    with WidgetsBindingObserver {
  /// Always Home. The dashboard is where the app tells you what needs doing;
  /// starting anywhere else buries that behind a tap and makes Shoto look
  /// like a gallery again.
  int _currentIndex = 0;

  // FoldersBloc lives here (above the IndexedStack) instead of inside
  // FoldersPage, because IndexedStack keeps every tab's widget alive once
  // built — FoldersPage would never rebuild (and its counts would never
  // refresh) just from switching tabs. Owning it here lets us force a
  // reload every time the Folders tab is selected.
  late final FoldersBloc _foldersBloc = sl<FoldersBloc>()
    ..add(LoadFoldersEvent());

  /// One screenshots bloc for the whole shell. Home reads counts from it and
  /// Library renders the grid from it, so a single load feeds both and the
  /// two can never disagree about what the library holds. It also means
  /// switching tabs costs nothing — previously each tab loaded its own copy.
  late final ScreenshotsBloc _screenshotsBloc = sl<ScreenshotsBloc>()
    ..add(LoadScreenshotsEvent());

  /// Built per call rather than held as a `static const` list: the labels are
  /// translated, so they change when the language does and cannot be baked in
  /// at compile time.
  static List<AppNavItem> _items(BuildContext context) => [
    AppNavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: context.l10n.navHome,
    ),
    AppNavItem(
      icon: Icons.photo_library_outlined,
      activeIcon: Icons.photo_library_rounded,
      label: context.l10n.navLibrary,
    ),
    AppNavItem(
      icon: Icons.folder_outlined,
      activeIcon: Icons.folder_rounded,
      label: context.l10n.navFolders,
    ),
    AppNavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: context.l10n.navSettings,
    ),
  ];

  /// Whether the starter folders have already been offered this launch.
  ///
  /// `didChangeDependencies` runs again whenever an inherited widget above
  /// this one changes — the theme, the locale, the media query — and without
  /// this the seed event would be posted on every one of them.
  bool _defaultFoldersOffered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // **Re-armed on every launch, because Android drops it silently.** The
    // watcher behind "offer new screenshots" is a content-trigger job, and
    // those cannot be persisted across a reboot (Android forbids combining
    // the two) and are cancelled outright by a force-stop or a battery
    // optimiser. None of that reaches the app as an event — the only moment
    // Shoto can notice is the next time it runs. Cheap: rescheduling an
    // already-scheduled job replaces it, and it does nothing at all unless
    // the user asked for the feature.
    unawaited(CaptureAlerts.rearm(wanted: sl<AppPreferences>().captureAlerts));
  }

  /// Offers the starter folders here rather than on the Folders page itself.
  ///
  /// The page is built lazily, on the first tap of its tab (see
  /// [LazyIndexedStack]) — so seeding there would mean a brand-new install has
  /// no folders at all until somebody visits the third tab. Everything that
  /// files a screenshot asks for the folder list first: the share sheet's
  /// picker, quick save, "move to folder". Each of those would open on
  /// "no folders yet, make one in the Folders tab" for a user who has seven
  /// waiting behind a tab they have not tapped.
  ///
  /// Not in `initState`, because the names are translated and `context.l10n`
  /// needs the localizations delegate resolved above it — which is exactly what
  /// this callback is for. Writing nothing is the normal case: after the first
  /// launch the repository answers from a flag without touching the folders
  /// table. See `SeedDefaultFoldersUseCase`.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_defaultFoldersOffered) return;
    _defaultFoldersOffered = true;
    _foldersBloc.add(SeedDefaultFoldersEvent(defaultFolderSeeds(context)));
  }

  void _onTabSelected(int index) {
    if (index == 2) _foldersBloc.add(LoadFoldersEvent());
    // **Library as well as Settings**, for the same reason Folders re-counts
    // above: the tabs are kept alive by the IndexedStack, so whatever one
    // painted the first time is what it goes on painting. A quota meter that
    // still reads 41 after an afternoon of filing is worse than no meter — it
    // is a number the user has no reason to distrust.
    //
    // Settings was the only one here for a while, and that was simply out of
    // date: the meter moved to the top of the Library and nobody extended this
    // line to the tab it had moved to. The visible symptom was a band reading
    // 0 of 100 on a library with things filed in it, which reads as the app
    // not having noticed any of the work you just did.
    if (index == 1 || index == 3) unawaited(sl<LibraryQuota>().refresh());
    setState(() => _currentIndex = index);
  }

  /// Home asking for the Library, showing a particular slice of it.
  ///
  /// The filter is set on the bloc *before* the tab changes, so the grid is
  /// already the right one on the first frame it is visible — setting it
  /// after would show the full library for a frame and then swap, which is
  /// the flicker this shell keeps a single shared bloc to avoid.
  void _openLibrary(LibraryFilter filter) {
    _screenshotsBloc.add(SetLibraryFilterEvent(filter));
    _onTabSelected(1);
  }

  /// Home starting a job that needs screenshots picked for it.
  ///
  /// Same ordering rule as the filter above, and for the same reason: the
  /// Library must already be in selection mode on the first frame it is
  /// visible, or the user watches it change its mind.
  void _openLibraryForIntent(LibraryIntent intent) {
    _screenshotsBloc.add(StartGuidedSelectionEvent(intent));
    _onTabSelected(1);
  }

  /// Re-reads the library whenever the app comes back to the foreground.
  ///
  /// Filing a screenshot from the share sheet happens in a **separate
  /// Android activity running its own Flutter engine** — a different process
  /// as far as Dart is concerned. It writes to the same database, but the
  /// blocs living in *this* engine never hear about it, so coming back to
  /// Shoto showed the library exactly as it was before: the screenshot
  /// missing and its folder's count unchanged, until the app was killed and
  /// reopened. That was the "I have to hot reload" symptom.
  ///
  /// Cheap enough to do unconditionally: the library is curated rather than
  /// the whole gallery, [RefreshScreenshotsEvent] replaces the loaded state
  /// without passing through a loading state (so no spinner flashes), and
  /// thumbnails come back from the image cache rather than being re-decoded.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _screenshotsBloc.add(RefreshScreenshotsEvent());
    _foldersBloc.add(LoadFoldersEvent());
    // The share sheet files screenshots from a separate engine in another
    // process, so coming back to the foreground is precisely when the managed
    // count has moved without this process seeing it happen.
    unawaited(sl<LibraryQuota>().refresh());
  }

  /// True while any scrollable on the visible page is moving, including the
  /// fling after the finger has left the glass. Read by [AppBottomNavBar],
  /// which stops blurring for exactly as long as it is true.
  final ValueNotifier<bool> _scrolling = ValueNotifier<bool>(false);

  /// How many scrollables are in motion, rather than a bare flag.
  ///
  /// A page can have more than one — a vertical list with a horizontal row of
  /// chips inside it — and their starts and ends interleave. A flag set by the
  /// first end notification to arrive would clear while the other was still
  /// running, which is the bug where the bar starts blurring again halfway
  /// through a fling.
  int _active = 0;

  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _active++;
    } else if (notification is ScrollEndNotification) {
      // Floored: notifications can arrive from a scrollable that started
      // before this listener was in the tree, and a negative count would take
      // a real scroll to bring back to zero.
      _active = _active > 0 ? _active - 1 : 0;
    } else {
      return false;
    }

    _scrolling.value = _active > 0;
    // Never absorbed — anything else listening further up is entitled to see
    // these, and this listener only observes.
    return false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrolling.dispose();
    _foldersBloc.close();
    _screenshotsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _foldersBloc),
        BlocProvider.value(value: _screenshotsBloc),
      ],
      child: ShareIntentListener(
        child: Scaffold(
          extendBody: true,
          // Lazy, but still a stack: a tab keeps its state once opened (which
          // the Folders counts and the Library's scroll position both depend
          // on) without all four being built before the app has drawn its
          // first frame. See LazyIndexedStack.
          body: NotificationListener<ScrollNotification>(
            // **Whether anything under here is moving**, for the bar below.
            //
            // A `BackdropFilter` re-filters whatever is behind it on every
            // frame in which those pixels change, so the bar is free while a
            // page sits still and is the most expensive object on screen the
            // moment one scrolls. Measured on the test phone in a profile
            // build, a few seconds of scrolling Settings produced **125 frames
            // over budget, the worst at 62ms of raster**, against 1 with the
            // bar's blur switched off — with Dart build time at 0.4ms
            // throughout, so all of it was paint. The phone runs Impeller on
            // OpenGLES (its Vulkan context fails and the engine falls back),
            // where a backdrop filter costs a full copy of the region behind
            // it.
            //
            // Listened for here rather than in the bar because the bar is not
            // an ancestor of anything that scrolls — the four pages are, and
            // notifications only travel up.
            onNotification: _onScroll,
            child: LazyIndexedStack(
              index: _currentIndex,
              children: [
                HomePage(
                  onOpenLibrary: _openLibrary,
                  onOpenLibraryForIntent: _openLibraryForIntent,
                ),
                const LibraryPage(),
                const FoldersPage(),
                const SettingsPage(),
              ],
            ),
          ),
          bottomNavigationBar: ListenableBuilder(
            listenable: sl<ThemeController>(),
            builder: (context, child) => AppBottomNavBar(
              currentIndex: _currentIndex,
              items: _items(context),
              onTap: _onTabSelected,
              scrolling: _scrolling,
            ),
          ),
        ),
      ),
    );
  }
}
