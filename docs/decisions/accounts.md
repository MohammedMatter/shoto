# Accounts

This one has been decided three times in opposite directions. All three
arguments are here, because each was right about something and the next
decision has to answer all of them rather than rediscover one.

## Where it stands

**Onboarding, then sign in, then the app.** Google or Apple, no skip. Signing
out returns to the sign-in screen and leaves the library, the folders and every
setting exactly where they are.

## Round one: it was a wall, and it bought nothing

`/home` was gated on a Firebase account, on the first screen, before the app
showed anything at all.

What signing in bought the user was nothing measurable. There is no cloud.
Backup is a local zip. The uid scoped rows in a sqlite file so two Google
accounts on one phone would not see each other's folders — a problem
approximately nobody has. So it cost every new user an identity handoff to a
third party to see an empty library, in an app whose positioning is that
nothing leaves your phone.

## Round two: no account at all

The wall came down and the whole feature went with it. The library moved to
`LocalIdentity` — a random id minted on first launch, kept in
`SharedPreferences` — and RevenueCat was keyed to that.

This was genuinely better in three ways, and they are the ones to protect
whatever else changes:

- **Launch got faster.** `Firebase.initializeApp` was the slowest single step
  in starting the app.
- **Nothing gated the first screen.**
- **The privacy claim became structural** rather than a promise: with no SDK
  that could send anything, "nothing leaves this phone" was not a policy, it
  was a fact about the binary.

Then a real gap appeared. **Google does not move a subscription between Google
accounts** — no button, no setting, no support request. So a user who buys Pro,
changes phone *and* changes their Google account has no way back: "Restore
purchases" asks the store about whoever is signed in now and gets nothing.

## Round three: an optional email account, and why that was not it either

The first answer to that gap was a lazily-loaded email/password account,
offered after a purchase and after a failed restore, never as a gate.

It solved the problem and was rejected anyway, for a reason worth recording:
**it was more machinery than the person maintaining it wanted to hold in their
head.** Two sign-in concepts, one of them invisible until a specific failure,
plus a lazily-initialized SDK, plus a sheet with its own error vocabulary — to
save a user one tap in an uncommon case.

That is a legitimate reason to reject a design, and it is not the same as the
design being wrong.

## What is true of the current shape

- **It is a wall again**, which is what round one was reversed for. That cost
  is real and it is being paid deliberately.
- **It answers the subscription question completely.** Signing in with the same
  account on any phone restores Pro regardless of which Google account the
  store is using.
- **The account still carries nothing else.** No folders, no favourites, no
  screenshots. Anyone tempted to add sync should read `library-intake.md`
  first, and change the privacy note in the same commit.

## If this is revisited a fourth time

The middle option nobody has built: keep the wall off, and make the sign-in
screen skippable — the same screen, with a "Not now" that lands on Home. It
gives round two's conversion and round three's recovery path without a second
sign-in concept anywhere in the app. It is a one-line route change and a
button.
