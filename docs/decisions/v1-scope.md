# What version one contains

Everything that was built. This file exists because that was very nearly not
the case, and the argument is worth keeping so it does not get re-proposed
from scratch.

## Cutting Duplicates and Stitch was proposed, built, and reversed

The case for cutting them:

- **Duplicates.** Both features were written while Shoto read the whole device
  gallery. In a library assembled by hand, one deliberate share at a time, you
  do not accumulate duplicates — so the honest result of a scan is "nothing
  found", which is a poor thing to charge for.
- **Stitch.** It needs two to five overlapping long-scroll captures, shared in
  and then multi-selected. The capture cost is higher than the merge saves, and
  the phones most likely to be used for it have scrolling capture in the
  shutter already.
- **The pitch.** Three features that work are easier to say in one sentence
  than five, and a paywall you can explain in a sentence is a paywall people
  read.

They were hidden behind a `V1Features` flag, and then the flag was removed and
both were put back. Two things decided it:

**The premise moved again.** The triage queue — added in the same session —
reads the device's Screenshots album and offers captures forty at a time, and
first-run bulk import brings in whatever the user multi-selects. Somebody
working quickly through a queue of forty *will* keep two shots of the same
thing. The library is no longer purely hand-curated, so the argument that it
cannot accumulate duplicates no longer holds. See
[library-intake.md](library-intake.md).

**The Stitch premise was never checked.** "The phones most likely to be used
for it have scrolling capture in the shutter already" was written above as a
fact and was never verified against a device. The project's own reference
phone — a Xiaomi on MIUI 14 / Android 13, the handset this app is developed
and tested on — does not offer it. One handset is not the market, and where a
phone does have scrolling capture it is genuinely a substitute; but a claim
that cannot be checked is not load-bearing, and this one was carrying an
argument to delete a working feature.

The copy no longer argues with the shutter at all, because it does not have
to. Scrolling capture, on a phone that has it, must be started while you are
still looking at the page. Stitch runs afterwards, on screenshots already in
the library — including ones somebody else sent you. That is true on every
device regardless of what its shutter can do, and it is what
`featStitchHow` now leads with.

**Cutting was never a release requirement.** It was mixed in with work that
genuinely does block a release — the package id, the developer unlock, the
release build, removing Firebase — and it is not in that category at all. The
app ships identically with five features or three.

**The reasoning reached the user last.** For a while it did not reach them at
all: this argument was settled here, in a file only a developer opens, while
`featDuplicatesHow` — the sentence somebody deciding whether to pay actually
reads — still said what it had said before the debate started. It explained
*how* the matching works and never answered the question a hand-curating user
asks first: where would my duplicates even come from? It now leads with the
answer, and names the triage screen by the title it carries on screen. **A
decision about whether a feature earns its place is not finished until the
paywall copy states the reason.**

## What is still true

- **The paid list must match the product.** `PremiumFeature.all` is the single
  source of truth, and it once advertised filing rules three releases after
  filing rules were deleted. Removing a feature means removing its entry in the
  same change.
- **Safe Share leads**, because it is the only thing in the list neither Google
  Photos nor Apple Photos will ever ship. Both OCR every screenshot for free,
  so "find your screenshots" is a commodity the OS gives away — and neither
  platform can approve a feature that writes a *different, plausible* card
  number into a user's photo.

## If this is re-proposed

The number to look at first is in the local funnel: how many people reach the
triage queue and keep anything. If the queue is used, Duplicates has real work
to do and the case for cutting it is dead. If nobody uses it, the library is
hand-curated after all, and this argument is worth having again.
