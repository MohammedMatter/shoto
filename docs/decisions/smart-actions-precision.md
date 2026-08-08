# The actions sheet no longer detects phone numbers

Removed, not tightened. This file exists because the rule had already been
tightened five times, each time correctly, and it was still wrong — so the
next person to look at a missed number needs to know that adding a sixth
guard is not the move.

## What happened

A screenshot of a page of generated IBANs was opened in the app and `Actions`
was tapped. The sheet returned three rows, each labelled *a phone number*,
each carrying **Call**, **WhatsApp** and **Message**:

```
3698-5387-302
6150000
0000 1597 54
```

None of them is a phone number. All three are fragments of account numbers and
bank codes on the page.

Every guard the rule had was working as designed at the time:

- no letters on either end, so `ABNA0417164300` could not contribute
- no date shapes, so `12/05/2024` could not
- seven to fifteen digits
- twelve or more only with a `+` or `00`
- fewer separators than digits

The three above pass all five, because there is nothing wrong with them *as
digit runs*. That is the finding.

## Why no sixth guard would have helped

**A bare run of digits carries no feature that distinguishes a phone number
from an account number.** Length overlaps, grouping overlaps, separators
overlap. The only thing that ever separates them is context outside the digits
— a `tel:` link, a contact card, a labelled field — and OCR text of a table
gives none of it.

So the pattern was not the bug and could not be fixed by being narrowed. The
bug was offering an action at all on evidence that thin.

Two further things made it worse than an ordinary false positive:

- **It cost trust that other features needed.** Safe Share asks the user to
  believe a claim about which parts of their screenshot are private. An app
  that has just offered to WhatsApp an account number has spent the credit
  that claim runs on.
- **The same app contradicted itself on the same image.** Safe Share flagged
  those digits as sensitive and offered to cover them. The actions sheet
  offered to dial them. Two readings of one screenshot, opposite conclusions,
  no way for the user to tell which to believe.

## What was kept

The Library's **Contact** filter still counts phone numbers, and the candidate
pattern lives on in `lib/core/utils/phone_candidates.dart` to serve it. That
is not the same decision reversed, and the difference is the evidence bar and
the blast radius:

|  | actions sheet | Contact chip |
|---|---|---|
| accepted on | the digits alone | a country code, **or** a cue word within 40 characters |
| when wrong | offers to call a stranger | narrows a list by one screenshot |
| user can tell? | only after dialling | never has to |

`ContentTraits` is the only caller, and the file says so. A second caller is a
decision to be argued here, not an import.

The invariant is executable, in `test/content_traits_test.dart`:

```dart
test('a corroborated number is a chip and never an action', () { … });
```

## If this is re-proposed

Bring a source of truth that is not the digits. A `tel:` URI in the text, a
recogniser that reports a phone-number entity rather than characters, or a
labelled field the OCR preserved. "A better regex" is not one, and the five
guards above are the evidence.

## The paid list moved with it

`featActionsBody`, `featActionsPoint1` and `featActionsPoint2` all advertised
calling a number, and `kindPhone`, `actionCall`, `actionWhatsapp` and
`actionSms` were deleted from every ARB. Same rule as in
[v1-scope.md](v1-scope.md): a decision about what a feature does is not
finished until the paywall copy states it.
