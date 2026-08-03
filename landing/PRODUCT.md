# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Stack

static HTML/CSS/JS, no build step (user's explicit choice — deploys directly to Vercel/Netlify/GitHub Pages)

## Users

Primary: everyday smartphone users whose camera roll fills up with hundreds of untracked screenshots (reels, chats, receipts, articles, ideas) and who can no longer find a specific one later.

Landing page audience specifically: people discovering SHOTO through its Instagram account (an active marketing channel — bio, launch post, feature-explainer post series already drafted) and following a link-in-bio to this page. Mobile-first traffic.

## Product Purpose

SHOTO turns a messy screenshot camera roll into a deliberately curated, searchable library. Users choose what to save (via the OS share sheet), and the app takes over from there — finding, organizing, and protecting anything they've filed. Success means a user can locate any screenshot they saved in seconds, without scrolling a giant camera roll.

## Positioning

Unlike a gallery app or the OS's own screenshots folder, SHOTO does not passively mirror everything captured — it is opt-in by design: nothing enters the library unless the user shares it in. Two mechanisms a copycat gallery app can't casually claim:
1. Auto-filing rules the user writes themselves, so every filing decision is explainable, never an opaque AI guess.
2. Fully on-device processing — no cloud, no servers — so search and organization never leave the phone.

## Operating Context

- Primary capture flow: share a screenshot from any other app (Instagram, WhatsApp, browser, etc.) into SHOTO via the OS share sheet; a bottom sheet immediately asks which folder to file it into.
- Search: type a word to search screenshot text (OCR) or visual content (on-device image recognition) — works even for images with no text at all.
- Organization: colored folders; user-authored filing rules automate sorting of new screenshots.
- Occasional outbound sharing: Safe Share scans and redacts sensitive data (card numbers, IDs, verification codes) before a screenshot is shared elsewhere.
- Marketing channel already live: an Instagram account is being built out now, driving traffic to this landing page.

## Capabilities and Constraints

- **Not yet released** — the app is not live on the App Store or Google Play. This landing page is pre-launch: no download buttons or store badges. The primary CTA is an email waitlist / "notify me" capture. The page must still read as a real, finished product, not a placeholder.
- Confirmed feature set:
  - **Quick Save** — share-sheet import + immediate folder prompt.
  - **Smart Search** — OCR text recognition and on-device visual recognition (no cloud vision), finds images by what's in them even with zero text.
  - **Auto-Filing Rules** — user-authored automation; a rule with no conditions matches nothing, never everything.
  - **Duplicate Detection** — perceptual-hash based, always user-confirmed, never auto-deletes.
  - **Scrolling Stitch** — merges sequential scrolled screenshots into one continuous image.
  - **Safe Share** — checksum-backed detection (Luhn for cards, mod-97 for IBANs) plus verification codes and IDs, redacted before sharing out.
  - **Smart Actions** — tap a phone number/email/link found inside a screenshot to act on it directly.
  - Colored folders, light/dark mode.
  - 6 in-app languages (English, Arabic, Urdu, Spanish, French, Hindi) — though this landing page itself ships **English-only** per this session's decision.
- Privacy is structural, not a policy promise: no cloud storage or servers exist in the architecture; screenshots and metadata never leave the device.
- Undecided: exact launch timeline, store-listing details, and whether to surface pricing/premium-tier info on this landing page (a free tier and a paid tier exist in the app; visibility here is not yet decided).

## Brand Commitments

- Name: **SHOTO**.
- Tone is an explicit, repeatedly confirmed constraint: professional and official-feeling — never playful, cute, or mascot/cartoon-character-driven. A cute mascot logo concept was explicitly rejected this session for breaking this tone.
- Strong tagline candidates validated this session: "Never lose a screenshot again" and "A pile becomes a library" (the latter also used as the app's own onboarding hook). Neither is finally locked for this specific page.
- No aesthetic direction (palette, typography, page concept) is decided for this landing page yet.

## Evidence on Hand

- No real app screenshots, UI mockups, or finished logo/icon exist yet to place on the page. Two reference logo directions were explored in conversation — a rejected cartoon-mascot concept, and a glossy blue folder/cards icon used only as a style reference for a future icon-generation prompt — neither is a final, usable asset.
- No testimonials, press mentions, user counts, or case studies exist — the app is unreleased; none of these may be fabricated.
- No existing web codebase for this landing page — `landing/` was created fresh for it.

## Product Principles

1. Opt-in curation over passive hoarding — never imply the app automatically captures everything; the user's deliberate choice to save is the entire premise.
2. Privacy is a structural fact, not a marketing line — state it plainly, without hedging or vague "we care about privacy" language.
3. Explainable automation — filing rules are user-authored; never imply a black-box AI decides for the user.
4. Confident pre-launch, not apologetic — the page must read as a real, finished product with a "notify me" gate, not a "coming soon" stub.
5. Professional restraint over cuteness — no mascots, no cartoon personality, matching the tone already locked in on the app's Instagram account.

## Accessibility & Inclusion

No product-specific accessibility requirement has been established for this landing page beyond standard web accessibility practice.
