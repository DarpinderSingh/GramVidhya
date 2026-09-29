import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/course_provider.dart';
import '../data/store.dart';
import '../data/user_store.dart';
import '../data/progress_service.dart';
import 'mentor_models.dart';
import 'mentor_thresholds.dart';

/// Core offline service managing student profile, mentor memory, learning events,
/// subject progress calculation, weak topic detection, daily plan generation,
/// and context-aware dynamic mentor messages based on actual learning data.
///
/// USER ISOLATION:
/// All Hive keys are suffixed with the current user ID so that switching users
/// gives each user a completely separate mentor context.
class MentorService extends ChangeNotifier {
  static final MentorService _instance = MentorService._internal();
  factory MentorService() => _instance;
  MentorService._internal();

  static Box get _box => Hive.box('app');

  // ── User-scoped Hive keys ──────────────────────────────────────────────

  static String get _uid => UserScopedStore.currentUserId;
  static String get _kProfile => 'mentor_student_profile_$_uid';
  static String get _kEvents => 'mentor_learning_events_$_uid';
  static String get _kMemory => 'mentor_memory_state_$_uid';
  static String get _kDailyPlan => 'mentor_daily_plan_$_uid';

  // ── In-memory state ────────────────────────────────────────────────────

  StudentProfile _profile = StudentProfile(name: 'Student');
  final List<LearningEvent> _events = [];
  MentorMemory _memory = MentorMemory();
  DailyPlan? _dailyPlan;

  String? _lastLoadedUserId; // track which user's data is loaded

  StudentProfile get profile => _profile;
  List<LearningEvent> get events => List.unmodifiable(_events);
  MentorMemory get memory => _memory;
  DailyPlan? get dailyPlan => _dailyPlan;

  Future<void> init() async {
    _ensureUserLoaded();
    _recalculateAnalytics();
  }

  /// Syncs state with Store (e.g. newly completed lessons or changed profile).
  /// Also ensures we reload if the user has changed since last call.
  void syncFromStore() {
    _ensureUserLoaded();
    _recalculateAnalytics();
    notifyListeners();
  }

  /// Reloads all mentor state for the current user.
  /// Call this after user login/logout/switch.
  void reloadForCurrentUser() {
    _lastLoadedUserId = null; // force full reload
    _ensureUserLoaded();
    _recalculateAnalytics();
    notifyListeners();
  }

  void _ensureUserLoaded() {
    final uid = _uid;
    if (uid == _lastLoadedUserId) return; // already loaded for this user
    _lastLoadedUserId = uid;
    _loadProfile();
    _loadEvents();
    _loadMemory();
    _loadDailyPlan();
  }

  // ── Helper ─────────────────────────────────────────────────────────────

  static String cleanSubject(String title) {
    final t = title.trim();
    final lower = t.toLowerCase();
    if (lower.contains('english')) return 'English';
    if (lower.contains('math')) return 'Mathematics';
    if (lower.contains('science') || lower.contains('nature')) return 'Science';
    if (lower.contains('digital')) return 'Digital Literacy';
    if (lower.contains('financial') || lower.contains('finance')) {
      return 'Financial Literacy';
    }
    if (lower.contains('machine learning') || lower.contains('ml')) {
      return 'Machine Learning';
    }
    if (lower.contains('operating system') || lower.contains('os')) {
      return 'Operating Systems';
    }
    final modRegex = RegExp(r'^Module\s*\d+\s*:\s*', caseSensitive: false);
    return t.replaceFirst(modRegex, '').trim();
  }

  // ── Profile Management ─────────────────────────────────────────────────

  void _loadProfile() {
    final raw = _box.get(_kProfile);
    if (raw != null) {
      try {
        final map = raw is Map
            ? Map<String, dynamic>.from(raw)
            : jsonDecode(raw as String) as Map<String, dynamic>;
        _profile = StudentProfile.fromJson(Map<String, dynamic>.from(map));
      } catch (_) {}
    } else {
      // Populate from auth profile for a new user.
      final p = Store.profile;
      final authName = (p['name'] as String?)?.trim();
      final grade = (p['educationLevel'] as String?)?.trim();
      _profile = StudentProfile(
        name: (authName != null && authName.isNotEmpty) ? authName : 'Student',
        classGrade: (grade != null && grade.isNotEmpty) ? grade : 'UG',
      );
    }

    // Sync currentTopic & currentSubject from user-scoped recent lessons if available.
    final recent = UserScopedStore.recentLessons;
    if (recent.isNotEmpty) {
      final latest = recent.first;
      final courseTitle = latest['courseTitle']?.toString() ?? '';
      final lessonTitle = latest['lessonTitle']?.toString() ?? '';
      if (courseTitle.isNotEmpty && lessonTitle.isNotEmpty) {
        _profile = _profile.copyWith(
          currentSubject: cleanSubject(courseTitle),
          currentTopic: lessonTitle,
        );
      }
    }
  }

