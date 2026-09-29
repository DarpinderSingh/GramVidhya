import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'course_provider.dart';
import 'user_store.dart';
import '../mentor/mentor_models.dart';

/// Central progress service providing a single, consistent source of truth
/// for learning progress, subject progress, activity timeline, statistics,
/// and dynamic needs-attention topics across the entire application.
///
/// Every query optionally accepts [userId] and defaults to the active user ID.
class ProgressService extends ChangeNotifier {
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;
  ProgressService._internal();

  static Box get _box => Hive.box('app');

  static String _cleanSubject(String title) {
    final t = title.trim();
    final lower = t.toLowerCase();
    if (lower.contains('english')) return 'English';
    if (lower.contains('math')) return 'Mathematics';
    if (lower.contains('science') || lower.contains('nature')) return 'Science';
    if (lower.contains('digital')) return 'Digital Literacy';
    if (lower.contains('financial') || lower.contains('finance')) return 'Financial Literacy';
    if (lower.contains('machine learning') || lower.contains('ml')) return 'Machine Learning';
    if (lower.contains('operating system') || lower.contains('os')) return 'Operating Systems';
    final modRegex = RegExp(r'^Module\s*\d+\s*:\s*', caseSensitive: false);
    return t.replaceFirst(modRegex, '').trim();
  }

  // ── 1. Lesson Progress ──────────────────────────────────────────────────

  /// Checks if a lesson is completed by the user.
  bool isLessonCompleted(String lessonId, [String? userId]) =>
      UserScopedStore.done(lessonId, userId);

  /// Returns 1.0 if lesson is completed, 0.0 otherwise.
  double getLessonProgress(String lessonId, [String? userId]) =>
      isLessonCompleted(lessonId, userId) ? 1.0 : 0.0;

  // ── 2. Course Progress ──────────────────────────────────────────────────

  /// Calculates and returns progress (0.0 to 1.0) for a list of lessons.
  double calculateProgressForLessons(List<dynamic> lessons, {String? courseId, String? userId}) {
    if (lessons.isEmpty) return 0.0;
    int completed = 0;
    for (final l in lessons) {
      String? id;
      if (l is Lesson) {
        id = l.id;
      } else if (l is Map) {
        id = l['id']?.toString();
      } else {
        try {
          id = (l as dynamic).id?.toString();
        } catch (_) {}
      }
      if (id != null && isLessonCompleted(id, userId)) {
        completed++;
      }
    }
    final progress = (completed / lessons.length).clamp(0.0, 1.0);
    if (courseId != null) {
      UserScopedStore.setCourseProgress(courseId, progress, userId);
    }
    return progress;
  }

  /// Gets progress (0.0 to 1.0) for a specific course.
  double getCourseProgress(String courseId, [String? userId]) {
    // 1. Check built-in courses
    for (final c in CourseManager.builtInCourses) {
      if (c.id == courseId) {
        return calculateProgressForLessons(c.lessons, courseId: courseId, userId: userId);
      }
    }

    // 2. Check stored progress value
    final stored = UserScopedStore.courseProgress(courseId, userId);
    if (stored > 0.0) return stored;

    // 3. Check downloaded course data
    final data = UserScopedStore.courseData(courseId, userId);
    if (data != null) {
      try {
        final map = jsonDecode(data) as Map<String, dynamic>;
        final c = Course.fromJson(map);
        return calculateProgressForLessons(c.lessons, courseId: courseId, userId: userId);
      } catch (_) {}
    }

    return 0.0;
  }

  // ── 3. Subject Progress ─────────────────────────────────────────────────

  /// Calculates real progress (0.0 to 1.0) for a given subject.
  double getSubjectProgress(String subject, [String? userId]) {
    final lowerSubj = subject.toLowerCase().trim();
    int totalLessons = 0;
    int completedLessons = 0;

    void tallyCourse(Course c) {
      final clean = _cleanSubject(c.title).toLowerCase();
      if (clean == lowerSubj ||
          c.title.toLowerCase().contains(lowerSubj) ||
          c.id.toLowerCase().contains(lowerSubj)) {
        for (final l in c.lessons) {
          totalLessons++;
          if (isLessonCompleted(l.id, userId)) {
            completedLessons++;
          }
        }
      }
    }

    for (final c in CourseManager.builtInCourses) {
      tallyCourse(c);
    }

    for (final id in UserScopedStore.getDownloadedCourseIds(userId)) {
      final raw = UserScopedStore.courseData(id, userId);
      if (raw != null) {
        try {
          final c = Course.fromJson(jsonDecode(raw) as Map<String, dynamic>);
          tallyCourse(c);
        } catch (_) {}
      }
    }

    if (totalLessons == 0) return 0.0;
    return (completedLessons / totalLessons).clamp(0.0, 1.0);
  }

