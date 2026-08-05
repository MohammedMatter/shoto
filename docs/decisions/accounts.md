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

## Now there is no account at all

Firebase, Google Sign-In, Sign in with Apple, the `auth` feature, the profile
card and the Account group are gone, along with the `google-services` Gradle
plugin and `Firebase.initializeApp` — which was the slowest single step in
launching the app.

The claim that nothing leaves this phone is now **structural rather than a
promise**: there is no SDK left that could send anything.

**Still true in the source:** the library belongs to `LocalIdentity`, a random
id minted on first launch and kept in `SharedPreferences`. Every data source
scopes its rows by it.

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
