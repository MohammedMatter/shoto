import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

/// Sets or clears a reminder about one screenshot.
///
/// [title] and [body] arrive already translated — see
/// [ScreenshotRepository.setReminder] for why the text cannot be composed any
/// deeper than the widget that asks for it. They are ignored when [at] is
/// null, which cancels.
///
/// Returns whether the reminder will actually be seen.
class SetReminderUseCase {
  final ScreenshotRepository repository;
  SetReminderUseCase(this.repository);

  Future<bool> call(
    String assetId,
    DateTime? at, {
    String title = '',
    String body = '',
  }) => repository.setReminder(assetId, at, title: title, body: body);
}
