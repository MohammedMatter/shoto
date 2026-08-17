import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shoto/core/services/haptics.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/utils/text_line_geometry.dart' show PositionedWord;
import 'package:shoto/core/utils/text_selection_geometry.dart';
import 'package:shoto/features/screenshots/data/data_sources/text_recognition_data_source.dart';

/// The recognised text of one screenshot, and what the user has selected of
/// it.
///
/// Held outside the widget on purpose. Three separate pieces of the viewer ask
/// this the same questions — the layer painting the highlight, the bar
/// offering Copy, and the button in the top bar that only exists when there is
/// something to select — and they are in three different subtrees. A
/// controller the page owns is what lets all three agree without any of them
/// knowing the others exist. Same reasoning as `ProStatus`, one screen down.
///
/// **Recognition is lazy and happens once.** A screenshot is the largest image
/// the phone can produce, and reading one costs a decode plus an ML Kit pass.
/// Doing that for every picture a thumb flies past would spend the battery of
/// somebody who was only looking, so the page asks for it when the picture has
/// settled and the user has stopped moving — see the debounce at the call
/// site.
class ScreenshotTextController extends ChangeNotifier {
  final TextRecognitionDataSource _recognition;

  /// Fetches the full-resolution file. A callback rather than a [File],
  /// because resolving one out of the gallery is itself asynchronous and the
  /// controller is built long before the file is needed.
  final Future<File?> Function() _open;

  /// The proportions the viewer is *drawing* the picture at, taken from what
  /// the gallery reports. Zero when the gallery reported nothing usable.
  ///
  /// It is here as a check, not as a measurement. See [_agrees].
  final double _displayAspect;

  ScreenshotTextController({
    required TextRecognitionDataSource recognition,
    required Future<File?> Function() open,
    double displayAspect = 0,
  }) : _recognition = recognition,
       _open = open,
       _displayAspect = displayAspect;

  List<SelectableWord> _words = const <SelectableWord>[];
  Size _imageSize = Size.zero;

  bool _loading = false;
  bool _loaded = false;
  bool _disposed = false;

  /// Where a long press landed while the words were still being read.
  ///
  /// Without this, the first long press on a picture — the one that starts the
  /// recognition — would produce nothing at all, and the user would learn that
  /// the gesture does not work. It is replayed the moment the words arrive, so
  /// the press they already made is the press that selects.
  Offset? _pending;

  int? _anchor;
  int? _focus;

  /// The words, in reading order. Empty until recognition finishes, and empty
  /// afterwards for a picture with no readable text in it.
  List<SelectableWord> get words => _words;

  /// The picture's own pixel size — the space every rectangle above is in.
  Size get imageSize => _imageSize;

  bool get isLoading => _loading;

  /// Whether recognition has finished, whatever it found.
  bool get isLoaded => _loaded;

  /// Whether this screenshot turned out to have text worth offering.
  bool get hasText => _words.isNotEmpty;

  bool get hasSelection => _anchor != null && _focus != null;

  int get _start => (_anchor! < _focus! ? _anchor! : _focus!);
  int get _end => (_anchor! > _focus! ? _anchor! : _focus!) + 1;

  /// The selection as text, ready for the clipboard.
  String get selectedText =>
      hasSelection ? TextSelectionGeometry.textIn(_words, _start, _end) : '';

  /// The bars to paint under the selection.
  List<Rect> get highlight => hasSelection
      ? TextSelectionGeometry.highlightRects(_words, _start, _end)
      : const <Rect>[];

  /// Reads the picture, unless that has already been done or is underway.
  ///
  /// Never throws: a screenshot that cannot be read is a screenshot with no
  /// selectable text, which is a state this screen already has to handle for
  /// the pictures that genuinely have none. Turning it into an error would put
  /// a failure message on a photo viewer for a feature the user may not even
  /// have asked for yet.
  Future<void> load() async {
    if (_loaded || _loading) return;
    _loading = true;
    _notify();

    try {
      final File? file = await _open();
      if (file != null) {
        final List<RecognizedLine> lines = await _recognition.recognizeLines(
          file,
        );
        _imageSize = await _sizeOf(file);
        _words = TextSelectionGeometry.wordsIn(<SelectableLine>[
          for (final RecognizedLine line in lines)
            SelectableLine(
              text: line.text,
              bounds: line.bounds,
              words: <PositionedWord>[
                for (final RecognizedWord word in line.words)
                  PositionedWord(text: word.text, bounds: word.bounds),
              ],
            ),
        ]);
      }
    } catch (_) {
      _words = const <SelectableWord>[];
    }

    if (!_agrees) _words = const <SelectableWord>[];

    _loading = false;
    _loaded = true;

    final Offset? pending = _pending;
    _pending = null;
    if (pending != null && _words.isNotEmpty) {
      selectWordAt(pending, slop: _replaySlop);
    }

    _notify();
  }

