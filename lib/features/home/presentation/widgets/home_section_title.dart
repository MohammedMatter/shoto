import 'package:flutter/material.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';

class HomeSectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const HomeSectionTitle(this.title, {super.key, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: context.text.sectionLabel),
        const Spacer(),
        if (onSeeAll != null)
          PressableScale(
            scale: 0.9,
            onTap: onSeeAll,
            child: Text(
              context.l10n.homeSeeAll,
              style: context.text.sectionLabel.asSemiBold.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
          ),
      ],
    );
  }
}
