import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/funnel_log.dart';
import 'package:shoto/core/localization/app_message.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/fade_slide_page_route.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/widgets/animated_id_grid.dart';
import 'package:shoto/core/widgets/empty_state.dart';
import 'package:shoto/core/widgets/header_icon_button.dart';
import 'package:shoto/core/widgets/primary_button.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/presentation/bloc/folder_sort.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_bloc.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_event.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_state.dart';
import 'package:shoto/features/folders/presentation/pages/folder_detail_page.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_actions_sheet.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_card.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_editor_sheet.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_search_field.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_sort_sheet.dart';

class FoldersPage extends StatefulWidget {
  const FoldersPage({super.key});

  @override
  State<FoldersPage> createState() => _FoldersPageState();
}

class _FoldersPageState extends State<FoldersPage> {
  /// When this page was first built, which is what stops the grid's entrance
  /// from replaying.
  ///
  /// The shell fires `LoadFoldersEvent` **every time the Folders tab is
  /// selected**, so the bloc goes back through a loading state on every visit
  /// — and stamping this from the loaded state would therefore re-run the
  /// cascade each time somebody tabbed over, which is the exact "replays every
  /// time it comes back into view" failure the animation rules in this app
  /// were written against.
  ///
  /// Stamped once, in `initState`, and never again: [EntranceStagger] only
  /// animates inside its own 400ms window, so the first visit gets the
  /// cascade and every visit afterwards paints instantly. The page is built
  /// lazily on that first tap (see LazyIndexedStack) with the load already in
  /// flight, and the load is a local SQLite read.
  final DateTime _since = DateTime.now();

