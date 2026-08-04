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
///    The list is deliberately small — a long one turns a one-second decision
///    into a menu.
/// 3. **Every one of them can be finished.** That is why "remember" is not
///    here: remembering is what saving a screenshot already is, and an intent
///    that can never be completed would put another number on the screen that
///    only ever goes up. This app has enough of those.
enum ScreenshotIntent {
  buy('buy'),
  read('read'),
  reply('reply'),
  tryIt('try'),
  visit('visit');

  /// Stored in the database, so these strings are permanent.
  ///
  /// Kept separate from the Dart name on purpose: `tryIt` exists only because
  /// `try` is a keyword, and a column full of the word "tryIt" would leak that
  /// accident into the data forever.
  final String id;

  const ScreenshotIntent(this.id);

  /// Null for anything unrecognised — a value written by a newer build, or a
  /// row corrupted. Unknown intents are dropped rather than guessed at, so an
  /// old app reading a new database simply sees a screenshot with no intent
  /// instead of inventing one.
  static ScreenshotIntent? fromId(String? id) {
    if (id == null) return null;
    for (final ScreenshotIntent intent in ScreenshotIntent.values) {
      if (intent.id == id) return intent;
    }
    return null;
  }
}

/// A screenshot's intent together with whether it has been dealt with.
///
/// The two are stored separately because they answer different questions and
/// change at different times: the intent is set once, at capture; done-ness
/// flips later, possibly more than once if somebody un-ticks it.
class IntentState {
  final ScreenshotIntent intent;

  /// When the user ticked it off, or null while it is still waiting.
  ///
  /// A timestamp rather than a boolean because "what did I finish this week"
  /// is a question worth being able to answer later, and a boolean throws that
  /// away for no saving.
  final DateTime? doneAt;

  const IntentState({required this.intent, this.doneAt});

  bool get isWaiting => doneAt == null;
  bool get isDone => doneAt != null;
}
