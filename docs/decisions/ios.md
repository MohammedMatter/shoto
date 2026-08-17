# iOS

A decision that has been drifting, written down so it stops drifting.

## Where iOS actually is

`ios/` contains `Runner` and nothing else. The app icon and launch image are
generated for it (`tool/generate_brand_assets.dart` writes all sixteen icon
sizes), the Dart is portable, and the pure-Dart core — the stitcher, the
sensitive-data matchers, the redaction compositor — has no platform in it at
all.

**The capture flow is entirely Android.** Quick Save is a Kotlin
`ShareActivity` with `BackgroundMode.transparent`, a translucent theme, and a
`shoto/share` method channel. None of that ports:

- iOS needs a **Share Extension**, which is a separate binary target with its
  own bundle id, entitlements and memory limit.
- The extension cannot see the app's documents. It needs an **App Group** and
  the database, preferences and image cache all have to move into the shared
  container — which touches `AppDatabase`, `AppPreferences`, `CacheService` and
  every path helper.
- A Share Extension cannot run a Flutter engine cheaply. Either the sheet is
  rebuilt in SwiftUI — a second implementation of the seven-stage flow, in
  another language, that has to stay in agreement with this one — or it hands
  off to the host app, which loses the entire point of not opening the app.

That is not "some iOS work later". It is a second implementation of the core
flow, and the estimate that matters is the one for keeping two of them
agreeing forever.

## The two honest options

**Ship Android-only, and say so.** The store listing, the landing page and the
Instagram bio all say Android. Nobody downloads a shell. The cost is that iOS
is where the paying users are.

**Scope the extension as a real project.** App Group, shared container,
migration of every path in the app, a SwiftUI capture sheet, and a policy for
which half owns what. Weeks, not evenings, and none of it moves the product
forward for the people who can already use it.

**Drifting is the expensive option**, and it is the one currently in effect:
every session adds Android-side behaviour that the iOS half will eventually
have to match.

## What is already true either way

- **The triage queue is Android-only by construction.** It reads an album
  named `Screenshots`; iOS exposes screen captures as a smart album rather
  than by name, so the iOS path would need its own lookup. Left unwritten
  rather than half-written — see
  `ScreenshotGalleryDataSource._captureAlbumNames`.
- **Nothing else in the app assumes Android**, and the ML Kit dependencies,
  RevenueCat and `photo_manager` all have iOS implementations.

## Decision

Not taken yet. This file exists so the next person finds a costing rather than
an assumption, and so "we'll do iOS later" stops being a sentence anybody can
say without a number attached.
