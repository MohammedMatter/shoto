import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoto/core/services/native_splash.dart';

/// Holds the user's chosen [ThemeMode] (system/light/dark), persisting it
/// across app restarts. Registered as a singleton in DI so both [MyApp]
/// (to react to changes) and the Settings screen (to change it) share the
/// same instance.
///
/// **It also tells the operating system**, which is not the same job and is
/// easy to mistake for one. Android paints Shoto's launch window before this
/// app has a process, resolving light or dark against the *system's* setting —
/// so a mode pinned only in here means a launch screen in the wrong one. See
/// [NativeSplash.pinNightMode].
class ThemeController extends ChangeNotifier {
  static const String _prefsKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? stored = prefs.getString(_prefsKey);
    _themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    // Before the write rather than after it, for the same reason the listeners
    // are: nothing here is waiting on the disk, and this is one binder call
    // that decides what the *next* cold start looks like.
    NativeSplash.pinNightMode(mode);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }
}
