import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';
import 'package:shoto/features/subscription/domain/use_cases/get_subscription_status_use_case.dart';

/// Reads the library once, in the background, so nothing else has to.
///
/// Three screens used to index, and all three were wrong in the same way.
/// Search read forty screenshots per visit, the rules backlog read forty per
/// tap, and Smart Actions read one on demand — each capped, each tied to a
/// screen staying open, each redoing work the others had already done. The
/// caps were not conservatism, they were the only thing standing between the
/// user and a page that blocked on hundreds of model calls.
///
/// The cost of that fell almost entirely on filing rules. A rule can only
/// match facts SHOTO holds, so on a library of five hundred unread
/// screenshots a perfectly correct rule filed nothing and kept filing nothing
/// until the user tapped "Run rules" thirteen times — and nothing on screen
/// distinguished that from a rule that simply did not work. Fixing the
/// message helped; the honest fix is to do the reading.
///
/// So: one sweep, running whenever the app is open, independent of any page,
/// with the caps removed. What makes that affordable is not speed but
/// **yielding** — see [_breath]. The work is the same work; it is spread out
/// so nothing waits on it.
///
/// A [ChangeNotifier] rather than a stream, the same shape as
/// [AppPreferences] and [ThemeController]: every consumer is a widget that
/// wants to rebuild when the numbers move.
class LibraryIndexer extends ChangeNotifier {
  final ScreenshotRepository _screenshots;
  final GetSubscriptionStatusUseCase _subscriptionStatus;

  LibraryIndexer(this._screenshots, this._subscriptionStatus);

  /// The pause between screenshots.
  ///
  /// This is the whole reason the caps can go. OCR and the vision model are
  /// platform calls, but decoding an image and writing a row is real work on
  /// this side, and a tight loop over a thousand screenshots starves the
  /// frame pipeline — the app stays "responsive" in the sense that it is not
  /// deadlocked, and janks visibly the entire time.
  ///
  /// Sized to be invisible rather than to finish fast. Somebody who just
  /// opened the app is going to scroll, and indexing must lose to scrolling
  /// every time; the sweep is allowed to take minutes because nobody is
  /// waiting on it.
  static const Duration _breath = Duration(milliseconds: 60);

  IndexPhase _phase = IndexPhase.idle;
  int _done = 0;
  int _total = 0;

  IndexPhase get phase => _phase;

  /// How many screenshots this sweep has read, out of [total].
  int get done => _done;
  int get total => _total;

  bool get isWorking => _phase == IndexPhase.working;

  /// Whether the library is fully read. Distinct from "not working": a paused
  /// or unsubscribed indexer is also not working, and means something else
  /// entirely to the screens that report it.
  bool get isUpToDate => _phase == IndexPhase.upToDate;

  int get remaining => (_total - _done).clamp(0, _total);

  /// Null until the sweep knows how much there is, so a progress bar can show
  /// indeterminate rather than a confident 0%.
  double? get fraction => _total <= 0 ? null : _done / _total;

  bool _paused = false;
  bool _disposed = false;

  /// Bumped to abandon an in-flight sweep. A sweep checks it between every
  /// screenshot, which is how [start] can be called freely without ever
  /// running two loops over the same library at once.
  int _generation = 0;

  Completer<void>? _resumed;

  /// Screenshots that could not be read *this session*.
  ///
  /// Recognition caches nothing when the underlying file cannot be opened —
  /// an image in the gallery index that never downloaded from the cloud, or
  /// one deleted outside SHOTO. Without this the worklist would contain it
  /// again on the very next sweep, forever, and a single broken file would
  /// keep the indexer reporting work it can never finish.
  ///
  /// Deliberately not persisted: "the file was not available" is usually
  /// temporary, and a restart is the right moment to try again.
  final Set<String> _unreadable = {};

  /// Begins or resumes indexing. Safe to call as often as you like.
  ///
  /// Cheap when there is nothing to do — three cached reads and a comparison
  /// — so screens that depend on the index can call it on open without
  /// coordinating with anyone else.
  Future<void> start() async {
    if (_disposed) return;
    _paused = false;
    _releasePause();

    // A fast path, not the safety net. It cannot be one: the phase only turns
    // `working` after an awaited subscription check, so two calls in the same
    // turn both get past here. What actually guarantees a single sweep is
    // [_generation] — a newer sweep bumps it and every older one bails at its
    // next check, before it reads anything.
    if (_phase == IndexPhase.working) return;
    await _sweep();
  }

  /// Stops between screenshots rather than mid-recognition.
  ///
  /// The in-flight screenshot is allowed to finish and cache: abandoning it
  /// would throw away work already paid for and leave the row unwritten, so
  /// the next sweep would do it again.
  void pause() {
    if (_disposed || _paused) return;
    _paused = true;
    if (_phase == IndexPhase.working) _setPhase(IndexPhase.paused);
  }

