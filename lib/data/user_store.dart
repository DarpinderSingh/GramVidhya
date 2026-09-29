import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'store.dart';

/// User-scoped storage layer.
///
/// Every key is automatically prefixed with the user's unique ID,
/// ensuring complete isolation between users for lesson completion,
/// course progress, recent lessons, mentor state, and course downloads.
///
/// Falls back to 'guest' when no user is logged in.
class UserScopedStore {
  static Box get _b => Hive.box('app');

  // ── Current user identity ─────────────────────────────────────────────

  /// Returns the current user's sanitized ID.
  /// If not logged in or profile is missing, returns 'guest'.
  static String get currentUserId {
    if (!Store.isLoggedIn) return 'guest';
    final profile = Store.profile;
    if (profile.isEmpty) return 'guest';
    final email = profile['email'] as String?;
    if (email != null && email.isNotEmpty) return sanitizeId(email);
    final name = profile['name'] as String?;
    if (name != null && name.isNotEmpty) return sanitizeId(name);
    return 'guest';
  }

  /// Returns either the explicit [userId] (sanitized) or the active [currentUserId].
  static String effectiveUserId([String? userId]) {
    if (userId != null && userId.trim().isNotEmpty) {
      return sanitizeId(userId.trim());
    }
    return currentUserId;
  }

  /// Sanitizes an identifier for safe use in Hive keys.
  static String sanitizeId(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '_');

  // ── Key scoping helpers ───────────────────────────────────────────────

  /// Scopes an arbitrary key by the user ID.
  static String scopedKey(String key, [String? userId]) =>
      '${effectiveUserId(userId)}_$key';

  static String _lessonKey(String id, [String? userId]) =>
      'done_${effectiveUserId(userId)}_$id';

  static String _cpKey(String cid, [String? userId]) =>
      'course_progress_${effectiveUserId(userId)}_$cid';

  static String _csKey(String cid, [String? userId]) =>
      'course_state_${effectiveUserId(userId)}_$cid';

  static String _cdKey(String cid, [String? userId]) =>
      'course_data_${effectiveUserId(userId)}_$cid';

  static String _liKey(String cid, [String? userId]) =>
      'lesson_idx_${effectiveUserId(userId)}_$cid';

  static String _rlKey([String? userId]) =>
      'recent_lessons_${effectiveUserId(userId)}';

  // ── Generic Scoped Storage ────────────────────────────────────────────

  static dynamic get(String key, {dynamic defaultValue, String? userId}) =>
      _b.get(scopedKey(key, userId), defaultValue: defaultValue);

  static Future<void> put(String key, dynamic value, [String? userId]) =>
      _b.put(scopedKey(key, userId), value);

  static Future<void> delete(String key, [String? userId]) =>
      _b.delete(scopedKey(key, userId));

  static bool containsKey(String key, [String? userId]) =>
      _b.containsKey(scopedKey(key, userId));

  /// Returns all keys that belong to the specified or current user.
  static List<String> getUserKeys([String? userId]) {
    final prefix = '${effectiveUserId(userId)}_';
    return _b.keys
        .where((k) => k.toString().startsWith(prefix))
        .map((k) => k.toString().substring(prefix.length))
        .toList();
  }

  static List<String> get userKeys => getUserKeys();

  // ── Lesson completion ─────────────────────────────────────────────────

  static bool done(String lessonId, [String? userId]) =>
      _b.get(_lessonKey(lessonId, userId), defaultValue: false) as bool;

  static Future<void> setDone(String lessonId, bool v, [String? userId]) async {
    final uid = effectiveUserId(userId);
    await _b.put(_lessonKey(lessonId, uid), v);
    final q = List<String>.from(
        _b.get('q', defaultValue: <String>[]) as List)
      ..add(jsonEncode({
        'e': 'lesson',
        'userId': uid,
        'lessonId': lessonId,
        'v': v,
        't': DateTime.now().toIso8601String(),
      }));
    await _b.put('q', q);
  }

