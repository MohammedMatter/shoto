import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/fade_slide_page_route.dart';
import 'package:shoto/core/services/pro_status.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/glass_layer.dart';
import 'package:shoto/features/subscription/domain/entities/premium_feature.dart';
import 'package:shoto/features/subscription/domain/use_cases/restore_purchases_use_case.dart';
import 'package:shoto/features/settings/presentation/widgets/settings_tiles.dart';
import 'package:shoto/features/subscription/presentation/pages/paywall_page.dart';

/// The one card at the top of Settings that says where this account stands.
///
/// It used to own the app's Pro state outright: it asked the repository in
/// `initState` and parked the reply in a **static field**, because Settings is
/// long enough that the card scrolls out of the `ListView`'s cache extent, gets
/// disposed, and rebuilds from nothing on the way back — which meant a fresh
/// platform-channel round trip mid-drag, and a card that rendered the wrong
/// height for a frame and shoved the whole page down.
///
/// All of that now lives in [ProStatus], which is the actual fix rather than a
/// workaround: the answer belongs to the app, not to one widget in a scroll
/// view, and once it belongs to the app the profile card and Home's wordmark
/// can read it too.
class SubscriptionCard extends StatefulWidget {
  const SubscriptionCard({super.key});

  @override
  State<SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends State<SubscriptionCard> {
  Future<void> _openPaywall() async {
    await Navigator.of(
      context,
    ).push<bool>(FadeSlidePageRoute(builder: (_) => const PaywallPage()));
    await sl<ProStatus>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sl<ProStatus>(),
      builder: (context, _) {
        final ProStatus pro = sl<ProStatus>();

        // Nothing, rather than a guess. "Not known yet" is not "not
        // subscribed", and rendering the upsell on the maybe put an
        // advertisement on a paying customer's own settings screen — then
        // corrected the card's height under their thumb when the truth landed.
        if (pro.status == null) return const SizedBox.shrink();

        final Widget card = pro.isPro
            ? _MembershipCard(expiresOn: pro.status?.expirationDate)
            : _UpgradeCard(onTap: _openPaywall);

        // **The one transition in this file, and it plays once in a
        // lifetime.**
        //
        // Frequency decides whether something animates at all: this fires the
        // moment a purchase lands and essentially never again, which is the
        // rarity band where delight is actually affordable. Everything else
        // here is still.
        //
        // Two animations rather than one, because the cards are different
        // heights and a cross-fade alone would leave the whole of Settings
        // jumping under the user's thumb at the exact moment they are looking
        // at the card. [AnimatedSize] carries the height; the switcher carries
        // the content.
        return AnimatedSize(
          duration: AppMotion.reduced(context)
              ? Duration.zero
              : AppMotion.sheet,
          curve: AppMotion.standard,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: AppMotion.reduced(context)
                ? Duration.zero
                : AppMotion.sheet,
            switchInCurve: AppMotion.standard,
            switchOutCurve: AppMotion.standard,
            transitionBuilder: (Widget child, Animation<double> animation) {
              final Widget faded = FadeTransition(
                opacity: animation,
                child: child,
              );
              if (AppMotion.reduced(context)) return faded;

              // From 0.97, never from zero. Nothing in the world appears out
              // of nothing, and a card that grows from a point reads as a
              // popup rather than as one object changing state.
              return ScaleTransition(
                scale: Tween<double>(begin: 0.97, end: 1).animate(animation),
                child: faded,
              );
            },
            child: KeyedSubtree(key: ValueKey<bool>(pro.isPro), child: card),
          ),
        );
      },
    );
  }
}

/// Every state of the card, laid out for a golden to photograph.
///
/// The card cannot be built in a widget test — it reads [ProStatus] out of the
/// service locator, which needs RevenueCat and a resolved subscription behind
/// it, neither of which has anything to say about the layout. Exposing the
/// arrangements directly is the smaller lie: it tests the picture, which is all
/// a golden can check anyway.
///
/// Three entries: the pitch, a membership with a renewal date behind it, and a
/// membership without one. The last two are the same card — what changes is
/// whether the store has given the app a date to show — and photographing both
/// is the only way to catch the line going missing or wrapping.
@visibleForTesting
List<Widget> get debugSubscriptionCardStates => <Widget>[
  _UpgradeCard(onTap: () {}),
  _MembershipCard(expiresOn: DateTime(2026, 9, 12), debugAnimate: false),
  const _MembershipCard(debugAnimate: false),
];

