import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/funnel_log.dart';
import 'package:shoto/core/localization/app_message.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/fade_slide_page_route.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/widgets/empty_state.dart';
import 'package:shoto/core/widgets/header_icon_button.dart';
import 'package:shoto/core/widgets/primary_button.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_bloc.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_event.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_state.dart';
import 'package:shoto/features/folders/presentation/pages/folder_detail_page.dart';
import 'package:shoto/features/folders/presentation/widgets/create_folder_sheet.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_actions_sheet.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_card.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';

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
                SizedBox(height: 18.h),
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
                        ) =>
                          _FoldersGrid(folders: f, since: _since),
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
  /// thing SHOTO asked them to do in the first place. Charging for it
  /// interrupted the one behaviour the app most needs to encourage, and it
  /// was the second of three different free-tier currencies to keep track
  /// of. The volume cap on screenshots is the whole free tier now.
  Future<void> _createFolder(BuildContext context) async {
    final FoldersBloc bloc = context.read<FoldersBloc>();

    showCreateFolderSheet(
      context,
      onCreate: (name, color, isPrivate) {
        // Counted at the two presentation call sites — here and the share
        // sheet's inline "new folder" — rather than inside the bloc or the
        // use case. Both of those are handed their collaborators through the
        // constructor and reach for nothing else; a service-locator lookup in
        // either would be the first exception to that in the codebase, for a
        // counter.
        sl<FunnelLog>().record(FunnelStep.folderCreated);
        bloc.add(CreateFolderEvent(name, color, isPrivate: isPrivate));
      },
    );
  }
}

/// The grid, and the one place folder covers are worked out.
///
/// Covers come from the library the shell already holds in memory rather than
/// from a query per folder: one pass over the screenshots produces the newest
/// asset for every folder at once, so the cost of showing twelve covers is the
/// same as showing one.
class _FoldersGrid extends StatelessWidget {
  final List<FolderEntity> folders;
  final DateTime since;

  const _FoldersGrid({required this.folders, required this.since});

  /// Newest filed screenshot per folder id.
  ///
  /// The library arrives newest-first — Home takes the first twelve of the
  /// same list for its "Recent" strip — so the first entity seen for a folder
  /// is its newest, and `putIfAbsent` keeps it.
  static Map<int, AssetEntity> _covers(List<ScreenshotEntity> screenshots) {
    final Map<int, AssetEntity> covers = {};
    for (final ScreenshotEntity screenshot in screenshots) {
      final int? folderId = screenshot.folderId;
      if (folderId == null) continue;
      covers.putIfAbsent(folderId, () => screenshot.asset);
    }
    return covers;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScreenshotsBloc, ScreenshotsState>(
      // Only the library's *contents* can change a cover. Without this the
      // grid would rebuild — and re-derive every cover — every time the
      // Library tab entered selection mode or changed its filter, neither of
      // which this screen can see.
      buildWhen: (previous, current) => !identical(
        previous is ScreenshotsLoadedState ? previous.screenshots : null,
        current is ScreenshotsLoadedState ? current.screenshots : null,
      ),
      builder: (context, state) {
        final Map<int, AssetEntity> covers = state is ScreenshotsLoadedState
            ? _covers(state.screenshots)
            : const {};

        return GridView.builder(
          padding: EdgeInsets.only(bottom: 130.h),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 22.h,
            crossAxisSpacing: 14.w,
            // Taller than wide, so the cover underneath the two lines of
            // caption comes out very slightly portrait. Screenshots are tall
            // images; a landscape crop of one throws away the top and bottom
            // of the thing being recognised.
            childAspectRatio: 0.72,
          ),
          itemCount: folders.length,
          itemBuilder: (context, index) {
            final FolderEntity folder = folders[index];
            return EntranceStagger(
              index: index,
              since: since,
              child: FolderCard(
                folder: folder,
                cover: covers[folder.id],
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
            );
          },
        );
      },
    );
  }
}