  void resume() {
    if (_disposed || !_paused) return;
    _paused = false;
    _releasePause();
    if (_phase == IndexPhase.paused) {
      _setPhase(IndexPhase.working);
    } else {
      unawaited(start());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _releasePause();
    super.dispose();
  }

  Future<void> _sweep() async {
    final int generation = ++_generation;

    // Premium-gated for the same reason search and rules are: this *is*
    // search and rules, done ahead of time. Checked at the start of every
    // sweep rather than once, so subscribing turns it on without a restart.
    if (!(await _subscriptionStatus()).isPremium) {
      _setPhase(IndexPhase.notPremium);
      return;
    }
    if (_isStale(generation)) return;

    final List<_Unread> work = await _worklist();
    if (_isStale(generation)) return;

    if (work.isEmpty) {
      _done = 0;
      _total = 0;
      _setPhase(IndexPhase.upToDate);
      return;
    }

    _done = 0;
    _total = work.length;
    _setPhase(_paused ? IndexPhase.paused : IndexPhase.working);

    for (final _Unread entry in work) {
      if (_isStale(generation)) return;
      await _waitWhilePaused();
      if (_isStale(generation)) return;

      await _read(entry);

      _done++;
      _notify();
      await Future<void>.delayed(_breath);
    }

    if (_isStale(generation)) return;
    await _rememberUnreadable(work);
    if (_isStale(generation)) return;
    _setPhase(IndexPhase.upToDate);
  }

  /// Everything SHOTO has not read yet.
  ///
  /// "Not read" is the key present in the cache, not the value being useful:
  /// both caches store an empty result rather than leaving the column null,
  /// precisely so that "looked, found nothing" and "never looked" stay
  /// distinguishable. Treating an empty result as unread would re-run the
  /// vision model on every wordless screenshot on every sweep, forever.
  /// Both caches are read **once** for the whole sweep, and what each
  /// screenshot still needs is decided here rather than in the loop. Asking
  /// per screenshot would be two full-table reads per item — the same mistake
  /// that once turned a two-hundred-item rules run into four hundred queries.
  Future<List<_Unread>> _worklist() async {
    final List<ScreenshotEntity> all = await _screenshots.getAllScreenshots();
    final Map<String, String> ocr = await _screenshots.getCachedOcrText();
    final Map<String, List<String>> labels = await _screenshots
        .getCachedVisualLabels();

    return [
      for (final ScreenshotEntity screenshot in all)
        if (!_unreadable.contains(screenshot.id))
          if (!ocr.containsKey(screenshot.id) ||
              !labels.containsKey(screenshot.id))
            _Unread(
              screenshot: screenshot,
              needsText: !ocr.containsKey(screenshot.id),
              needsLabels: !labels.containsKey(screenshot.id),
            ),
    ];
  }

  /// Reads one screenshot, and never lets one bad file end the sweep.
  ///
  /// The two halves are tried independently because they fail independently:
  /// a screenshot whose text was cached before the vision model existed still
  /// needs labels, and pairing them would mean re-running OCR over the whole
  /// library to get them.
  Future<void> _read(_Unread entry) async {
    if (entry.needsText) {
      try {
        await _screenshots.extractAndCacheText(entry.screenshot);
      } catch (_) {
        // Keep going: one unreadable screenshot is not a reason to stop
        // reading the other nine hundred.
      }
    }
    if (entry.needsLabels) {
      try {
        await _screenshots.extractAndCacheLabels(entry.screenshot);
      } catch (_) {
        // As above.
      }
    }
  }

  /// Marks whatever the sweep failed to record, so the next one skips it.
  ///
  /// Recognition returns empty *without caching* when the file cannot be
  /// opened at all — an image the gallery lists but never downloaded from the
  /// cloud, or one deleted outside SHOTO — and that is indistinguishable from
  /// a legitimate empty result by return value alone. Comparing the caches
  /// against the worklist afterwards tells them apart, in one read rather
  /// than one per screenshot.
  ///
  /// Without this the same broken file returns to every worklist forever, and
  /// the indexer reports work it can never finish.
  Future<void> _rememberUnreadable(List<_Unread> work) async {
    final Map<String, String> ocr = await _screenshots.getCachedOcrText();
    final Map<String, List<String>> labels = await _screenshots
        .getCachedVisualLabels();

    for (final _Unread entry in work) {
      final String id = entry.screenshot.id;
      if ((entry.needsText && !ocr.containsKey(id)) ||
          (entry.needsLabels && !labels.containsKey(id))) {
        _unreadable.add(id);
      }
    }
  }

  Future<void> _waitWhilePaused() async {
    while (_paused && !_disposed) {
      _resumed ??= Completer<void>();
      await _resumed!.future;
    }
  }

  void _releasePause() {
    final Completer<void>? waiting = _resumed;
    _resumed = null;
    if (waiting != null && !waiting.isCompleted) waiting.complete();
  }

  /// Whether this sweep has been superseded or the indexer thrown away.
  bool _isStale(int generation) => _disposed || generation != _generation;

  void _setPhase(IndexPhase phase) {
    if (_phase == phase) return;
    _phase = phase;
    _notify();
  }

  /// [ChangeNotifier.notifyListeners] throws after dispose, and a sweep can
  /// outlive the object by one screenshot.
  void _notify() {
    if (!_disposed) notifyListeners();
  }
}

/// One screenshot and which half of the reading it still needs.
///
/// Carried through the loop so the decision is made once, from the caches
/// read at the start of the sweep, instead of being re-asked per item.
class _Unread {
  final ScreenshotEntity screenshot;
  final bool needsText;
  final bool needsLabels;

  const _Unread({
    required this.screenshot,
    required this.needsText,
    required this.needsLabels,
  });
}

/// What the indexer is doing, in the terms the screens report it in.
enum IndexPhase {
  /// Not started yet this session.
  idle,

  /// Reading. [LibraryIndexer.done] and [LibraryIndexer.total] are moving.
  working,

  /// Stopped because the app is in the background. Resumes on its own.
  paused,

  /// Everything readable has been read — the state where a rule's preview
  /// count is a real answer rather than a floor.
  upToDate,

  /// Reading the library is what search and rules are; it is not done for
  /// free accounts. Distinct from [idle] so a screen can say why.
  notPremium,
}
