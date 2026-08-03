import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/fade_slide_page_route.dart';
import 'package:shoto/core/routes/photo_viewer_route.dart';
import 'package:shoto/core/services/library_indexer.dart';
import 'package:shoto/core/utils/visual_vocabulary.dart';
import 'package:shoto/core/widgets/premium_gate.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/empty_state.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_cached_ocr_text_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_cached_visual_labels_use_case.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/screenshots/presentation/pages/screenshot_detail_page.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshot_thumbnail.dart';

/// Premium-gates then opens [SearchPage]. Pass [bloc] to reuse an
/// already-loaded [ScreenshotsBloc] (e.g. Home's, so favorite/move actions
/// taken from search stay in sync with Home's grid); omit it to spin up a
/// fresh, independently-loaded one for entry points that don't have one in
/// scope (e.g. the shell's quick-actions button).
Future<void> openSearchPage(
  BuildContext context, {
  ScreenshotsBloc? bloc,
}) async {
  if (!await ensurePremium(context)) return;
  if (!context.mounted) return;
  final ScreenshotsBloc resolvedBloc =
      bloc ?? (sl<ScreenshotsBloc>()..add(LoadScreenshotsEvent()));
  Navigator.of(context).push(
    FadeSlidePageRoute(
      builder: (_) =>
          BlocProvider.value(value: resolvedBloc, child: SearchPage()),
    ),
  );
}

/// Premium "search your screenshots" feature, reading each picture two ways.
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
/// Both are cached permanently in `screenshot_meta`, and this page only ever
/// *reads* that cache — [LibraryIndexer] fills it, continuously, for as long
/// as the app is open.
///
/// It did not always. Search used to index forty screenshots per visit, the
/// filing rules another forty per tap, and Smart Actions one at a time: three
/// capped indexers, each doing work the others had already done, each alive
/// only while its own page was. The caps were the only thing keeping the page
/// from blocking on hundreds of model calls, and the cost landed hardest on
/// rules, where a correct rule matched nothing simply because nothing had
/// been read yet. One indexer, started at the shell, removes both the caps
/// and the duplication.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  final Map<String, String> _ocrByAssetId = {};
  final Map<String, List<String>> _labelsByAssetId = {};
  String _query = '';

  late final LibraryIndexer _indexer = sl<LibraryIndexer>();
  Timer? _reloadTimer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _query = _controller.text.trim().toLowerCase());
    });

    _indexer.addListener(_onIndexerChanged);
    // Nudged rather than started: the shell has been running it since launch,
    // so on most visits this finds the work already done. It matters for the
    // visit right after somebody subscribes, when the last sweep stopped at
    // the premium check.
    unawaited(_indexer.start());
    unawaited(_loadCaches());
  }

  @override
  void dispose() {
    _indexer.removeListener(_onIndexerChanged);
    _reloadTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Picks up what the indexer has read, at most once a second.
  ///
  /// The indexer notifies after every screenshot, and reacting to each one
  /// would mean two full-table reads and a rebuild of a page holding a grid,
  /// interleaved with the heaviest work the app does. Results still stream in
  /// while the model runs, which is the point of updating at all; they simply
  /// arrive in batches nobody can perceive as batches.
  void _onIndexerChanged() {
    if (!mounted) return;
    // The phase line at the top has to move immediately even when the
    // expensive reload is still on its timer.
    setState(() {});
    if (_reloadTimer?.isActive ?? false) return;
    _reloadTimer = Timer(
      const Duration(seconds: 1),
      () => unawaited(_loadCaches()),
    );
  }

  Future<void> _loadCaches() async {
    final Map<String, String> cachedText =
        await sl<GetCachedOcrTextUseCase>()();
    final Map<String, List<String>> cachedLabels =
        await sl<GetCachedVisualLabelsUseCase>()();
    if (!mounted) return;
    setState(() {
      _ocrByAssetId
        ..clear()
        ..addAll(cachedText);
      _labelsByAssetId
        ..clear()
        ..addAll(cachedLabels);
    });
  }

  /// Why this screenshot should appear for the current query, or null if it
  /// shouldn't. Returning the reason rather than a bool is what lets a
  /// visual match explain itself on screen.
  _Match? _match(ScreenshotEntity screenshot) {
    final bool matchedText = (_ocrByAssetId[screenshot.id] ?? '')
        .toLowerCase()
        .contains(_query);

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
      backgroundColor: AppColors.background,
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
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: AppColors.textSecondary,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              autofocus: true,
                              style: AppTextStyles.bodyLarge,
                              decoration: InputDecoration(
                                hintText: context.l10n.searchHint,
                                hintStyle: AppTextStyles.bodyMedium,
                                border: InputBorder.none,
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
            // Now says *how much* is left rather than only that something is
            // happening. Search over a partly-read library gives incomplete
            // answers, and "still reading, 340 to go" is the difference
            // between an empty result somebody waits out and one they read as
            // "SHOTO cannot find my screenshot".
            if (_indexer.isWorking)
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(20.w, 10.h, 20.w, 0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14.w,
                      height: 14.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: _indexer.fraction,
                        color: AppColors.secondary,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        context.l10n.indexingProgress(_indexer.remaining),
                        style: AppTextStyles.caption,
                      ),
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
        if (state is! ScreenshotsLoadedState) return const SizedBox.shrink();

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
            message: context.l10n.searchNoneBody(_query),
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
              onLongPress: () {},
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
              style: AppTextStyles.caption.asSemiBold.copyWith(
                color: AppColors.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
