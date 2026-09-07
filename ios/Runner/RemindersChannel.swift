import Flutter
import UIKit
import UserNotifications

/// The iOS half of reminders — the same `shoto/reminders` channel Android
/// answers, backed by `UNUserNotificationCenter` instead of `AlarmManager`.
///
/// Dart is untouched by which of the two is underneath. Every decision about
/// *when* a reminder fires — the presets, what "this evening" means, refusing
/// a time that has already gone — lives in `reminder_times.dart`, and both
/// platforms are handed a moment and a translated pair of strings. What is
/// here is only what needs the system notification centre.
///
/// ## What iOS gives away for free
///
/// `ReminderScheduler.kt` carries three pieces of machinery this file does not
/// need, and it is worth saying why rather than leaving the asymmetry to look
/// like something missing:
///
/// * **No boot receiver.** Android drops every alarm on restart, so Kotlin
///   keeps its own mirror of what is pending and re-arms from it. Pending
///   `UNNotificationRequest`s are held by the system and survive a reboot, so
///   there is nothing to mirror and nothing to put back.
/// * **No request-code hashing.** Android identifies a `PendingIntent` by an
///   int derived from the asset id, which is what makes replacing and
///   cancelling work. Here the identifier *is* a string: adding a request with
///   an identifier that already exists replaces it, which is the exact
///   behaviour Android buys with arithmetic and `FLAG_UPDATE_CURRENT`.
/// * **No inexactness trade.** `setAndAllowWhileIdle` costs up to an hour of
///   slack on a distant alarm because the exact APIs need a Play-reviewed
///   permission. `UNCalendarNotificationTrigger` fires at the minute it was
///   given, with no permission beyond the one this feature already asks for.
///
/// ## The ceiling that does exist
///
/// **iOS holds at most 64 pending notification requests per app.** Past that,
/// `add` fails silently — the reminder is written to the database, shows in
/// the app, and never rings. Nothing here works around it, deliberately: the
/// alternatives are to refuse the 65th reminder (a cap the user never agreed
/// to) or to drop the furthest-out one to make room (losing a reminder without
/// saying so), and both are worse than a limit no real library reaches. If
/// that stops being true, the fix is to keep the soonest 64 armed and re-arm
/// the rest on foreground — not to raise a number.
final class RemindersChannel: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate {
    private static let channelName = "shoto/reminders"

    /// Namespaced, so a reminder's identifier can never collide with anything
    /// else this app schedules later, and so `cancel` can only ever remove
    /// what this file put there.
    private static let identifierPrefix = "shoto.reminder."

    private static let assetIdKey = "assetId"

    /// One instance, because it is two things at once: the channel's method
    /// handler and the notification centre's delegate. Those are installed at
    /// different moments — the delegate before the app finishes launching, the
    /// channel when the engine comes up — and they have to share
    /// [pendingAssetId] across that gap.
    static let shared = RemindersChannel()

    /// The screenshot the user arrived here by tapping, handed to Dart once
    /// and then cleared.
    ///
    /// Cleared for the same reason Android clears its intent extra: without
    /// it, every later resume would reopen the same screenshot long after the
    /// reminder was dealt with. `MainShellPage` asks on launch *and* on every
    /// resume, and an ordinary resume is supposed to get nothing.
    private var pendingAssetId: String?

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(shared, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "schedule":
            guard let arguments = call.arguments as? [String: Any],
                  let assetId = arguments["assetId"] as? String,
                  let at = arguments["at"] as? NSNumber
            else {
                result(
                    FlutterError(
                        code: "bad_args",
                        message: "assetId and at are required",
                        details: nil
                    )
                )
                return
            }

            schedule(
                assetId: assetId,
                // Dart sends `millisecondsSinceEpoch`; `Date` counts seconds.
                at: Date(timeIntervalSince1970: at.doubleValue / 1000),
                title: arguments["title"] as? String ?? "",
                body: arguments["body"] as? String ?? "",
                result: result
            )

        case "cancel":
            guard let arguments = call.arguments as? [String: Any],
                  let assetId = arguments["assetId"] as? String
            else {
                result(
                    FlutterError(
                        code: "bad_args",
                        message: "assetId is required",
                        details: nil
                    )
                )
                return
            }
            cancel(assetId: assetId)
            result(nil)

        case "notificationsEnabled":
            authorizationState { state in
                DispatchQueue.main.async { result(state != .blocked) }
            }

        // Consumed exactly once — see [pendingAssetId].
        case "consumeLaunchAssetId":
            result(pendingAssetId)
            pendingAssetId = nil

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Arms one, replacing any earlier reminder for the same screenshot, and
    /// reports whether it will actually be seen.
    ///
    /// **The permission is asked for here**, at the moment somebody sets their
    /// first reminder, which is the only moment the request explains itself —
    /// the same reasoning as `requestNotificationsIfNeeded` on Android. Unlike
    /// Android, the answer is *waited for* before replying:
    /// `ActivityCompat.requestPermissions` is fire-and-forget, so Kotlin has
    /// to report the state from before the dialog and can tell a user their
    /// notifications are off a second before they turn them on. Here the reply
    /// is the real one, and "this will not reach you" only reaches somebody
    /// who actually declined.
    ///
    /// The reminder is armed either way. A user who says no to the prompt
    /// still has it in the app and on the Reminders page, exactly as a user
    /// who turned notifications off in Settings does.
    private func schedule(
        assetId: String,
        at: Date,
        title: String,
        body: String,
        result: @escaping FlutterResult
    ) {
        authorize { granted in
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            // What the tap has to carry, and the only reason the screenshot is
            // still identifiable by the time `didReceive` runs.
            content.userInfo = [Self.assetIdKey: assetId]

            // A wall-clock moment rather than an interval from now, because
            // that is what the user picked. An interval trigger would also
            // have to be strictly positive, which turns a reminder set for a
            // moment that has only just passed into a thrown exception instead
            // of an alarm that quietly never fires — and Dart already refuses
            // those before they reach the channel.
            let fields = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: at
            )

            let request = UNNotificationRequest(
                identifier: Self.identifier(for: assetId),
                content: content,
                trigger: UNCalendarNotificationTrigger(
                    dateMatching: fields,
                    repeats: false
                )
            )

            UNUserNotificationCenter.current().add(request) { _ in
                // Back to the platform thread: a `FlutterResult` sent from the
                // notification centre's own queue is a channel reply on a
                // background thread, which is the shape of bug that works
                // until it does not.
                DispatchQueue.main.async { result(granted) }
            }
        }
    }

