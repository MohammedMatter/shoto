import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/funnel_log.dart';
import 'package:shoto/core/localization/app_message.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/empty_state.dart';
import 'package:shoto/core/services/feature_trials.dart';
import 'package:shoto/core/services/pro_status.dart';
import 'package:shoto/core/widgets/premium_gate.dart';
import 'package:shoto/core/widgets/primary_button.dart';
import 'package:shoto/features/safe_share/data/services/redaction_service.dart';
import 'package:shoto/features/safe_share/domain/entities/sensitive_region.dart';
import 'package:shoto/features/safe_share/presentation/widgets/finding_row.dart';
import 'package:shoto/features/safe_share/presentation/widgets/scan_report_card.dart';
import 'package:shoto/features/safe_share/presentation/widgets/screenshot_preview.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';

/// How a review of a picture that came in from a share ended.
///
/// Popped as the route's result, because the sheet underneath has to tell
/// three endings apart and only one of them is "nothing happened":
///
/// * **[handedOn]** — the picture went to another app. The task is finished
///   and everything closes.
/// * **[kept]** — the covered copy is staying here. The sheet takes the file
///   and files it, which is the one thing it has always known how to do.
/// * **null** (an ordinary pop) — the back gesture, which must cost nothing.
///
/// Only the share-sheet path produces these. A review opened on a library
/// screenshot returns to the library, where the picture already is.
class SafeShareOutcome {
  final bool handedOn;

  /// The covered copy to file, set only when the user chose to keep it.
  ///
  /// A real file rather than a flag, because the thing worth keeping is the
  /// *protected* image — not the original the reviewer arrived with. Passing a
  /// flag would have left the caller filing the uncovered picture, which is
  /// the exact opposite of what the button says.
  final File? kept;

  const SafeShareOutcome.handedOn() : handedOn = true, kept = null;
  const SafeShareOutcome.kept(File this.kept) : handedOn = false;
}

/// Review-and-share screen for hiding private details before a screenshot
/// leaves the phone.
///
/// The screen is split in two, and the split is the product:
///
/// **Looking is free.** Anyone, subscribed or not, can open a screenshot and
/// be told exactly what is in it — "4 private details: your location, your
/// account number, your name, your phone number" — with each one marked on
/// the picture. That is the part worth giving away, because most people have
/// no idea a screenshot they were about to send carries any of it, and an app
/// that charges to *tell you there is a problem* teaches you to distrust the
/// answer.
///
/// **Fixing is paid.** Turning those findings into a clean copy is the work,
/// and it is behind the paywall.
///
/// Two rules the screen obeys throughout. Shoto never decides alone: it
/// proposes, shows exactly where every change lands, and the user confirms —
/// because the one thing worse than leaking a card number is an app that
/// silently rewrote the wrong half of a screenshot and let you send it
/// believing it was fine. And the preview is always the exported bytes, never
/// an approximation drawn with widgets, so what is checked is what is sent.
class SafeSharePage extends StatefulWidget {
  /// The library item being protected, when this was opened from inside the
  /// app.
  final ScreenshotEntity? screenshot;

  /// A picture handed in from the system share sheet, which is **not** in the
  /// library and is not being put there.
  ///
  /// Somebody who shares a screenshot into Shoto to cover an account number
  /// has asked for it to be fixed, not filed. Importing it anyway would grow
  /// their library with something they never chose — and would break the
  /// sentence this app says on two of its own screens: *nothing joins your
  /// library until you say so*.
  ///
  /// It costs nothing to honour, which is the other half of the argument.
  /// [RedactionService.scan] has always taken a [File]; the entity was only
  /// ever used to fetch one, on a single line. The library was a coincidence
  /// of where the screen happened to be opened from, never a requirement.
  final File? incoming;

  const SafeSharePage({super.key, required ScreenshotEntity this.screenshot})
    : incoming = null;