/// The free-tier card, which doubles as the pitch.
///
/// **It names the features.** The card carried the right principle in a
/// comment once — "'more' is not a reason to pay" — and then showed four
/// anonymous icon chips, which is exactly "more" drawn as pictures. Nobody
/// recognises a rule engine from a folder glyph. Three real titles and a count
/// of the rest is the same space spent on something a person can actually
/// decide from, and that part survives every redesign this card has had.
///
/// ## It is no longer the loud one, and that is the redesign
///
/// It used to be a solid accent slab: a pale periwinkle rectangle roughly
/// **300px tall**, with a recessed plate inside it holding three rows. Every
/// individual decision in it was defensible — the fill is the app's accent,
/// the lit edge is the sanctioned way to build depth, the radius is on the
/// scale — and the sum of them was still wrong, for a reason none of them
/// could see on its own: it was the largest and highest-contrast object on a
/// screen full of quiet grey rows, so Settings opened on an advertisement.
/// A card can obey every token in the system and still be the wrong size.
///
/// So the weight came out and the **structure** stayed. What it is now:
///
/// * **The same shell as [_MembershipCard]** — ordinary surface, hairline
///   border, [AppRadius.lg], the app's own [GlassRim] rather than a shadow
///   (`app_colors.dart`: depth here is what a surface reflects, never what it
///   blocks). The two cards were an advert and a receipt; they are now one
///   object in two conditions, which is what the slot always claimed to be.
///   Paying no longer swaps the card for a different species of card.
/// * **The same header skeleton** — tinted disc, title, one line under it.
///   The pitch says what you would get and how much there is of it; the
///   membership card says what you have. Same shape, different sentence.
/// * **Accent spent on three things only**: the disc, the feature glyphs, and
///   the arrow. Filling the affordance and nothing else puts the strongest
///   colour on the screen exactly where the tap is meant to land, instead of
///   spreading it over 300px of rectangle where it competes with itself.
/// * **The plate is gone.** An inset panel with hairline dividers is structure
///   a three-item list does not need; three lines of text with their own
///   glyphs already read as a list. It was most of the height.
///
/// **No clipped corner**, and that is a rule rather than an oversight:
/// `app_shapes.dart` reserves the cut for *things you kept*. A sales card is
/// the one object on the screen that is not in anybody's library.
class _UpgradeCard extends StatelessWidget {
  final VoidCallback onTap;

  const _UpgradeCard({required this.onTap});

  /// Named on the card. Past three the card stops being a pitch and starts
  /// being the "what is included" page, which already exists and is one tap
  /// away.
  static const int _named = 3;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final List<PremiumFeature> features = PremiumFeature.all;
    final BorderRadius shape = BorderRadius.circular(AppRadius.lg);

    return PressableScale(
      scale: 0.98,
      onTap: onTap,
      child: GlassRim(
        borderRadius: shape,
        // The default strength and the membership card's falloff, because it
        // is now the same kind of surface: glass over the canvas rather than a
        // highlight solved against an accent fill.
        falloff: 34,
        child: Container(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: shape,
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 36.w,
                    height: 36.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.primary.withValues(alpha: 0.14),
                    ),
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      size: 19.sp,
                      color: colors.primary,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          context.l10n.subUnlockEverything,
                          style: context.text.titleSmall.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        // The total, not "and 2 more" — the string is
                        // "{count} features, one plan", which closes the list
                        // by saying what the whole thing costs to think about
                        // rather than by counting what was left out. It sits
                        // in the header now, where the membership card puts
                        // its own one-liner, instead of trailing the card as a
                        // footnote nobody reaches.
                        Text(
                          context.l10n.settingsFeatureCount(features.length),
                          style: context.text.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  const _ArrowChip(),
                ],
              ),
              SizedBox(height: 14.h),
              for (final PremiumFeature feature in features.take(_named))
                _FeatureLine(feature: feature),
            ],
          ),
        ),
      ),
    );
  }
}