    /// Takes one off, from both the pending queue and the shade.
    ///
    /// **Clearing a delivered one has no Android counterpart**, and that is an
    /// improvement rather than a divergence: on Android a reminder that has
    /// already fired sits in the shade until it is tapped or swiped, so
    /// removing it from the Reminders page leaves a notification about a
    /// reminder that no longer exists. iOS hands us the ability to tidy that
    /// up, and nothing about it contradicts what the user asked for — they
    /// said remove it.
    private func cancel(assetId: String) {
        let centre = UNUserNotificationCenter.current()
        let identifiers = [Self.identifier(for: assetId)]
        centre.removePendingNotificationRequests(withIdentifiers: identifiers)
        centre.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    private static func identifier(for assetId: String) -> String {
        identifierPrefix + assetId
    }

    // MARK: - Permission

    /// What the notification centre would do with a reminder, reduced to the
    /// three answers this app behaves differently about.
    private enum AuthorizationState {
        /// Asked and granted, in whatever form.
        case granted
        /// Asked and refused. The only state that makes a reminder silent.
        case blocked
        /// Never asked. Not the same as refused — see [authorizationState].
        case unasked
    }

    /// Reads the current state **without prompting**.
    ///
    /// `unasked` is kept apart from `blocked` because collapsing the two is how
    /// this would report a lie on a fresh install. Android is enabled by
    /// default and only turns false when somebody switches it off, so "are
    /// notifications enabled" there means "has anybody switched this off". iOS
    /// starts at `notDetermined`, and answering false for it would tell a user
    /// their notifications are off and send them to Settings to fix a switch
    /// they have never been shown. So `notificationsEnabled` treats anything
    /// but a refusal as yes, and the honest answer for the unasked case
    /// arrives from [schedule], which prompts and then reports what was chosen.
    private func authorizationState(
        _ completion: @escaping (AuthorizationState) -> Void
    ) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let state: AuthorizationState
            switch settings.authorizationStatus {
            case .notDetermined: state = .unasked
            case .denied: state = .blocked
            // `.authorized`, `.provisional`, `.ephemeral`, and whatever a later
            // iOS adds. Everything that is not a refusal will either show the
            // notification or ask first.
            default: state = .granted
            }
            completion(state)
        }
    }

    /// Resolves to whether a reminder will be seen, prompting once if the user
    /// has never been asked.
    private func authorize(_ completion: @escaping (Bool) -> Void) {
        authorizationState { state in
            switch state {
            case .granted:
                completion(true)
            case .blocked:
                completion(false)
            case .unasked:
                UNUserNotificationCenter.current().requestAuthorization(
                    // No badge: nothing in Shoto counts, and asking for a
                    // permission the app does not use is how a prompt starts
                    // to look like an overreach.
                    options: [.alert, .sound]
                ) { granted, _ in
                    completion(granted)
                }
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// The tap. Records which screenshot it was about, for Dart to collect.
    ///
    /// On a cold launch iOS holds the response until a delegate exists, which
    /// is why `AppDelegate` installs one before launching finishes rather than
    /// when the engine comes up — otherwise the response is dropped and the
    /// reminder merely opens the app on whatever screen it was left on, which
    /// is the one outcome that makes a reminder feel broken: it fired, and it
    /// did nothing.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let assetId =
            response.notification.request.content.userInfo[Self.assetIdKey] as? String
        {
            pendingAssetId = assetId
        }
        completionHandler()
    }

    /// Shows the reminder even while Shoto is open.
    ///
    /// iOS suppresses notifications for the foreground app by default, which is
    /// right for a chat message and wrong for this: the user asked to be
    /// interrupted at this moment, and swallowing it because they happen to be
    /// looking at a different screenshot is the app deciding it knows better.
    /// Android never had the choice — a posted notification is posted.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }
}
