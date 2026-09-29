import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'user_store.dart';

/// Global (non-user-scoped) store for app-wide settings, auth, and theme.
///
/// NOTE: All LEARNING STATE (lesson completion, course progress, recent lessons)
/// is now dynamically scoped to the logged-in user via UserScopedStore.
/// All learning methods here forward directly to UserScopedStore to ensure
/// complete backward compatibility and 100% user isolation.
class Store {
  static Box get _b => Hive.box('app');

  // ── Pending sync queue (global) ────────────────────────────────────────
  static int get pending =>
      (_b.get('q', defaultValue: <String>[]) as List).length;

  // ── Auth / profile ─────────────────────────────────────────────────────

  static bool get isLoggedIn =>
      _b.get('auth_logged_in', defaultValue: false) as bool;

  static String? get activeEmail =>
      _b.get('auth_active_email') as String?;

  /// Returns the currently active user profile.
  /// If logged out, returns empty map.
  static Map<String, dynamic> get profile {
    if (!isLoggedIn) return {};
    final email = activeEmail;
    if (email != null) {
      final users = registeredUsers;
      if (users.containsKey(email)) {
        return users[email]!;
      }
    }
    final raw = _b.get('auth_profile');
    if (raw == null) return {};
    if (raw is Map) return Map<String, dynamic>.from(raw);
    try {
      return jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// Registered users dictionary: email -> profileData
  static Map<String, Map<String, dynamic>> get registeredUsers {
    final raw = _b.get('auth_users');
    if (raw == null) return {};
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(
            k.toString(),
            v is Map
                ? Map<String, dynamic>.from(v)
                : jsonDecode(v as String) as Map<String, dynamic>,
          ));
    }
    try {
      final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(
            k,
            v is Map
                ? Map<String, dynamic>.from(v)
                : jsonDecode(v as String) as Map<String, dynamic>,
          ));
    } catch (_) {
      return {};
    }
  }

  /// Saves a user profile, persisting it to the users registry and setting active session.
  static Future<void> saveProfile(Map<String, dynamic> data) async {
    final email = (data['email'] as String?)?.toLowerCase().trim();
    if (email != null && email.isNotEmpty) {
      final users = registeredUsers;
      users[email] = Map<String, dynamic>.from(data);
      await _b.put('auth_users', jsonEncode(users));
      await _b.put('auth_active_email', email);
    }
    await _b.put('auth_profile', jsonEncode(data));
    await _b.put('auth_logged_in', true);
  }

  /// Sets the active logged-in user without overwriting their registered account.
  static Future<void> setActiveUser(String email) async {
    final normEmail = email.toLowerCase().trim();
    final users = registeredUsers;
    if (users.containsKey(normEmail)) {
      await _b.put('auth_profile', jsonEncode(users[normEmail]));
      await _b.put('auth_active_email', normEmail);
      await _b.put('auth_logged_in', true);
    }
  }

  /// Clears active session (logs out current user) without deleting user records.
  static Future<void> clearSession() async {
    await _b.put('auth_logged_in', false);
    await _b.delete('auth_active_email');
    await _b.delete('auth_profile');
  }

  // ── Theme ──────────────────────────────────────────────────────────────
  static String get themeMode =>
      _b.get('theme_mode', defaultValue: 'system') as String;

  static Future<void> setThemeMode(String mode) async =>
      _b.put('theme_mode', mode);

  // ── Human Mentor Directory Contact ────────────────────────────────────
  static Map<String, dynamic>? get mentor {
    final raw = _b.get('mentor');
    if (raw == null) return null;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    try {
      return jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> setMentor(Map<String, dynamic>? m) async {
    if (m == null) {
      await _b.delete('mentor');
    } else {
      await _b.put('mentor', jsonEncode(m));
    }
  }

  // ── User-Scoped Learning State Delegation ──────────────────────────────
  // All learning state methods delegate to UserScopedStore for strict user isolation.

  static bool done(String id) => UserScopedStore.done(id);

  static Future<void> setDone(String id, bool v) =>
      UserScopedStore.setDone(id, v);

  static double courseProgress(String courseId) =>
      UserScopedStore.courseProgress(courseId);

  static Future<void> setCourseProgress(String courseId, double p) =>
      UserScopedStore.setCourseProgress(courseId, p);

  static String courseState(String courseId) =>
      UserScopedStore.courseState(courseId);

  static Future<void> setCourseState(String courseId, String state) =>
      UserScopedStore.setCourseState(courseId, state);

  static String? courseData(String courseId) =>
      UserScopedStore.courseData(courseId);

  static Future<void> setCourseData(String courseId, String json) =>
      UserScopedStore.setCourseData(courseId, json);

  static List<Map<String, dynamic>> get recentLessons =>
      UserScopedStore.recentLessons;

  static Future<void> addRecentLesson({
    required String courseId,
    required String courseTitle,
    required int lessonIndex,
    required String lessonTitle,
  }) =>
      UserScopedStore.addRecentLesson(
        courseId: courseId,
        courseTitle: courseTitle,
        lessonIndex: lessonIndex,
        lessonTitle: lessonTitle,
      );

  static List<String> get downloadedCourseIds =>
      UserScopedStore.downloadedCourseIds;

  static int lessonProgress(String courseId) =>
      UserScopedStore.lessonProgress(courseId);

  static Future<void> setLessonProgress(String courseId, int index) =>
      UserScopedStore.setLessonProgress(courseId, index);
}
