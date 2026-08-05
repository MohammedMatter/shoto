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
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/empty_state.dart';
import 'package:shoto/core/widgets/premium_gate.dart';
import 'package:shoto/core/widgets/primary_button.dart';
import 'package:shoto/features/safe_share/data/services/redaction_service.dart';
import 'package:shoto/features/safe_share/domain/entities/sensitive_region.dart';
import 'package:shoto/features/safe_share/presentation/widgets/finding_row.dart';
import 'package:shoto/features/safe_share/presentation/widgets/scan_report_card.dart';
import 'package:shoto/features/safe_share/presentation/widgets/screenshot_preview.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';

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
/// Two rules the screen obeys throughout. SHOTO never decides alone: it
/// proposes, shows exactly where every change lands, and the user confirms —
/// because the one thing worse than leaking a card number is an app that
/// silently rewrote the wrong half of a screenshot and let you send it
/// believing it was fine. And the preview is always the exported bytes, never
/// an approximation drawn with widgets, so what is checked is what is sent.
class SafeSharePage extends StatefulWidget {
  final ScreenshotEntity screenshot;

  const SafeSharePage({super.key, required this.screenshot});

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
      final File? file = await widget.screenshot.asset.file;
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
    if (!await ensurePremium(context)) return;
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

  /// Shares the protected copy, or the original when there was nothing to
  /// protect and the user asked to send it anyway.
  Future<void> _share({required bool protected}) async {
    setState(() => _sharing = true);
    try {
      final File out;
      if (protected) {
        // Never the debounced preview: a share tapped inside the debounce
        // window would send the copy from *before* the last change.
        final Uint8List bytes = await sl<RedactionService>().redact(
          _file!,
          _plan!,
        );
        // Written to a cache file rather than the gallery — this copy exists
        // to be sent, and saving every protected version would quietly fill
        // the user's library with near-duplicates of their own screenshots.
        final Directory dir = await getTemporaryDirectory();
        out = File(
          '${dir.path}/shoto_protected_'
          '${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await out.writeAsBytes(bytes);
        // Only the protected branch counts. Sending the original from this
        // screen means the user looked at what Safe Share found and decided
        // it did not need to do anything — a legitimate outcome, and not the
        // same event as the headline feature actually being used.
        sl<FunnelLog>().record(FunnelStep.safeShareCompleted);
      } else {
        out = _file!;
      }

      if (!mounted) return;
      setState(() => _sharing = false);
      await SharePlus.instance.share(ShareParams(files: [XFile(out.path)]));
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          context.l10n.safeShareTitle,
          style: AppTextStyles.titleLarge,
        ),
      ),
      body: SafeArea(top: false, child: _body()),
    );
  }

  Widget _body() {
    if (_failed) return _Unreadable();

    final RedactionPlan? plan = _plan;
    // Not `const`: every widget in this app reads the mutable `AppColors`
    // rather than `Theme.of`, and a const instance is identical across
    // rebuilds, so Flutter skips the subtree and freezes it at whichever
    // brightness happened to be active first. This has shipped twice.
    if (plan == null) return _Scanning();
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
                CoverExplainer(),
                SizedBox(height: 16.h),
              ],
              Text(
                _unlocked
                    ? context.l10n.safeShareReviewTitle
                    : context.l10n.safeShareFoundCount(plan.regions.length),
                style: AppTextStyles.overline,
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

  const _Actions({
    required this.unlocked,
    required this.plan,
    required this.busy,
    required this.onUnlock,
    required this.onShareProtected,
    required this.onShareOriginal,
  });

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
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
            SizedBox(height: 6.h),
          ],
          PrimaryButton(
            label: unlocked
                ? (nothingToDo
                      ? context.l10n.safeShareShareUnchanged
                      : context.l10n.safeShareShareProtected)
                : context.l10n.safeShareCleanAction,
            icon: unlocked
                ? Icons.ios_share_rounded
                : Icons.auto_fix_high_rounded,
            isLoading: busy,
            onPressed: unlocked
                ? (nothingToDo ? onShareOriginal : onShareProtected)
                : onUnlock,
          ),
          SizedBox(height: 6.h),
          // Always available, on both sides of the wall. Somebody who decides
          // the findings do not matter should not have to pay to leave.
          TextButton(
            onPressed: busy ? null : onShareOriginal,
            child: Text(
              context.l10n.safeShareShareAsIs,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Scanning extends StatelessWidget {
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
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 18.h),
          Text(context.l10n.safeShareScanning, style: AppTextStyles.titleLarge),
          SizedBox(height: 5.h),
          Text(context.l10n.safeShareOnDevice, style: AppTextStyles.bodySmall),
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
