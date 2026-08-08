# Decisions

Why things in Shoto are the way they are, when the reason is a *history*
rather than a rule.

## What belongs here, and what belongs in the source

The comments in this codebase are unusually good and that is worth keeping.
But they had started doing two different jobs at once, and only one of them
belongs next to the code.

**A constraint stays in the source.** Something a future reader must not
break, stated as a fact about the code as it is now:

```dart
// Must happen before MaterialApp.router builds its subtree — every custom
// widget below reads AppColors synchronously during this same frame.
```

Delete that line and somebody breaks the app. It is load-bearing, it is short,
and it describes the present.

**A history moves here.** The record of what a thing used to be and why it
stopped being that:

> This began as a slab of accent colour with a glow under it, became a bordered
> surface with a coloured rule, and is now nothing at all…

That paragraph is genuinely valuable — it is the argument for the current
design and it stops the next person re-proposing a rejected one. But it
describes three things that no longer exist, and **it rots**: six months from
now a reader cannot tell which paragraphs still describe the code. At 38%
comments, `home_page.dart` had more lines about what Home used to be than
about what it does.

## The test

Ask: *if I changed this code, would this comment become wrong, or merely
old?*

- Becomes **wrong** → it was describing the present. Keep it in the source.
- Becomes **old** → it was describing the past. It belongs here.

## Rules

1. **Never delete the reasoning.** Moving it here is the point; losing it is
   not. A rejected design that nobody wrote down gets re-proposed.
2. **Leave a pointer, not a summary.** The source keeps the invariant and one
   line naming the file here. A summary in both places is two things to keep
   in sync.
3. **One file per screen or subsystem**, named after it.
4. **Write in the past tense.** These are records. If a sentence is in the
   present tense it is probably a constraint and belongs in the source.

[home.md](home.md) breaks rule 4 at the end, and the exception is worth
knowing about rather than discovering. Home's comments were all removed when
the page was split into `presentation/widgets/`, so five live constraints had
no source to stay in. They are gathered there under their own heading, in the
present tense, clearly marked as not being records. Nothing else in this
folder works that way.

## Index

- [home.md](home.md) — the Home tab: why it stopped being a gallery, what the
  hero has been, and the five constraints left without a comment to live in
  when the page was split.
- [accounts.md](accounts.md) — the sign-in wall, why it bought nobody
  anything, and where the user's name went.
- [library-intake.md](library-intake.md) — two reversals: the gallery mirror,
  the empty room, and the inbox that answers both.
- [onboarding.md](onboarding.md) — what the introduction used to describe, and
  why it no longer ends on a price.
- [v1-scope.md](v1-scope.md) — cutting two features to sharpen the pitch:
  proposed, built, and reversed.
- [ios.md](ios.md) — what a Share Extension actually costs, so "later" stops
  being a sentence without a number.
- [ml-models.md](ml-models.md) — the bundled models, the unbundled swap, and
  what has to be tested on a device before taking it.
