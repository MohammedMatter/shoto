# Accounts

## There was a sign-in wall, on the first screen

`/home` was gated on a Firebase account. Signed out meant bounced to `/auth`
before the app would show anything at all, and the only ways through were
Google and Apple — there was no guest path.

What signing in bought the user was **nothing**. There is no cloud. Backup is a
local zip handed to the OS share sheet. The uid scoped rows in a sqlite file so
that two Google accounts on one phone would not see each other's folders, which
is a problem approximately zero users have.

So it cost every new user an identity handoff to a third party to see an empty
library, on the first screen, in an app whose whole positioning is that nothing
leaves your phone.

## Then it was optional, and still pointless

The gate came off and `/auth` stayed, reachable from Settings, for the one
thing an account could plausibly do: carry a purchase to a second device.

It could not really do that either. Both stores restore what the same *store*
account bought — that is the account the user paid with, and the only one they
should have to remember. RevenueCat is initialised with the device id so a
reinstall on the same phone restores, and the store handles the rest.

## Then one came back, for one reason

There is one case neither the store nor a device id can answer: **a new phone
signed in to a different Google account.**

Google does not move a subscription between Google accounts. There is no
button, no setting and no support request that does it — the purchase belongs
to the account that paid. So "Restore purchases" asks the store about whoever
is signed in *now*, gets nothing, and the app's answer to "I paid for this" is
a shrug.

An account fixes exactly that, because the entitlement is then keyed to an id
**we** own. `Purchases.logIn()` aliases the anonymous device id to it, so a
purchase made before signing in follows the user in rather than being stranded.

**What it deliberately does not do:**

- It does not move the billing. That stays on the old Google account until it
  lapses, and when it lapses the entitlement goes with it.
- It does not sync the library. Folders, favourites and intents are device-local
  sqlite; syncing them needs a server this app does not have.

**What keeps it from becoming the wall again:**

- **Firebase is initialized on demand**, inside `AccountService`, the first
  time somebody opens the account sheet. A user who never makes an account
  never pays for the SDK — which is what made the old sign-in so expensive:
  `Firebase.initializeApp` was the slowest single step in launching the app,
  for something most sessions never touched.
- **It is offered in exactly two places**: after a purchase, and when a restore
  comes back empty. Both are moments where an account has just become worth
  something. Never on the first screen, never as a gate.
- **One field pair, no sign-in/sign-up choice.** Whether an account exists for
  an address is something the server knows and the user usually does not.

**Still true in the source:** nothing in the app may assume Firebase is
initialized. Every method in `AccountService` calls `_ready()` first, and no
other file imports `firebase_core`.

## The library still has no account at all

Google Sign-In, Sign in with Apple, the `auth` feature, the profile card, the
mandatory gate and the `google-services` Gradle plugin are all gone, and none
of them came back with the account above.

**Still true in the source:** the library belongs to `LocalIdentity`, a random
id minted on first launch and kept in `SharedPreferences`. Every data source
scopes its rows by it, and signing in changes none of that — an account moves
an entitlement, not a library.

## What the privacy note may claim

It used to say *"SHOTO never reads your gallery… nothing is ever uploaded."*
Neither half survived contact with the product:

- The triage queue reads the Screenshots album, when switched on.
- An account sends an email address, when created.

Both are opt-in and both are worth having, but a promise with two silent
exceptions is not a promise. The note now says what is unconditional — *your
pictures are never uploaded* — and then names the two things the user
themselves switches on. Anything added later that leaves the device belongs in
that sentence on the same day it is written.

## The one thing the account was really used for

Safe Share read the signed-in user's name. That is not incidental — a name is
the only private detail with no checksum and no label to find it by. "Ahmed
Khalil" on a line by itself is a name only if you already know whose screenshot
this is.

It is a field in Settings now: typed once, optional, and more accurate, because
the name on somebody's email is often not the name their bank prints.

**Still true in the source:** `AppPreferences.ownerName` is the only personal
string SHOTO asks anybody to type, and `RedactionService` treats empty as a
fine answer.
