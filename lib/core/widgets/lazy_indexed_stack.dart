import 'package:flutter/material.dart';

/// An [IndexedStack] that does not build a tab until it has been opened, and
/// never throws one away afterwards.
///
/// The shell needs both halves of that, and a plain `IndexedStack` only gives
/// the second one.
///
/// **Keeping tabs alive is deliberate** and has already fixed real bugs: the
/// Library keeps its scroll position, and the Folders counts refresh instead
/// of being frozen at whatever they were when the tab was first built. That is
/// why the shell uses a stack at all rather than swapping the body.
///
/// **Building them all up front was not deliberate**, it was the price of the
/// first half. `IndexedStack` puts every child in the tree immediately, so
/// opening SHOTO built four screens before the first frame: the Library grid
/// (which resolves thumbnails as it builds, so the image pipeline starts
/// working on pictures nobody has asked to see), the Folders grid, and
/// Settings — which walks the cache directory on disk to show how big it is.
/// None of that is work the user has asked for at launch, and all of it
/// competes with the frames of the app opening.
///
/// The cost moves to the first time a tab is opened, which is the moment it is
/// actually worth something. After that this behaves exactly like the stack it
/// replaces.
class LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  /// Which tabs have ever been shown. Only grows — a tab that has been built
  /// stays in the tree so its state survives, which is the whole reason this
  /// is a stack rather than a swap.
  final Set<int> _opened = <int>{};

  @override
  void initState() {
    super.initState();
    _opened.add(widget.index);
  }

  @override
  void didUpdateWidget(LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    // No setState: a widget update is already followed by a build.
    _opened.add(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: [
        for (int i = 0; i < widget.children.length; i++)
          if (_opened.contains(i))
            widget.children[i]
          else
            // An empty box rather than the real child. It costs one render
            // object and holds the slot so the indices still line up.
            const SizedBox.shrink(),
      ],
    );
  }
}
