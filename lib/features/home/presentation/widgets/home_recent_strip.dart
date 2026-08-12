import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/routes/photo_viewer_route.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/widgets/asset_thumbnail_image.dart';
import 'package:shoto/core/widgets/photo_hero.dart';
import 'package:shoto/core/widgets/skeleton.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/pages/screenshot_detail_page.dart';

class HomeRecentStrip extends StatelessWidget {
  final List<ScreenshotEntity> screenshots;

  /// Whether these are placeholders for pictures still being read.
  final bool isPending;

  static const String _heroPrefix = 'home';

  const HomeRecentStrip({super.key, required this.screenshots})
    : isPending = false;

  /// The strip at its real height, with grey cards in it.
  ///
  /// **The tallest block on Home**, which is why it gets a placeholder at all
  /// rather than simply being absent until the gallery answers. A section this
  /// size arriving late does not read as content loading, it reads as the page
  /// growing — everything below it jumps a hundred and ninety pixels down the
  /// screen, under a thumb that may already be moving.
  ///
  /// Four cards, because that is roughly what a phone shows before the edge
  /// and the row is horizontal: the count is scenery, not a claim about how
  /// many screenshots exist.
  const HomeRecentStrip.pending({super.key})
    : screenshots = const <ScreenshotEntity>[],
      isPending = true;

  static const double _cardWidth = 96;
  static const double _cardHeight = 176;

  @override
  Widget build(BuildContext context) {
    if (isPending) return const _PendingStrip();

    return SizedBox(
      height: _cardHeight.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsetsDirectional.only(start: 20.w, end: 6.w),
        itemCount: screenshots.length,
        separatorBuilder: (_, _) => SizedBox(width: 9.w),
        itemBuilder: (context, index) => PressableScale(
          scale: 0.95,
          onTap: () {
            final ScreenshotsBloc bloc = context.read<ScreenshotsBloc>();
            Navigator.of(context).push(
              PhotoViewerRoute(
                builder: (_) => BlocProvider.value(
                  value: bloc,
                  child: ScreenshotDetailPage(
                    screenshots: screenshots,
                    initialIndex: index,
                    heroPrefix: _heroPrefix,
                  ),
                ),
              ),
            );
          },
          // **The signature, finally on something.**
          //
          // `ClippedCorner` is documented in `app_shapes.dart` as the one shape
          // that means *Shoto is holding this*, with the rule that it appears
          // on things you kept and on nothing else — and it was drawn in
          // exactly three places, all of them pictures of the app rather than
          // the app: the brand mark, the launcher icon and an onboarding
          // illustration. The product had a signature it never signed with,
          // which is most of the reason its screens looked like anyone's.
          //
          // A recent screenshot is the most literal possible instance of the
          // rule, so the cut goes here, not on the cards or the chips around
          // it. The border stops at the cut rather than tracing it: a clipped
          // corner with an outline is a hexagon, and the point is that a
          // corner is *missing*.
          child: ClippedCorner(
            radius: AppRadius.md,
            cut: 15.r,
            child: Container(
              width: _cardWidth.w,
              decoration: BoxDecoration(
                color: context.colors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: PhotoHero(
                tag: '$_heroPrefix-${screenshots[index].id}',
                radius: AppRadius.md,
                child: AssetThumbnailImage(asset: screenshots[index].asset),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The strip's geometry with nothing in it yet.
///
/// **The same `ListView` the real strip is**, with the same padding and the
/// same gap, because that is what makes the swap invisible: a `Row` here
/// overflowed its 340 points of width on a phone the moment four cards were
/// asked for, and even clipped, a placeholder laid out by different rules is a
/// placeholder that will one day disagree with the thing it stands in for.
///
/// Frozen, though. There is nothing past the edge to reach, and a strip that
/// slides under a finger to reveal more grey is a promise about content that
/// does not exist yet.
class _PendingStrip extends StatelessWidget {
  const _PendingStrip();

  /// Enough to run off the trailing edge on the narrowest phone, which is all
  /// this number has to do — it is scenery, not a claim about how many
  /// screenshots there are.
  static const int _cards = 4;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: HomeRecentStrip._cardHeight.h,
      child: SkeletonPulse(
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsetsDirectional.only(start: 20.w, end: 6.w),
          itemCount: _cards,
          separatorBuilder: (_, _) => SizedBox(width: 9.w),
          // The signature cut, from the first frame — see the note on the real
          // card above. A corner that appears only once the picture loads makes
          // the placeholder a different shape from the thing it replaces.
          itemBuilder: (BuildContext context, int index) => ClippedCorner(
            radius: AppRadius.md,
            cut: 15.r,
            child: Container(
              width: HomeRecentStrip._cardWidth.w,
              decoration: BoxDecoration(
                color: context.colors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
