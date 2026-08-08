import 'package:shoto/features/screenshots/presentation/bloc/library_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/widgets/app_bottom_nav_bar.dart';
import 'package:shoto/core/widgets/lazy_indexed_stack.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_bloc.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_event.dart';
import 'package:shoto/features/folders/presentation/pages/folders_page.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _onTabSelected(int index) {
    if (index == 2) _foldersBloc.add(LoadFoldersEvent());
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

  /// Home's folder count, which is now a way in rather than a fact.
  void _openFolders() => _onTabSelected(2);

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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
          body: LazyIndexedStack(
            index: _currentIndex,
            children: [
              HomePage(
                onOpenLibrary: _openLibrary,
                onOpenLibraryForIntent: _openLibraryForIntent,
                onOpenFolders: _openFolders,
              ),
              const LibraryPage(),
              const FoldersPage(),
              const SettingsPage(),
            ],
          ),
          bottomNavigationBar: ListenableBuilder(
            listenable: sl<ThemeController>(),
            builder: (context, child) => AppBottomNavBar(
              currentIndex: _currentIndex,
              items: _items(context),
              onTap: _onTabSelected,
            ),
          ),
        ),
      ),
    );
  }
}
