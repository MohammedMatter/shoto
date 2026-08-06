import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_bloc.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_state.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_filter.dart';

class HomeStatLine extends StatelessWidget {
  final int total;
  final int favorites;
  final ValueChanged<LibraryFilter> onOpenLibrary;
  final VoidCallback onOpenFolders;

  const HomeStatLine({
    super.key,
    required this.total,
    required this.favorites,
    required this.onOpenLibrary,
    required this.onOpenFolders,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FoldersBloc, FoldersState>(
      builder: (context, state) {
        final int folders = state is FoldersLoadedState
            ? state.folders.length
            : 0;

        final TextStyle label = context.text.bodySmall.copyWith(
          color: context.colors.textSecondary,
        );
        TextStyle figure(Color color) => context.text.mono.asSemiBold.copyWith(
          fontSize: 12.sp,
          color: color,
        );

        Widget dot() => Padding(
          padding: EdgeInsets.symmetric(horizontal: 7.w),
          child: Text('·', style: label),
        );

        Widget stat(String name, int value, Color tint, VoidCallback onTap) =>
            PressableScale(
              scale: 0.94,
              onTap: onTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name, style: label),
                  Text(
                    ' $value',
                    style: figure(
                      value == 0 ? context.colors.textSecondary : tint,
                    ),
                  ),
                ],
              ),
            );

        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            stat(
              context.l10n.homeStatScreenshots,
              total,
              context.colors.textPrimary,
              () => onOpenLibrary(LibraryFilter.all),
            ),
            dot(),
            stat(
              context.l10n.homeStatFavorites,
              favorites,
              context.colors.error,
              () => onOpenLibrary(LibraryFilter.favorites),
            ),
            dot(),
            stat(
              context.l10n.homeStatFolders,
              folders,
              context.colors.secondary,
              onOpenFolders,
            ),
          ],
        );
      },
    );
  }
}