  /// Whether the file the words were read out of is shaped like the picture
  /// the viewer is drawing.
  ///
  /// **The two can disagree, and when they do every rectangle here is wrong.**
  /// The layout box comes from the gallery's reported dimensions while the
  /// recogniser works on the file's own; a photograph carrying an EXIF
  /// rotation reports one size and decodes to the other, and the result would
  /// be a highlight lying on its side over somebody's picture — confidently,
  /// with a Copy button next to it.
  ///
  /// Screenshots do not carry rotation, so in this app's own subject matter
  /// this never fires. It fires on the imported photograph, which is exactly
  /// the case nobody would have tested. **Refusing is the right answer**: a
  /// picture with no selectable text is a state the whole screen already
  /// handles, and a wrong selection is one it cannot.
  bool get _agrees {
    if (_displayAspect <= 0 || _imageSize.isEmpty) return true;
    final double read = _imageSize.width / _imageSize.height;
    return (read - _displayAspect).abs() <= _displayAspect * 0.02;
  }

  /// The picture's pixel dimensions, **read from the file's header rather than
  /// by decoding it**.
  ///
  /// Every rectangle OCR reports is in this space, so getting it wrong puts
  /// the whole highlight in the wrong place — which rules out taking the
  /// gallery's own numbers on faith. It also rules out decoding the image
  /// again to ask: that is the single most expensive thing this screen does,
  /// and it has already been done once for the picture on screen.
  /// [ui.ImageDescriptor] reads the size out of the encoded bytes without ever
  /// rasterising them.
  static Future<Size> _sizeOf(File file) async {
    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromFilePath(
      file.path,
    );
    try {
      final ui.ImageDescriptor descriptor = await ui.ImageDescriptor.encoded(
        buffer,
      );
      final Size size = Size(
        descriptor.width.toDouble(),
        descriptor.height.toDouble(),
      );
      descriptor.dispose();
      return size;
    } finally {
      buffer.dispose();
    }
  }

  /// Starts a selection at [point], in image pixels.
  ///
  /// Returns whether a word was actually hit — the caller uses that to decide
  /// between a confirming tick and leaving the gesture alone, because a long
  /// press on the empty margin of a picture should feel like nothing happened
  /// rather than like something failed.
  bool selectWordAt(Offset point, {required double slop}) {
    if (!_loaded) {
      // Remembered rather than dropped: the press that triggers the read is
      // also the press that should select. See [_pending].
      _pending = point;
      load();
      return false;
    }

    final int? index = TextSelectionGeometry.wordAt(_words, point, slop: slop);
    if (index == null) return false;

    _anchor = index;
    _focus = index;
    _notify();
    return true;
  }

  /// Moves the free end of the selection to whatever word is nearest [point].
  ///
  /// Nearest rather than exact — a finger dragging across a picture spends
  /// most of its time in the gaps between lines, and a selection that let go
  /// there would read as the app losing the gesture.
  void extendTo(Offset point) {
    if (_anchor == null || _words.isEmpty) return;
    final int index = TextSelectionGeometry.nearestWord(_words, point);
    if (index < 0 || index == _focus) return;
    _focus = index;
    // Once per word crossed, which is what makes dragging over text feel like
    // dragging over something rather than over glass.
    Haptics.tap();
    _notify();
  }

  /// Drags the given end instead of the free one, for the two handles.
  ///
  /// Grabbing a handle swaps the roles: the *other* end becomes the fixed
  /// anchor, so pulling the top handle upwards grows the selection instead of
  /// collapsing it onto itself.
  void beginHandleDrag(SelectionEdge edge) {
    if (!hasSelection) return;
    final int start = _start;
    final int end = _end - 1;
    _anchor = edge == SelectionEdge.start ? end : start;
    _focus = edge == SelectionEdge.start ? start : end;
    _notify();
  }

  /// Everything readable in the picture, in one gesture.
  void selectAll() {
    if (_words.isEmpty) return;
    _anchor = 0;
    _focus = _words.length - 1;
    Haptics.confirm();
    _notify();
  }

