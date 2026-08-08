# The app ships in what the recogniser can read

Arabic, Urdu and Hindi were replaced by German, Italian, Portuguese and Dutch.
The shipped set is now English, German, Spanish, French, Italian, Portuguese
and Dutch — seven languages, all Latin script.

This was not a market decision dressed up as a technical one. It is the
technical one, and the market follows from it.

## The problem

[`text_recognition_data_source.dart`](../../lib/features/screenshots/data/data_sources/text_recognition_data_source.dart)
constructs its recogniser with `TextRecognitionScript.latin`, and that is the
only model bundled. ML Kit's on-device text recognition has no Arabic model at
all.

Almost everything SHOTO sells reads the words inside a screenshot:

- **Search** matches recognised text.
- **Safe Share** finds what is private in recognised text.
- **Smart actions** pulls links, codes and IBANs out of recognised text.
- **Content filters** derive every trait from recognised text.

So for somebody using the app in Arabic — the author's own language, and the
first this app was ever asked for — a screenshot of an Arabic UI returned
nothing at all. Not a poor result: an empty string. Four paid or headline
features, silently doing nothing, in a fully translated interface that gave no
hint why.

The clearest evidence was in the code rather than on the screen.
`ActionExtractor._codeCues` had held, for several releases:

```dart
'رمز', 'كود', 'التحقق', 'تحقق', 'السري',
'कोड', 'सत्यापन', 'ओटीपी',
'کوڈ', 'تصدیقی', 'پاس ورڈ',
```

Careful, reviewed, translated into three scripts — and unreachable. The rule
searches the text the recogniser returned, and the recogniser cannot return
those characters. `ContentTraits._phoneCues` carried the same dead vocabulary,
and so did the place, Wi-Fi and tracking extractors.

The tests were green over all of it, because a test hands `ContentTraits.of` a
string directly. Nothing on a phone ever did.

## Why replace rather than fix

Adding an Arabic OCR model is a real option and a much larger one: a different
engine, its own accuracy work against real Arabic screenshots, and APK size on
top of the ~20-30MB ML Kit already costs. It is a project, not a change.

Shipping a language whose features do not work is worse than not shipping it.
The four that came in are covered by the model already bundled — German,
Italian, Portuguese and Dutch are Latin script, so search, Safe Share and the
extractors work in them on day one, with no new dependency and no extra byte
of model.

## What changed

- `AppLanguage` lost `arabic`, `urdu`, `hindi` and gained `german`, `italian`,
  `portuguese`, `dutch`. Four new `.arb` files, 511 keys each, checked for
  parity by `localization_test.dart` — which now reads its locale list *from*
  `AppLanguage` so it cannot go stale the way it did here.
- Three Noto faces deleted from `pubspec.yaml` and `assets/fonts`: **2.2MB**.
  Text the user types in another script now falls back to the platform's own
  fonts, which Android and iOS both ship.
- Cue vocabulary swapped, not just deleted: German, Italian, Portuguese and
  Dutch words were added everywhere the dead ones were removed. A German
  screenshot saying *Bestätigungscode* is now recognised as carrying a code,
  which it was not before this change either.

  All seven lists were done, not just the two that started it: `sensitive_data`
  (Safe Share's labels for names, addresses, IDs and order numbers),
  `tracking_extractor` (DHL, DPD, Hermes, GLS, PostNL, CTT, Correos and
  Colissimo replacing carriers with no presence in the new markets),
  `wifi_extractor`, `place_extractor` (the *Hauptstraße 12* and *Via Roma 12*
  word orders, which the Arabic rule's shape could not express) and
  `event_extractor`.

## Two gaps the swap exposed

Neither is a regression — both were broken before and nobody had looked,
because until this change no shipped language wrote a date that way.

- **German writes the day as an ordinal.** *15. Oktober 2026* is the ordinary
  prose form and *15. Okt. 2026* its abbreviation, and the day separator
  carried space and comma only, so both found nothing. A dot is now allowed in
  two tightly placed spots — after the day digits, and after a month name —
  and deliberately *not* in the separator itself, because a dot between month
  and year would make `1.2.30` a date rather than a version number.
- **German states the hour with a word.** *20 Uhr* is how a card writes eight
  in the evening. It is kept apart from the AM/PM list rather than folded in,
  because it means the opposite thing: a meridiem folds twelve onto
  twenty-four, `Uhr` asserts the number is already twenty-four, and merging
  them turns *20 Uhr* into thirty-two o'clock.

## The Hijri calendar survived, and that is not an inconsistency

The Arabic month spellings went the way of every other unreachable cue. The
converter did not, and the distinction is worth stating because the obvious
move — delete the vocabulary, delete the dependency — would have thrown away a
live feature.

**`15/9/1447` contains no Arabic.** It is digits and a slash, and a four-digit
year in the fourteen-hundreds identifies itself: no Gregorian date this feature
would accept has one. A Gulf app rendering its interface in English still hands
that over intact. The romanised month names (*Ramadan*, *Rabi al-awwal*,
*Dhul-Hijjah*) are Latin text for the same reason, and they were widened —
there is no standard transliteration, so the table now holds the `dh`/`zul`,
`-`/space and ordinal (`Rabi I`) variants that were previously carried by the
Arabic spelling alone.

The same test distinguishes the two cases generally: **a digit fold is
preprocessing, a cue word is a match target.** `ActionExtractor.normalizeDigits`
rewrites ٠-٩ before any rule sees the text and costs nothing when they never
arrive. A cue word that can only match characters the recogniser cannot produce
is not cheap — it is a line of code asserting a capability the app does not
have. That is why the digits stayed and the words went.

## What did not change

**Right-to-left support stays**, deliberately, though no shipped language uses
it. `AppLanguage.isRightToLeft`, `fontFallback` and `lineHeightScale` all
remain and all sit at their defaults — they are the three things a non-Latin
language needs, and keeping them is what makes bringing one back a string
table rather than an audit of the type scale. A forced-RTL golden
(`home_rtl.png`) exercises the mirroring so it cannot rot unnoticed.

**Content handling for other scripts stays.** The app's language and the
screenshot's language are different questions.
`ActionExtractor.normalizeDigits` still rewrites Arabic-Indic digits, and
`RedactionService` still lays out right-to-left runs, because both read what
was *recognised* — and the day a recogniser returns those characters, the rest
of the pipeline should already be ready for them.

## If this is re-proposed

Bringing Arabic back is not a translation task. The order is: a recogniser
that reads the script, measured against real screenshots, **then** the string
table, the font, and the cue vocabulary. Doing it in the other order is
exactly what produced eleven dead cue words and a green test suite.
