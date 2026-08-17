import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/funnel_log.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/services/haptics.dart';
import 'package:shoto/core/services/premium_bootstrap.dart';
import 'package:shoto/core/routes/fade_slide_page_route.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/features/safe_share/presentation/pages/safe_share_page.dart';
import 'package:shoto/features/screenshots/presentation/widgets/intent_picker_row.dart';
import 'package:shoto/features/screenshots/presentation/widgets/shared_image_choice_sheet.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/domain/use_cases/create_folder_use_case.dart';
import 'package:shoto/features/folders/domain/use_cases/get_folders_use_case.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_limit_gate.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_colors.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_name_limit.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshot_limit_gate.dart';

/// The sheet that rises when an image is shared into Shoto.
///
/// It runs in its own translucent Android activity, so what the user sees is
/// their current app dimmed slightly with a small panel sliding up over it —
/// the same shape as a system share sheet. Nothing about it should read as
/// "you have been moved into another app", because being thrown into the
/// full app is exactly what made sharing here not worth doing.
class QuickSavePage extends StatefulWidget {
  const QuickSavePage({super.key});

  @override
  State<QuickSavePage> createState() => _QuickSavePageState();
}

// `signedOut` is gone. It was a dead end that could only be escaped by
// leaving the sheet, opening Shoto, handing over a Google account and
// sharing the image again — in front of the one flow whose entire value is
// that it takes two seconds and never leaves the app you were in. There is
// always a library to save into now.
enum _Stage {
  loading,

  /// Bringing up the subscription stack the covering path needs, which this
  /// process deliberately skipped at launch. See [ensurePremiumServicesReady].
  preparing,

  ready,
  naming,
  saving,
  saved,
  failed,
}