  /// Returns subject breakdown with real progress for common subjects.
  Map<String, double> getSubjectBreakdown([String? userId]) {
    final subjects = [
      'English',
      'Mathematics',
      'Science',
      'Digital Literacy',
      'Financial Literacy',
    ];
    final map = <String, double>{};
    for (final s in subjects) {
      map[s] = getSubjectProgress(s, userId);
    }
    return map;
  }

  // ── 4. Overall User Progress ───────────────────────────────────────────

  /// Calculates overall progress across all available courses.
  double getUserProgress([String? userId]) {
    int totalLessons = 0;
    int completedLessons = 0;

    for (final c in CourseManager.builtInCourses) {
      for (final l in c.lessons) {
        totalLessons++;
        if (isLessonCompleted(l.id, userId)) {
          completedLessons++;
        }
      }
    }

    for (final id in UserScopedStore.getDownloadedCourseIds(userId)) {
      final raw = UserScopedStore.courseData(id, userId);
      if (raw != null) {
        try {
          final c = Course.fromJson(jsonDecode(raw) as Map<String, dynamic>);
          for (final l in c.lessons) {
            totalLessons++;
            if (isLessonCompleted(l.id, userId)) {
              completedLessons++;
            }
          }
        } catch (_) {}
      }
    }

    if (totalLessons == 0) return 0.0;
    return (completedLessons / totalLessons).clamp(0.0, 1.0);
  }

  double getOverallProgress([String? userId]) => getUserProgress(userId);

  /// Returns total count of completed lessons across all courses.
  int getTotalCompletedLessons([String? userId]) {
    final counted = <String>{};

    for (final c in CourseManager.builtInCourses) {
      for (final l in c.lessons) {
        if (isLessonCompleted(l.id, userId)) {
          counted.add(l.id);
        }
      }
    }

    for (final id in UserScopedStore.getDownloadedCourseIds(userId)) {
      final raw = UserScopedStore.courseData(id, userId);
      if (raw != null) {
        try {
          final c = Course.fromJson(jsonDecode(raw) as Map<String, dynamic>);
          for (final l in c.lessons) {
            if (isLessonCompleted(l.id, userId)) {
              counted.add(l.id);
            }
          }
        } catch (_) {}
      }
    }

    return counted.length;
  }

  // ── 5. Learning Statistics ──────────────────────────────────────────────

  /// Calculates comprehensive, un-faked learning statistics for the target user.
  LearningStats getLearningStats([String? userId]) {
    final overall = getUserProgress(userId);
    final completedLessons = getTotalCompletedLessons(userId);

    final recents = getRecentLessons(userId);
    final startedCourseIds = <String>{};
    final completedCourseIds = <String>{};
    int totalLessonsInActiveCourses = 0;

    // Check all built-in courses
    for (final c in CourseManager.builtInCourses) {
      int cCompleted = 0;
      for (final l in c.lessons) {
        if (isLessonCompleted(l.id, userId)) cCompleted++;
      }
      if (cCompleted > 0 || recents.any((r) => r['courseId'] == c.id)) {
        startedCourseIds.add(c.id);
        totalLessonsInActiveCourses += c.lessons.length;
      }
      if (c.lessons.isNotEmpty && cCompleted == c.lessons.length) {
        completedCourseIds.add(c.id);
      }
    }

    // Check downloaded courses
    for (final id in UserScopedStore.getDownloadedCourseIds(userId)) {
      final raw = UserScopedStore.courseData(id, userId);
      if (raw != null) {
        try {
          final c = Course.fromJson(jsonDecode(raw) as Map<String, dynamic>);
          int cCompleted = 0;
          for (final l in c.lessons) {
            if (isLessonCompleted(l.id, userId)) cCompleted++;
          }
          if (cCompleted > 0 || recents.any((r) => r['courseId'] == c.id)) {
            startedCourseIds.add(c.id);
            totalLessonsInActiveCourses += c.lessons.length;
          }
          if (c.lessons.isNotEmpty && cCompleted == c.lessons.length) {
            completedCourseIds.add(c.id);
          }
        } catch (_) {}
      }
    }

    final inProgress = recents.where((r) {
      final lid = r['lessonId']?.toString();
      return lid != null && !isLessonCompleted(lid, userId);
    }).length;

    final remaining = (totalLessonsInActiveCourses - completedLessons).clamp(0, 9999);

    // Study sessions and streak from events
    final events = _loadUserEvents(userId);
    final sessionDates = <String>{};
    for (final e in events) {
      final dateStr = '${e.timestamp.year}-${e.timestamp.month.toString().padLeft(2, '0')}-${e.timestamp.day.toString().padLeft(2, '0')}';
      sessionDates.add(dateStr);
    }
    // Also include recents
    for (final r in recents) {
      final dateStr = r['timestamp']?.toString();
      if (dateStr != null && dateStr.length >= 10) {
        sessionDates.add(dateStr.substring(0, 10));
      }
    }

    int streak = 0;
    if (sessionDates.isNotEmpty) {
      final sortedDates = sessionDates.toList()..sort((a, b) => b.compareTo(a));
      var currentCheck = DateTime.now();
      while (true) {
        final dStr = '${currentCheck.year}-${currentCheck.month.toString().padLeft(2, '0')}-${currentCheck.day.toString().padLeft(2, '0')}';
        if (sortedDates.contains(dStr)) {
          streak++;
          currentCheck = currentCheck.subtract(const Duration(days: 1));
        } else {
          // If today hasn't had a session yet, check if yesterday had one
          if (streak == 0) {
            final yCheck = currentCheck.subtract(const Duration(days: 1));
            final yStr = '${yCheck.year}-${yCheck.month.toString().padLeft(2, '0')}-${yCheck.day.toString().padLeft(2, '0')}';
            if (sortedDates.contains(yStr)) {
              streak++;
              currentCheck = yCheck.subtract(const Duration(days: 1));
              continue;
            }
          }
          break;
        }
      }
    }

    return LearningStats(
      overallProgress: overall,
      coursesStarted: startedCourseIds.length,
      coursesCompleted: completedCourseIds.length,
      lessonsCompleted: completedLessons,
      lessonsInProgress: inProgress,
      lessonsRemaining: remaining,
      studySessions: sessionDates.length,
      streakDays: streak,
    );
  }

