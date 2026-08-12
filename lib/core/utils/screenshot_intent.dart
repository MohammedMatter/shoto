/// What the user meant to *do* with a screenshot, chosen by them in one tap at
/// the moment they saved it.
///
/// **This is not a description, and the difference is the whole feature.** A
/// description says what is in the picture — which the app already knows, from
/// OCR, from the vision labels, from the content filters. An intent says what
/// the person was going to do about it, which nothing in the picture can
/// reveal: the same photograph of a shoe is "buy this", "show this to Sara"
/// and "remember not to buy this", and only the person who took it knows
/// which.
///
/// Three properties are load-bearing, and dropping any of them turns this back
/// into the auto-filing features that were deleted twice:
///
/// 1. **The user states it.** Nothing here is inferred. There is no confidence
///    score because there is nothing to be confident about.
/// 2. **One tap, from a short list.** Anything requiring typing at capture
///    time will be skipped by everybody, walking down the street, every time.
/// 3. **Every one of them can be finished.** That is why "remember" is not
///    here: remembering is what saving a screenshot already is, and an intent
///    that can never be completed would put another number on the screen that
///    only ever goes up. This app has enough of those.
///
/// ## Why there are now fifteen of these and not five
///
/// Rule 2 used to be enforced by keeping the *vocabulary* short, which is not
/// the same thing and cost more than it saved. A person whose screenshot is a
/// recipe has to file it under "try" or under nothing, and both answers are
/// lies — so they stop answering, and the feature dies of not describing
/// anyone's actual life.
///
/// What rule 2 actually protects is the length of the row **on screen**, and
/// that is now protected directly: the picker shows five chips, chosen by what
/// this person keeps using, and everything else lives one tap further away
/// behind `+`. The common case stays a single tap no matter how long this enum
/// grows; see `IntentPickerRow`.
///
/// Rule 3 still binds absolutely, and it is what keeps this list from becoming
/// a tag cloud. Every verb below is something that is at some point *done*.
enum ScreenshotIntent {
  buy('buy'),
  read('read'),
  reply('reply'),
  tryIt('try'),
  visit('visit'),
  watch('watch'),
  listen('listen'),
  cook('cook'),
  book('book'),
  pay('pay'),
  send('send'),
  download('download'),
  apply('apply'),
  compare('compare'),
  fix('fix');

  /// Stored in the database, so these strings are permanent.
  ///
  /// Kept separate from the Dart name on purpose: `tryIt` exists only because
  /// `try` is a keyword, and a column full of the word "tryIt" would leak that
  /// accident into the data forever.
  final String id;

  const ScreenshotIntent(this.id);

  /// Null for anything unrecognised — a value written by a newer build, a
  /// custom intent's id, or a row corrupted. Unknown intents are dropped
  /// rather than guessed at, so an old app reading a new database simply sees
  /// a screenshot with no intent instead of inventing one.
  static ScreenshotIntent? fromId(String? id) {
    if (id == null) return null;
    for (final ScreenshotIntent intent in ScreenshotIntent.values) {
      if (intent.id == id) return intent;
    }
    return null;
  }
}

/// One intent a screenshot can carry: either one this app shipped, or one this
/// person wrote themselves.
///
/// **Both kinds are the same thing everywhere except where they are made.** A
/// screenshot filed under a custom "return it" is waiting exactly as hard as
/// one filed under "buy", appears in the same places, is counted by the same
/// number and is ticked off the same way. Modelling that as one type rather
/// than as an enum with a nullable string beside it is what stops the second
/// kind from quietly becoming a lesser citizen in half the widgets.
///
/// Equality is on [id] alone, because [id] is what the database stores and
/// what every lookup is keyed by. Two `CustomIntent`s with the same id and a
/// different label are the same intent mid-rename, not two intents.
sealed class IntentRef {
  const IntentRef();

  /// What goes in `screenshot_meta.intent`. Permanent.
  String get id;

  /// Marks an id as belonging to a user-authored intent.
  ///
  /// A prefix rather than a separate column: the column already exists and is
  /// full of built-in ids, and a prefixed namespace means the existing rows,
  /// the existing queries and the existing migration all keep working
  /// untouched. `ScreenshotIntent.fromId` returns null for anything starting
  /// with this, which is exactly right — it is not one of those.
  static const String customPrefix = 'c:';

  static bool isCustomId(String id) => id.startsWith(customPrefix);

  /// Where a verb sits in the one canonical order: built-ins as declared, then
  /// the user's own after all of them.
  ///
  /// **Here rather than on whoever needs it**, because two places now sort the
  /// same list — the loaded state's `waitingByIntent` and the summary the app
  /// boots from before the gallery has been read. Those two both feed Home's
  /// inbox, one right after the other, so a second copy of this ordering would
  /// show up as the tags visibly reshuffling the moment the real read lands.
  static int pickerOrder(IntentRef ref) => switch (ref) {
    BuiltInIntent(:final ScreenshotIntent intent) => intent.index,
    CustomIntent(:final int sortOrder) =>
      ScreenshotIntent.values.length + sortOrder,
  };

  @override
  bool operator ==(Object other) => other is IntentRef && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// One of the verbs Shoto ships, translated into the user's language.
final class BuiltInIntent extends IntentRef {
  final ScreenshotIntent intent;

  const BuiltInIntent(this.intent);

  @override
  String get id => intent.id;
}

/// A verb this person wrote for themselves.
///
/// The label is **not** localized and must never be run through the l10n
/// lookups the built-ins use: it is the user's own words, in whatever language
/// they typed it, and translating it would be putting words in their mouth.
final class CustomIntent extends IntentRef {
  /// Always carries [IntentRef.customPrefix], so an id alone is enough to know
  /// which kind of intent it names without consulting any table.
  @override
  final String id;

  final String label;

  /// Names a glyph in `IntentIcons`, not an icon code point.
  ///
  /// A key rather than the `IconData` itself because this row is written by
  /// the data layer and read back after an app update: storing a code point
  /// would pin the database to whatever Flutter's icon font happened to
  /// contain on the day it was written, and tree-shaking treats non-constant
  /// `IconData` as a reason to ship the whole font.
  final String iconKey;

  /// Where it sits in the full picker, low first. Creation order by default.
  final int sortOrder;

  const CustomIntent({
    required this.id,
    required this.label,
    required this.iconKey,
    required this.sortOrder,
  });
}

/// A screenshot's intent together with whether it has been dealt with.
///
/// The two are stored separately because they answer different questions and
/// change at different times: the intent is set once, at capture; done-ness
/// flips later, possibly more than once if somebody un-ticks it.
class IntentState {
  final IntentRef ref;

  /// When the user ticked it off, or null while it is still waiting.
  ///
  /// A timestamp rather than a boolean because "what did I finish this week"
  /// is a question worth being able to answer later, and a boolean throws that
  /// away for no saving.
  final DateTime? doneAt;

  const IntentState({required this.ref, this.doneAt});

  bool get isWaiting => doneAt == null;
  bool get isDone => doneAt != null;
}
