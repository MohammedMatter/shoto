import 'package:flutter/material.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/features/screenshots/domain/use_cases/import_from_system_picker_use_case.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';

/// Hands the OS picker the job, then reports what actually landed.
///
/// Shared by Home and Library, which reach it from a tool row and a header
/// button. One function rather than one per screen because everything
/// interesting here is a rule about *messages*, and two copies of those rules
/// drift — the second entry point is exactly where a "5 imported" for a
/// three-image import gets introduced.
///
/// [bloc] is passed in rather than read from [context]: the picker takes over the
/// screen, and looking a provider up through a context that has been rebuilt in
/// the meantime is the standard use-after-await bug. Callers read it before
/// calling, while their own build is still on screen.
Future<void> importScreenshots(
  BuildContext context, {
  required ScreenshotsBloc bloc,
}) async {
  final ImportResult result = await sl<ImportFromSystemPickerUseCase>()();

  // Nothing to say. The user opened the picker, closed it, and already knows —
  // a "0 imported" toast for that reads as an error report for something that
  // went exactly as they chose.
  if (result.cancelled) return;

  if (result.imported > 0) bloc.add(RefreshScreenshotsEvent());

  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(_message(context, result))));
}

/// One message per *cause*, not one per outcome.
///
/// These were collapsed into a single "could not read those images", which is
/// the mistake this function exists to not repeat: the picker never opening and
/// the pictures failing to save are different problems with different fixes, and
/// a user handed one sentence for both cannot act on either. The first is the
/// app's install being out of date with its own plugins; the second is the
/// gallery write being refused.
String _message(BuildContext context, ImportResult result) {
  if (result.pickerFailed) return context.l10n.importPickerUnavailable;
  if (result.imported == 0) return context.l10n.importFailed;

  return result.partial
      ? context.l10n.importPartial(result.imported, result.picked)
      : context.l10n.importDone(result.imported);
}