  /// Opens on a file that lives outside the library and stays outside it.
  const SafeSharePage.incoming({super.key, required File this.incoming})
    : screenshot = null;

  @override
  State<SafeSharePage> createState() => _SafeSharePageState();
}

class _SafeSharePageState extends State<SafeSharePage> {
  RedactionPlan? _plan;
  File? _file;
  bool _failed = false;

  /// Whether the paywall has been passed. Findings are visible either way;
  /// this only gates the clean copy.
  bool _unlocked = false;

  Uint8List? _preview;
  bool _rendering = false;
  bool _sharing = false;

  /// Re-rendering a full-resolution screenshot costs a decode, a draw and a
  /// PNG encode. Tapping through three treatments in a second must not queue
  /// three of those.
  Timer? _renderDebounce;

  /// Guards against an earlier, slower render landing after a later one and
  /// showing the user a preview of choices they have already changed.
  int _renderToken = 0;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  @override
  void dispose() {
    _renderDebounce?.cancel();
    super.dispose();
  }

  Future<void> _scan() async {
    try {
      final File? file =
          widget.incoming ?? await widget.screenshot!.asset.file;
      if (file == null) {
        throw const RedactionException(AppMessage.stitchUnreadable);
      }
      final RedactionPlan plan = await sl<RedactionService>().scan(file);
      if (!mounted) return;
      setState(() {
        _file = file;
        _plan = plan;
      });
    } catch (error, stack) {
      // Reported rather than swallowed: this catch used to turn every fault —
      // a missing file, a decode failure, a bug in the scanner — into the
      // same "could not read that image", which points the next person at the
      // screenshot instead of at the code.
      debugPrint('Safe share scan failed: $error\n$stack');
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _unlock() async {
    if (!await ensurePremium(context, trial: FeatureTrial.safeShare)) {
      return;
    }
    if (!mounted) return;
    setState(() => _unlocked = true);
    await _render();
  }

  void _setTreatment(int index, RegionTreatment treatment) {
    final RedactionPlan plan = _plan!;
    final List<SensitiveRegion> updated = List.of(plan.regions);
    updated[index] = updated[index].copyWith(treatment: treatment);
    setState(() => _plan = plan.withRegions(updated));

    _renderDebounce?.cancel();
    _renderDebounce = Timer(const Duration(milliseconds: 220), _render);
  }

  Future<void> _render() async {
    final RedactionPlan? plan = _plan;
    final File? file = _file;
    if (plan == null || file == null) return;

    final int token = ++_renderToken;
    setState(() => _rendering = true);

    try {
      final Uint8List bytes = await sl<RedactionService>().redact(file, plan);
      if (!mounted || token != _renderToken) return;
      setState(() {
        _preview = bytes;
        _rendering = false;
      });
    } catch (error, stack) {
      debugPrint('Safe share render failed: $error\n$stack');
      if (!mounted || token != _renderToken) return;
      setState(() => _rendering = false);
      _reportFailure();
    }
  }

  void _reportFailure() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.safeShareFailed)));
  }

  /// Renders the plan and writes it out as a file.
  ///
  /// Extracted so sending the copy and keeping it are the *same bytes* by
  /// construction. Two call sites each rendering their own would be two
  /// chances for one of them to miss a treatment the user had just changed —
  /// and the failure mode is a screenshot kept with a number still showing.
  ///
  /// Never the debounced preview: an action tapped inside the debounce window
  /// would use the copy from *before* the last change.
  ///
  /// Written to the cache rather than the gallery. This file exists to be
  /// handed somewhere, and writing every protected version straight to the
  /// user's photos would quietly fill their library with near-duplicates of
  /// their own screenshots. Keeping it in Shoto is a deliberate second step,
  /// taken by somebody who pressed a button that says so.
  Future<File> _protectedCopy() async {
    final Uint8List bytes = await sl<RedactionService>().redact(_file!, _plan!);
    final Directory dir = await getTemporaryDirectory();
    final File out = File(
      '${dir.path}/shoto_protected_'
      '${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await out.writeAsBytes(bytes);

    // Recorded here rather than at either call site, because this is the line
    // that only runs when the headline feature actually produced something.
    // Sending the original from this screen means the user looked at the
    // findings and decided nothing needed doing — a legitimate outcome, and
    // not the same event.
    sl<FunnelLog>().record(FunnelStep.safeShareCompleted);
    return out;
  }

  /// Keeps the covered copy in Shoto, without a trip through the share sheet.
  ///
  /// **The round trip is what this replaces.** Keeping the copy was reachable
  /// before — share it, find Shoto in the system chooser, pick it, arrive back
  /// where you already were — and every step of that is the operating system
  /// being asked to hand an app a file it is currently running. Filing
  /// something into Shoto is not sharing it with another app.
  ///
  /// The file is handed *up* rather than imported here. The sheet below owns
  /// filing — folders, the intent, the library ceiling, the funnel — and a
  /// second implementation of that on this screen is how the two would start
  /// disagreeing about what saving means.
  Future<void> _keep() async {
    setState(() => _sharing = true);
    try {
      final File copy = await _protectedCopy();
      if (!mounted) return;
      Navigator.of(context).pop(SafeShareOutcome.kept(copy));
    } catch (error, stack) {
      debugPrint('Safe share keep failed: $error\n$stack');
      if (!mounted) return;
      setState(() => _sharing = false);
      _reportFailure();
    }
  }

  /// Shares the protected copy, or the original when there was nothing to
  /// protect and the user asked to send it anyway.
  Future<void> _share({required bool protected}) async {
    setState(() => _sharing = true);
    try {
      final File out = protected ? await _protectedCopy() : _file!;

      if (!mounted) return;
      setState(() => _sharing = false);
      await SharePlus.instance.share(ShareParams(files: [XFile(out.path)]));
      if (!mounted) return;

      // **Handing the picture on is the end of this screen's job — but only
      // when the picture was never ours.**
      //
      // A capture opened from the library is still in the library afterwards,
      // so returning to it is returning to something the user owns. One that
      // arrived through the system share sheet is *passing through*: it was
      // never imported, there is nothing left to look at, and the only reason
      // the user opened Shoto at all has just happened.
      //
      // Leaving it up is what made the share sheet ask "cover it, or keep
      // it?" a second time about a screenshot the user had already covered
      // and sent — the offer is one back-press below this screen, so the
      // reward for finishing the task was being asked to start it again.
      //
      // An outcome rather than a bare pop, because "the user backed out" and
      // "the user finished" are answers the caller has to tell apart: the
      // first must return to the offer so a mis-tap costs nothing, and the
      // second must close everything.
      //
      // Deliberately not conditioned on whether the send *succeeded*.
      // `SharePlus` reports `unavailable` for a perfectly good send on most
      // Android builds, so success is not knowable here — but it is also not
      // the question. The chooser opened and closed; the user has been where
      // they were going.
      if (widget.incoming != null) {
        Navigator.of(context).pop(const SafeShareOutcome.handedOn());
      }
    } catch (error, stack) {
      debugPrint('Safe share failed: $error\n$stack');
      if (!mounted) return;
      setState(() => _sharing = false);
      _reportFailure();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        title: Text(
          context.l10n.safeShareTitle,
          style: context.text.titleLarge,
        ),
      ),
      body: SafeArea(top: false, child: _body()),
    );
  }

  Widget _body() {
    if (_failed) return const _Unreadable();

    final RedactionPlan? plan = _plan;
    // Both of these are `const` now, and for most of this app's life they
    // could not be: the palette was a mutable global, a const instance is
    // identical across rebuilds, and Flutter skips an identical subtree — so
    // it froze at whichever brightness happened to be active first. That bug
    // shipped twice. Reading through `context.colors` ended it: these two
    // depend on the theme by reading it, and a dependent is rebuilt on a
    // change no matter how it was constructed.
    if (plan == null) return const _Scanning();
    if (plan.isEmpty) {
      return _NothingFound(onShare: () => _share(protected: false));
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 8.h),
            children: [
              ScreenshotPreview(
                file: _file!,
                imageSize: plan.imageSize,
                markers: _unlocked ? const [] : plan.regions,
                result: _unlocked ? _preview : null,
                busy: _rendering,
              ),
              SizedBox(height: 14.h),
              if (!_unlocked) ...[
                ScanReportCard(plan: plan),
                SizedBox(height: 10.h),
                const CoverExplainer(),
                SizedBox(height: 16.h),
              ],
              Text(
                _unlocked
                    ? context.l10n.safeShareReviewTitle
                    : context.l10n.safeShareFoundCount(plan.regions.length),
                style: context.text.overline,
              ),
              SizedBox(height: 8.h),
              for (int i = 0; i < plan.regions.length; i++) ...[
                FindingRow(
                  region: plan.regions[i],
                  onTreatmentChanged: _unlocked
                      ? (RegionTreatment treatment) =>
                            _setTreatment(i, treatment)
                      : null,
                ),
                SizedBox(height: 8.h),
              ],
            ],
          ),
        ),
        _Actions(
          unlocked: _unlocked,
          plan: plan,
          busy: _sharing || _rendering,
          onUnlock: _unlock,
          onShareProtected: () => _share(protected: true),
          onShareOriginal: () => _share(protected: false),
          // **Only on the way in from a share, and only once there is a copy
          // to keep.** A review opened on a library screenshot already has the
          // picture filed, so the offer there would be to save a redacted
          // near-duplicate of something the user owns — the very thing the
          // cache write exists to avoid. And before the paywall there is no
          // protected copy in existence, so the button would be promising to
          // keep a file that has never been rendered.
          onKeep: widget.incoming != null && _unlocked ? _keep : null,
        ),
      ],
    );
  }
}

