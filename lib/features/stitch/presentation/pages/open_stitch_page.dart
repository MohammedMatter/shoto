import 'package:flutter/material.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/fade_slide_page_route.dart';
import 'package:shoto/core/widgets/premium_gate.dart';
import 'package:shoto/features/stitch/data/services/image_stitch_service.dart';
import 'package:shoto/features/stitch/presentation/pages/stitch_page.dart';
import 'package:shoto/core/widgets/app_snack_bar.dart';

/// Premium gate + navigation for merging long screenshots.
///
/// Kept beside the page rather than inside the toolbar that calls it so the
/// entitlement check lives in one place if more entry points appear later —
/// the same shape as the search and duplicates gates.
///
/// Returns true when a merged image was saved, so the caller can clear the
/// selection it was built from.
Future<bool> openStitchPage(BuildContext context, List<String> assetIds) async {
  if (assetIds.length > ImageStitchService.maxSources) {
    showAppSnackBar(
      context,
      context.l10n.stitchLimit(ImageStitchService.maxSources),
    );
    return false;
  }

  if (!await ensurePremium(context)) return false;
  if (!context.mounted) return false;
  final bool? saved = await Navigator.of(context).push<bool>(
    FadeSlidePageRoute(builder: (_) => StitchPage(assetIds: assetIds)),
  );
  return saved ?? false;
}
