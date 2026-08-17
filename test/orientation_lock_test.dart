import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/main.dart';

/// Shoto is drawn one way up, and it takes three separate files to say so.
///
/// Dart asks for portrait, the Android manifest declares it, and the iOS
/// property list declares it again — and every one of the three governs a
/// stretch of the app's life the other two cannot reach. Dart cannot reach the
/// launch window, because that is painted before the engine exists. The
/// manifest cannot reach iOS. The plist cannot reach Android. A lock that
/// holds in two of the three is a lock with a visible hole in it: the app comes
/// up sideways for as long as the cold start takes and then snaps upright,
/// which is the exact flicker this suite exists to keep out.
///
/// So the checks below are deliberately not all widget tests. Only the first
/// group could be — the rest are the two configuration files, read as text,
/// because that is where every one of these regressions actually happens. A
/// `<activity>` added for a plugin, a landscape entry left in the plist by a
/// template, an `await` dropped from `main`: none of those are reachable from
/// a `WidgetTester`, and all three have shipped in real apps.
void main() {
  group('the Flutter layer', () {
    late List<MethodCall> calls;

    setUp(() {
      calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding
          .instance
          .defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            calls.add(call);
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('asks the platform for portrait, and only portrait', (
      tester,
    ) async {
      await lockOrientation();

      expect(
        calls.map((MethodCall call) => call.method),
        contains('SystemChrome.setPreferredOrientations'),
      );
      final MethodCall orientation = calls.firstWhere(
        (MethodCall call) =>
            call.method == 'SystemChrome.setPreferredOrientations',
      );
      // Exactly one entry. A list containing `portraitDown` would still be a
      // lock, and would still let the app turn upside down.
      expect(orientation.arguments, ['DeviceOrientation.portraitUp']);
    });

    testWidgets('a platform that refuses the lock does not fail the launch', (
      tester,
    ) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            // What Android 8.0 does to a translucent activity that asks for a
            // fixed orientation. `main` awaits this future before `runApp`, so
            // an error escaping here is a black screen rather than a rotated
            // one.
            throw PlatformException(code: 'error');
          });

      await expectLater(lockOrientation(), completes);
    });
  });

  group('the Android layer', () {
    final String manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    /// Every `<activity …>` opening tag, comments stripped first so the prose
    /// explaining why ShareActivity is exempt is not itself read as an
    /// activity.
    List<String> activityTags() {
      final String stripped = manifest.replaceAll(
        RegExp(r'<!--.*?-->', dotAll: true),
        '',
      );
      return RegExp(r'<activity\s[^>]*>', dotAll: true)
          .allMatches(stripped)
          .map((Match m) => m.group(0)!)
          .toList();
    }

    test('MainActivity is pinned to portrait', () {
      final String main = activityTags().singleWhere(
        (String tag) => tag.contains('android:name=".MainActivity"'),
      );
      expect(main, contains('android:screenOrientation="portrait"'));
    });

    test('the in-app browser url_launcher contributes is pinned too', () {
      final String browser = activityTags().singleWhere(
        (String tag) => tag.contains('urllauncher.WebViewActivity'),
      );
      expect(browser, contains('android:screenOrientation="portrait"'));
    });

    test('no activity asks for anything other than portrait', () {
      for (final String tag in activityTags()) {
        final RegExpMatch? declared = RegExp(
          r'android:screenOrientation="([^"]+)"',
        ).firstMatch(tag);
        if (declared == null) continue;
        expect(
          declared.group(1),
          'portrait',
          reason:
              'An activity declares a non-portrait orientation:\n$tag\n'
              '"userPortrait" is not a substitute — it lets a phone with '
              'auto-rotate on turn 180°.',
        );
      }
    });

    test('ShareActivity is the one exemption, and it locks itself', () {
      // Deliberately undeclared in the manifest: Android 8.0 throws out of
      // Activity.onCreate for a *translucent* activity carrying a fixed
      // orientation, and ShareTheme is translucent. The lock moves into Kotlin,
      // where it can be guarded — so this asserts the guard exists rather than
      // asserting an attribute that must not.
      final String share = activityTags().singleWhere(
        (String tag) => tag.contains('android:name=".ShareActivity"'),
      );
      expect(share, isNot(contains('android:screenOrientation')));

      final String kotlin = File(
        'android/app/src/main/kotlin/com/shoto/app/ShareActivity.kt',
      ).readAsStringSync();
      expect(kotlin, contains('ActivityInfo.SCREEN_ORIENTATION_PORTRAIT'));
      expect(kotlin, contains('lockToPortrait()'));
      // The override is what keeps Flutter's own call from coming back across
      // the channel as an error on that one OS version.
      expect(kotlin, contains('override fun setRequestedOrientation'));
    });
  });

  group('the iOS layer', () {
    final String plist = File('ios/Runner/Info.plist').readAsStringSync();

    /// The `<array>` that follows a given `<key>`, as a list of its strings.
    List<String> arrayAfter(String key) {
      final RegExpMatch? match = RegExp(
        '<key>${RegExp.escape(key)}</key>\\s*<array>(.*?)</array>',
        dotAll: true,
      ).firstMatch(plist);
      expect(match, isNotNull, reason: '$key is missing from Info.plist');
      return RegExp(r'<string>([^<]+)</string>')
          .allMatches(match!.group(1)!)
          .map((Match m) => m.group(1)!)
          .toList();
    }

    test('iPhone supports portrait and nothing else', () {
      expect(arrayAfter('UISupportedInterfaceOrientations'), [
        'UIInterfaceOrientationPortrait',
      ]);
    });

    test('iPad supports portrait and nothing else', () {
      // A separate key, and the one that is easy to miss: trim only the iPhone
      // list and an iPad goes on rotating freely no matter what Dart asks for.
      expect(arrayAfter('UISupportedInterfaceOrientations~ipad'), [
        'UIInterfaceOrientationPortrait',
      ]);
    });

    test('the app declares it requires full screen', () {
      // Required rather than preferred: an iPad app that joins multitasking
      // must support all four orientations, so the trimmed ~ipad list above
      // fails App Store validation without this.
      expect(
        plist,
        contains(RegExp(r'<key>UIRequiresFullScreen</key>\s*<true\s*/>')),
      );
    });

    test('nothing overrides the plist in Swift', () {
      for (final String path in const [
        'ios/Runner/AppDelegate.swift',
        'ios/Runner/SceneDelegate.swift',
      ]) {
        expect(
          File(path).readAsStringSync(),
          isNot(contains('supportedInterfaceOrientations')),
          reason:
              '$path overrides the orientations the plist declares, which '
              'silently wins over it.',
        );
      }
    });
  });

  group('nothing unlocks it again', () {
    test('main is the only place that sets a preferred orientation', () {
      final List<String> offenders = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((File f) => f.path.endsWith('.dart'))
          .where(
            (File f) =>
                f.readAsStringSync().contains('setPreferredOrientations'),
          )
          .map((File f) => f.path.replaceAll(r'\', '/'))
          .toList();

      // A fullscreen viewer or a video player that allows landscape and
      // restores the lock in `dispose` is the classic way this requirement
      // rots: the restore is skipped on one exit path and the whole app is
      // left rotatable. Shoto has no such screen, and this is what notices the
      // day one is added.
      expect(offenders, ['lib/main.dart']);
    });
  });
}
