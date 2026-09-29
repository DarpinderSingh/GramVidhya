import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'course_provider.dart';
import 'diksha_provider.dart';
import 'download_manager.dart';
import 'models/learning_resource.dart';
import 'providers/content_provider.dart';
import 'providers/khan_academy_provider.dart';
import 'providers/mit_ocw_provider.dart';
import 'providers/nptel_provider.dart';
import 'providers/openstax_provider.dart';
import 'providers/swayam_provider.dart';
import 'providers/youtube_provider.dart';
import 'user_store.dart';

/// Central repository orchestrating educational content providers,
/// offline cache, recent chapters tracking, and download statuses.
///
/// USER ISOLATION:
/// Recent chapters are stored per-user in the 'recent_chapters' Hive box
/// using keys of the form  "<userId>_<courseId>_<chapterId>".
/// The resource metadata cache (24-hour TTL) is also user-scoped.
class ContentRepository extends ChangeNotifier {
  static final ContentRepository _instance = ContentRepository._internal();
  factory ContentRepository() => _instance;
  ContentRepository._internal();

  static const String _kCacheBox = 'content_cache';
  static const String _kRecentBox = 'recent_chapters';
  Box? _cacheBox;
  Box? _recentBox;

  final List<EducationalProvider> _providers = [
    NptelProvider(),
    OpenStaxProvider(),
    MitOcwProvider(),
    SwayamProvider(),
    KhanAcademyProvider(),
    YoutubeEduProvider(),
  ];

  final DikshaContentProvider _diksha = DikshaContentProvider();
  final DownloadManager _downloadManager = DownloadManager();

  bool _isOnline = true;
  bool _forcedOffline = false;
  bool get isForcedOffline => _forcedOffline;
  bool get isOnline => !_forcedOffline && _isOnline;

  Future<void> init() async {
    _cacheBox = await Hive.openBox(_kCacheBox);
    _recentBox = await Hive.openBox(_kRecentBox);
    await _downloadManager.init();
    _isOnline = true;
    checkConnectivity();
  }

  // ── Online / Offline toggle ────────────────────────────────────────────

  Future<void> toggleOnlineMode() async {
    _forcedOffline = !_forcedOffline;
    if (_forcedOffline) {
      _isOnline = false;
    } else {
      _isOnline = true;
      await checkConnectivity();
    }
    notifyListeners();
  }

  void setOnlineMode(bool online) {
    _forcedOffline = !online;
    _isOnline = online;
    notifyListeners();
  }

  Future<bool> checkConnectivity() async {
    if (_forcedOffline) {
      _isOnline = false;
      notifyListeners();
      return false;
    }
    try {
      final res = await http
          .get(Uri.parse('https://dns.google/resolve?name=example.com'))
          .timeout(const Duration(seconds: 3));
      _isOnline = res.statusCode == 200;
    } catch (_) {
      _isOnline = !_forcedOffline;
    }
    notifyListeners();
    return _isOnline;
  }

  // ── User-scoped Recent Chapters ────────────────────────────────────────

  /// Builds a user-scoped key for the recent chapters box.
  String _recentKey(String courseId, String chapterId) =>
      '${UserStore.currentUserId}_${courseId}_$chapterId';

  Box? get _boxRecent =>
      _recentBox ?? (Hive.isBoxOpen(_kRecentBox) ? Hive.box(_kRecentBox) : null);

  /// Records actual user chapter/lesson access.
  Future<void> recordChapterAccess({
    required String courseId,
    required String courseName,
    required String chapterId,
    required String chapterName,
    required double progress,
    required bool completed,
    required String provider,
    int lessonIndex = 0,
    int totalLessons = 1,
    String? thumbnailUrl,
  }) async {
    final entry = RecentChapter(
      courseId: courseId,
      courseName: courseName,
      chapterId: chapterId,
      chapterName: chapterName,
      lastOpened: DateTime.now(),
      progress: progress.clamp(0.0, 1.0),
      completed: completed,
      provider: provider,
      thumbnailUrl: thumbnailUrl,
      lessonIndex: lessonIndex,
      totalLessons: totalLessons,
    );

    final box = _boxRecent;
    if (box != null) {
      await box.put(
        _recentKey(courseId, chapterId),
        jsonEncode(entry.toJson()),
      );
    }

    // Also sync to user-scoped Store for MentorService compatibility.
    await UserStore.addRecentLesson(
      courseId: courseId,
      courseTitle: courseName,
      lessonIndex: lessonIndex,
      lessonTitle: chapterName,
    );

    notifyListeners();
  }

  /// Returns this user's recent chapters, sorted by lastOpened descending.
  List<RecentChapter> getRecentChapters([String? userId]) {
    final box = _boxRecent;
    if (box == null) return [];
    final uid = UserScopedStore.effectiveUserId(userId);
    final prefix = '${uid}_';
    final list = <RecentChapter>[];

    for (final key in box.keys) {
      // Only include keys belonging to the target user.
      if (!key.toString().startsWith(prefix)) continue;
      try {
        final raw = _recentBox!.get(key);
        if (raw != null) {
          final map = raw is Map
              ? Map<String, dynamic>.from(raw)
              : jsonDecode(raw as String) as Map<String, dynamic>;
          list.add(RecentChapter.fromJson(Map<String, dynamic>.from(map)));
        }
      } catch (_) {}
    }

    list.sort((a, b) => b.lastOpened.compareTo(a.lastOpened));
    return list.take(10).toList();
  }