/// One named feature, as a line of text with its own glyph.
///
/// Deliberately **not** a boxed row and not a tile. The membership card owns
/// the tile vocabulary — every feature as a lit chip — and repeating it here
/// with three of them would read as the same object half-finished. Words are
/// what the free card has that the paid one does not, so words are what it
/// shows.
///
/// The glyph is the feature's own, in the accent, at the size a run of them
/// reads as a column of marks rather than as icons competing with the text
/// beside them.
class _FeatureLine extends StatelessWidget {
  final PremiumFeature feature;

  const _FeatureLine({required this.feature});

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: <Widget>[
          Icon(feature.icon, color: colors.primary, size: 15.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              feature.title(context),
              style: context.text.bodySmall.copyWith(
                color: colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// The card's one affordance.
///
/// A disc rather than a bare glyph, which is the shape the unsorted card on
/// Home already uses for exactly this job — "this whole card opens something".
/// Two identical jobs drawn two different ways is how an app stops reading as
/// one app.
///
/// **Filled, not tinted**, and it is the only filled object on the card. On
/// the old slab the accent was the background, so the chip had to be a wash of
/// the on-accent colour to be seen at all; on a quiet surface the accent is
/// free again, and the one place worth spending it is the thing the finger is
/// aiming at.
class _ArrowChip extends StatelessWidget {
  const _ArrowChip();

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;

    return Container(
      width: 34.w,
      height: 34.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.primary,
      ),
      child: Icon(
        Icons.arrow_forward_rounded,
        color: colors.onMarker,
        size: 18.sp,
      ),
    );
  }
}

/// What a subscriber sees, and **the argument for it existing at all.**
///
/// This slot held a Pro card once, it was removed, and the reason it was
/// removed is the specification for the one that replaced it. The old card
/// said *"Shoto Pro — every feature unlocked for you"* next to a PRO pill,
/// directly under a profile card that already carries a PRO badge and an
/// accent ring on the avatar. Three statements of one fact inside 250px is not
/// emphasis, and a card whose entire content is a status the screen has
/// already given twice is better deleted than restyled.
///
/// So this one does not restate the status — it shows the **holding**. Every
/// premium glyph, lit at once, which is a fact the screen states nowhere else:
/// the free card names three of them and this names all of them, so the two
/// cards read as one object in two conditions rather than as an advert and a
/// receipt. There is deliberately **no PRO pill on it**; the profile card
/// above owns that word.
///
/// **The weight inverts, and that is the design.** The pitch asks for
/// something; this confirms something. Continuing to shout at somebody after
/// they have paid is the actual tastelessness, and a paid customer's own
/// settings screen is the last place an app should look like it is still
/// selling.
///
/// ## One card, and no "Tester access" variant
///
/// This used to render a second, visibly different card — amber instead of
/// accent, titled *Tester access*, subtitled "not a real subscription" —
/// whenever premium came from the on-device developer switch rather than a
/// purchase. The argument for it was sound as far as it went: a demo build
/// that claims a subscription nobody bought is how a paywall ships without
/// anyone having watched it complete.
///
/// It is gone because **the same warning is already on the screen, stated
/// better**. [AppVersionBlock] draws a live `DEVELOPER MODE` badge at the foot
/// of Settings whenever the switch is on, with "Tap 3× to turn off" under it —
/// which not only says the state but says how to leave it. Two warnings about
/// one condition is not twice as safe; it just meant the only way to look at
/// the real subscriber card was to hold a real subscription, which nobody can
/// do until the store products exist. A card you cannot see is a card nobody
/// checked.
///
/// The distinction is still kept where it belongs — [SubscriptionStatus]
/// carries `isTesterAccess`, and the gates can still read it. It is the
/// *picture* that stopped forking, so the picture can finally be reviewed.
class _MembershipCard extends StatefulWidget {
  /// When the subscription renews, if the store has told us.
  ///
  /// Null for the tester switch, and null for a store that has not answered
  /// yet — in both cases the card falls back to the plain confirmation rather
  /// than inventing a date. **This is the one piece of information on the card
  /// a subscriber cannot get anywhere else in the app**, and it is why the
  /// card is worth its space at all: "you are on Pro" is already said by the
  /// badge on the profile row directly above it, and a card whose whole
  /// content is a fact the screen has already given is better deleted than
  /// restyled. A date is not a restatement.
  final DateTime? expiresOn;

  /// Off in goldens only, where the card is drawn at its **finished** state
  /// rather than from a controller nothing is pumping.
  ///
  /// The first version of this simply skipped `forward()`, which left the
  /// cascade parked at zero — so every glyph rendered at `opacity: 0` and the
  /// golden photographed the one thing on the card that is new as an empty
  /// strip of padding. A test double that produces a picture the app can never
  /// show is worse than no picture.
  final bool debugAnimate;

  const _MembershipCard({this.expiresOn, this.debugAnimate = true});

  @override
  State<_MembershipCard> createState() => _MembershipCardState();
}

class _MembershipCardState extends State<_MembershipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  @override
  void initState() {
    super.initState();
    // **Both branches touch the controller, and that is load-bearing.**
    //
    // It is a `late final` field, so it is not built until something reads it
    // — and the first version only read it inside the animating branch. In a
    // golden the field therefore stayed unbuilt right up until `dispose`
    // called `_controller.dispose()`, which constructed it *then*, which sent
    // `SingleTickerProviderStateMixin` looking for a `TickerMode` above an
    // element that had already been deactivated. The test died in teardown,
    // several frames after the mistake.
    //
    // Jumping it to the end is also the honest way to express "no cascade":
    // the cascade is finished, rather than a separate always-complete
    // animation standing in for one.
    if (widget.debugAnimate) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final DateTime? expiresOn = widget.expiresOn;
    final BorderRadius shape = BorderRadius.circular(AppRadius.lg);

    // The same lit top edge the pitch above it has, and the same one the
    // unsorted card on Home is raised by — at the default strength, because
    // this one sits on an ordinary surface rather than on the accent. Both
    // cards in this slot are objects in the same room; only one of them being
    // lit is what would make the quiet one read as flat rather than as calm.
    return GlassRim(
      borderRadius: shape,
      falloff: 34,
      child: Container(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: shape,
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                // **The same mark as the pitch, filled instead of tinted.**
                //
                // It was a check, and a check was the wrong word. A tick means
                // *done* — a task closed, a form accepted — and a subscription
                // is not a completed errand, it is something you hold. The
                // glyph read like a confirmation toast that had wandered onto
                // a card.
                //
                // So both cards now carry the identical premium mark in the
                // identical place, and **the fill is the entire difference**:
                // a wash of the accent while it is something on offer, solid
                // accent once it is yours. Nothing else on either card changes
                // shape, which is what makes the pair read as one object in
                // two conditions rather than as an advert and a receipt — and
                // it means the meaning is carried by the one property a person
                // can read without knowing any iconography at all.
                //
                // The solid object also stays unique per card and simply
                // moves: on the pitch it is the arrow at the trailing edge —
                // go and do this — and here it is the mark at the leading
                // edge, because there is nothing left to do.
                Container(
                  width: 36.w,
                  height: 36.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary,
                  ),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    size: 20.sp,
                    color: colors.onMarker,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        context.l10n.subPremiumTitle,
                        style: context.text.titleSmall.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        expiresOn == null
                            ? context.l10n.subPremiumBody
                            : context.l10n.subPremiumRenews(
                                _formatRenewal(context, expiresOn),
                              ),
                        style: context.text.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            _LitFeatureRow(cascade: _controller, tint: colors.primary),
          ],
        ),
      ),
    );
  }
}

