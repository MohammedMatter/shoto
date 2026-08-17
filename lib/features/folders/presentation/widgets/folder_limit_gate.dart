import 'package:flutter/material.dart';
import 'package:shoto/core/constants/subscription_constants.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/routes/fade_slide_page_route.dart';
import 'package:shoto/features/folders/domain/use_cases/get_folders_use_case.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';
import 'package:shoto/features/subscription/domain/use_cases/get_subscription_status_use_case.dart';
import 'package:shoto/features/subscription/presentation/pages/paywall_page.dart';

/// Checks the free tier's folder cap — [SubscriptionConstants.freeFolderLimit]
/// — before a folder is made.
///
/// Returns true if the caller should go ahead: under the cap, already premium,
/// or the user subscribed on the paywall this presented.
///
/// **Asked before the editor opens, not when Save is pressed.** The sheet asks
/// for a name, a colour and a glyph; refusing after all three have been chosen
/// spends somebody's attention and then throws the result away. The honest
/// order is to find out first.
///
/// **Counted here rather than read off the grid.** `FoldersBloc` is holding a
/// list that is almost always right, and "almost always" is the wrong standard
/// for the check that decides whether somebody is asked for money — the same
/// reason `LibraryQuota` exists for painting and `ensureUnderScreenshotLimit`
/// still counts for itself. It is one local `SELECT` on a table with single
/// digits in it, and the second call site (Quick Save, running in the share
/// activity) has no folders bloc above it at all.
///
/// **Refuses only new folders.** Anybody already over the line — which on the
/// day this shipped is everybody, since the cap did not exist and the starter
/// set was seven — keeps every folder they have. Nothing is deleted, nothing is
/// hidden, and deleting one of their own gives a slot back.
Future<bool> ensureUnderFolderLimit(BuildContext context) async {
  final int folders = (await sl<GetFoldersUseCase>()()).length;
  if (folders < SubscriptionConstants.freeFolderLimit) return true;

  // Counted first, status second: a subscriber under the cap — which is most
  // of them, most of the time — never pays for a status lookup, and the count
  // is the cheaper of the two questions.
  final SubscriptionStatus status = await sl<GetSubscriptionStatusUseCase>()();
  if (status.isPremium) return true;

  if (!context.mounted) return false;
  final bool? purchased = await Navigator.of(
    context,
  ).push<bool>(FadeSlidePageRoute(builder: (_) => const PaywallPage()));
  return purchased == true;
}
