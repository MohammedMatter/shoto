# What version one contains

## Two features were built for an app that no longer exists

Find duplicates and Stitch were both written while SHOTO read the whole device
gallery. When the library became opt-in, neither was re-examined, and both stop
making sense in a library the user assembled by hand:

- **Duplicates.** You do not accumulate duplicates in a set you built one
  deliberate share at a time. The honest result of a scan is "nothing found",
  and that is a poor thing to charge for.
- **Stitch.** It needs two to five overlapping long-scroll captures, shared in
  and then multi-selected. The capture cost is higher than the merge saves, and
  the phones most likely to be used for it have scrolling capture in the
  shutter already.

Both were on the paywall, so the app was selling two answers to a problem it
had stopped creating.

**Still true in the source:** `V1Features` holds one constant each, both false.
The Home rows, the Library merge action, the Settings row and
`PremiumFeature.all` all read them, and `test/home_empty_state_test.dart`
derives its expectations from the flag rather than naming rows.

They are off rather than deleted because the code is good and tested, and
because this is an argument about what a first release should contain — an
argument that can be lost. Flipping a constant restores the feature whole.

## What that leaves

Safe Share, smart actions, and volume. Three things that work, rather than
five that dilute both the pitch and the paywall.

Safe Share leads because it is the only one of them neither Google Photos nor
Apple Photos will ever ship: both OCR every screenshot for free, so "find your
screenshots" is a commodity the OS gives away, and neither platform can approve
a feature that writes a *different, plausible* card number into a user's photo.
