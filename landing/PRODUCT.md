# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Stack

static HTML/CSS/JS, no build step (user's explicit choice — deploys directly to Vercel/Netlify/GitHub Pages)

## Users

Primary: everyday smartphone users whose camera roll fills up with hundreds of untracked screenshots (reels, chats, receipts, articles, ideas) and who can no longer find a specific one later.

Landing page audience specifically: people discovering Shoto through its Instagram account (an active marketing channel — bio, launch post, feature-explainer post series already drafted) and following a link-in-bio to this page. Mobile-first traffic.

## Product Purpose

Shoto turns a messy screenshot camera roll into a deliberately curated, searchable library. Users choose what to save (via the OS share sheet), and the app takes over from there — finding, organizing, and protecting anything they've filed. Success means a user can locate any screenshot they saved in seconds, without scrolling a giant camera roll.

## Positioning

**Lead with Safe Share: "the screenshot you can actually send."**

Organizing screenshots is a commodity. Google Photos and Apple Photos already OCR every screenshot for free, index it, search it and auto-album it, with no import step and across devices — so "find your screenshots" cannot be the headline claim against them, and a page that leads with it invites the comparison Shoto loses.

Safe Share is the one capability neither platform will ever ship, because a platform owner cannot approve a feature that writes a *different, plausible* card number into a user's photo. It is also the only one that is genuinely novel rather than merely well-executed:

1. **Substitution, not redaction.** A card number becomes a different card number that passes the same Luhn check; an IBAN becomes a valid mod-97 IBAN — same length, same position, same typeface. A black bar announces that there was something to hide. A replacement announces nothing.
2. **Fully on-device processing** — no cloud, no servers, and now no account either — so nothing about a screenshot ever leaves the phone.
3. **Opt-in curation.** Nothing enters the library unless the user shares it in; the app never mirrors the camera roll.

Search, folders and the share sheet are the reason people stay, and they support the headline rather than competing with it — but they are table stakes, not the pitch.

## Operating Context

- Primary capture flow: share a screenshot from any other app (Instagram, WhatsApp, browser, etc.) into Shoto via the OS share sheet; a bottom sheet immediately asks which folder to file it into.
- Search: type a word to search screenshot text (OCR) or visual content (on-device image recognition) — works even for images with no text at all.
- Organization: colored folders, chosen by the user at save time. There is no automation — see the note on filing rules below.
- Outbound sharing (**the headline flow**): Safe Share finds sensitive data (card numbers, IBANs, IDs, verification codes, names, addresses) and substitutes plausible stand-ins before a screenshot is sent elsewhere.
- No account. The app opens straight into the library on first launch; signing in is offered only to carry a purchase to a second device.
- Marketing channel already live: an Instagram account is being built out now, driving traffic to this landing page.

## Capabilities and Constraints

- **Not yet released** — the app is not live on the App Store or Google Play. This landing page is pre-launch: no download buttons or store badges. The primary CTA is an email waitlist / "notify me" capture. The page must still read as a real, finished product, not a placeholder.
- Confirmed feature set:
  - **Quick Save** — share-sheet import + immediate folder prompt.
  - **Smart Search** — OCR text recognition and on-device visual recognition (no cloud vision), finds images by what's in them even with zero text.
  - **Duplicate Detection** — perceptual-hash based, always user-confirmed, never auto-deletes.
  - **Scrolling Stitch** — merges sequential scrolled screenshots into one continuous image.
  - **Safe Share** — checksum-backed detection (Luhn for cards, mod-97 for IBANs) plus verification codes and IDs, redacted before sharing out.
  - **Smart Actions** — tap a phone number/email/link found inside a screenshot to act on it directly.
  - Colored folders, light/dark mode.
  - 6 in-app languages (English, Arabic, Urdu, Spanish, French, Hindi) — though this landing page itself ships **English-only** per this session's decision.
- Privacy is structural, not a policy promise: no cloud storage or servers exist in the architecture; screenshots and metadata never leave the device.
- Undecided: exact launch timeline, store-listing details, and whether to surface pricing/premium-tier info on this landing page (a free tier and a paid tier exist in the app; visibility here is not yet decided).

## Brand Commitments

- Name: **Shoto**.
- Tone is an explicit, repeatedly confirmed constraint: professional and official-feeling — never playful, cute, or mascot/cartoon-character-driven. A cute mascot logo concept was explicitly rejected this session for breaking this tone.
- Tagline: **"The screenshot you can actually send."** This replaces "Never lose a screenshot again" and "A pile becomes a library" as the headline — both describe the organizer, which is the commodity half of the product. The pile line survives as the app's own onboarding hook, where it is doing a different job (naming the problem, not the differentiator).
- No aesthetic direction (palette, typography, page concept) is decided for this landing page yet.

## Evidence on Hand

- No real app screenshots or UI mockups exist yet to place on the page.
- **A finished logo does exist**, and this document previously said it did not. The mark is a tray with three screenshots filed into it, drawn in Dart by `lib/core/widgets/shoto_brand_mark.dart` and rasterised to all 28 platform sizes plus `branding/shoto_icon.png` by `flutter test tool/generate_brand_assets.dart`. It is usable on the page today. The earlier note describing "a glossy blue folder used only as a style reference" was describing this asset without recognising it — the mark is deliberately blue while the interface is achromatic (a logo is allowed a colour the UI does not have), and the scoop in its front face exists specifically so the shape is *not* a folder.
- Open question, for the owner rather than for copy: whether the mark's glossy 3D treatment — gradient, bevel, highlight — sits well against the "professional and official-feeling, never playful" tone constraint, and against the flat, restrained interface behind it. This is a taste call on a deliberate design, not a defect, and no change should be made to it without an explicit decision.
- No testimonials, press mentions, user counts, or case studies exist — the app is unreleased; none of these may be fabricated.
- No existing web codebase for this landing page — `landing/` was created fresh for it.

## Product Principles

1. Opt-in curation over passive hoarding — never imply the app automatically captures everything; the user's deliberate choice to save is the entire premise.
2. Privacy is a structural fact, not a marketing line — state it plainly, without hedging or vague "we care about privacy" language.
3. Never advertise what the app cannot do. **Auto-filing rules do not exist** — they were built and removed in v13, and this document went on listing them as a headline differentiator for three releases afterwards. Smart Albums were built and removed before them. Any copy describing automatic filing, rules, or AI that sorts for the user is false and must not appear on the page.
4. Confident pre-launch, not apologetic — the page must read as a real, finished product with a "notify me" gate, not a "coming soon" stub.
5. Professional restraint over cuteness — no mascots, no cartoon personality, matching the tone already locked in on the app's Instagram account.

## Accessibility & Inclusion

No product-specific accessibility requirement has been established for this landing page beyond standard web accessibility practice.