  Future<void> saveProfile(StudentProfile p) async {
    _profile = p;
    await _box.put(_kProfile, jsonEncode(p.toJson()));
    notifyListeners();
  }

  // ── Learning Events ────────────────────────────────────────────────────

  void _loadEvents() {
    final rawList = _box.get(_kEvents, defaultValue: <dynamic>[]) as List;
    _events.clear();
    for (final item in rawList) {
      try {
        final map = item is Map
            ? Map<String, dynamic>.from(item)
            : jsonDecode(item as String) as Map<String, dynamic>;
        _events.add(LearningEvent.fromJson(Map<String, dynamic>.from(map)));
      } catch (_) {}
    }
  }

  Future<void> recordEvent({
    required LearningEventType type,
    required String subject,
    required String topic,
    double? score,
    Map<String, dynamic>? metadata,
  }) async {
    _ensureUserLoaded();
    final event = LearningEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      subject: subject,
      topic: topic,
      score: score,
      metadata: metadata,
    );

    _events.insert(0, event);
    if (_events.length > 200) _events.removeRange(200, _events.length);

    final rawList = _events.map((e) => jsonEncode(e.toJson())).toList();
    await _box.put(_kEvents, rawList);

    _recalculateAnalytics();
    notifyListeners();
  }

  Future<void> recordLessonCompleted({
    required String courseId,
    required String courseTitle,
    required String lessonId,
    required String lessonTitle,
  }) async {
    _ensureUserLoaded();
    await UserScopedStore.setDone(lessonId, true);
    final subject = cleanSubject(courseTitle);
    await recordEvent(
      type: LearningEventType.lessonCompleted,
      subject: subject,
      topic: lessonTitle,
      score: 100.0,
      metadata: {'courseId': courseId, 'lessonId': lessonId},
    );
  }

  // ── Memory & Analytics ─────────────────────────────────────────────────

  void _loadMemory() {
    final raw = _box.get(_kMemory);
    if (raw != null) {
      try {
        final map = raw is Map
            ? Map<String, dynamic>.from(raw)
            : jsonDecode(raw as String) as Map<String, dynamic>;
        _memory = MentorMemory.fromJson(Map<String, dynamic>.from(map));
      } catch (_) {}
    } else {
      _memory = MentorMemory();
    }
  }

  Future<void> _saveMemory() async {
    await _box.put(_kMemory, jsonEncode(_memory.toJson()));
  }

  void _recalculateAnalytics() {
    // 1. Identify completed topics from events
    final completed = <String>{};
    for (final e in _events) {
      if (e.type == LearningEventType.lessonCompleted) {
        completed.add(e.topic);
      }
    }

    // 2. Include lessons marked done in user-scoped store
    for (final course in CourseManager.builtInCourses) {
      for (final lesson in course.lessons) {
        if (UserScopedStore.done(lesson.id)) completed.add(lesson.title);
      }
    }
    for (final id in UserScopedStore.downloadedCourseIds) {
      final raw = UserScopedStore.courseData(id);
      if (raw != null) {
        try {
          final c = Course.fromJson(jsonDecode(raw) as Map<String, dynamic>);
          for (final lesson in c.lessons) {
            if (UserScopedStore.done(lesson.id)) completed.add(lesson.title);
          }
        } catch (_) {}
      }
    }

    // 3. Identify weak topics via quiz scores & repeated questions
    final topicScores = <String, List<double>>{};
    final topicSubjects = <String, String>{};
    final repeatedQ = <String, int>{};

    for (final e in _events) {
      topicSubjects[e.topic] = e.subject;
      if (e.type == LearningEventType.quizResult && e.score != null) {
        topicScores.putIfAbsent(e.topic, () => []).add(e.score!);
      } else if (e.type == LearningEventType.topicAsked) {
        repeatedQ[e.topic] = (repeatedQ[e.topic] ?? 0) + 1;
      }
    }

    final weakList = <WeakTopic>[];

    topicScores.forEach((topic, scores) {
      if (scores.length >= MentorThresholds.minEventsForEvaluation) {
        final avg = scores.reduce((a, b) => a + b) / scores.length;
        if (avg < MentorThresholds.quizWeakThreshold) {
          weakList.add(WeakTopic(
            subject: topicSubjects[topic] ?? 'General',
            topic: topic,
            reason:
                'Low quiz performance (${avg.toStringAsFixed(0)}% average)',
            recommendedAction: 'Practice basic concepts and review key formulas',
            actionType: 'revision',
            errorCount:
                scores.where((s) => s < MentorThresholds.quizWeakThreshold).length,
            averageScore: avg,
          ));
        } else if (avg < MentorThresholds.quizPracticeThreshold) {
          weakList.add(WeakTopic(
            subject: topicSubjects[topic] ?? 'General',
            topic: topic,
            reason: 'Needs practice (${avg.toStringAsFixed(0)}% avg)',
            recommendedAction: 'Solve 3 additional practice problems',
            actionType: 'practice',
            errorCount: 1,
            averageScore: avg,
          ));
        }
      }
    });

    repeatedQ.forEach((topic, count) {
      if (count >= MentorThresholds.repeatedQuestionThreshold &&
          !weakList.any((w) => w.topic == topic) &&
          !completed.contains(topic)) {
        weakList.add(WeakTopic(
          subject: topicSubjects[topic] ?? 'General',
          topic: topic,
          reason: 'Asked $count times without completing the lesson',
          recommendedAction: 'Review guided lesson step-by-step with mentor',
          actionType: 'revision',
          errorCount: count,
        ));
      }
    });

    // 4. Fetch dynamic needs-attention from ProgressService
    final needsAttn = ProgressService().getNeedsAttention(_uid);

    _memory = MentorMemory(
      weakTopics: weakList,
      needsAttention: needsAttn,
      completedTopics: completed.toList(),
      recentEvents: _events.take(20).toList(),
      lastSessionSummary: _memory.lastSessionSummary,
      lastActive: DateTime.now(),
    );

    _saveMemory();
    _generateDailyPlan();
  }

  // ── Dynamic Mentor Message (Uses Real Learning Data) ──────────────────

  /// Generates a personalized mentor greeting and encouragement based on
  /// real student learning data, completed topics, weak topics, and active subject.
  /// Never hardcodes topics like Quadratic Equations unless actual user studied it.
  String generateMentorMessage() {
    _ensureUserLoaded();
    final name = _profile.name.isNotEmpty ? _profile.name : 'Student';
    final subject = _profile.currentSubject;
    final topic = _profile.currentTopic;

    // 1. Dynamic Needs-Attention or Weak topics requiring attention
    if (_memory.needsAttention.isNotEmpty) {
      final item = _memory.needsAttention.first;
      return "Hello $name! I noticed you found '${item.topic}' in ${item.subject} challenging (${item.reason}). Let's review it together and work through some practice today!";
    }
    if (_memory.weakTopics.isNotEmpty) {
      final weak = _memory.weakTopics.first;
      return "Hello $name! I noticed you found '${weak.topic}' in ${weak.subject} challenging (${weak.reason}). Let's review it together and do a few quick practice questions today.";
    }

    // 2. Student has completed multiple topics
    if (_memory.completedTopics.isNotEmpty) {
      final count = _memory.completedTopics.length;
      final lastCompleted = _memory.completedTopics.last;
      if (subject.isNotEmpty && topic.isNotEmpty) {
        final progress = getSubjectProgress(subject);
        final pct = (progress * 100).toInt();
        return "Great job $name! You have mastered $count topics so far, including '$lastCompleted'. You are at $pct% in $subject. Let's tackle '$topic' next!";
      } else {
        return "Good to see you $name! You've already completed $count topics. Ready to continue your learning journey today?";
      }
    }

    // 3. Recent lesson activity
    final recent = UserScopedStore.recentLessons;
    if (recent.isNotEmpty) {
      final latest = recent.first;
      final lTitle = latest['lessonTitle']?.toString() ?? topic;
      final cTitle = latest['courseTitle']?.toString() ?? subject;
      return "Welcome back $name! You were recently studying '$lTitle' in $cTitle. Let's keep your learning momentum going!";
    }

    // 4. Fresh or beginner student
    if (topic.isNotEmpty && subject.isNotEmpty) {
      return "Welcome $name! I am your GramVidya Digital Mentor. We are exploring $subject. Let's begin with '$topic' together!";
    }

    return "Welcome $name! I am your GramVidya Digital Mentor. Choose a course from the Learn section to begin exploring!";
  }

  // ── Subject Progress Calculation (Synced with ProgressService) ─────────

  double getSubjectProgress(String subject) =>
      ProgressService().getSubjectProgress(subject, _uid);

  Map<String, dynamic> getCourseStats(String courseId, List<dynamic> lessons) {
    final total = lessons.length;
    if (total == 0) return {'completed': 0, 'total': 0, 'progress': 0.0};

    int completed = 0;
    for (final lesson in lessons) {
      String? id;
      if (lesson is Map) {
        id = lesson['id'] as String?;
      } else if (lesson is Lesson) {
        id = lesson.id;
      } else {
        try {
          id = (lesson as dynamic).id?.toString();
        } catch (_) {}
      }
      if (id != null && UserScopedStore.done(id)) completed++;
    }
    return {
      'completed': completed,
      'total': total,
      'progress': (completed / total).clamp(0.0, 1.0),
    };
  }

  Map<String, double> getAllSubjectProgress() =>
      ProgressService().getSubjectBreakdown(_uid);

  // ── Daily Learning Plan ────────────────────────────────────────────────

  void _loadDailyPlan() {
    final raw = _box.get(_kDailyPlan);
    if (raw != null) {
      try {
        final map = raw is Map
            ? Map<String, dynamic>.from(raw)
            : jsonDecode(raw as String) as Map<String, dynamic>;
        _dailyPlan = DailyPlan.fromJson(Map<String, dynamic>.from(map));
      } catch (_) {}
    }
  }

  void _generateDailyPlan() {
    final steps = <DailyPlanStep>[];

    // Priority 1: Top needs-attention item
    if (_memory.needsAttention.isNotEmpty) {
      final top = _memory.needsAttention.first;
      steps.add(DailyPlanStep(
        title: '${top.actionType == "practice" ? "Practice" : "Revise"} ${top.topic}',
        durationMinutes: 5,
        actionType: top.actionType,
        subject: top.subject,
        topic: top.topic,
      ));
    } else if (_memory.weakTopics.isNotEmpty) {
      final topWeak = _memory.weakTopics.first;
      steps.add(DailyPlanStep(
        title: 'Revise ${topWeak.topic}',
        durationMinutes: 5,
        actionType: 'revision',
        subject: topWeak.subject,
        topic: topWeak.topic,
      ));
    }

    final currentTopic = _profile.currentTopic;
    final currentSubject = _profile.currentSubject;

    if (currentTopic.isNotEmpty && currentSubject.isNotEmpty) {
      steps.add(DailyPlanStep(
        title: 'Study $currentTopic',
        durationMinutes: 15,
        actionType: 'lesson',
        subject: currentSubject,
        topic: currentTopic,
      ));

      steps.add(DailyPlanStep(
        title: 'Take 5-question quiz',
        durationMinutes: 5,
        actionType: 'quiz',
        subject: currentSubject,
        topic: currentTopic,
      ));
    } else {
      // Pick from first course if profile has no topic
      final firstCourse = CourseManager.builtInCourses.isNotEmpty
          ? CourseManager.builtInCourses.first
          : null;
      if (firstCourse != null && firstCourse.lessons.isNotEmpty) {
        final l = firstCourse.lessons.first;
        steps.add(DailyPlanStep(
          title: 'Start ${l.title}',
          durationMinutes: 15,
          actionType: 'lesson',
          subject: cleanSubject(firstCourse.title),
          topic: l.title,
        ));
      }
    }

    final totalMinutes = steps.fold(0, (acc, s) => acc + s.durationMinutes);
    _dailyPlan = DailyPlan(
      title: "Today's Plan",
      estimatedMinutes: totalMinutes > 0 ? totalMinutes : 20,
      steps: steps,
    );

    _box.put(_kDailyPlan, jsonEncode(_dailyPlan!.toJson()));
  }

  Future<void> recordSessionSummary(String summary) async {
    _ensureUserLoaded();
    _memory = MentorMemory(
      weakTopics: _memory.weakTopics,
      needsAttention: _memory.needsAttention,
      completedTopics: _memory.completedTopics,
      recentEvents: _memory.recentEvents,
      lastSessionSummary: summary,
      lastActive: DateTime.now(),
    );
    await _saveMemory();
    await recordEvent(
      type: LearningEventType.sessionCompleted,
      subject: _profile.currentSubject.isNotEmpty ? _profile.currentSubject : 'General',
      topic: _profile.currentTopic.isNotEmpty ? _profile.currentTopic : 'Session',
      metadata: {'summary': summary},
    );
  }

  /// Returns full mentor context pipeline for the current or specified user.
  MentorContext getMentorContext([String? userId]) =>
      ProgressService().getMentorContext(userId ?? _uid);
}
