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

## The other half: one source of truth for "private"

Removing the phone rule fixed the sheet. It did not fix the *disagreement*,
and the disagreement was the worse half of what the user saw on that IBAN
page: Safe Share offered to cover the account numbers in the same second this
sheet offered to call fragments of them. Two features, one image, opposite
verdicts. Somebody who notices that stops trusting both — including the
feature whose whole job is to be trusted with the things worth hiding.

Both were answering "is this private?" from their own patterns. Two card
regexes existed, one in each file, and the copy in `ActionExtractor` carried a
comment saying it matched the one in `SensitiveData` — a promise nothing
enforced and nothing would have reported breaking.

So the actions sheet now *asks*. `SensitiveData.findIn` runs during
extraction, and every span it returns whose kind has no action worth offering
is claimed before the entity passes see the text. The duplicated card patterns
are gone.

### Sensitive and actionable are not opposites

The gate is a list, not "everything Safe Share found", because three kinds are
both at once — and all three are the product:

| Kind | Private | Action | Gated |
|---|---|---|---|
| email | yes | write to it | no |
| iban | yes | copy it | no |
| code | yes | copy it before it expires | no |
| card, nationalId, orderNumber, address, personName, phone, number | yes | *nothing* | **yes** |

Covering something before sharing a picture of it, and acting on it yourself,
are different questions with different right answers. Collapsing them would
have deleted the feature in the name of protecting it.

### Order: a label beats a shape

The gate runs *after* the intent passes and before the entity ones. This is
not cosmetic. A tracking number is an order reference by another name, and
`SensitiveData` calls "Order number 4567890" an order number — so running the
gate first would silently delete the tracking action on every delivery
notification the app was built to read. The intent passes have a label from
the screenshot; the gate has a shape derived from digits.

### What it costs

One extra scan of the text, on a sheet the user opened deliberately. The
alternative is two detectors that agree by inspection until one of them is
edited.

### What it exposed

With both features reading one answer, a flaw in that answer stops being
invisible. `SensitiveData._claimCode` labels "Account number 4820193" a
*verification code* when the words "verification code" appear on the following
line — its window is 20 non-digit characters and does not stop at a line
break, which is the exact bug `TextCues.maxLineGap` exists to prevent on this
side. Now that the label decides whether a span is offered, it is worth
fixing; before the gate, the two features simply disagreed quietly.

## The paid list moved with it

`featActionsBody`, `featActionsPoint1` and `featActionsPoint2` all advertised
calling a number, and `kindPhone`, `actionCall`, `actionWhatsapp` and
`actionSms` were deleted from every ARB. Same rule as in
[v1-scope.md](v1-scope.md): a decision about what a feature does is not
finished until the paywall copy states it.