  // ── 6. Activity Timeline ────────────────────────────────────────────────

  /// Returns real chronological activity timeline for the user.
  List<ActivityTimelineItem> getRecentActivity([String? userId]) {
    final list = <ActivityTimelineItem>[];
    final events = _loadUserEvents(userId);

    for (final e in events) {
      String action = 'completed';
      String subtitle = e.subject;
      if (e.type == LearningEventType.lessonCompleted) {
        action = 'completed';
        subtitle = 'Completed lesson in ${e.subject}';
      } else if (e.type == LearningEventType.quizResult) {
        action = 'quiz';
        subtitle = 'Quiz score: ${e.score?.toStringAsFixed(0) ?? 'N/A'}%';
      } else if (e.type == LearningEventType.topicAsked) {
        action = 'asked';
        subtitle = 'Asked mentor about ${e.topic}';
      } else if (e.type == LearningEventType.lessonStarted) {
        action = 'started';
        subtitle = 'Started lesson in ${e.subject}';
      }

      list.add(ActivityTimelineItem(
        title: e.topic.isNotEmpty ? e.topic : e.subject,
        subtitle: subtitle,
        actionType: action,
        timestamp: e.timestamp,
        courseTitle: e.subject,
        courseId: e.metadata?['courseId']?.toString(),
        lessonId: e.metadata?['lessonId']?.toString(),
      ));
    }

    // Add recent chapter accesses
    final recents = getRecentLessons(userId);
    for (final r in recents) {
      final tStr = r['timestamp']?.toString();
      final dt = tStr != null ? DateTime.tryParse(tStr) ?? DateTime.now() : DateTime.now();
      final lTitle = r['lessonTitle']?.toString() ?? 'Lesson';
      final cTitle = r['courseTitle']?.toString() ?? 'Course';
      final isDone = r['lessonId'] != null && isLessonCompleted(r['lessonId'].toString(), userId);

      // Avoid exact duplicates
      final alreadyIn = list.any((item) =>
          item.title == lTitle &&
          item.timestamp.difference(dt).abs().inMinutes < 5);

      if (!alreadyIn) {
        list.add(ActivityTimelineItem(
          title: lTitle,
          subtitle: isDone ? 'Completed in $cTitle' : 'Studied in $cTitle',
          actionType: isDone ? 'completed' : 'started',
          timestamp: dt,
          courseTitle: cTitle,
          courseId: r['courseId']?.toString(),
          lessonId: r['lessonId']?.toString(),
        ));
      }
    }

    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list.take(20).toList();
  }

  // ── 7. Dynamic Needs Attention (Signal-Driven) ───────────────────────────

