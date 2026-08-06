import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/routes/photo_viewer_route.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/widgets/asset_thumbnail_image.dart';
import 'package:shoto/core/widgets/photo_hero.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/pages/screenshot_detail_page.dart';

class HomeRecentStrip extends StatelessWidget {
  final List<ScreenshotEntity> screenshots;

  static const String _heroPrefix = 'home';

  const HomeRecentStrip({super.key, required this.screenshots});

  static const double _cardWidth = 96;
  static const double _cardHeight = 176;

  @override
  Widget build(BuildContext context) {
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
          child: Container(
            width: _cardWidth.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: context.colors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md - 1),
              child: PhotoHero(
                tag: '$_heroPrefix-${screenshots[index].id}',
                radius: AppRadius.md - 1,
                child: AssetThumbnailImage(asset: screenshots[index].asset),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
