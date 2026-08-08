# SHOTO

A screenshot app built around one question: **can I send this picture without
sending what is in it?**

Safe Share reads a screenshot, finds the card numbers, IBANs, addresses, names
and contact details in it, and covers them — with a solid block, never a
plausible-looking substitute. Everything else in the app exists to make that
worth opening: a library you can search by what a picture *shows*, actions
lifted out of a screenshot's text, duplicate cleanup, and merging a scrolling
capture back into one tall image.

## The rule the whole app is built on

**Your gallery is never read.** Nothing enters the library except what you hand
over — shared into SHOTO, picked in the system picker, or answered in the
optional queue of new captures. That constraint decides more of this codebase
than any framework choice, and where a feature would have been easier without
it, the feature changed instead.

Recognition runs entirely on the device. No screenshot is uploaded, at any
point, for any feature.

## Running it

```bash
flutter pub get
flutter run
```

Tests, including golden files:

```bash
flutter test
```

Requires the Dart SDK in `pubspec.yaml`'s `environment` block.

**Android only, deliberately.** `ios/` builds, and the pure-Dart core — the
stitcher, the sensitive-data matchers, the redaction compositor — has no
platform in it. The capture flow does: sharing into SHOTO without opening it is
a Kotlin activity, and the iOS equivalent is a Share Extension with its own
bundle, an App Group holding the database, and a second implementation of the
save flow to keep in agreement with this one forever. The reasoning is written
out in [docs/decisions/ios.md](docs/decisions/ios.md).

## Layout

`lib/features/<feature>/` in clean-architecture layers — `data/` (data sources,
repository implementations), `domain/` (entities, repository interfaces, use
cases), `presentation/` (blocs, pages, widgets). Anything shared sits in
`lib/core/`.

The features:

| | |
|---|---|
| `safe_share` | Find private details in a screenshot and cover them |
| `smart_actions` | Links, emails, codes, IBANs, events, addresses, parcels, Wi-Fi |
| `screenshots` | The library — search, filters, content traits, intents |
| `folders` | Manual filing |
| `duplicates` | Perceptual-hash cleanup |
| `stitch` | Merge overlapping scroll captures |
| `quick_save` · `shell` · `home` · `settings` · `onboarding` · `backup` · `auth` · `subscription` | The rest of the app around them |

## Languages

Seven: English, German, Spanish, French, Italian, Dutch, Portuguese.

The list is not a marketing decision. On-device text recognition can read Latin
script and nothing else, so a language whose script the recogniser cannot
return is a language where search, Safe Share and Smart Actions silently do
nothing — see
[docs/decisions/shipped-languages.md](docs/decisions/shipped-languages.md).

## docs/decisions

Read this before changing anything that looks arbitrary. It records *why*
things are the way they are when the reason is a history rather than a rule —
including several decisions that were made, reversed, and made again.

Start with [docs/decisions/README.md](docs/decisions/README.md), which explains
what belongs there versus in a source comment.