/// The renewal date in the reader's own conventions.
///
/// Falls back to the default locale rather than throwing, the same guard
/// `action_options.dart` puts around its own dates: `DateFormat` raises if the
/// app is running in a language whose date symbols were never loaded, and
/// losing the card to a formatting detail would be absurd.
///
/// `yMMMMd` rather than a numeric format, because "12 September 2026" cannot
/// be read as the wrong day by somebody used to the other convention — and a
/// billing date is exactly where that mistake costs something.
String _formatRenewal(BuildContext context, DateTime date) {
  final String locale = Localizations.localeOf(context).toLanguageTag();
  try {
    return DateFormat.yMMMMd(locale).format(date);
  } catch (_) {
    return DateFormat.yMMMMd().format(date);
  }
}

/// Every premium glyph, arriving one after another.
///
/// **The one piece of delight in this file**, and it is affordable for the
/// same reason the card's own transition is: a person sees this the first time
/// Settings is opened after they pay. It is not attached to anything repeated.
///
/// The cascade is short on purpose — roughly 45ms between glyphs, which is
/// inside the band where a stagger reads as one gesture sweeping across rather
/// than as several separate things being switched on. Long delays do not read
/// as luxurious, they read as slow.
///
/// Every glyph, wrapped so a long list or a large text scale rolls onto a
/// second line instead of overflowing — the count comes from
/// [PremiumFeature.all] and is expected to grow.
class _LitFeatureRow extends StatelessWidget {
  final Animation<double> cascade;
  final Color tint;