/// The bottom bar, which says different things on either side of the wall.
class _Actions extends StatelessWidget {
  final bool unlocked;
  final RedactionPlan plan;
  final bool busy;
  final VoidCallback onUnlock;
  final VoidCallback onShareProtected;
  final VoidCallback onShareOriginal;

  /// Null wherever keeping the copy makes no sense — see the call site.
  final VoidCallback? onKeep;

  const _Actions({
    required this.unlocked,
    required this.plan,
    required this.busy,
    required this.onUnlock,
    required this.onShareProtected,
    required this.onShareOriginal,
    required this.onKeep,
  });

  /// "Clean this screenshot", plus the free try when there is one to spend.
  ///
  /// Read at build time rather than held in state: [FeatureTrials] is a
  /// `ChangeNotifier` the gate writes to, and the one moment this label has to
  /// change is the moment it is consumed — which happens two lines into the
  /// tap this button just handled.
  String _freeTryLabel(BuildContext context) {
    final bool offered =
        !sl<ProStatus>().isPro &&
        sl<FeatureTrials>().hasTrial(FeatureTrial.safeShare);
    final String action = context.l10n.safeShareCleanAction;
    return offered ? '$action · ${context.l10n.trialFree}' : action;
  }

  @override
  Widget build(BuildContext context) {
    final bool nothingToDo = plan.handledCount == 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 14.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Said out loud rather than left to be inferred from a button
          // label. Somebody who has switched every finding to "keep" is about
          // to send the screenshot exactly as it was, and that is worth one
          // sentence of warning.
          if (unlocked && nothingToDo) ...[
            Text(
              context.l10n.safeShareNothingSelected,
              style: context.text.caption.copyWith(color: context.colors.error),
            ),
            SizedBox(height: 6.h),
          ],
          PrimaryButton(
            label: unlocked
                ? (nothingToDo
                      ? context.l10n.safeShareShareUnchanged
                      : context.l10n.safeShareShareProtected)
                // **The free try, said here, on the button that spends it.**
                //
                // It was only ever on Home's tool row, and that was survivable
                // while Home was how people arrived. It stopped being
                // survivable the moment the share sheet grew a way in:
                // gallery → share → Shoto → cover reaches this screen without
                // passing Home at all, so the most important entry point was
                // the one that showed a paid-looking button and never
                // mentioned that the first one is free. Somebody who backs out
                // there was never told what they were backing out of.
                //
                // The same two conditions as the Home tag, deliberately: gone
                // once the allowance is spent, because a button that goes on
                // advertising a free try the gate will refuse is worse than
                // never having offered — and never shown to a subscriber, to
                // whom it is not an offer but a note that others pay less.
                : _freeTryLabel(context),
            icon: unlocked
                ? Icons.ios_share_rounded
                : Icons.auto_fix_high_rounded,
            isLoading: busy,
            onPressed: unlocked
                ? (nothingToDo ? onShareOriginal : onShareProtected)
                : onUnlock,
          ),
          // **Second, not first.** Sending it on is why this screen was
          // opened — somebody covers a card number because they are trying to
          // send the screenshot to a person. Keeping the copy is the useful
          // afterthought, and an afterthought that outranks the errand reads
          // as the app steering you into its own library.
          //
          // A full button rather than a text link, because it commits
          // something: unlike "share without changes" below, this one adds an
          // item to the user's library.
          if (onKeep != null) ...[
            SizedBox(height: 8.h),
            _KeepButton(onPressed: busy ? null : onKeep),
          ],
          SizedBox(height: 6.h),
          // Always available, on both sides of the wall. Somebody who decides
          // the findings do not matter should not have to pay to leave.
          TextButton(
            onPressed: busy ? null : onShareOriginal,
            child: Text(
              context.l10n.safeShareShareAsIs,
              style: context.text.caption.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Keep the copy", as an outlined twin of [PrimaryButton].
///
/// Written here rather than as a `filled: false` flag on that button, whose
/// own doc calls it *the app's one filled button* — a variant would make that
/// sentence false everywhere it is read. This is the only place in Shoto that
/// puts two committing actions side by side, so the second style lives with
/// the screen that needs it until something else asks for it too.
///
/// The geometry is deliberately identical — same height, same radius, same
/// press scale — because these two sit stacked and any difference reads as
/// misalignment rather than as hierarchy. What separates them is fill.
class _KeepButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _KeepButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    final Color tint = enabled
        ? context.colors.textPrimary
        : context.colors.textDisabled;

    return PressableScale(
      scale: 0.985,
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 35.h,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: context.colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_rounded, size: 16.sp, color: tint),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                context.l10n.safeShareKeepCopy,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.button.copyWith(color: tint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Scanning extends StatelessWidget {
  const _Scanning();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 44.w,
            height: 44.w,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: context.colors.primary,
            ),
          ),
          SizedBox(height: 18.h),
          Text(context.l10n.safeShareScanning, style: context.text.titleLarge),
          SizedBox(height: 5.h),
          Text(context.l10n.safeShareOnDevice, style: context.text.bodySmall),
        ],
      ),
    );
  }
}

class _NothingFound extends StatelessWidget {
  final VoidCallback onShare;

  const _NothingFound({required this.onShare});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: EmptyState(
        icon: Icons.verified_user_rounded,
        title: context.l10n.safeShareCleanTitle,
        message: context.l10n.safeShareCleanBody,
        action: PrimaryButton(
          label: context.l10n.safeShareShareAnyway,
          icon: Icons.ios_share_rounded,
          onPressed: onShare,
        ),
      ),
    );
  }
}

class _Unreadable extends StatelessWidget {
  const _Unreadable();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: EmptyState(
        icon: Icons.error_outline_rounded,
        title: context.l10n.safeShareUnreadableTitle,
        message: context.l10n.safeShareUnreadableBody,
        action: PrimaryButton(
          label: context.l10n.commonBack,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
