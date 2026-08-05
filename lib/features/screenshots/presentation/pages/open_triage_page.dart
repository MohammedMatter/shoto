import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/fade_slide_page_route.dart';
import 'package:shoto/core/widgets/app_snack_bar.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_new_captures_use_case.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';
import 'package:shoto/features/screenshots/presentation/pages/triage_page.dart';

/// Opens the triage queue, and does the one thing the page itself must not:
/// decide there is anything to open.
///
/// The list is re-read here rather than passed in from whatever drew the
/// badge, because a badge can be a minute old — the user may have taken three
/// more screenshots since, or reviewed them in another entry point — and a
/// queue built from a stale count shows the wrong pictures.
///
/// Returns how many captures joined the library.
Future<int> openTriagePage(BuildContext context) async {
  final ScreenshotsBloc bloc = context.read<ScreenshotsBloc>();
  final List<AssetEntity> captures = await sl<GetNewCapturesUseCase>()();

  if (!context.mounted) return 0;
  if (captures.isEmpty) return 0;

  final int? kept = await Navigator.of(context).push<int>(
    FadeSlidePageRoute(builder: (_) => TriagePage(captures: captures)),
  );

  if (kept == null || !context.mounted) return kept ?? 0;

  // Said out loud, including zero. A review where everything was skipped did
  // work — it emptied the queue — and returning to Home with no acknowledgement
  // at all reads as the app having lost the answers.
  showAppSnackBar(context, context.l10n.triageKept(kept));
  if (kept > 0) bloc.add(RefreshScreenshotsEvent());
  return kept;
}
