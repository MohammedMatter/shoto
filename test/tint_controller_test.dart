import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoto/core/theme/app_tint.dart';
import 'package:shoto/core/theme/tint_controller.dart';

/// **What survives a restart**, checked here rather than on a device.
///
/// The accent is the only preference in this app a user is likely to change
/// several times in one sitting and then judge the app by — so "it looked
/// right until I reopened it" is the failure that matters, and it is exactly
/// the one a screenshot cannot rule out. An in-memory value and a persisted
/// one agreeing is a claim about two different things, and only one of them
/// is visible.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('a fresh install opens on the default', () async {
    final TintController controller = TintController();
    await controller.load();

    expect(controller.tint, AppTint.fallback);
    expect(controller.isCustom, isFalse);
  });

  test('a choice is written, and read back by the next launch', () async {
    final TintController first = TintController();
    await first.load();
    await first.setTint(AppTint.plum);

    // A second controller over the same store stands in for the next cold
    // start — which is the only way this preference is ever read.
    final TintController next = TintController();
    await next.load();

    expect(next.tint, AppTint.plum);
    expect(next.isCustom, isTrue);
  });

  test('the id is stored, never the colour', () async {
    final TintController controller = TintController();
    await controller.load();
    await controller.setTint(AppTint.amber);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // The whole point of storing a decision rather than a value: a later
    // correction to amber's hue or saturation has to reach the people who
    // already chose it. A hex here would have frozen them at whatever the
    // solver produced on the day they tapped.
    expect(prefs.getString('accent_tint'), 'amber');
  });

  test('listeners fire before the write, so the frame is not waited on', () {
    final TintController controller = TintController();
    int notifications = 0;
    controller.addListener(() => notifications++);

    // Not awaited: the point is that the notification has already happened by
    // the time `setTint` yields, so the repaint does not queue behind a disk
    // round trip.
    controller.setTint(AppTint.indigo);

    expect(notifications, 1);
    expect(controller.tint, AppTint.indigo);
  });

  test('choosing the accent already in force does nothing at all', () async {
    final TintController controller = TintController();
    await controller.load();
    await controller.setTint(AppTint.moss);

    int notifications = 0;
    controller.addListener(() => notifications++);
    await controller.setTint(AppTint.moss);

    expect(notifications, isZero, reason: 'a no-op must not repaint the app');
  });

  test('a stored id that no longer exists opens on the default', () async {
    // An accent dropped in a later version is still sitting in somebody's
    // preferences. Reading it back must not throw on the first frame.
    SharedPreferences.setMockInitialValues(<String, Object>{
      'accent_tint': 'chartreuse',
    });

    final TintController controller = TintController();
    await controller.load();

    expect(controller.tint, AppTint.fallback);
  });

  test('every shipped id survives the round trip', () async {
    for (final AppTint tint in AppTint.all) {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final TintController writer = TintController();
      await writer.load();
      await writer.setTint(tint);

      final TintController reader = TintController();
      await reader.load();
      expect(reader.tint, tint, reason: tint.id);
    }
  });
}