class _QuickSavePageState extends State<QuickSavePage>
    with SingleTickerProviderStateMixin {
  static const MethodChannel _channel = MethodChannel('shoto/share');

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.sheet,
    reverseDuration: AppMotion.normal,
  );

  late final Animation<double> _rise = CurvedAnimation(
    parent: _controller,
    // The one surface in the app with real distance to travel, so it gets
    // the strongest ease-out: almost all of the rise happens in the first
    // third, then it settles. That front-loading is what makes a sheet feel
    // like it was already on its way rather than starting when you looked.
    curve: AppMotion.emphasis,
    reverseCurve: AppMotion.exit,
  );

  /// Flick speed that dismisses regardless of how far the sheet was dragged.
  ///
  /// Was 700px/s, which is a hard throw — a normal downward flick sat around
  /// 300 and the sheet stubbornly sprang back. Dismissal should follow the
  /// gesture's *intent*, and 320px/s is comfortably above anything produced
  /// by scrolling or an accidental brush.
  static const double _flickVelocity = 320;

  /// Or drag it this far and let go, at any speed.
  static const double _dismissDistance = 110;

  /// Where the drag stops following the finger one-to-one.
  static const double _resistAfter = 180;

  /// Rubber-banding past [_resistAfter].
  ///
  /// Without it the sheet tracks the finger all the way to 600px and simply
  /// stops dead, which feels like the gesture broke. Resistance says "you
  /// have gone far enough for this to count" through the movement itself,
  /// so the user knows the throw has registered before they let go.
  static double _resist(double offset) {
    if (offset <= _resistAfter) return offset.clamp(0, _resistAfter);
    return _resistAfter + (offset - _resistAfter) * 0.35;
  }

  _Stage _stage = _Stage.loading;

  /// Everything this share brought in. One image is just the common case —
  /// selecting several screenshots in the gallery and sharing them all is a
  /// single trip through this sheet.
  List<_SharedImage> _images = const [];

  /// How many images Android handed over beyond what the sheet accepts, so
  /// the user is told rather than quietly given fewer than they picked.
  int _skipped = 0;

  /// Where this sheet was opened from, which only ever matters when nothing
  /// arrived.
  ///
  /// **An empty hand has three different causes and three different next
  /// steps**, and offering the wrong one is worse than offering none:
  ///
  /// * a **share** that comes back empty is an image that could not be read,
  ///   and sharing it again is the fix;
  /// * a **tile** press with nothing to show means the phone holds no
  ///   screenshot — telling that person to re-share a picture they never took
  ///   sends them hunting for a share sheet that was never involved;
  /// * a tile press **without photo access** looks identical from here and is
  ///   a dead end: Android revokes permissions from apps left unused for a few
  ///   months, so "take a screenshot and tap again" becomes a loop they cannot
  ///   leave, because what is missing was never a screenshot.
  String _source = 'share';

  List<FolderEntity> _folders = const [];
  FolderEntity? _selected;

  /// What the user says they will do with what they are saving.
  ///
  /// Never required. The button is enabled without it and always has been —
  /// this is one optional tap taken at the only moment the answer is obvious,
  /// not a second thing to fill in before a screenshot can be kept.
  IntentRef? _intent;

  int get _alreadyInLibraryCount =>
      _images.where((image) => image.isAlreadyInLibrary).length;

  bool get _allAlreadyInLibrary =>
      _images.isNotEmpty && _alreadyInLibraryCount == _images.length;

  /// A folder is the point. Saving to the library and stopping there just
  /// makes another pile to sort later, which is the problem Shoto exists to
  /// solve — so the button waits until somewhere has been chosen.
  bool get _inert => _selected == null;

  /// How far the user has dragged the sheet down, in logical pixels. Kept
  /// separate from the controller so a drag can be abandoned and spring back
  /// without fighting the entrance animation.
  double _dragOffset = 0;
  bool _closing = false;

  /// Completes once the sheet has finished arriving.
  ///
  /// [_load] waits on this before swapping the spinner out for the form. The
  /// work itself still starts immediately in [initState] — what is deferred is
  /// only the *rebuild*, because landing it mid-slide meant an AnimatedSize
  /// relayout and an AnimatedSwitcher crossfade running on top of a surface
  /// that was still translating. Three animations of three different kinds,
  /// on the same subtree, in the same frames.
  final Completer<void> _entered = Completer<void>();

  void _markEntered() {
    if (!_entered.isCompleted) _entered.complete();
  }

  @override
  void initState() {
    super.initState();
    // Both start now. Only the rebuild waits — see [_entered].
    _controller.forward().whenComplete(_markEntered);
    _load();

    // Android hands a second share to the instance already on screen rather
    // than building a new one, so this sheet has to be able to become a
    // different share without being rebuilt. See `ShareActivity.onNewIntent`.
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'reshare') await _reshare();
    });
  }

  /// A different picture, into the sheet already standing.
  ///
  /// **Everything on screen belongs to the picture that has just been
  /// replaced**, and that includes whatever is stacked over the sheet — a Safe
  /// Share review of the old image, or the paywall opened from it. Leaving
  /// those up would show the user findings for a screenshot they are no longer
  /// sharing, with a button that sends it.
  ///
  /// The panel itself is deliberately *not* replayed. It is already up, the
  /// user is already looking at it, and animating it out and back in to say
  /// "the thing you just shared arrived" would be the app performing its own
  /// plumbing.
  Future<void> _reshare() async {
    if (!mounted || _closing) return;

    Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);

    setState(() {
      _stage = _Stage.loading;
      _images = const [];
      _skipped = 0;
      // Cleared with the rest: a folder chosen for the previous picture is not
      // an answer about this one, and leaving it selected would arm the save
      // button before the user has looked at anything.
      _selected = null;
      _intent = null;
    });

    await _load();
  }

  @override
  void dispose() {
    // A cancelled ticker never completes its future, so `whenComplete` above
    // would not fire and anything awaiting [_entered] would hang forever.
    _markEntered();
    _channel.setMethodCallHandler(null);
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      // **Started before the images are asked for, not after them.**
      //
      // The folder list has nothing to do with the picture — it is this
      // account's folders, the same answer whatever arrived — and it used to
      // be read at the end, after the channel round trip and after every
      // shared image had been resolved against the library. That put a
      // database open, which is the slowest thing on this path, at the back of
      // a queue it had no reason to be in.
      //
      // Kicked off here instead, so it overlaps the platform call and the
      // lookups below. Not awaited until the moment the form actually needs
      // it, which is the whole point.
      final Future<List<FolderEntity>> folders = sl<GetFoldersUseCase>()();

      final Map<Object?, Object?>? shared = await _channel
          .invokeMethod<Map<Object?, Object?>>('getSharedImages');
      final List<Object?> raw =
          (shared?['images'] as List<Object?>?) ?? const [];
      // Read before the early return below, since the empty case is the one
      // place it matters.
      final String source = (shared?['source'] as String?) ?? 'share';
      if (raw.isEmpty) {
        if (mounted) {
          setState(() {
            _source = source;
            _stage = _Stage.failed;
          });
        }
        return;
      }

      final ScreenshotRepository repository = sl<ScreenshotRepository>();
      final List<_SharedImage> images = [];
      for (final Object? entry in raw) {
        final Map<Object?, Object?> map = entry as Map<Object?, Object?>;
        final String? path = map['path'] as String?;
        if (path == null) continue;

        // Sharing a screenshot Shoto already shows used to write a *second*
        // copy into the gallery, so the app then listed the same picture
        // twice and the whole feature looked pointless. Resolving the
        // MediaStore id means anything already in the library is only filed.
        final String? mediaId = map['mediaId'] as String?;
        images.add(
          _SharedImage(
            path: path,
            mediaId: mediaId,
            fromShotoItself: map['fromShoto'] == true,
            existingAssetId: mediaId == null
                ? null
                : await repository.findLibraryAsset(mediaId),
          ),
        );
      }

      if (images.isEmpty) {
        if (mounted) {
          setState(() {
            _source = source;
            _stage = _Stage.failed;
          });
        }
        return;
      }

      final List<FolderEntity> loadedFolders = await folders;

      await _entered.future;
      // `_closing` as well as `mounted`: the entrance can be released by a
      // dismissal rather than by finishing, and swapping the spinner for the
      // form on a sheet that is already sliding away is worse than the mid-
      // slide rebuild this deferral exists to prevent.
      if (!mounted || _closing) return;
      setState(() {
        _images = images;
        _skipped = (shared?['skipped'] as int?) ?? 0;
        _folders = loadedFolders;
        // **Filing, always, without being asked anything first.**
        //
        // Covering briefly got its own stage here — a full-width two-option
        // gate that every share had to answer before it could reach a folder.
        // It put the app's best feature in front of people, and it charged the
        // common case for it: the overwhelming majority of shares are somebody
        // keeping a picture, and all of them were stopped, made to read two
        // paragraphs and pick. A sheet whose whole promise is that it takes two
        // seconds cannot open with a decision.
        //
        // So the default is the default again, and covering is one tap from
        // inside it — see the entry at the foot of the form.
        _stage = _Stage.ready;
      });
    } catch (_) {
      if (mounted) setState(() => _stage = _Stage.failed);
    }
  }

  /// Whether this share may be covered rather than filed.
  ///
  /// Drives the secondary entry at the foot of the form, and nothing else —
  /// there is no stage to reach and nothing to answer. See [coveringOffered]
  /// for why a four-image share and Shoto's own output are both excluded.
  bool get _canCover =>
      _images.isNotEmpty &&
      coveringOffered(
        _images.length,
        fromShotoItself: _images.first.fromShotoItself,
      );

  /// Straight into Safe Share on the file the other app handed over.
  ///
  /// **Nothing is imported first, and that is the whole promise of this
  /// path.** Somebody covering an account number asked for the picture to be
  /// fixed, not filed; growing their library with it on the way past would
  /// break the sentence the app says on two of its own screens. The file here
  /// is the copy `ShareActivity` already materialised into the cache, which is
  /// exactly what [SafeSharePage.incoming] is built to take.
  ///
  /// A full page over the sheet rather than more sheet: covering is a review,
  /// with findings to read and treatments to choose, and none of that fits in
  /// a panel sized for one question. The activity's window is translucent, so
  /// the opaque page simply becomes what is on screen.
  /// Whether filing this share would stay inside the free tier's cap — and if
  /// not, whether the user came back from the paywall having paid.
  ///
  /// **Counts what would newly come *under management*, not what is being
  /// saved.** The cap is on screenshots Shoto is looking after, which means a
  /// row in `screenshot_meta` with a folder or a star. Three things arrive at
  /// this sheet and only two of them add to that number:
  ///
  /// * an image not in the library yet — imported and filed, so it counts;
  /// * one already in the library but unsorted — filing it is what brings it
  ///   under management, so it counts;
  /// * one already filed somewhere — moving it between folders changes nothing
  ///   about how many Shoto looks after, so it must not count, or re-filing
  ///   your own screenshots would walk you into a paywall.
  ///
  /// The third case is why this asks the repository rather than counting the
  /// list. Guessing high here is not the safe direction: it charges people for
  /// work they already paid for.
  Future<bool> _withinFreeLimit() async {
    setState(() => _stage = _Stage.preparing);

    // Same reasoning as [_protect]: the subscription stack is not up in this
    // process, and `ensureUnderScreenshotLimit` reads it. Without this a
    // subscriber would be shown a paywall for a limit they do not have — the
    // exact failure premium_bootstrap.dart was written about.
    await ensurePremiumServicesReady();
    if (!mounted || _closing) return false;

    final ScreenshotRepository repository = sl<ScreenshotRepository>();
    int newlyManaged = _images.where((i) => !i.isAlreadyInLibrary).length;

    final List<String> existing = _images
        .map((_SharedImage image) => image.existingAssetId)
        .nonNulls
        .toList();
    if (existing.isNotEmpty) {
      final List<ScreenshotEntity> known = await repository.getScreenshotsByIds(
        existing,
      );
      newlyManaged += known
          .where((ScreenshotEntity s) => !s.isFavorite && s.folderId == null)
          .length;
    }

    if (!mounted || _closing) return false;
    final bool allowed = await ensureUnderScreenshotLimit(
      context,
      additionalNewItems: newlyManaged,
    );
    if (!mounted || _closing) return false;

    // Back to the form either way. Refused, it is what the user returns to;
    // allowed, [_save] moves straight on to `saving` and this frame is never
    // seen.
    setState(() => _stage = _Stage.ready);
    return allowed;
  }

  Future<void> _protect() async {
    setState(() => _stage = _Stage.preparing);

    // Awaited here rather than at launch, so the shares that never touch a
    // paid feature — most of them — do not pay for the store.
    await ensurePremiumServicesReady();
    if (!mounted || _closing) return;

    // **Back to the form before the page goes up, not after it comes down.**
    //
    // The spinner covers the bootstrap and nothing else. Left in place it
    // would sit underneath Safe Share for the whole review — an indeterminate
    // progress indicator animating every frame behind an opaque page, which is
    // both a lie about something still loading and a widget the framework can
    // never consider settled. The form is also exactly what should be revealed
    // if the page is dismissed, so putting it back now means the retreat path
    // has nothing left to do.
    setState(() => _stage = _Stage.ready);

    final SafeShareOutcome? outcome = await Navigator.of(context)
        .push<SafeShareOutcome>(
          FadeSlidePageRoute(
            builder: (_) =>
                SafeSharePage.incoming(incoming: File(_images.first.path)),
          ),
        );
    if (!mounted || _closing) return;

    // **Three ways out of Safe Share, and only one of them is "nothing
    // happened".**
    //
    // Null is the back gesture, which means "not this" rather than "I am
    // finished with Shoto" — the form is already showing underneath, so a
    // mis-tap costs nothing. The other two both mean the user finished, and
    // for a while they were all treated as the first: somebody who covered an
    // account number and sent it landed back on the sheet they started from,
    // the app asking them to begin a task they had just completed.
    if (outcome == null) return;

    if (outcome.handedOn) {
      await _close();
      return;
    }

    // Kept. The covered copy replaces the picture that arrived, and the sheet
    // carries on into the filing it already knows how to do — folders, the
    // intent, the ceiling. Marked as ours because it is: it came out of Safe
    // Share, so a later `reshare` must not offer to cover it again.
    setState(() {
      _images = <_SharedImage>[
        _SharedImage(
          path: outcome.kept!.path,
          mediaId: null,
          existingAssetId: null,
          fromShotoItself: true,
        ),
      ];
      _stage = _Stage.ready;
    });
  }

  Future<void> _save() async {
    final FolderEntity? folder = _selected;
    if (folder == null) return;

    // Resolved here, synchronously, before a single `await` runs.
    //
    // Both are read off `context`, and everything below is asynchronous — the
    // import, the filing, then a two-second wait during which the user can
    // drag the sheet away. Reading a MediaQuery off an element that has since
    // been unmounted is how a delay like this becomes a crash nobody can
    // reproduce.
    //
    // **The dwell is two seconds, and that is deliberate.** It went
    // 950 -> 420 -> 800 -> 2000 before landing, and the mistake in the middle
    // is worth recording: 420 came from applying the 300ms UI ceiling to it.
    // That ceiling is for motion a user is *waiting on* — a sheet opening, a
    // button answering a press. This is not that. Nothing is blocked; the
    // save is already committed and the sheet leaves on its own. It is a
    // confirmation, and a confirmation's only job is to be read.
    //
    // Read by whom, and from where, is what sets the number. This panel
    // appears over a completely different app, so the eye has to travel to it
    // before it can start reading — and the tick still needs AppMotion.normal
    // to arrive through the AnimatedSwitcher below. At 800ms it was landing
    // as a flash. Two seconds is a dwell, the length a toast sits for, and
    // nothing waits on it: every exit stays live throughout, so anyone who has
    // already read it leaves immediately.
    final Duration dwell = AppMotion.duration(
      context,
      const Duration(seconds: 2),
    );

    // The one exit in this sheet that **nobody asked for**.
    //
    // `reverseDuration` is AppMotion.normal — 220ms — because every other way
    // out of here is user-initiated: a drag, the back gesture, a tap on the
    // scrim. In all of those the user has decided and is now waiting on the
    // app, so the exit should snap. This one is the app leaving on its own
    // while the user is still reading, and 220ms across a full-height sheet
    // reads as the panel being yanked rather than withdrawing.
    final Duration exit = AppMotion.duration(context, AppMotion.sheet);

    // **The free tier's one cap, checked on the path that had never checked
    // it.**
    //
    // `ensureUnderScreenshotLimit` guarded five entry points — the detail
    // page, the quick-actions sheet, the selection toolbar, the old share
    // listener — and not this one. That would be a small omission except that
    // session 14 made *this* the primary way screenshots enter the library:
    // every other door files something that is already inside. So the one
    // unguarded door was the front one, and a free account could walk past
    // fifty without ever meeting the limit it was under.
    //
    // Checked on the tap rather than when the sheet opens — the same trade
    // covering makes (see [_protect]): most shares are under the cap and must
    // not pay a store round trip to discover it.
    //
    // **Below the two lines above, not before them.** They read `context`
    // synchronously precisely so that nothing awaits ahead of them, and
    // putting this first quietly turned both into reads across an async gap —
    // which the analyzer caught and which would, one day, have been the crash
    // their comment was written to prevent.
    if (!await _withinFreeLimit()) return;

    setState(() => _stage = _Stage.saving);
    try {
      final ScreenshotRepository repository = sl<ScreenshotRepository>();

      // Import only what this account does not already have; everything else
      // is purely a filing operation on an asset that is already there.
      final List<String> assetIds = [];
      for (final _SharedImage image in _images) {
        assetIds.add(
          image.existingAssetId ??
              await repository.importSharedFile(
                image.path,
                sourceAssetId: image.mediaId,
              ),
        );
      }

      // One call for the whole batch rather than one per image — filing is
      // the single thing the user asked for, so it either happened or it
      // didn't.
      await repository.assignFolder(assetIds, folder.id);

      // After the filing, and never allowed to fail the save. Filing is what
      // the user pressed the button for; an intent is a note attached to it,
      // and losing the screenshot because a note could not be written would be
      // the wrong way round.
      final IntentRef? intent = _intent;
      if (intent != null) {
        for (final String assetId in assetIds) {
          try {
            await repository.setIntent(assetId, intent);
          } catch (error) {
            debugPrint('Shoto: intent not recorded for $assetId — $error');
          }
        }
      }

      // Activation, and the only step in the funnel that changes what the
      // user owns. Recorded after the writes rather than on the tap, so it
      // counts screenshots that actually landed.
      sl<FunnelLog>().record(FunnelStep.screenshotSaved);

      if (!mounted) return;
      Haptics.confirm();
      setState(() => _stage = _Stage.saved);
    } catch (error, stack) {
      // Still reported as a failed save rather than crashing the sheet — but
      // no longer swallowed. Everything that goes wrong in here used to
      // surface as "Could not read that image", which points at the file and
      // sends anyone debugging it to the wrong place.
      debugPrint('Shoto: quick save failed — $error\n$stack');
      if (mounted) setState(() => _stage = _Stage.failed);
      return;
    }

    // Deliberately **outside** the try.
    //
    // The close used to sit inside it, which meant a failure while dismissing
    // was caught by the same handler as a failure while saving — and that
    // handler flips the sheet to `_Stage.failed`. So a screenshot that had
    // been imported and filed correctly could still report that it had not
    // been, purely because the platform channel that finishes the activity
    // threw on the way out. Telling someone their save failed when it did not
    // is worse than any close error the try was protecting against.
    await Future<void>.delayed(dwell);
    if (!mounted) return;

    // Two seconds is long enough that the user often beats it. The drag, the
    // back gesture and the scrim all route through [_close], which sets
    // `_closing` and starts the reverse. Without this guard the auto-close
    // would reach in and rewrite `reverseDuration` on a controller that is
    // already reversing, then call [_close] a second time. Neither is harmful
    // today — the controller reads its duration when the reverse begins, and
    // [_close] returns early on `_closing` — but both stop being harmless the
    // moment somebody changes one of them.
    if (_closing) return;

    _controller.reverseDuration = exit;
    await _close();
  }

  /// Plays the sheet back down before handing control to Android, so the
  /// activity never vanishes mid-animation.
  final TextEditingController _nameController = TextEditingController();
  int _newFolderColor = kFolderColors.first;

  Future<void> _createFolder() async {
    final String name = _nameController.text.trim();
    if (name.isEmpty) return;

    // The free tier's folder cap, checked here as well as on the Folders tab
    // — this is the *other* place a folder can be made, and a limit with two
    // entry points and one guard is not a limit. See [ensureUnderFolderLimit];
    // it counts for itself rather than trusting [_folders], which was read
    // when this sheet opened and belongs to a share activity that may have
    // been sitting behind the app for a while.
    if (!await ensureUnderFolderLimit(context)) return;
    if (!mounted) return;

    final FolderEntity created = await sl<CreateFolderUseCase>()(
      name,
      _newFolderColor,
    );
    sl<FunnelLog>().record(FunnelStep.folderCreated);
    if (!mounted) return;
    // Drop straight back into the save flow with the new folder already
    // chosen — making someone pick it again right after naming it would be
    // asking the same question twice.
    setState(() {
      _folders = [..._folders, created];
      _selected = created;
      _stage = _Stage.ready;
      _nameController.clear();
    });
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    // Releases anything waiting on the entrance.
    //
    // `reverse()` below cancels the in-flight `forward()`, and a cancelled
    // Ticker's future never completes — so `whenComplete` never fires and
    // [_load] would sit on `_entered.future` until dispose happened to free
    // it. Dragging the sheet away during its own 280ms arrival is a real
    // thing to do, and "it works because the widget gets destroyed later" is
    // not a guarantee worth depending on.
    _markEntered();
    if (mounted) setState(() => _dragOffset = 0);
    await _controller.reverse();
    await _channel.invokeMethod<void>('close');
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_stage == _Stage.saving ||
        _stage == _Stage.saved ||
        // Committed work in flight, with a page about to arrive over the top.
        // Dragging the panel away underneath it leaves Safe Share standing on
        // a sheet that has already asked Android to finish the activity.
        _stage == _Stage.preparing) {
      return;
    }
    setState(() => _dragOffset = _resist(_dragOffset + details.delta.dy));
  }

  void _onDragEnd(DragEndDetails details) {
    if (_stage == _Stage.saving ||
        _stage == _Stage.saved ||
        // Committed work in flight, with a page about to arrive over the top.
        // Dragging the panel away underneath it leaves Safe Share standing on
        // a sheet that has already asked Android to finish the activity.
        _stage == _Stage.preparing) {
      return;
    }
    // Either a decisive flick or dragged far enough to mean it. Anything else
    // springs back, which is what makes an accidental brush feel forgiving.
    final bool dismissed =
        details.velocity.pixelsPerSecond.dy > _flickVelocity ||
        _dragOffset > _dismissDistance;
    if (dismissed) {
      _close();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        // Transparent all the way down, so the app behind stays visible.
        backgroundColor: Colors.transparent,
        // The sheet lifts itself above the keyboard (see [_Sheet]) rather than
        // letting Scaffold resize the body. Scaffold's version would shrink
        // the *scrim* too, exposing a strip of the app behind it, and this
        // activity is translucent so that strip is the user's home screen.
        resizeToAvoidBottomInset: false,
        body: AnimatedBuilder(
          animation: _rise,
          builder: (context, child) {
            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _close,
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.55 * _rise.value),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionalTranslation(
                    translation: Offset(0, 1 - _rise.value),
                    child: Transform.translate(
                      offset: Offset(0, _dragOffset),
                      child: child,
                    ),
                  ),
                ),
              ],
            );
          },
          // The sheet is rasterised once and then only re-composited as it
          // slides and as it is dragged. Without this the whole subtree
          // repainted on every frame of both — the same pixels at a different
          // offset, which is exactly what a repaint boundary exists to tell
          // Flutter it can skip.
          //
          // It earned its place against a full-width `BoxShadow` at
          // `blurRadius: 32` that used to sit on this panel, redrawn sixty
          // times a second for a surface that was only moving. That shadow is
          // gone now (see [AppPalette]), so the saving is smaller — but the
          // panel is still the widest, deepest subtree in the app and it still
          // moves under a finger, which is the case this is for.
          child: RepaintBoundary(
            child: _Sheet(
              onDragUpdate: _onDragUpdate,
              onDragEnd: _onDragEnd,
              child: AnimatedSize(
                duration: AppMotion.duration(context, AppMotion.normal),
                curve: AppMotion.standard,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: AppMotion.duration(context, AppMotion.normal),
                  switchInCurve: AppMotion.standard,
                  // Was missing, so the outgoing stage faded out on a linear
                  // curve while the incoming one eased in.
                  switchOutCurve: AppMotion.standard,
                  child: _content(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content() {
    switch (_stage) {
      case _Stage.loading:
        return _spinner(const ValueKey('loading'));

      // Same spinner, its own key. The two waits are indistinguishable to look
      // at and must stay distinguishable to the AnimatedSwitcher: sharing a key
      // would let it treat the second as a continuation of the first and skip
      // the crossfade back from the offer.
      case _Stage.preparing:
        return _spinner(const ValueKey('preparing'));

      // Nothing arrived — but *why* differs by where the sheet was opened
      // from, and so does the only useful next step. See [_fromTile]. The
      // tile's version is not an error either: a phone with no screenshot on
      // it is a phone working correctly, so it takes the neutral glyph and the
      // app's own accent rather than the alarm red kept for things that broke.
      case _Stage.failed:
        return switch (_source) {
          // Not an error, so not the alarm colour: a phone with no screenshot
          // on it is a phone working correctly.
          'tile' => _Status(
            key: const ValueKey('no-capture'),
            icon: Icons.photo_camera_back_outlined,
            tint: context.colors.primary,
            title: context.l10n.quickSaveNoCaptureTitle,
            subtitle: context.l10n.quickSaveNoCaptureBody,
          ),
          // This one *is* something the user has to go and fix, and the fix
          // is not on this sheet — the full app is where access can be asked
          // for again, so the sentence points there rather than at a button
          // that cannot exist here.
          'tile-no-access' => _Status(
            key: const ValueKey('no-access'),
            icon: Icons.no_photography_outlined,
            tint: context.colors.warning,
            title: context.l10n.quickSaveNoAccessTitle,
            subtitle: context.l10n.quickSaveNoAccessBody,
          ),
          _ => _Status(
            key: const ValueKey('failed'),
            icon: Icons.error_outline_rounded,
            tint: context.colors.error,
            title: context.l10n.quickSaveFailedTitle,
            subtitle: context.l10n.quickSaveFailedBody,
          ),
        };

      case _Stage.saved:
        return _Status(
          key: const ValueKey('saved'),
          icon: Icons.check_rounded,
          tint: context.colors.success,
          title: context.l10n.quickSaveSaved,
          subtitle: _savedSubtitle(context),
        );

      case _Stage.naming:
        return _newFolderForm();

      case _Stage.ready:
      case _Stage.saving:
        return _form();
    }
  }

  /// A spinner repaints on every single frame, for as long as it is on screen.
  /// Unboxed, that marked the entire sheet dirty sixty times a second — the
  /// whole panel, for a 40-pixel spinner — so a widget whose job is to say
  /// "please wait" was itself the reason the wait looked rough. Its own
  /// boundary keeps those repaints to the 40 or so pixels that actually change.
  Widget _spinner(Key key) => Padding(
    key: key,
    padding: EdgeInsets.symmetric(vertical: 46.h),
    child: Center(
      child: RepaintBoundary(
        child: CircularProgressIndicator(color: context.colors.primary),
      ),
    ),
  );

  /// Naming a folder without leaving the sheet.
  ///
  /// Sending someone into the full app to make a folder and then back out to
  /// finish saving would break the one promise this sheet makes — that it
  /// does not take you anywhere.
  Widget _newFolderForm() {
    return Column(
      key: const ValueKey('naming'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PressableScale(
              scale: 0.9,
              onTap: () => setState(() => _stage = _Stage.ready),
              child: Icon(
                Icons.arrow_back_rounded,
                color: context.colors.textSecondary,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Text(context.l10n.foldersNew, style: context.text.titleLarge),
          ],
        ),
        SizedBox(height: 16.h),
        TextField(
          controller: _nameController,
          autofocus: true,
          maxLength: kMaxFolderNameLength,
          textCapitalization: TextCapitalization.sentences,
          style: context.text.bodyLarge,
          onSubmitted: (_) => _createFolder(),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: context.l10n.foldersNameHint,
            hintStyle: context.text.bodyLarge.copyWith(
              color: context.colors.textDisabled,
            ),
            // Suppressed for the same reason as the intent label field: the
            // cap is here so the button and the chips can render the name,
            // not a budget the user is meant to watch themselves spend.
            counterText: '',
            filled: true,
            fillColor: context.colors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 14.h,
            ),
          ),
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            for (final int color in kFolderColors) ...[
              PressableScale(
                scale: 0.85,
                onTap: () => setState(() => _newFolderColor = color),
                child: Container(
                  width: 30.w,
                  height: 30.w,
                  decoration: BoxDecoration(
                    color: Color(color),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _newFolderColor == color
                          ? context.colors.textPrimary
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 9.w),
            ],
          ],
        ),
        SizedBox(height: 20.h),
        PressableScale(
          onTap: _nameController.text.trim().isEmpty ? null : _createFolder,
          child: Container(
            height: 52.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: _nameController.text.trim().isEmpty
                  ? null
                  : context.colors.primaryGradient,
              color: _nameController.text.trim().isEmpty
                  ? context.colors.surfaceVariant
                  : null,
              borderRadius: BorderRadius.circular(17.r),
            ),
            child: Text(
              context.l10n.foldersCreate,
              style: context.text.button.copyWith(
                color: _nameController.text.trim().isEmpty
                    ? context.colors.textDisabled
                    : context.colors.onPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _form() {
    final bool busy = _stage == _Stage.saving;

    return Column(
      key: const ValueKey('form'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          // Keyed so a test can measure it. The covering entry inside this row
          // claims to land in space the row was already paying for, and that
          // claim is only worth making if something checks it — see
          // `share_covering_test.dart`.
          key: const ValueKey<String>('shareHeader'),
          children: [
            // The preview is the confirmation that the *right* images
            // arrived, which matters more than it sounds when several apps
            // can share — and more still once a share can carry a dozen.
            _SharedPreview(images: _images),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // **One line each, and that is load-bearing now.**
                  //
                  // Both of these used to have the whole width and could wrap
                  // as far as they liked. The cover button on the trailing
                  // edge takes about ninety points of it, and unbounded these
                  // two answered by running to three lines — which pushed the
                  // header past the thumbnail that sets its height and made a
                  // "free" control cost forty points. Ellipsis is the right
                  // answer regardless: a header that reflows to three lines
                  // because the picture came from a different app is a header
                  // whose size the user cannot predict.
                  Text(
                    _title(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleLarge,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _folders.isEmpty
                        ? context.l10n.quickSaveNeedFolder
                        : context.l10n.quickSavePickFolder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                  if (_skipped > 0) ...[
                    SizedBox(height: 3.h),
                    Text(
                      context.l10n.quickSaveSkipped(_images.length),
                      style: context.text.caption.copyWith(
                        color: context.colors.warning,
                      ),
                    ),
                  ],

                  // **The way into covering, said in words.**
                  //
                  // It was a bare shield on the trailing edge for one build,
                  // and a glyph on its own does not read as a control — it
                  // reads as decoration, or as a status badge about the
                  // picture. Somebody who shared a screenshot *because* it has
                  // an account number in it had no way to know the thing they
                  // came for was one tap away.
                  //
                  // Placed inside the header's own column rather than under
                  // the save button, because that column is the one part of
                  // this sheet with room already going spare: the row's height
                  // is set by the 62pt thumbnail beside it, and two lines of
                  // text do not fill 62pt. A third line lands in space the
                  // sheet was already paying for — asserted as an equal-height
                  // comparison in `share_covering_test.dart`, not left to this
                  // paragraph.
                  //
                  // Tinted and led by the shield so it reads as an action
                  // rather than as more description, and it borrows the words
                  // the paywall and Home already use for this feature.
                  if (_canCover) ...[
                    // 2, not the 5 this started at. The header's whole budget
                    // is the thumbnail's 62pt beside it, and at 5 the three
                    // lines came to 64.4 — the row grew by two and a half
                    // pixels and the claim below stopped being true. Measured,
                    // then set to the number that fits.
                    SizedBox(height: 2.h),
                    Text(
                      context.l10n.quickSaveCoverWhy,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.caption.copyWith(
                        color: context.colors.secondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // **A button, on the trailing edge, in space the header already
            // had.**
            //
            // Four arrangements got here and the discarded three are worth
            // recording, because they failed in two different ways. A
            // two-option gate the sheet opened on, and then a full-width row
            // under the save button, both charged the common case — nearly
            // every share is somebody keeping a picture — for a decision only
            // a few people need. Then a bare shield on this edge, which cost
            // nothing and *communicated* nothing: a glyph alone reads as
            // decoration, or as a badge about the picture. Then a tinted line
            // of text, which said what it did and still looked like writing.
            //
            // So: a real surface, a border, a label. It is a button because it
            // has to look like one before anybody presses it.
            //
            // The four-word question to its left carries the *why*, which is
            // the half a one-word label cannot hold. Together they read "has
            // private details?" / "cover" — the whole feature, in five words,
            // at a glance.
            //
            // Still on this row rather than below the save button, for the
            // reason the whole arrangement exists: the row's height is set by
            // the 62pt thumbnail, so everything placed here is free. Asserted
            // as an equal-height comparison in `share_covering_test.dart`,
            // not left to this paragraph.
            if (_canCover) ...[
              SizedBox(width: 10.w),
              PressableScale(
                scale: 0.94,
                onTap: busy ? null : _protect,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 11.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.secondary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(13.r),
                    border: Border.all(
                      color: context.colors.secondary.withValues(alpha: 0.45),
                    ),
                  ),
                  // Side by side rather than stacked. Stacked was the first
                  // try and it stood 101pt — the row's budget is the
                  // thumbnail's 62 — so the chip alone would have made the
                  // sheet taller than the gate this whole design replaced.
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 16.sp,
                        color: context.colors.secondary,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        context.l10n.quickSaveCoverAction,
                        maxLines: 1,
                        style: context.text.caption.asSemiBold.copyWith(
                          color: context.colors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        if (_folders.isEmpty) ...[
          SizedBox(height: 18.h),
          // No folders yet. Rather than a disabled control and no explanation,
          // the sheet says what a folder is for and offers to make one here.
          PressableScale(
            scale: 0.98,
            onTap: () => setState(() => _stage = _Stage.naming),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15.r),
                border: Border.all(
                  color: context.colors.primary.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.create_new_folder_rounded,
                    color: context.colors.primary,
                    size: 19.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.quickSaveCreateFirstFolder,
                          style: context.text.titleSmall,
                        ),
                        Text(
                          context.l10n.quickSaveCreateFirstFolderWhy,
                          style: context.text.caption,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.add_rounded,
                    color: context.colors.primary,
                    size: 19.sp,
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_folders.isNotEmpty) ...[
          SizedBox(height: 20.h),
          SizedBox(
            height: 38.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              // "New" leads, then the folders. It sits first because the
              // folder you want is often the one that doesn't exist yet, and
              // at the far end of a scrolling strip it was effectively
              // hidden behind however many folders you already had.
              itemCount: _folders.length + 1,
              separatorBuilder: (_, _) => SizedBox(width: 8.w),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _FolderChip(
                    label: context.l10n.quickSaveNewChip,
                    icon: Icons.add_rounded,
                    selected: false,
                    onTap: () => setState(() => _stage = _Stage.naming),
                  );
                }
                final FolderEntity folder = _folders[index - 1];
                return _FolderChip(
                  label: folder.name,
                  icon: Icons.folder_rounded,
                  tint: Color(folder.color),
                  selected: _selected?.id == folder.id,
                  onTap: () => setState(() => _selected = folder),
                );
              },
            ),
          ),
        ],
        // **Asked here, and nowhere earlier, because here is where the answer
        // is known.**
        //
        // The intent is the one thing about a screenshot the app can never
        // work out for itself, and the moment of saving is the only moment the
        // person holding the phone still remembers why they took it. A day
        // later they are looking at a picture of a shoe with no idea whether
        // they meant to buy it or laugh at it.
        //
        // Below the folders rather than above: filing is what the button does
        // and what the sheet is for. This is an optional note taken on the way
        // past, and putting it first would make it look like a second required
        // field.
        SizedBox(height: 18.h),
        IntentPickerRow(
          selected: _intent,
          onChanged: (IntentRef? next) => setState(() => _intent = next),
        ),

        SizedBox(height: 20.h),
        PressableScale(
          // Dimmed until a folder is picked. Filing is the whole action here,
          // so a button that could run without one would be offering to do
          // nothing.
          onTap: busy || _inert ? null : _save,
          child: Container(
            height: 54.h,
            alignment: Alignment.center,
            // Keeps an ellipsized label off the rounded ends. Without it a
            // long folder name runs the text right into the corner radius,
            // which reads as clipped rather than shortened.
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              gradient: _inert ? null : context.colors.primaryGradient,
              color: _inert ? context.colors.surfaceVariant : null,
              borderRadius: BorderRadius.circular(17.r),
            ),
            child: busy
                ? SizedBox(
                    width: 21.w,
                    height: 21.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: context.colors.onPrimary,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.folder_open_rounded,
                        color: _inert
                            ? context.colors.textDisabled
                            : context.colors.onPrimary,
                        size: 20.sp,
                      ),
                      SizedBox(width: 9.w),
                      // **Flexible, because the folder name is user-written
                      // and this label embeds it.** The row is
                      // `MainAxisSize.min` so the button's contents hug and
                      // centre, and a bare `Text` in that row is measured at
                      // its intrinsic width — a long enough folder name simply
                      // ran off the end and painted the overflow stripes. This
                      // hands the text whatever is left after the icon and
                      // lets it ellipsize instead.
                      //
                      // Fixed here rather than only by capping the name field:
                      // names also arrive from the folders screen, from rename,
                      // and from a restored backup, so the label has to survive
                      // any length whatever the inputs allow.
                      Flexible(
                        child: Text(
                          // Branches on where the screenshot is going rather
                          // than on whether the button is tappable — the two
                          // are the same thing again now that a folder is the
                          // only way to file, but writing it this way is what
                          // keeps `_selected!` provably safe.
                          _selected != null
                              ? context.l10n.quickSaveFileIn(_selected!.name)
                              : context.l10n.quickSavePickFolder,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.button.copyWith(
                            color: _inert
                                ? context.colors.textDisabled
                                : context.colors.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  /// Where it went.
  ///
  /// `_selected` is non-null by construction here: [_save] returns early
  /// without a folder, so the sheet can only reach [_Stage.saved] with one
  /// chosen.
  String _savedSubtitle(BuildContext context) =>
      context.l10n.quickSaveFiled(_selected!.name);

  /// Says how many, and whether this is an import or only a filing job.
  String _title(BuildContext context) {
    final int count = _images.length;
    if (count == 1) {
      return _allAlreadyInLibrary
          ? context.l10n.quickSaveFileOne
          : context.l10n.quickSaveTitleOne;
    }
    return _allAlreadyInLibrary
        ? context.l10n.quickSaveFileMany(count)
        : context.l10n.quickSaveTitleMany(count);
  }
}

/// One image handed over by another app, and whether Shoto already has it.
class _SharedImage {
  final String path;

  /// The gallery id it came from, when Android gave one. Lets an image
  /// already sitting in Shoto's album be taken into this account's library
  /// rather than copied a second time.
  final String? mediaId;

  /// Set when the *signed-in account's* library already holds this exact
  /// image, in which case there is nothing to import — only to file.
  final String? existingAssetId;

  /// Handed out by Shoto's own share sheet a moment ago — most often the
  /// covered copy, coming back to be kept. Such a picture has already been
  /// through the cover-or-keep offer, so it is not asked again.
  final bool fromShotoItself;

  const _SharedImage({
    required this.path,
    required this.mediaId,
    required this.existingAssetId,
    this.fromShotoItself = false,
  });

  bool get isAlreadyInLibrary => existingAssetId != null;
}

/// What is about to be filed: one thumbnail, or a small stack with a count.
///
/// Stacked rather than a scrolling row because this is a confirmation, not a
/// gallery — the question it answers is "did the right things arrive", and
/// three corners plus a number answers it in the same space one image took.
class _SharedPreview extends StatelessWidget {
  final List<_SharedImage> images;
  const _SharedPreview({required this.images});

  static const int _maxVisible = 3;

  @override
  Widget build(BuildContext context) {
    final int visible = images.length.clamp(0, _maxVisible);
    final int hidden = images.length - visible;

    return SizedBox(
      width: 62.w,
      height: 62.w,
      child: Stack(
        children: [
          for (int i = visible - 1; i >= 0; i--)
            Positioned(
              left: i * 4.w,
              top: i * 4.w,
              child: Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13.r),
                  border: Border.all(color: context.colors.surface, width: 1.5),
                  color: context.colors.surfaceVariant,
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.file(File(images[i].path), fit: BoxFit.cover),
              ),
            ),
          if (hidden > 0)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  gradient: context.colors.primaryGradient,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: context.colors.surface, width: 1.5),
                ),
                child: Text(
                  '+$hidden',
                  style: context.text.caption.asSemiBold.copyWith(
                    color: context.colors.onPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The panel itself: rounded top, drag handle, and a grab area that covers
/// the whole header so the sheet can be pulled down from anywhere near the
/// top rather than from a 4-pixel bar.
class _Sheet extends StatelessWidget {
  final Widget child;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;

  const _Sheet({
    required this.child,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: onDragUpdate,
      onVerticalDragEnd: onDragEnd,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            // Naming a folder opens the keyboard, and the Create button sits
            // at the very bottom of the sheet — without this it would be the
            // one control hidden behind the keyboard.
            padding: EdgeInsets.fromLTRB(
              20.w,
              10.h,
              20.w,
              18.h + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 18.h),
                  decoration: BoxDecoration(
                    color: context.colors.border,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FolderChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? tint;
  final bool selected;
  final VoidCallback onTap;

  const _FolderChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = tint ?? context.colors.primary;

    return PressableScale(
      scale: 0.94,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.press,
        curve: AppMotion.standard,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.14)
              : context.colors.surfaceVariant,
          borderRadius: BorderRadius.circular(13.r),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15.sp,
              color: selected ? accent : context.colors.textSecondary,
            ),
            SizedBox(width: 7.w),
            // The strip scrolls horizontally, so a long folder name never
            // overflows here — it does something quieter and worse: one chip
            // grows wider than the phone and hides every other folder behind
            // a scroll nobody knows to perform. Capped so the strip keeps
            // showing that there are others.
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 150.w),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall.asMedium.copyWith(
                  color: selected
                      ? context.colors.textPrimary
                      : context.colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;

  const _Status({
    super.key,
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62.w,
            height: 62.w,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32.sp, color: tint),
          ),
          SizedBox(height: 16.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.text.titleLarge,
          ),
          SizedBox(height: 3.h),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: context.text.bodySmall,
          ),
        ],
      ),
    );
  }
}