  void clear() {
    if (_anchor == null && _focus == null) return;
    _anchor = null;
    _focus = null;
    _notify();
  }

  /// How generously the replayed press is allowed to miss.
  ///
  /// Larger than the live one: by the time the words arrive the finger has
  /// been down for the length of a recognition pass, and it has drifted.
  static const double _replaySlop = 24;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Which end of a selection a handle belongs to.
enum SelectionEdge { start, end }

/// The selectable text of a screenshot, drawn over the screenshot.
///
/// Lives **inside** the zoomable, pageable photo rather than over the whole
/// screen, and that placement does three jobs at once for free: the highlight
/// scales and moves with the picture when it is zoomed, the coordinates are
/// the picture's own so nothing has to be un-transformed by hand, and a
/// selection cannot survive a swipe to the next screenshot.
///
/// The gesture is one long press from beginning to end — press, drag, release
/// — rather than a long press that hands over to a pan. That is not a style
/// choice: this sits inside an [InteractiveViewer], whose own recogniser
/// claims a one-finger drag the moment it moves past the slop. A separate pan
/// would be in a race with it that it loses about half the time. A long press
/// wins the arena by being still, and everything that follows belongs to the
/// same gesture, which is exactly how selecting text on a phone has always
/// worked.
class ScreenshotTextLayer extends StatefulWidget {
  final ScreenshotTextController controller;

  /// Where the finger is on the *screen* while a handle is being dragged, so
  /// the page can float a magnifier over it. Null when nothing is dragging.
  final ValueChanged<Offset?> onDragPoint;

  const ScreenshotTextLayer({
    super.key,
    required this.controller,
    required this.onDragPoint,
  });

  @override
  State<ScreenshotTextLayer> createState() => _ScreenshotTextLayerState();
}

class _ScreenshotTextLayerState extends State<ScreenshotTextLayer>
    with SingleTickerProviderStateMixin {
  /// Shows every readable word for a moment when a selection begins.
  ///
  /// **The one honest answer to "what can I even touch here?"** A picture
  /// gives no clue which parts of it are words, so the first selection on a
  /// screenshot is a guess. One pass of faint boxes over everything the
  /// recogniser found turns that guess into knowledge — and then gets out of
  /// the way, because a permanent grid of boxes over somebody's photograph is
  /// the app drawing on their picture.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(ScreenshotTextLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  bool _hadSelection = false;

  void _onControllerChanged() {
    final bool has = widget.controller.hasSelection;
    if (has && !_hadSelection) _reveal.forward(from: 0);
    _hadSelection = has;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _reveal.dispose();
    super.dispose();
  }

  /// Image pixels per logical pixel of the box this layer fills.
  ///
  /// The box is the picture's own shape — the viewer sizes it by aspect ratio
  /// precisely so the opening flight is one rectangle growing — so the
  /// horizontal and vertical scales are the same number and either will do.
  double _scale(BoxConstraints constraints) {
    final Size image = widget.controller.imageSize;
    if (image.width <= 0 || constraints.maxWidth <= 0) return 1;
    return image.width / constraints.maxWidth;
  }

  Offset _toImage(Offset local, double scale) => local * scale;

  void _longPressStart(LongPressStartDetails details, double scale) {
    final bool hit = widget.controller.selectWordAt(
      _toImage(details.localPosition, scale),
      // A fingertip covers several words' worth of gap. Converted through the
      // scale so the allowance is a constant *finger* size rather than a
      // constant number of image pixels, which would be generous on a small
      // screenshot and useless on a tall one.
      slop: _touchSlop * scale,
    );
    if (!hit) return;
    Haptics.longPress();
    // The lens belongs to the whole gesture, not only to the handles: the
    // press that starts a selection is aimed at small text with a fingertip
    // that covers it, which is the same problem in the same moment.
    widget.onDragPoint(details.globalPosition);
  }

  void _longPressMove(LongPressMoveUpdateDetails details, double scale) {
    if (!widget.controller.hasSelection) return;
    widget.controller.extendTo(_toImage(details.localPosition, scale));
    widget.onDragPoint(details.globalPosition);
  }

  void _handleDrag(Offset globalPosition, double scale) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    widget.controller.extendTo(
      _toImage(box.globalToLocal(globalPosition), scale),
    );
    widget.onDragPoint(globalPosition);
  }