  // ── Course progress ───────────────────────────────────────────────────

  static double courseProgress(String courseId, [String? userId]) =>
      (_b.get(_cpKey(courseId, userId), defaultValue: 0.0) as num).toDouble();

  static Future<void> setCourseProgress(String courseId, double p, [String? userId]) async =>
      _b.put(_cpKey(courseId, userId), p.clamp(0.0, 1.0));

  // ── Course state ──────────────────────────────────────────────────────

  static const _builtIn = {
    'basic-english',
    'basic-math',
    'science-nature',
    'digital-literacy',
    'financial-literacy',
  };

  static String courseState(String courseId, [String? userId]) {
    final v = _b.get(_csKey(courseId, userId));
    if (v != null) return v as String;
    if (_builtIn.contains(courseId)) return 'downloaded';
    return 'available';
  }

  static Future<void> setCourseState(String courseId, String state, [String? userId]) async =>
      _b.put(_csKey(courseId, userId), state);

  // ── Course data ───────────────────────────────────────────────────────

  static String? courseData(String courseId, [String? userId]) =>
      _b.get(_cdKey(courseId, userId)) as String?;

  static Future<void> setCourseData(String courseId, String json, [String? userId]) async =>
      _b.put(_cdKey(courseId, userId), json);

  static Future<void> deleteCourse(String courseId, [String? userId]) async {
    await _b.delete(_csKey(courseId, userId));
    await _b.delete(_cpKey(courseId, userId));
    await _b.delete(_cdKey(courseId, userId));
  }

  static List<String> getDownloadedCourseIds([String? userId]) {
    final prefix = 'course_state_${effectiveUserId(userId)}_';
    return _b.keys
        .where((k) => k.toString().startsWith(prefix) && _b.get(k) == 'downloaded')
        .map((k) => k.toString().replaceFirst(prefix, ''))
        .toList();
  }

  static List<String> get downloadedCourseIds => getDownloadedCourseIds();

  // ── Lesson index (continue-learning pointer) ──────────────────────────

  static int lessonProgress(String courseId, [String? userId]) =>
      _b.get(_liKey(courseId, userId), defaultValue: 0) as int;

  static Future<void> setLessonProgress(String courseId, int idx, [String? userId]) async =>
      _b.put(_liKey(courseId, userId), idx);

  // ── Recent lessons (user-scoped) ──────────────────────────────────────

  static List<Map<String, dynamic>> getRecentLessons([String? userId]) {
    final raw = _b.get(_rlKey(userId), defaultValue: <dynamic>[]) as List;
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static List<Map<String, dynamic>> get recentLessons => getRecentLessons();

  static Future<void> addRecentLesson({
    required String courseId,
    required String courseTitle,
    required int lessonIndex,
    required String lessonTitle,
    String? userId,
  }) async {
    final uid = effectiveUserId(userId);
    final list = getRecentLessons(uid);
    list.removeWhere(
        (e) => e['courseId'] == courseId && e['lessonIndex'] == lessonIndex);
    list.insert(0, {
      'courseId': courseId,
      'courseTitle': courseTitle,
      'lessonIndex': lessonIndex,
      'lessonTitle': lessonTitle,
      'userId': uid,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await _b.put(_rlKey(uid), list.take(10).toList());
  }

  // ── Pending sync count (global) ───────────────────────────────────────

  static int get pending =>
      (_b.get('q', defaultValue: <String>[]) as List).length;

  // ── User switch helpers ───────────────────────────────────────────────

  /// Clears only leftover legacy non-scoped keys.
  /// Does NOT delete any user's learning records.
  static Future<void> clearSessionCache() async {
    await _b.delete('recent_lessons'); // legacy unscoped key
  }
}

/// Backward compatibility alias so both UserScopedStore and UserStore can be used.
typedef UserStore = UserScopedStore;
