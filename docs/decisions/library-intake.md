# Library intake

How screenshots get into SHOTO, and the two reversals it took to get here.

## The library used to be the gallery

SHOTO read the device's Screenshots album and listed all of it. That made the
library a mirror of the gallery: opening SHOTO answered *"what do I have?"* —
a question the photo app already answers — and the app could see pictures the
user had never chosen to give it.

It was reversed. Nothing enters the library except by the share sheet or the
system picker, both of which are the user handing something over.

**Still true in the source:** `ScreenshotGalleryDataSource.getScreenshotAssets`
reads SHOTO's own album and nothing else, and it is the only read the library
is built on.

## And then the app was an empty room

The reversal was right and its consequence was not survivable on its own: a
new install is an empty app, and it stays as full as the user's willpower.

The people with four hundred unfindable screenshots are drowning *precisely
because they never curate*. An app that only works for people disciplined
enough to file at capture time works for the people who do not have the
problem.

Two of the paid features appeared to lose their justification at the same
moment — you do not accumulate duplicates in a set assembled by hand — and
were nearly cut for it. The queue below is what put them back: a library fed
forty captures at a time is not a hand-curated one. See
[v1-scope.md](v1-scope.md).

## The third option: an inbox, not a library

The queue reads the Screenshots album, but a capture is *offered*, never kept:

- **Off until switched on**, and the switch is a question in plain words, asked
  once, after there is already a library — not on the first screen, where it
  would read as a permission grab.
- **Nothing enters implicitly.** Keeping runs the same import a picked file
  runs; skipping moves a watermark and touches nothing.
- **Nothing is deleted or moved**, ever. Kept captures are copied; the user's
  original stays in the gallery.
- **Only the Screenshots album**, never the camera roll.

That is the honesty of opt-in with the app full on day one, and the unsorted
count becomes a triage queue with a bottom rather than a chore counter that
only goes up.

## Why the queue runs oldest first

So a half-finished review is resumable. The watermark advances to the last
capture the user decided about, which only means "everything before this is
handled" if the queue is worked from the oldest end.

Newest first would leave two bad options: re-ask about decided captures, or
silently swallow undecided ones. The third option is a table of dismissed ids
that grows forever.

**Still true in the source:** `getDeviceCaptures` sorts ascending and
`AppPreferences.advanceTriageSince` refuses to move backwards. Both are pinned
by `test/triage_queue_test.dart`, along with the rule that nothing is read at
all while the queue is off.
