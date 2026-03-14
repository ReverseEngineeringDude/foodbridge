import 'package:shared_preferences/shared_preferences.dart';

/// Keys for auth-related SharedPreferences.
class _Keys {
  static const hasSeenOnboarding = 'hasSeenOnboarding';
  static const savedUserId = 'savedUserId';
}

/// Manages auth-related preferences (login state, onboarding).
class AuthPreferences {
  final SharedPreferences _prefs;

  AuthPreferences(this._prefs);

  bool get hasSeenOnboarding => _prefs.getBool(_Keys.hasSeenOnboarding) ?? false;

  String? get savedUserId => _prefs.getString(_Keys.savedUserId);

  /// Call when user completes onboarding or logs in.
  Future<void> setHasSeenOnboarding(bool value) async {
    await _prefs.setBool(_Keys.hasSeenOnboarding, value);
  }

  /// Call when user logs in successfully.
  Future<void> saveLoginState(String userId) async {
    await _prefs.setString(_Keys.savedUserId, userId);
    await _prefs.setBool(_Keys.hasSeenOnboarding, true);
  }

  /// Call when user logs out.
  Future<void> clearLoginState() async {
    await _prefs.remove(_Keys.savedUserId);
  }
}
