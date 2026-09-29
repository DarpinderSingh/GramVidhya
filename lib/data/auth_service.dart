import 'package:flutter/foundation.dart';
import 'store.dart';
import 'user_store.dart';
import 'content_repository.dart';
import '../mentor/mentor_service.dart';

/// Authentication service with multi-user local session management.
/// GramVidya remains fully usable offline even without auth.
///
/// USER ISOLATION & MULTI-USER SWITCHING:
/// - Accounts are registered in a persistent user registry (`Store.registeredUsers`).
/// - On registration or login, the user's active session is established.
/// - All user state (completed lessons, course progress, recent chapters, mentor memory)
///   is keyed by user ID via UserScopedStore.
/// - On logout or user switch, in-memory caches for ContentRepository and MentorService
///   are cleared and reloaded for the newly active user context.
/// - Data belonging to other users is never overwritten or deleted.
class AuthService extends ChangeNotifier {
  bool get isLoggedIn => Store.isLoggedIn;
  Map<String, dynamic> get profile => Store.profile;

  /// Register a new user locally.
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? educationLevel,
    String? preferredLang,
  }) async {
    if (name.trim().isEmpty) return 'Name is required';
    final normEmail = email.trim().toLowerCase();
    if (normEmail.isEmpty || !_isValidEmail(normEmail)) {
      return 'Valid email is required';
    }
    if (password.length < 6) return 'Password must be at least 6 characters';

    final hashedPassword = _hashPassword(password, normEmail);

    final profileData = {
      'name': name.trim(),
      'email': normEmail,
      'phone': phone?.trim() ?? '',
      'educationLevel': educationLevel ?? '',
      'preferredLang': preferredLang ?? 'en',
      'passwordHash': hashedPassword,
      'createdAt': DateTime.now().toIso8601String(),
    };

    // Save profile to registry and activate session
    await Store.saveProfile(profileData);

    // After registration, reload mentor & repo for this new user.
    await _onUserChanged();

    notifyListeners();
    return null;
  }

  /// Login with email and password.
  Future<String?> login({required String email, required String password}) async {
    final normEmail = email.trim().toLowerCase();
    final users = Store.registeredUsers;

    Map<String, dynamic>? userProfile = users[normEmail];
    if (userProfile == null) {
      // Check legacy single-profile fallback
      final legacy = Store.profile;
      if (legacy.isNotEmpty && (legacy['email'] as String?)?.toLowerCase() == normEmail) {
        userProfile = legacy;
      }
    }

    if (userProfile == null) {
      return 'No account found with this email. Please register first.';
    }

    final hash = _hashPassword(password, normEmail);
    if (hash != userProfile['passwordHash']) {
      return 'Incorrect password.';
    }

    // Set active user session
    await Store.saveProfile(userProfile);

    // After login, reload all user-specific state.
    await _onUserChanged();

    notifyListeners();
    return null;
  }

  /// Update profile fields (excluding password).
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final current = Map<String, dynamic>.from(Store.profile);
    current.addAll(updates);
    await Store.saveProfile(current);
    notifyListeners();
  }

  /// Logout — clears session flag and active user, switches to guest mode,
  /// but does NOT delete any user learning records.
  Future<void> logout() async {
    await Store.clearSession();
    await UserScopedStore.clearSessionCache();
    await _onUserChanged();
    notifyListeners();
  }

  // ── Internal helpers ─────────────────────────────────────────────────────

  /// Called after any user identity change (login, logout, register).
  /// Reloads all user-scoped singletons without touching the database.
  Future<void> _onUserChanged() async {
    await UserScopedStore.clearSessionCache();
    ContentRepository().clearUserCache();
    MentorService().reloadForCurrentUser();
  }

  String _hashPassword(String password, String salt) {
    final input = '$password\$gramvidya\$$salt';
    var hash = 0xcbf29ce484222325;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x100000001b3) & 0x7FFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email.trim());
  }
}
