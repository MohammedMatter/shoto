import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/funnel_log.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/fade_slide_page_route.dart';
import 'package:shoto/core/routes/photo_viewer_route.dart';
import 'package:shoto/core/utils/text_folding.dart';
import 'package:shoto/core/utils/visual_vocabulary.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/empty_state.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/domain/use_cases/extract_and_cache_labels_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/extract_and_cache_text_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_cached_ocr_text_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_cached_visual_labels_use_case.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/screenshots/presentation/pages/screenshot_detail_page.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshot_actions.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshot_thumbnail.dart';
import 'package:shoto/features/screenshots/presentation/widgets/library_unavailable.dart';

/// Opens [SearchPage]. Pass [bloc] to reuse an already-loaded
/// [ScreenshotsBloc] (e.g. Home's, so favorite/move actions taken from search
/// stay in sync with Home's grid); omit it to spin up a fresh, independently
/// loaded one for entry points that don't have one in scope (e.g. the shell's
/// quick-actions button).
///
/// Free, and deliberately so. This used to call `ensurePremium` first, which
/// meant the most prominent control on the app's first screen — the search
/// field, placed second on Home precisely to be reachable and obvious — was
/// a paywall trigger. "Find any screenshot in seconds" is the sentence the
/// whole product is sold on; withholding it does not make the free tier a
/// smaller version of Shoto, it makes it a demo with the point removed. The
/// paid line now sits at Safe Share, Stitch, and volume: things somebody
/// reaches for after the app has already proved it works.
Future<void> openSearchPage(
  BuildContext context, {
  ScreenshotsBloc? bloc,
}) async {
  // Now that this is free, the number finally means something: it measures
  // whether people want search, rather than how many were willing to pay to
  // find out whether they wanted it.
  sl<FunnelLog>().record(FunnelStep.searchUsed);

  final ScreenshotsBloc resolvedBloc =
      bloc ?? (sl<ScreenshotsBloc>()..add(LoadScreenshotsEvent()));
  Navigator.of(context).push(
    FadeSlidePageRoute(
      builder: (_) =>
          BlocProvider.value(value: resolvedBloc, child: const SearchPage()),
    ),
  );
}

