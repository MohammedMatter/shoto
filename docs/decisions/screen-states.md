# Every screen answers for every state

Not a bug fix. The bug was fixed three times.

## What kept happening

Home shipped with `isLoading: loaded == null`. Four states folded into one, so
a refused photo permission and a failed read both drew the loading branch: the
count, the sentence and the import button vanished, and the first screen of the
app sat blank with no way out of it.

That was fixed. Then `IntentPage` turned out to fold the same four states into
*empty* — and empty there is not blank, it is a green tick and "you're all
done". A screen that had never been allowed to read the gallery was
congratulating the user for clearing it.

That was fixed too. Then Duplicates: an `is!` chain ending in
`SizedBox.shrink()`, so *initial* and *deleted* drew a title bar over nothing —
on the one screen whose entire job is to report a number.

Three screens, one mistake, three correct fixes, and nothing that would have
caught the fourth.

## Why review does not catch it

`if (state is! LoadedState) return const SizedBox.shrink();` reads as a guard.
It is not a guard, it is four branches collapsing into one, and the collapse is
invisible precisely because the code that does it is shorter than the code that
would not. Nothing in the language objected: `is!` costs nothing to write and
says nothing about what was left out.

The same shape appeared in a ternary on the paywall — error on one side,
"everything else" on the other — where the three states inside "everything
else" include a purchase mid-flight.

## The rule

**Every bloc state family is `sealed`, and every screen picks its body with a
`switch` that has no `default`.**

Adding a state is then a compile error at every screen that reads it. Not a
warning, not a lint, not a convention someone has to remember during review —
the app does not build until every screen says what it draws. That is the whole
mechanism, and it is the only part of this document that cannot rot.

`sealed` and not merely `abstract`: `abstract` stops the base class being
instantiated, which was never the problem. Exhaustiveness is.

A `switch` and not an `if` chain: an `if` chain over a sealed type still
compiles with a state missing, and still falls off the end into whatever the
last line does.

## The inventory

| Screen | States | Blank state allowed |
|---|---|---|
| Home | `ScreenshotsState` × 5 | no |
| Library | `ScreenshotsState` × 5 | no |
| Search | `ScreenshotsState` × 5 | no |
| Intent | `ScreenshotsState` × 5 | no |
| Folders | `FoldersState` × 4 | **yes — loading + initial** |
| Duplicates | `DuplicatesState` × 5 | no |
| Merge | `StitchState` × 5 | no |
| Paywall | `SubscriptionState` × 4 | no |
| Auth | `AuthState` × 5 | n/a — see below |
| Settings | no bloc | n/a |

Nineteen cases are drawn and asserted in `screen_states_test.dart`; the four
screens reading `ScreenshotsState` are covered by `blocked_states_test.dart`
and `home_blocked_state_test.dart`, which predate this file and are what it
generalises.

The three ways a library can fail to be a library are drawn once, by
`LibraryUnavailable`, and the four screens reading `ScreenshotsState` all defer
to it. One blocked-state design, four screens, no chance of them disagreeing.

### The one exemption

Folders draws nothing while its folder list is being read. This is deliberate:
the read is a local SQLite query measured in milliseconds, the screen is
re-entered dozens of times a session because the shell reloads on every tab
select, and a spinner there is a flash rather than an explanation. Silence is
the only state on that screen that is never wrong, and there is nothing to
fill.

It is written as its own `switch` arm rather than reached by falling through
one, so the next state added to `FoldersState` cannot inherit the exemption by
accident. `screen_states_test.dart` asserts the silence, which is what keeps it
a decision instead of a leftover.

### Auth is not exempt, it is shaped differently

`AuthPage` draws the same sign-in screen in every state; the states only
decorate it — a spinner inside whichever button was pressed, a snack bar for
an error, a navigation away on success. There is no state in which the screen
has nothing to say, because the screen is what it has to say. No `switch` is
needed where there are no branches.

## The test

`test/screen_states_test.dart` draws every state of every state-bearing screen
and inspects the result. It is the second half of the guard, and it fails
differently from the first:

- The compiler stops a state from being **undrawn**.
- The test stops a state from being **drawn as something it is not**.

The second is the one that bit twice. Nothing about `SizedBox.shrink()` or a
green tick is a compile error; both are perfectly good widgets. So each case
asserts two things — what the user should see, and what they must not: a scan
that has not started must not show "no duplicates found", a failed read must
not show the tick, a failure must not still be spinning.

Every assertion has its inverse somewhere in the file. The success states are
tested too, or "must not show the tick" could be satisfied by deleting the tick.

The `_name` switches at the top of the test file are exhaustive for the same
reason the screens' switches are: adding a state stops the test file compiling
until a sample and an expectation are written for it.

## What it found on its first run

Three bugs, none of them the one it was written for. Drawing every state means
drawing states nobody had looked at in a while, at a real width, with real
strings in them:

- **Merge, ready state.** "Save to gallery" beside its icon overflowed by 38px
  on a 360pt phone. The row gave a third of its width to a one-word text
  button by a fixed `flex` ratio, and a fixed ratio cannot know how long
  either word is — in any of the seven languages.
- **Paywall, loaded state.** "Yearly" and its "Save 73%" badge overflowed by
  127px, because the price beside them is laid out at its intrinsic width and
  takes what it needs first.
- **`PrimaryButton`, everywhere.** The label was a plain `Text` in a
  `mainAxisSize.min` row: it said it wanted to be as wide as its contents, and
  nothing said what to do when it was not allowed to be.

All three are the same shape as the state bugs — a layout that is correct for
the case somebody had in front of them and undefined for the rest. None would
have been caught by opening the app on the developer's phone, which is wider
than 360pt and set to English.

## If this is re-proposed

Someone will eventually want to collapse a `switch` back to
`if (state is LoadedState)` because most of the arms look alike. Three of them
did look alike, on three different screens, and all three were wrong in a way
that reached users. The arms that look alike are the ones worth writing out.
