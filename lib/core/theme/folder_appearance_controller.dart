import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What a folder card shows, and how many fit across.
///
/// **Its own controller rather than three more booleans in [AppPreferences],**
/// because that class says in its first line what belongs in it: preferences
/// that change how the app *behaves*, with the ones that change how it *looks*
/// living beside [GridDensityController] so the widgets watching them repaint
/// directly. These are the second kind — nothing here alters what the app
/// does, only what a card has printed on it.
///
/// ## Why these three and not the four in the design this follows
///
/// The reference layout has Row Size, Description, Modification Date and
/// Count. Two of those describe data Shoto does not keep:
///
/// * **A folder has no description.** `FolderEntity` is a name, a colour, an
///   icon key, a created date, a count and a lock. A switch offering to show a
///   field that does not exist is a control that can only ever do nothing.
/// * **A folder has no modification date** — only `createdAt`. Labelling that
///   "modified" would be the same lie one layer down: it would be a real date
///   under a word that does not describe it, which is worse than no row,
///   because it is wrong rather than absent.
///
/// So the date here is [showCreated] and it says *created*. Adding a real
/// description field is a database migration and an editor, and it is a
/// feature rather than an appearance toggle — the day it exists, this class is
/// where its switch goes.
class FolderAppearanceController extends ChangeNotifier {
  static const String _countKey = 'folder_show_count';
  static const String _createdKey = 'folder_show_created';
  static const String _columnsKey = 'folder_columns';

  static const int defaultColumns = 3;
  static const List<int> columnOptions = <int>[2, 3, 4];

  /// **On by default, because it was not optional before this existed.**
  ///
  /// Every folder card has printed its count since the grid was built, so
  /// defaulting this off would silently take a line away from every existing
  /// user in the name of giving them a choice about it.
  bool _showCount = true;
  bool get showCount => _showCount;

  /// **Off by default**, for the opposite reason: it is new information, and a
  /// card that suddenly grew a third line on update reads as a bug rather than
  /// as a feature nobody asked for yet.
  ///
  /// It is also the less useful of the two on a card this size — a count
  /// answers "is there anything in here", which is the question somebody
  /// scanning a grid of folders is actually asking.
  bool _showCreated = false;
  bool get showCreated => _showCreated;

  int _columns = defaultColumns;
  int get columns => _columns;

  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _showCount = prefs.getBool(_countKey) ?? true;
    _showCreated = prefs.getBool(_createdKey) ?? false;
    final int? storedColumns = prefs.getInt(_columnsKey);
    if (storedColumns != null && columnOptions.contains(storedColumns)) {
      _columns = storedColumns;
    }
    notifyListeners();
  }

  Future<void> setShowCount(bool value) =>
      _setBool(_countKey, value, (bool v) => _showCount = v);

  Future<void> setShowCreated(bool value) =>
      _setBool(_createdKey, value, (bool v) => _showCreated = v);

  Future<void> setColumns(int value) async {
    if (value == _columns || !columnOptions.contains(value)) return;
    _columns = value;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_columnsKey, value);
  }

  /// Notifies before the write, like every other preference in this app: the
  /// switch has to move under the finger rather than after a disk round trip.
  Future<void> _setBool(
    String key,
    bool value,
    void Function(bool) apply,
  ) async {
    apply(value);
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}