  /// Computes data-driven needs-attention topics based on actual signals:
  /// 1. Low quiz scores (< 60%) or repeated quiz failures.
  /// 2. Repeated questions asked without completing lesson.
  /// 3. Incomplete lessons (started/accessed but not marked done).
  /// 4. Repeatedly opened without completion.
  List<NeedsAttentionItem> getNeedsAttention([String? userId]) {
    final items = <NeedsAttentionItem>[];
    final events = _loadUserEvents(userId);
    final recents = getRecentLessons(userId);

    // 1. Analyze quiz scores
    final quizScores = <String, List<double>>{};
    final quizSubjects = <String, String>{};
    for (final e in events) {
      if (e.type == LearningEventType.quizResult && e.score != null) {
        quizScores.putIfAbsent(e.topic, () => []).add(e.score!);
        quizSubjects[e.topic] = e.subject;
      }
    }

    quizScores.forEach((topic, scores) {
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      if (avg < 50.0) {
        items.add(NeedsAttentionItem(
          topic: topic,
          subject: quizSubjects[topic] ?? 'General',
          reason: 'Quiz score: ${avg.toStringAsFixed(0)}% (Needs revision)',
          actionType: 'revision',
          score: avg,
          priority: 1, // highest priority
        ));
      } else if (avg < 65.0) {
        items.add(NeedsAttentionItem(
          topic: topic,
          subject: quizSubjects[topic] ?? 'General',
          reason: 'Quiz score: ${avg.toStringAsFixed(0)}%',
          actionType: 'practice',
          score: avg,
          priority: 2,
        ));
      }
    });

    // 2. Analyze repeated questions
    final questionCounts = <String, int>{};
    final questionSubjects = <String, String>{};
    for (final e in events) {
      if (e.type == LearningEventType.topicAsked && e.topic.isNotEmpty) {
        questionCounts[e.topic] = (questionCounts[e.topic] ?? 0) + 1;
        questionSubjects[e.topic] = e.subject;
      }
    }

    questionCounts.forEach((topic, count) {
      if (count >= 2 && !items.any((i) => i.topic == topic)) {
        items.add(NeedsAttentionItem(
          topic: topic,
          subject: questionSubjects[topic] ?? 'General',
          reason: 'Asked $count times without completing the lesson',
          actionType: 'revision',
          priority: 3,
        ));
      }
    });

    // 3. Analyze recently accessed incomplete lessons & repeat opens
    final openCounts = <String, int>{};
    for (final r in recents) {
      final lid = r['lessonId']?.toString();
      final lTitle = r['lessonTitle']?.toString();
      if (lid != null && lTitle != null) {
        openCounts[lTitle] = (openCounts[lTitle] ?? 0) + 1;
      }
    }

    for (final r in recents) {
      final lid = r['lessonId']?.toString();
      final lTitle = r['lessonTitle']?.toString();
      final cTitle = r['courseTitle']?.toString() ?? 'General';
      final cId = r['courseId']?.toString();
      final lIdx = r['lessonIndex'] is int ? r['lessonIndex'] as int : null;

      if (lid != null && lTitle != null && !isLessonCompleted(lid, userId)) {
        if (!items.any((i) => i.topic == lTitle)) {
          final opens = openCounts[lTitle] ?? 1;
          if (opens >= 3) {
            items.add(NeedsAttentionItem(
              topic: lTitle,
              subject: _cleanSubject(cTitle),
              reason: 'Opened $opens times without completing',
              actionType: 'revision',
              courseId: cId,
              lessonId: lid,
              lessonIndex: lIdx,
              priority: 2,
            ));
          } else {
            items.add(NeedsAttentionItem(
              topic: lTitle,
              subject: _cleanSubject(cTitle),
              reason: 'Started but incomplete',
              actionType: 'continue',
              courseId: cId,
              lessonId: lid,
              lessonIndex: lIdx,
              priority: 4,
            ));
          }
        }
      }
    }

    items.sort((a, b) => a.priority.compareTo(b.priority));
    return items;
  }

  // ── 8. Recent Lessons ───────────────────────────────────────────────────

  List<Map<String, dynamic>> getRecentLessons([String? userId]) =>
      UserScopedStore.getRecentLessons(userId);

  // ── 9. Mentor Context Pipeline ──────────────────────────────────────────

