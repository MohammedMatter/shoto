import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/fade_slide_page_route.dart';
import 'package:shoto/core/routes/photo_viewer_route.dart';
import 'package:shoto/core/utils/visual_vocabulary.dart';
import 'package:shoto/core/widgets/premium_gate.dart';
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
  String _query = '';
  bool _isIndexing = true;
  Timer? _publishTimer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _query = _controller.text.trim().toLowerCase());
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
                        color: AppColors.secondary,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      context.l10n.searchWorking,
                      style: AppTextStyles.caption,
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
