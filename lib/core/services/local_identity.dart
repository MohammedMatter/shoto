import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoto/core/utils/random_id.dart';

/// Who this phone's library belongs to when nobody has signed in.
///
/// Every row in the database is scoped to a `user_id`, which used to mean a
/// Firebase uid and nothing else — so the app could not open a single screen
/// until somebody had handed their Google or Apple account over. That was a
/// mandatory identity handoff in front of an app whose whole claim is that
/// nothing leaves the phone, and it bought the user nothing: there is no
/// cloud behind it, backup is a local zip, and the uid only ever served to
/// keep two accounts on one phone from seeing each other's folders.
///
/// This mints that id locally instead. It is a real, stable, persistent
/// identity — the same one across launches, so the library is still there
/// tomorrow — it simply never leaves the device and costs the user nothing to
/// obtain.
///
/// Signing in remains available and now means what it should: a way to carry
/// a purchase to a second device, offered at the moment that matters rather
/// than as a toll gate on the first screen.
class LocalIdentity {
  /// Prefixed so a local id is never mistaken for a Firebase uid — in a
  /// backup archive, in a bug report, or by a future migration that needs to
  /// tell the two apart. Firebase uids are 28 alphanumeric characters and
  /// contain no punctuation, so this prefix cannot collide with one.
  static const String prefix = 'local:';

  static const String _key = 'local_identity_id';

  String? _id;

  /// The device-local user id, available synchronously after [load].
  ///
  /// Throws rather than minting one on demand: an id handed out before the
  /// stored one has been read would scope that session's writes to a
  /// different user than every session before it, and the library would look
  /// empty for no reason the user could understand. Failing loudly at startup
  /// is far better than losing somebody's data quietly.
  String get id {
    final String? id = _id;
    if (id == null) {
      throw StateError(
        'LocalIdentity.id read before load(). It must be awaited in main() '
        'alongside the other preference loads, before anything touches the '
        'database.',
      );
    }
    return id;
  }

  /// Whether [load] has run. Lets callers that can tolerate its absence — a
  /// share sheet deciding whether it may write — check instead of throwing.
  bool get isLoaded => _id != null;

  /// Reads the stored id, minting one on first ever launch.
  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? stored = prefs.getString(_key);
    if (stored != null && stored.isNotEmpty) {
      _id = stored;
      return;
    }

    // 32 characters from a cryptographically secure source. Uniqueness is not
    // actually load-bearing — this id is only ever compared against rows in
    // one sqlite file on one phone — but a guessable id would end up in
    // backup archives, and an id that looks like a counter invites somebody
    // to assume it means something.
    final String minted = '$prefix${RandomId.generate()}';
    _id = minted;
    await prefs.setString(_key, minted);
    if (kDebugMode) debugPrint('LocalIdentity: minted $minted');
  }

  /// Replaces the stored id. Only for tests and for the sign-in migration,
  /// which needs the local id to survive being adopted by an account.
  @visibleForTesting
  Future<void> overrideForTesting(String id) async {
    _id = id;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, id);
  }
}