  const _LitFeatureRow({required this.cascade, required this.tint});

  /// How much of the run each glyph gets. Overlapping windows rather than
  /// discrete slots: each one is still moving as the next begins, which is
  /// what makes it a sweep instead of a metronome.
  static const double _window = 0.45;

  @override
  Widget build(BuildContext context) {
    final List<PremiumFeature> features = PremiumFeature.all;
    final bool reduced = AppMotion.reduced(context);

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: <Widget>[
        for (int i = 0; i < features.length; i++)
          _Glyph(
            feature: features[i],
            tint: tint,
            // Nothing at all under reduced motion: a decorative cascade over
            // something the user did not trigger is precisely what that
            // setting exists to remove. The glyphs are simply lit.
            step: reduced
                ? const AlwaysStoppedAnimation<double>(1)
                : CurvedAnimation(
                    parent: cascade,
                    curve: Interval(
                      // Spread the starts across everything the window leaves
                      // over, so the last glyph still finishes exactly at the
                      // end of the run however many features there are.
                      features.length == 1
                          ? 0
                          : (1 - _window) * (i / (features.length - 1)),
                      features.length == 1
                          ? 1
                          : (1 - _window) * (i / (features.length - 1)) +
                                _window,
                      curve: AppMotion.standard,
                    ),
                  ),
          ),
      ],
    );
  }
}

class _Glyph extends StatelessWidget {
  final PremiumFeature feature;
  final Color tint;
  final Animation<double> step;

  const _Glyph({required this.feature, required this.tint, required this.step});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: step,
      builder: (BuildContext context, Widget? child) {
        final double t = step.value;
        return Opacity(
          opacity: t,
          // A hair of scale, from 0.9 — enough that the glyph arrives rather
          // than blinks on, and small enough that eight of them sweeping past
          // does not read as popcorn.
          child: Transform.scale(scale: 0.9 + 0.1 * t, child: child),
        );
      },
      // **A lit tile, not a button.**
      //
      // At 12% on a surface this close in value, the fill was barely a shade
      // off the card behind it and the row read as five *disabled* controls —
      // the exact opposite of what it is there to say. The tint carries a
      // hairline of the same accent now, which is what gives each tile an
      // edge to be seen by, and 18% of fill behind a full-strength glyph is
      // enough to read as lit in both modes without any tile out-weighing the
      // solid mark in the header.
      child: Container(
        width: 34.w,
        height: 34.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: tint.withValues(alpha: 0.22)),
        ),
        child: Icon(feature.icon, size: 17.sp, color: tint),
      ),
    );
  }
}

/// "Restore purchases", as a row with words on it.
///
/// **Shown to everybody, which is the whole correction.** This was a bare
/// refresh glyph in the corner of the card a *subscriber* saw — so the person
/// it exists for, the one who paid on another device and is looking at a
/// paywall, could not reach it at all. Restoring is the answer to "I already
/// bought this and the app has forgotten"; that sentence is only ever said by
/// somebody the app currently thinks is on the free tier.
///
/// It lives with the other Pro rows rather than on a card, because it is an
/// action and not a status, and every other action in Settings is a row.
class RestorePurchasesTile extends StatefulWidget {
  const RestorePurchasesTile({super.key});

  @override
  State<RestorePurchasesTile> createState() => _RestorePurchasesTileState();
}

class _RestorePurchasesTileState extends State<RestorePurchasesTile> {
  bool _isRestoring = false;

  Future<void> _restore() async {
    setState(() => _isRestoring = true);
    try {
      await sl<RestorePurchasesUseCase>()();
    } finally {
      if (mounted) setState(() => _isRestoring = false);
      await sl<ProStatus>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsNavTile(
      icon: Icons.restore_outlined,
      label: context.l10n.paywallRestore,
      description: context.l10n.settingsRestoreHint,
      // Null while it runs, which greys the row and blocks a second tap —
      // the same "in flight" shape the row already knows how to draw for a
      // cache that has nothing left to clear.
      onTap: _isRestoring ? null : _restore,
    );
  }
}