  /// Returns the best "Continue Learning" item for the target or current user.
  ///
  /// Algorithm:
  /// 1. Find the most recently accessed chapter that is NOT yet completed.
  /// 2. If all are completed, return the most recently accessed chapter.
  /// 3. If none at all, return null.
  RecentChapter? getContinueLearning([String? userId]) {
    final recent = getRecentChapters(userId);
    if (recent.isEmpty) return null;

    for (final item in recent) {
      if (!item.completed && item.progress < 1.0) return item;
    }
    return recent.first;
  }

  /// Clears in-memory caches on user switch without deleting database records.
  void clearUserCache() {
    notifyListeners();
  }

  // ── Resource metadata cache (user-scoped, 24-hour TTL) ────────────────

  Future<void> cacheResource(LearningResource resource) async {
    if (_cacheBox != null) {
      await _cacheBox!.put(
        'res_${UserStore.currentUserId}_${resource.id}',
        jsonEncode({
          'cachedAt': DateTime.now().toIso8601String(),
          'data': resource.toJson(),
        }),
      );
    }
  }

  LearningResource? getCachedResource(String id) {
    if (_cacheBox == null) return null;
    final raw =
        _cacheBox!.get('res_${UserStore.currentUserId}_$id');
    if (raw == null) return null;
    try {
      final map = raw is Map
          ? Map<String, dynamic>.from(raw)
          : jsonDecode(raw as String) as Map<String, dynamic>;
      final cachedAt = DateTime.tryParse(map['cachedAt'] as String? ?? '');
      if (cachedAt != null &&
          DateTime.now().difference(cachedAt).inHours < 24) {
        return LearningResource.fromJson(
            Map<String, dynamic>.from(map['data'] as Map));
      }
    } catch (_) {}
    return null;
  }

  // ── Educational Content Discovery ─────────────────────────────────────

  Future<List<LearningResource>> getAllResources() async {
    final results = <LearningResource>[];

    for (final p in _providers) {
      try {
        final res = await p.fetchResources();
        results.addAll(res);
      } catch (_) {}
    }

    // Built-in GramVidya courses
    for (final c in CourseManager.builtInCourses) {
      results.add(LearningResource(
        id: c.id,
        title: c.title,
        description: c.description,
        provider: 'GramVidya',
        subject: c.title.split(':').last.trim(),
        category: 'Foundations',
        level: 'All Levels',
        officialUrl: 'https://gramvidya.org',
        type: ResourceType.course,
        downloadable: true,
        license: 'Open Educational Resource (OER)',
        lessons: c.lessons
            .asMap()
            .entries
            .map((e) => ChapterLesson(
                  id: e.value.id,
                  chapterNumber: e.key + 1,
                  title: e.value.title,
                  content: e.value.content,
                  durationMinutes: e.value.durationMinutes ?? 20,
                  downloadable: true,
                ))
            .toList(),
      ));
    }

    // DIKSHA courses (online only)
    if (_isOnline) {
      try {
        final dikshaList = await _diksha.fetchCourses();
        for (final d in dikshaList) {
          results.add(LearningResource(
            id: d.id,
            title: d.title,
            description: d.description,
            provider: d.provider ?? 'DIKSHA',
            subject: 'School Education',
            category: 'NCERT / State Boards',
            level: 'School',
            officialUrl: 'https://diksha.gov.in',
            type: ResourceType.course,
            downloadable: true,
            license: 'Open Government Data (DIKSHA)',
            lessons: d.lessons
                .asMap()
                .entries
                .map((e) => ChapterLesson(
                      id: e.value.id,
                      chapterNumber: e.key + 1,
                      title: e.value.title,
                      content: e.value.content,
                      sourceUrl: e.value.sourceUrl,
                      downloadable: true,
                    ))
                .toList(),
          ));
        }
      } catch (_) {}
    }

    return results;
  }

  Future<List<LearningResource>> searchResources({
    String? query,
    String? provider,
    String? subject,
    String? level,
    bool downloadableOnly = false,
  }) async {
    final all = await getAllResources();
    return all.where((r) {
      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final matches = r.title.toLowerCase().contains(q) ||
            r.description.toLowerCase().contains(q) ||
            r.subject.toLowerCase().contains(q) ||
            r.provider.toLowerCase().contains(q) ||
            r.instructorOrAuthor?.toLowerCase().contains(q) == true ||
            r.lessons.any((l) =>
                l.title.toLowerCase().contains(q) ||
                l.content.toLowerCase().contains(q));
        if (!matches) return false;
      }

      if (provider != null && provider != 'All') {
        if (!r.provider.toLowerCase().contains(provider.toLowerCase())) {
          return false;
        }
      }

      if (subject != null && subject != 'All') {
        if (!r.subject.toLowerCase().contains(subject.toLowerCase())) {
          return false;
        }
      }

      if (level != null && level != 'All') {
        if (!r.level.toLowerCase().contains(level.toLowerCase())) {
          return false;
        }
      }

      if (downloadableOnly && !r.downloadable) return false;

      return true;
    }).toList();
  }

  Future<LearningResource?> getResource(String id) async {
    final all = await getAllResources();
    try {
      return all.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Returns resources available offline for the CURRENT USER.
  Future<List<LearningResource>> getDownloadedResources() async {
    final all = await getAllResources();
    return all.where((r) {
      // GramVidya built-in courses are always available
      if (r.provider == 'GramVidya') return true;
      // Check user's downloaded state
      return UserStore.courseState(r.id) == 'downloaded' ||
          _downloadManager.isDownloaded(r.id);
    }).toList();
  }
}