  /// Roughly half a fingertip, in logical pixels.
  static const double _touchSlop = 14;

  @override
  Widget build(BuildContext context) {
    final ScreenshotTextController controller = widget.controller;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double scale = _scale(constraints);

        return GestureDetector(
          // Translucent so the tap that hides the chrome, and the drag that
          // pans a zoomed picture, both still reach the viewer underneath.
          behavior: HitTestBehavior.translucent,
          onLongPressStart: (LongPressStartDetails details) =>
              _longPressStart(details, scale),
          onLongPressMoveUpdate: (LongPressMoveUpdateDetails details) =>
              _longPressMove(details, scale),
          onLongPressEnd: (_) => widget.onDragPoint(null),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _reveal,
                  builder: (BuildContext context, Widget? child) => CustomPaint(
                    painter: _SelectionPainter(
                      bars: controller.highlight,
                      words: controller.words,
                      reveal: _revealAt(_reveal.value),
                      scale: scale,
                      tint: context.colors.primary,
                    ),
                  ),
                ),
              ),
              if (controller.hasSelection) ..._handles(controller, scale),
            ],
          ),
        );
      },
    );
  }

  /// In, hold, out — rather than a linear fade, which spends most of its time
  /// at an alpha too low to read and reads as a flicker.
  double _revealAt(double t) {
    if (t <= 0 || t >= 1) return 0;
    if (t < 0.25) return t / 0.25;
    if (t < 0.6) return 1;
    return 1 - (t - 0.6) / 0.4;
  }

  List<Widget> _handles(ScreenshotTextController controller, double scale) {
    final List<Rect> bars = controller.highlight;
    if (bars.isEmpty) return const <Widget>[];

    final Rect first = bars.first;
    final Rect last = bars.last;

    return <Widget>[
      _Handle(
        edge: SelectionEdge.start,
        at: Offset(first.left, first.bottom) / scale,
        height: first.height / scale,
        onDrag: (Offset global) => _handleDrag(global, scale),
        controller: controller,
        onDone: () => widget.onDragPoint(null),
      ),
      _Handle(
        edge: SelectionEdge.end,
        at: Offset(last.right, last.bottom) / scale,
        height: last.height / scale,
        onDrag: (Offset global) => _handleDrag(global, scale),
        controller: controller,
        onDone: () => widget.onDragPoint(null),
      ),
    ];
  }
}

/// One end of the selection, and the target that drags it.
///
/// The dot is deliberately below the line rather than centred on it: a finger
/// on the handle must not be covering the word it is being used to include.
class _Handle extends StatelessWidget {
  final SelectionEdge edge;
  final Offset at;
  final double height;
  final ValueChanged<Offset> onDrag;
  final ScreenshotTextController controller;
  final VoidCallback onDone;

  const _Handle({
    required this.edge,
    required this.at,
    required this.height,
    required this.onDrag,
    required this.controller,
    required this.onDone,
  });

  /// The visible dot. The touch target around it is [_target], which is four
  /// times as wide — the dot is a marker, not a button, and sizing the target
  /// to the marker is how handles end up feeling slippery.
  static const double _dot = 11;
  static const double _target = 44;

  @override
  Widget build(BuildContext context) {
    // Clamped at both ends: a heading's line box would give a stem half the
    // screen tall, and a line of tiny print would give one too short to see.
    final double stem = height.clamp(8, 44);

    // The box starts at the *top* of the line and runs past the bottom of it,
    // so the stem covers the words and the dot — and the finger that grabs it
    // — sit underneath them rather than on top of what is being selected.
    return Positioned(
      left: at.dx - _target / 2,
      top: at.dy - stem,
      width: _target,
      height: stem + _target,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) {
          controller.beginHandleDrag(edge);
          Haptics.tap();
        },
        onPanUpdate: (DragUpdateDetails details) =>
            onDrag(details.globalPosition),
        onPanEnd: (_) => onDone(),
        onPanCancel: onDone,
        child: CustomPaint(
          painter: _HandlePainter(
            stem: stem,
            dot: _dot,
            tint: context.colors.primary,
          ),
        ),
      ),
    );
  }
}

class _HandlePainter extends CustomPainter {
  final double stem;
  final double dot;
  final Color tint;