  /// Assembles the complete, user-scoped Mentor Context pipeline.
  MentorContext getMentorContext([String? userId]) {
    final uid = UserScopedStore.effectiveUserId(userId);
    final stats = getLearningStats(uid);
    final recents = getRecentLessons(uid);
    final needsAttn = getNeedsAttention(uid);

    final recentCourses = <String>{};
    final recentLessons = <Map<String, dynamic>>[];
    final incompleteLessons = <Map<String, dynamic>>[];
    final completedLessons = <String>[];
    final courseProgressMap = <String, double>{};

    for (final r in recents) {
      final cTitle = r['courseTitle']?.toString();
      final cId = r['courseId']?.toString();
      final lTitle = r['lessonTitle']?.toString();
      final lId = r['lessonId']?.toString();

      if (cTitle != null) recentCourses.add(cTitle);
      if (cId != null && !courseProgressMap.containsKey(cId)) {
        courseProgressMap[cId] = getCourseProgress(cId, uid);
      }
      if (lId != null) {
        if (isLessonCompleted(lId, uid)) {
          if (lTitle != null && !completedLessons.contains(lTitle)) {
            completedLessons.add(lTitle);
          }
        } else {
          incompleteLessons.add(r);
        }
      }
      recentLessons.add(r);
    }

    final subjProgress = getSubjectBreakdown(uid);

    return MentorContext(
      userId: uid,
      recentCourses: recentCourses.toList(),
      recentLessons: recentLessons,
      incompleteLessons: incompleteLessons,
      completedLessons: completedLessons,
      courseProgress: courseProgressMap,
      subjectProgress: subjProgress,
      strugglingTopics: needsAttn,
      recentlyStudiedTopics: recents.map((r) => r['lessonTitle']?.toString() ?? '').where((s) => s.isNotEmpty).toList(),
      overallProgress: stats.overallProgress,
      coursesStarted: stats.coursesStarted,
      coursesCompleted: stats.coursesCompleted,
      lessonsCompleted: stats.lessonsCompleted,
      lessonsInProgress: stats.lessonsInProgress,
      lessonsRemaining: stats.lessonsRemaining,
      studySessions: stats.studySessions,
      streakDays: stats.streakDays,
    );
  }

  // ── Helper ─────────────────────────────────────────────────────────────

  List<LearningEvent> _loadUserEvents([String? userId]) {
    final uid = UserScopedStore.effectiveUserId(userId);
    final rawList = _box.get('mentor_learning_events_$uid', defaultValue: <dynamic>[]) as List;
    final events = <LearningEvent>[];
    for (final item in rawList) {
      try {
        final map = item is Map
            ? Map<String, dynamic>.from(item)
            : jsonDecode(item as String) as Map<String, dynamic>;
        events.add(LearningEvent.fromJson(Map<String, dynamic>.from(map)));
      } catch (_) {}
    }
    return events;
  }

  // ── Mutating Methods ────────────────────────────────────────────────────

  Future<void> markLessonCompleted({
    required String courseId,
    required String lessonId,
    String? courseTitle,
    String? lessonTitle,
    List<dynamic>? allLessons,
    String? userId,
  }) async {
    await UserScopedStore.setDone(lessonId, true, userId);

    if (allLessons != null && allLessons.isNotEmpty) {
      calculateProgressForLessons(allLessons, courseId: courseId, userId: userId);
    } else {
      getCourseProgress(courseId, userId);
    }

    // Record learning event for the user
    final uid = UserScopedStore.effectiveUserId(userId);
    final kEvents = 'mentor_learning_events_$uid';
    final rawList = _box.get(kEvents, defaultValue: <dynamic>[]) as List;
    final events = <LearningEvent>[];
    for (final item in rawList) {
      try {
        final map = item is Map
            ? Map<String, dynamic>.from(item)
            : jsonDecode(item as String) as Map<String, dynamic>;
        events.add(LearningEvent.fromJson(Map<String, dynamic>.from(map)));
      } catch (_) {}
    }

    final subj = courseTitle != null ? _cleanSubject(courseTitle) : 'General';
    final topic = lessonTitle ?? lessonId;
    events.insert(0, LearningEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: LearningEventType.lessonCompleted,
      subject: subj,
      topic: topic,
      score: 100.0,
      metadata: {'courseId': courseId, 'lessonId': lessonId},
    ));
    if (events.length > 200) events.removeRange(200, events.length);
    await _box.put(kEvents, events.map((e) => jsonEncode(e.toJson())).toList());

    notifyListeners();
  }

  Future<void> markLessonIncomplete({
    required String courseId,
    required String lessonId,
    List<dynamic>? allLessons,
    String? userId,
  }) async {
    await UserScopedStore.setDone(lessonId, false, userId);

    if (allLessons != null && allLessons.isNotEmpty) {
      calculateProgressForLessons(allLessons, courseId: courseId, userId: userId);
    } else {
      getCourseProgress(courseId, userId);
    }

    notifyListeners();
  }
}