  /// What the user is looking for, narrowing the grid as they type.
  ///
  /// **Page state, where the sort is bloc state**, and the difference is not an
  /// oversight. A sort is a preference — it should still be in force after a
  /// trip to Library and back, which is why the bloc holds it across the
  /// reload the shell fires on every tab select. A half-typed search is not a
  /// preference; coming back to the Folders tab to find it still filtered by
  /// "rec" from ten minutes ago would read as the app having lost your
  /// folders.
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sl<ThemeController>(),
      builder: (context, child) => Scaffold(
        backgroundColor: context.colors.background,
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.l10n.navFolders,
                      style: context.text.headlineLarge,
                    ),
                    // The app's one header-action button — see
                    // [HeaderIconButton] for why this stopped being a filled
                    // accent slab.
                    HeaderIconButton(
                      icon: Icons.add_rounded,
                      tooltip: context.l10n.foldersCreate,
                      onTap: () => _createFolder(context),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                Expanded(
                  child: BlocBuilder<FoldersBloc, FoldersState>(
                    builder: (context, state) {
                      // Exhaustive, no `default` — see
                      // `docs/decisions/screen-states.md`.
                      return switch (state) {
                        // **Nothing at all while the folders are being read.**
                        //
                        // This was a centred spinner. Reading the folder table
                        // is a local SQLite query measured in milliseconds, so
                        // what it actually produced was a spinner appearing and
                        // vanishing — a flash, on a screen that is re-entered
                        // dozens of times a session because the shell reloads
                        // on every tab select. Home settled the same question
                        // the same way: silence is the only state here that is
                        // never wrong, and there is nothing to fill.
                        //
                        // Silence chosen, not fallen into: this is the one
                        // branch in the app allowed to draw nothing, and it is
                        // written out so that the next state added here cannot
                        // inherit the exemption by accident.
                        FoldersLoadingState() ||
                        FoldersInitialState() => const SizedBox.shrink(),

                        FoldersErrorState(:final AppMessage message) =>
                          EmptyState(
                            icon: Icons.error_outline_rounded,
                            title: context.l10n.commonSomethingWentWrong,
                            message: message.resolve(context),
                          ),

                        // **The controls go with the grid, not above it.**
                        //
                        // A search field over an empty screen is furniture for
                        // a job there is nothing to do — and the folder that
                        // has to be *made* before anything can be found should
                        // not have to share the screen with a way to look for
                        // it.
                        FoldersLoadedState(folders: final List<FolderEntity> f)
                            when f.isEmpty =>
                          EmptyState(
                            icon: Icons.folder_off_rounded,
                            title: context.l10n.foldersEmptyTitle,
                            message: context.l10n.foldersEmptyMessage,
                            action: PrimaryButton(
                              label: context.l10n.foldersNew,
                              onPressed: () => _createFolder(context),
                            ),
                          ),

                        FoldersLoadedState(
                          folders: final List<FolderEntity> f,
                          sort: final FolderSort sort,
                        ) =>
                          _FoldersBody(
                            folders: f,
                            sort: sort,
                            query: _query,
                            since: _since,
                            onQueryChanged: (String value) =>
                                setState(() => _query = value),
                          ),
                      };
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// No cap, and no paywall.
  ///
  /// Making a fourth folder used to open the paywall. A folder is not a
  /// feature somebody enjoys — it is the work of tidying up, which is the
  /// thing Shoto asked them to do in the first place. Charging for it
  /// interrupted the one behaviour the app most needs to encourage, and it
  /// was the second of three different free-tier currencies to keep track
  /// of. The volume cap on screenshots is the whole free tier now.
  Future<void> _createFolder(BuildContext context) async {
    final FoldersBloc bloc = context.read<FoldersBloc>();

    showFolderEditorSheet(
      context,
      onSave: (name, color, iconKey, isPrivate) {
        // Counted at the two presentation call sites — here and the share
        // sheet's inline "new folder" — rather than inside the bloc or the
        // use case. Both of those are handed their collaborators through the
        // constructor and reach for nothing else; a service-locator lookup in
        // either would be the first exception to that in the codebase, for a
        // counter.
        sl<FunnelLog>().record(FunnelStep.folderCreated);
        bloc.add(
          CreateFolderEvent(
            name,
            color,
            isPrivate: isPrivate,
            iconKey: iconKey,
          ),
        );
      },
    );
  }
}

/// The search row and the grid, which only exist once there are folders.
class _FoldersBody extends StatelessWidget {
  final List<FolderEntity> folders;
  final FolderSort sort;
  final String query;
  final DateTime since;
  final ValueChanged<String> onQueryChanged;

  const _FoldersBody({
    required this.folders,
    required this.sort,
    required this.query,
    required this.since,
    required this.onQueryChanged,
  });

  /// Case- and diacritic-insensitive enough for a folder list.
  ///
  /// `toLowerCase` on both sides rather than a `RegExp`: the query is typed a
  /// character at a time, so this runs on every keystroke over every folder,
  /// and building a pattern per keystroke to do a substring test is work for
  /// nothing.
  List<FolderEntity> get _matches {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) return folders;
    return folders
        .where((FolderEntity f) => f.name.toLowerCase().contains(needle))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<FolderEntity> matches = _matches;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: FolderSearchField(value: query, onChanged: onQueryChanged),
            ),
            SizedBox(width: 10.w),
            HeaderIconButton(
              icon: Icons.swap_vert_rounded,
              tooltip: context.l10n.foldersSortLabel,
              // The dot says the grid is in an order somebody chose, which is
              // the same job it does on Library's view button: a control that
              // hides a setting and looks identical either way is worse than
              // no control.
              isMarked: sort != FolderSort.recent,
              onTap: () => showFolderSortSheet(
                context,
                current: sort,
                onSelected: (FolderSort next) =>
                    context.read<FoldersBloc>().add(SetFolderSortEvent(next)),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Expanded(
          child: matches.isEmpty
              ? EmptyState(
                  icon: Icons.search_off_rounded,
                  title: context.l10n.foldersNoMatchTitle,
                  message: context.l10n.foldersNoMatchMessage(query.trim()),
                )
              : _FoldersGrid(folders: matches, since: since),
        ),
      ],
    );
  }
}

/// The grid.
///
/// **Diffed rather than rebuilt.** This was a `GridView.builder`, which has no
/// opinion about what changed: hand it one more folder and the new tile is
/// simply there on the next frame, with every tile after it one slot along.
/// Creating a folder is the one thing this screen exists for, and it was the
/// only action in the app whose result appeared without being animated at all
/// — the same complaint that put [AnimatedIdGrid] on the library page, arriving
/// here for the same reason.
///
/// **No longer reads the library.** It used to derive a cover thumbnail per
/// folder from the screenshots the shell holds in memory, which meant every
/// folder on this page was a picture of the last thing filed into it. See
/// [FolderCard] for why that came out — and note what came out with it: this
/// widget no longer subscribes to `ScreenshotsBloc` at all, so nothing the
/// Library does can rebuild the folder grid.
class _FoldersGrid extends StatelessWidget {
  final List<FolderEntity> folders;
  final DateTime since;

  const _FoldersGrid({required this.folders, required this.since});

  @override
  Widget build(BuildContext context) {
    return AnimatedIdGrid<FolderEntity>(
      items: folders,
      idOf: (FolderEntity folder) => folder.id,
      padding: EdgeInsets.only(bottom: 130.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        // **Three, where the cover grid had two.**
        //
        // A photograph needs the width — a screenshot at a third of the screen
        // is unreadable. A drawn folder does not: it is a shape, a colour and
        // a glyph, all three of which survive being small, and at three across
        // the whole of a starter set is on screen at once without scrolling.
        crossAxisCount: 3,
        mainAxisSpacing: 18.h,
        crossAxisSpacing: 12.w,
        // Taller than wide: the plate is roughly square and the pocket hangs
        // below it.
        childAspectRatio: 0.76,
      ),
      itemBuilder:
          (
            BuildContext context,
            FolderEntity folder,
            int index,
            Animation<double> animation,
          ) {
            // Scale as well as fade, and from 0.85 rather than from zero — the
            // library's tiles arrive the same way, and the reasoning there
            // applies exactly: a tile that only fades leaves a hole its own
            // size behind it, so the grid still looks like it snapped.
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.85, end: 1).animate(
                  CurvedAnimation(parent: animation, curve: AppMotion.standard),
                ),
                // The first-paint cascade, unchanged: it refuses to run outside
                // its own 400ms window, so a folder created twenty minutes into
                // the session gets the insert above and nothing from this.
                child: EntranceStagger(
                  index: index,
                  since: since,
                  child: FolderCard(
                    folder: folder,
                    onTap: () => Navigator.of(context).push(
                      FadeSlidePageRoute(
                        // The pushed route sits outside this page's subtree, so
                        // the bloc has to be handed over explicitly — otherwise
                        // renaming or deleting from inside the folder wouldn't
                        // refresh the grid behind it.
                        builder: (_) => BlocProvider.value(
                          value: context.read<FoldersBloc>(),
                          child: FolderDetailPage(folder: folder),
                        ),
                      ),
                    ),
                    onMoreTap: () => showFolderActionsSheet(
                      context,
                      folder: folder,
                      bloc: context.read<FoldersBloc>(),
                    ),
                  ),
                ),
              ),
            );
          },
    );
  }
}
