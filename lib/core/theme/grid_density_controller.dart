import 'package:shoto/core/localization/l10n.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Number of columns in the screenshots grid — persisted like
/// [ThemeController], read directly by [ScreenshotsBody] via
/// `ListenableBuilder` rather than threaded through constructor params.
class GridDensityController extends ChangeNotifier {
  static const String _prefsKey = 'grid_density';
  static const int defaultColumns = 3;
  static const List<int> options = [2, 3, 4];

  int _columns = defaultColumns;
  int get columns => _columns;

  /// How each density looks and what it is called.
  ///
  /// Kept here rather than inside the Settings selector that used to own it,
  /// because two places show this setting now — the segmented picker in
  /// Settings and the cycling button in the Library header — and an icon
  /// meaning "small" in one place and "large" in the other is exactly the
  /// kind of drift a private table invites.
  static IconData iconFor(int columns) => switch (columns) {
    2 => Icons.grid_view_rounded,
    3 => Icons.apps_rounded,
    _ => Icons.grid_on_rounded,
  };

  /// Names the density by how big the screenshots end up, not by how many
  /// columns there are — nobody browsing a grid is counting columns.
  ///
  /// Takes a context because the three names are translated. It used to return
  /// the English literals, which meant the density picker and the Library
  /// header tooltip stayed in English in all six languages.
  static String labelFor(BuildContext context, int columns) =>
      switch (columns) {
        2 => context.l10n.densityLarge,
        3 => context.l10n.densityMedium,
        _ => context.l10n.densitySmall,
      };

  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? stored = prefs.getInt(_prefsKey);
    if (stored != null && options.contains(stored)) {
      _columns = stored;
      notifyListeners();
    }
  }

  /// Steps to the next density and wraps around — one button that cycles
  /// beats three that have to be found in a menu, for a setting people flip
  /// back and forth while browsing.
  Future<void> cycle() {
    final int next = options[(options.indexOf(_columns) + 1) % options.length];
    return setColumns(next);
  }

  Future<void> setColumns(int columns) async {
    if (columns == _columns) return;
    _columns = columns;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, columns);
  }
}