  const _HandlePainter({
    required this.stem,
    required this.dot,
    required this.tint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double x = size.width / 2;
    // The stem starts at the top of the box, which the caller has aligned with
    // the top of the line. Everything below it is touch target.
    const double top = 0;

    // The same two-luminance trick the Safe Share markers use, and for the
    // same reason: this is painted on a photograph, and the photograph's
    // colours are the one set of colours Shoto does not choose. A dark halo
    // under a light shape means one of the two always separates from whatever
    // is behind it.
    final Paint halo = Paint()
      ..color = AppPalette.overlay.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;
    final Paint line = Paint()
      ..color = tint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final Offset from = Offset(x, top);
    final Offset to = Offset(x, top + stem);
    canvas.drawLine(from, to, halo);
    canvas.drawLine(from, to, line);
    canvas.drawCircle(to + Offset(0, dot / 2), dot / 2 + 1, halo);
    canvas.drawCircle(to + Offset(0, dot / 2), dot / 2, line);
  }

  @override
  bool shouldRepaint(_HandlePainter old) =>
      old.stem != stem || old.dot != dot || old.tint != tint;
}

class _SelectionPainter extends CustomPainter {
  final List<Rect> bars;
  final List<SelectableWord> words;

  /// 0 when the "here is what is readable" pass is not running.
  final double reveal;

  /// Image pixels per logical pixel.
  final double scale;
  final Color tint;

  const _SelectionPainter({
    required this.bars,
    required this.words,
    required this.reveal,
    required this.scale,
    required this.tint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (reveal > 0) {
      final Paint hint = Paint()
        ..color = AppPalette.paper.withValues(alpha: 0.30 * reveal);
      for (final SelectableWord word in words) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            _toScreen(word.bounds).inflate(1),
            const Radius.circular(2),
          ),
          hint,
        );
      }
    }

    if (bars.isEmpty) return;

    // Translucent rather than solid, always: the point of selecting text in a
    // picture is to *read* what you have selected, and a fill that hides it
    // turns checking your work into removing the selection and starting again.
    final Paint fill = Paint()..color = tint.withValues(alpha: 0.34);
    final Paint edge = Paint()
      ..color = AppPalette.paper.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final Rect bar in bars) {
      final RRect rounded = RRect.fromRectAndRadius(
        _toScreen(bar).inflate(2),
        const Radius.circular(3),
      );
      canvas.drawRRect(rounded, fill);
      canvas.drawRRect(rounded, edge);
    }
  }

  Rect _toScreen(Rect box) => Rect.fromLTRB(
    box.left / scale,
    box.top / scale,
    box.right / scale,
    box.bottom / scale,
  );

  @override
  bool shouldRepaint(_SelectionPainter old) =>
      old.bars != bars ||
      old.words != words ||
      old.reveal != reveal ||
      old.scale != scale ||
      old.tint != tint;
}

/// The picture under the finger, blown up, while a handle is being dragged.
///
/// It exists because of a problem this feature cannot design its way out of:
/// the thing being aimed at is small text, and the aiming is done with a
/// fingertip that covers it completely. Every text selection on every phone
/// solves this the same way, and a selection that can only be adjusted by
/// lifting the finger to see what happened is one people give up on.
///
/// [RawMagnifier] samples whatever is painted beneath it, so it belongs at the
/// page's level — above the photo in the stack, outside the zoomable subtree
/// that would otherwise scale the magnifier itself.
class SelectionMagnifier extends StatelessWidget {
  /// Where the finger is, in global coordinates.
  final Offset at;

  const SelectionMagnifier({super.key, required this.at});

  static const Size _size = Size(96, 62);
  static const double _above = 74;

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.sizeOf(context);
    final double left = (at.dx - _size.width / 2).clamp(
      8,
      screen.width - _size.width - 8,
    );
    // Never off the top: on the first line of a screenshot there is nothing
    // above the finger to put it in, so it comes down to just under the touch
    // instead of hanging off the screen.
    final double wanted = at.dy - _above;
    final double top = wanted < MediaQuery.paddingOf(context).top + 8
        ? at.dy + 28
        : wanted;

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: RawMagnifier(
          size: _size,
          magnificationScale: 1.7,
          // What the lens shows, relative to its own centre. The lens sits
          // above the finger so that the hand does not cover it, so the thing
          // worth looking at is exactly that far below.
          focalPointOffset: Offset(
            at.dx - left - _size.width / 2,
            at.dy - top - _size.height / 2,
          ),
          decoration: MagnifierDecoration(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            shadows: <BoxShadow>[
              BoxShadow(
                color: AppPalette.overlay.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