/// "Search your screenshots", reading each picture two ways.
///
/// **Text**, via OCR — the words printed inside the image.
///
/// **Content**, via an on-device vision model — what the picture actually
/// shows. This exists because text-only search has a hole it can never close:
/// a photo of a cat contains no words, so no amount of better reading finds
/// it. The model names it `Cat`, and [VisualVocabulary] turns that into the
/// words somebody would type, in Arabic or English, including the general
/// ones like "حيوان" that no single label answers.
///
/// Both are indexed lazily on first open and capped per visit so the page
/// never blocks on hundreds of model calls, then cached permanently in
/// `screenshot_meta` — every later visit is instant.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  static const int _indexBatchCap = 40;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  final Map<String, String> _ocrByAssetId = {};
  final Map<String, List<String>> _labelsByAssetId = {};

  /// The query **folded for comparison**, never for display — see the empty
  /// state, which quotes the controller's own text back instead.
  String _query = '';
  bool _isIndexing = true;
  Timer? _publishTimer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _query = foldForMatching(_controller.text.trim()));
    });
    _loadAndIndex();
  }

  @override
  void dispose() {
    _publishTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadAndIndex() async {
    final Map<String, String> cachedText =
        await sl<GetCachedOcrTextUseCase>()();
    final Map<String, List<String>> cachedLabels =
        await sl<GetCachedVisualLabelsUseCase>()();
    if (!mounted) return;
    setState(() {
      _ocrByAssetId.addAll(cachedText);
      _labelsByAssetId.addAll(cachedLabels);
    });

    final ScreenshotsState state = context.read<ScreenshotsBloc>().state;
    if (state is! ScreenshotsLoadedState) {
      setState(() => _isIndexing = false);
      return;
    }

    // The two indexes are filled independently: a screenshot whose text was
    // read before this feature existed still needs looking at, and pairing
    // them would mean re-running OCR on the entire library to get labels.
    final List<ScreenshotEntity> needsText = state.screenshots
        .where((s) => !_ocrByAssetId.containsKey(s.id))
        .take(SearchPage._indexBatchCap)
        .toList();
    final List<ScreenshotEntity> needsLabels = state.screenshots
        .where((s) => !_labelsByAssetId.containsKey(s.id))
        .take(SearchPage._indexBatchCap)
        .toList();

    for (final ScreenshotEntity screenshot in needsText) {
      final String text = await sl<ExtractAndCacheTextUseCase>()(screenshot);
      if (!mounted) return;
      _ocrByAssetId[screenshot.id] = text;
      _publish();
    }

    for (final ScreenshotEntity screenshot in needsLabels) {
      final List<String> labels = await sl<ExtractAndCacheLabelsUseCase>()(
        screenshot,
      );
      if (!mounted) return;
      _labelsByAssetId[screenshot.id] = labels;
      _publish();
    }

    _publishTimer?.cancel();
    if (mounted) setState(() => _isIndexing = false);
  }

  /// Shows what has been read so far, at most a few times a second.
  ///
  /// Indexing walks up to eighty screenshots through OCR and a vision model,
  /// and it used to `setState` after every single one — eighty full rebuilds
  /// of a page holding a grid, interleaved with the heaviest work the app
  /// does. Results still stream in while the model runs, which is the point of
  /// updating at all; they simply arrive in batches nobody can perceive as
  /// batches.
  void _publish() {
    if (_publishTimer?.isActive ?? false) return;
    _publishTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() {});
    });
  }

  /// Why this screenshot should appear for the current query, or null if it
  /// shouldn't. Returning the reason rather than a bool is what lets a
  /// visual match explain itself on screen.
  ///
  /// **Both sides are folded, and this used to lower-case only.**
  /// [foldForMatching] was written for exactly this — its own doc names the
  /// two places that claimed to be diacritic-insensitive and were not — and
  /// the largest search surface in the app was not one of its callers. Six of
  /// the seven shipped languages write accents, so "cafe" missed a receipt
  /// reading *Café* and "strasse" missed an address reading *Straße*: not an
  /// edge case on those phones, but the ordinary way somebody types on a
  /// keyboard where an accent costs two presses.
  ///
  /// The recognised text is folded on every keystroke rather than once at
  /// index time on purpose. It is a `contains` over a few hundred cached
  /// strings behind a text field, and a second copy of the library's text kept
  /// only for matching is a cache that can disagree with the one the viewer
  /// shows.
  _Match? _match(ScreenshotEntity screenshot) {
    final bool matchedText = foldForMatching(
      _ocrByAssetId[screenshot.id] ?? '',
    ).contains(_query);

    final List<String> matchedLabels = VisualVocabulary.matchingLabels(
      _labelsByAssetId[screenshot.id] ?? const [],
      _query,
    );

    if (!matchedText && matchedLabels.isEmpty) return null;
    return _Match(
      screenshot: screenshot,
      matchedText: matchedText,
      labels: matchedLabels,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(12.w, 8.h, 20.w, 4.h),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: context.colors.textSecondary,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              autofocus: true,
                              style: context.text.bodyLarge,
                              decoration: InputDecoration(
                                hintText: context.l10n.searchHint,
                                hintStyle: context.text.bodyMedium,
                                border: InputBorder.none,
                                // **The app-wide focus ring is refused here,
                                // and only here.**
                                //
                                // `inputDecorationTheme` gives every field a
                                // blue ring when focused, which is right for a
                                // field sitting on a page among others: it says
                                // which one the keyboard is typing into. This
                                // field is the only thing on its screen and it
                                // is `autofocus`, so the ring answers a question
                                // nobody asked — and it is drawn *inside* the
                                // rounded box above, which already draws the
                                // field's shape. Two rounded outlines, one
                                // inside the other, from the first frame the
                                // screen exists.
                                //
                                // Stated explicitly because `applyDefaults`
                                // only fills a *null* `focusedBorder` from the
                                // theme. `border` alone does not cover it.
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 14.h,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isIndexing)
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(20.w, 10.h, 20.w, 0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14.w,
                      height: 14.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.colors.secondary,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      context.l10n.searchWorking,
                      style: context.text.caption,
                    ),
                  ],
                ),
              ),
            Expanded(child: _buildResults(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    return BlocBuilder<ScreenshotsBloc, ScreenshotsState>(
      builder: (context, state) {
        // Search is opened from a loaded library, so this is only reached
        // when access is revoked or a refresh fails underneath it — which is
        // exactly when a blank results area reads as "found nothing".
        final Widget? blocked = LibraryUnavailable.maybeOf(state);
        if (blocked != null) return blocked;
        state as ScreenshotsLoadedState;

        if (_query.isEmpty) {
          return EmptyState(
            icon: Icons.image_search_rounded,
            title: context.l10n.searchTitle,
            message: context.l10n.searchIntro,
          );
        }

        final List<_Match> results = [
          for (final ScreenshotEntity screenshot in state.screenshots)
            if (_match(screenshot) case final _Match match) match,
        ];

        if (results.isEmpty) {
          return EmptyState(
            icon: Icons.image_search_rounded,
            title: context.l10n.searchNoneTitle,
            // What they typed, not what was matched. [_query] is folded for
            // comparison — accents stripped, ß opened out to ss — and quoting
            // that back would answer a search for *Café* with "nothing for
            // cafe", which reads as the app having mistyped their word.
            message: context.l10n.searchNoneBody(_controller.text.trim()),
          );
        }

        return GridView.builder(
          padding: EdgeInsetsDirectional.fromSTEB(20.w, 12.h, 20.w, 120.h),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10.h,
            crossAxisSpacing: 10.w,
            childAspectRatio: 1,
          ),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final _Match match = results[index];
            final ScreenshotEntity item = match.screenshot;

            final Widget thumbnail = ScreenshotThumbnail(
              asset: item.asset,
              // Search is its own route, so it can hold a tag the library
              // grid underneath also holds — but it is namespaced anyway,
              // because the day one of these becomes a sheet instead of a
              // route is the day a duplicate tag crashes it.
              heroTag: 'search-${item.id}',
              isFavorite: item.isFavorite,
              intent: item.intent,
              isSelected: false,
              selectionMode: false,
              onTap: () => Navigator.of(context).push(
                PhotoViewerRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<ScreenshotsBloc>(),
                    child: ScreenshotDetailPage(
                      screenshots: [
                        for (final _Match m in results) m.screenshot,
                      ],
                      initialIndex: index,
                      heroPrefix: 'search',
                    ),
                  ),
                ),
              ),
              // The same gesture as the grid this search was opened from.
              //
              // It was an empty closure, which was defensible while a
              // long-press meant "start selecting" — there is no selection
              // mode here, so there was nothing for it to do. It stopped being
              // defensible when the gesture became "this screenshot's own
              // actions" everywhere else: a result you have just hunted down
              // is the *most* likely thing to want to file or share, and dying
              // silently on the one screen where you found it is how a person
              // stops trying the gesture at all.
              //
              // The list rebuilds from `state.screenshots` inside a
              // `BlocBuilder`, so a move or a delete taken from here drops out
              // of the results underneath without search having to know.
              onLongPress: () => showScreenshotQuickActionsSheet(context, item),
            );

            // A text match needs no explanation — the word is in the picture.
            // A visual match is the model's opinion, so it says whose opinion
            // it is. Being able to see "Cat" and disagree is the difference
            // between a search you learn to trust and one you stop using.
            if (match.labels.isEmpty) return thumbnail;

            return Stack(
              fit: StackFit.expand,
              children: [
                thumbnail,
                Positioned(
                  left: 5.w,
                  bottom: 5.w,
                  right: 5.w,
                  child: _VisualMatchBadge(label: match.labels.first),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// A result together with the reason it is a result.
class _Match {
  final ScreenshotEntity screenshot;

  /// True when the query appears in the text printed inside the image.
  final bool matchedText;

  /// The model's labels that the query matched, empty for a text-only match.
  final List<String> labels;

  const _Match({
    required this.screenshot,
    required this.matchedText,
    required this.labels,
  });
}

/// Names what the model saw, over the thumbnail that came back because of it.
class _VisualMatchBadge extends StatelessWidget {
  final String label;
  const _VisualMatchBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        // Dark on the photo rather than a brand colour: it has to stay
        // readable over whatever the picture happens to be.
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 11.sp,
            color: Colors.white.withValues(alpha: 0.85),
          ),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.caption.asSemiBold.copyWith(
                color: context.colors.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
