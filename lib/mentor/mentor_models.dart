/// Represents a student profile with educational context.
class StudentProfile {
  StudentProfile({
    required this.name,
    this.classGrade = 'UG',
    this.selectedLanguage = 'en',
    this.subjects = const ['Computer Science', 'Mathematics', 'Science'],
    this.learningGoals = const ['Academic Excellence', 'Skill Development'],
    this.preferredStudyDuration = 25,
    this.currentTopic = '',
    this.currentSubject = '',
  });

  final String name;
  final String classGrade;
  final String selectedLanguage;
  final List<String> subjects;
  final List<String> learningGoals;
  final int preferredStudyDuration; // in minutes
  final String currentTopic;
  final String currentSubject;

  StudentProfile copyWith({
    String? name,
    String? classGrade,
    String? selectedLanguage,
    List<String>? subjects,
    List<String>? learningGoals,
    int? preferredStudyDuration,
    String? currentTopic,
    String? currentSubject,
  }) {
    return StudentProfile(
      name: name ?? this.name,
      classGrade: classGrade ?? this.classGrade,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      subjects: subjects ?? this.subjects,
      learningGoals: learningGoals ?? this.learningGoals,
      preferredStudyDuration: preferredStudyDuration ?? this.preferredStudyDuration,
      currentTopic: currentTopic ?? this.currentTopic,
      currentSubject: currentSubject ?? this.currentSubject,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'classGrade': classGrade,
        'selectedLanguage': selectedLanguage,
        'subjects': subjects,
        'learningGoals': learningGoals,
        'preferredStudyDuration': preferredStudyDuration,
        'currentTopic': currentTopic,
        'currentSubject': currentSubject,
      };

  factory StudentProfile.fromJson(Map<String, dynamic> j) => StudentProfile(
        name: j['name'] as String? ?? 'Student',
        classGrade: j['classGrade'] as String? ?? 'UG',
        selectedLanguage: j['selectedLanguage'] as String? ?? 'en',
        subjects: (j['subjects'] as List?)?.map((e) => e.toString()).toList() ??
            const ['Computer Science', 'Mathematics', 'Science'],
        learningGoals: (j['learningGoals'] as List?)?.map((e) => e.toString()).toList() ??
            const ['Academic Excellence'],
        preferredStudyDuration: j['preferredStudyDuration'] as int? ?? 25,
        currentTopic: j['currentTopic'] as String? ?? '',
        currentSubject: j['currentSubject'] as String? ?? '',
      );
}

/// Types of learning events recorded during student interaction.
enum LearningEventType {
  lessonCompleted,
  lessonStarted,
  quizResult,
  topicAsked,
  sessionCompleted,
  practiceAttempt,
}

/// An immutable event capturing a student learning milestone.
class LearningEvent {
  LearningEvent({
    required this.id,
    required this.type,
    required this.subject,
    required this.topic,
    this.score,
    this.metadata,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String id;
  final LearningEventType type;
  final String subject;
  final String topic;
  final double? score; // Percentage (0.0 to 100.0)
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'subject': subject,
        'topic': topic,
        'score': score,
        'metadata': metadata,
        'timestamp': timestamp.toIso8601String(),
      };

  factory LearningEvent.fromJson(Map<String, dynamic> j) => LearningEvent(
        id: j['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        type: LearningEventType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => LearningEventType.lessonCompleted,
        ),
        subject: j['subject'] as String? ?? 'General',
        topic: j['topic'] as String? ?? '',
        score: (j['score'] as num?)?.toDouble(),
        metadata: j['metadata'] != null ? Map<String, dynamic>.from(j['metadata'] as Map) : null,
        timestamp: j['timestamp'] != null
            ? DateTime.tryParse(j['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

/// A topic identified as needing attention based on performance or behavioral data.
class WeakTopic {
  WeakTopic({
    required this.subject,
    required this.topic,
    required this.reason,
    required this.recommendedAction,
    this.actionType = 'revision', // 'revision', 'practice', 'continue'
    this.courseId,
    this.lessonId,
    this.lessonIndex,
    this.errorCount = 1,
    this.averageScore,
    DateTime? detectedAt,
  }) : detectedAt = detectedAt ?? DateTime.now();

  final String subject;
  final String topic;
  final String reason;
  final String recommendedAction;
  final String actionType;
  final String? courseId;
  final String? lessonId;
  final int? lessonIndex;
  final int errorCount;
  final double? averageScore;
  final DateTime detectedAt;

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'topic': topic,
        'reason': reason,
        'recommendedAction': recommendedAction,
        'actionType': actionType,
        'courseId': courseId,
        'lessonId': lessonId,
        'lessonIndex': lessonIndex,
        'errorCount': errorCount,
        'averageScore': averageScore,
        'detectedAt': detectedAt.toIso8601String(),
      };

  factory WeakTopic.fromJson(Map<String, dynamic> j) => WeakTopic(
        subject: j['subject'] as String? ?? 'General',
        topic: j['topic'] as String? ?? '',
        reason: j['reason'] as String? ?? '',
        recommendedAction: j['recommendedAction'] as String? ?? '',
        actionType: j['actionType'] as String? ?? 'revision',
        courseId: j['courseId'] as String?,
        lessonId: j['lessonId'] as String?,
        lessonIndex: j['lessonIndex'] as int?,
        errorCount: j['errorCount'] as int? ?? 1,
        averageScore: (j['averageScore'] as num?)?.toDouble(),
        detectedAt: j['detectedAt'] != null
            ? DateTime.tryParse(j['detectedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

/// Dynamic Needs Attention Item with explicit action type and data-driven reason.
class NeedsAttentionItem {
  final String topic;
  final String subject;
  final String reason;
  final String actionType; // 'revision', 'practice', 'continue'
  final String? courseId;
  final String? lessonId;
  final int? lessonIndex;
  final double? score;
  final int priority; // 1 = highest
  final DateTime detectedAt;

  NeedsAttentionItem({
    required this.topic,
    required this.subject,
    required this.reason,
    required this.actionType,
    this.courseId,
    this.lessonId,
    this.lessonIndex,
    this.score,
    this.priority = 1,
    DateTime? detectedAt,
  }) : detectedAt = detectedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'subject': subject,
        'reason': reason,
        'actionType': actionType,
        'courseId': courseId,
        'lessonId': lessonId,
        'lessonIndex': lessonIndex,
        'score': score,
        'priority': priority,
        'detectedAt': detectedAt.toIso8601String(),
      };

  factory NeedsAttentionItem.fromJson(Map<String, dynamic> j) => NeedsAttentionItem(
        topic: j['topic'] as String? ?? '',
        subject: j['subject'] as String? ?? 'General',
        reason: j['reason'] as String? ?? '',
        actionType: j['actionType'] as String? ?? 'revision',
        courseId: j['courseId'] as String?,
        lessonId: j['lessonId'] as String?,
        lessonIndex: j['lessonIndex'] as int?,
        score: (j['score'] as num?)?.toDouble(),
        priority: j['priority'] as int? ?? 1,
        detectedAt: j['detectedAt'] != null
            ? DateTime.tryParse(j['detectedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

/// A single step in a daily plan.
class DailyPlanStep {
  DailyPlanStep({
    required this.title,
    required this.durationMinutes,
    required this.actionType, // 'revision', 'lesson', 'quiz'
    required this.subject,
    required this.topic,
  });

  final String title;
  final int durationMinutes;
  final String actionType;
  final String subject;
  final String topic;

  Map<String, dynamic> toJson() => {
        'title': title,
        'durationMinutes': durationMinutes,
        'actionType': actionType,
        'subject': subject,
        'topic': topic,
      };

  factory DailyPlanStep.fromJson(Map<String, dynamic> j) => DailyPlanStep(
        title: j['title'] as String? ?? '',
        durationMinutes: j['durationMinutes'] as int? ?? 10,
        actionType: j['actionType'] as String? ?? 'lesson',
        subject: j['subject'] as String? ?? '',
        topic: j['topic'] as String? ?? '',
      );
}

/// Daily plan recommended by the mentor.
class DailyPlan {
  DailyPlan({
    required this.title,
    required this.estimatedMinutes,
    required this.steps,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  final String title;
  final int estimatedMinutes;
  final List<DailyPlanStep> steps;
  final DateTime generatedAt;

  Map<String, dynamic> toJson() => {
        'title': title,
        'estimatedMinutes': estimatedMinutes,
        'steps': steps.map((s) => s.toJson()).toList(),
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory DailyPlan.fromJson(Map<String, dynamic> j) => DailyPlan(
        title: j['title'] as String? ?? "Today's Learning Plan",
        estimatedMinutes: j['estimatedMinutes'] as int? ?? 25,
        steps: (j['steps'] as List?)
                ?.map((s) => DailyPlanStep.fromJson(Map<String, dynamic>.from(s as Map)))
                .toList() ??
            [],
        generatedAt: j['generatedAt'] != null
            ? DateTime.tryParse(j['generatedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

/// Structured mentor memory persisted across sessions.
class MentorMemory {
  MentorMemory({
    this.weakTopics = const [],
    this.needsAttention = const [],
    this.completedTopics = const [],
    this.recentEvents = const [],
    this.lastSessionSummary,
    DateTime? lastActive,
  }) : lastActive = lastActive ?? DateTime.now();

  final List<WeakTopic> weakTopics;
  final List<NeedsAttentionItem> needsAttention;
  final List<String> completedTopics;
  final List<LearningEvent> recentEvents;
  final String? lastSessionSummary;
  final DateTime lastActive;

  Map<String, dynamic> toJson() => {
        'weakTopics': weakTopics.map((w) => w.toJson()).toList(),
        'needsAttention': needsAttention.map((n) => n.toJson()).toList(),
        'completedTopics': completedTopics,
        'recentEvents': recentEvents.map((e) => e.toJson()).toList(),
        'lastSessionSummary': lastSessionSummary,
        'lastActive': lastActive.toIso8601String(),
      };

  factory MentorMemory.fromJson(Map<String, dynamic> j) => MentorMemory(
        weakTopics: (j['weakTopics'] as List?)
                ?.map((w) => WeakTopic.fromJson(Map<String, dynamic>.from(w as Map)))
                .toList() ??
            [],
        needsAttention: (j['needsAttention'] as List?)
                ?.map((n) => NeedsAttentionItem.fromJson(Map<String, dynamic>.from(n as Map)))
                .toList() ??
            [],
        completedTopics:
            (j['completedTopics'] as List?)?.map((c) => c.toString()).toList() ?? [],
        recentEvents: (j['recentEvents'] as List?)
                ?.map((e) => LearningEvent.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
        lastSessionSummary: j['lastSessionSummary'] as String?,
        lastActive: j['lastActive'] != null
            ? DateTime.tryParse(j['lastActive'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

/// Centralized, user-scoped mentor context pipeline model.
class MentorContext {
  final String userId;
  final List<String> recentCourses;
  final List<Map<String, dynamic>> recentLessons;
  final List<Map<String, dynamic>> incompleteLessons;
  final List<String> completedLessons;
  final Map<String, double> courseProgress;
  final Map<String, double> subjectProgress;
  final Map<String, dynamic> quizPerformance;
  final Map<String, int> repeatedQuestions;
  final List<NeedsAttentionItem> strugglingTopics;
  final List<String> recentlyStudiedTopics;
  final List<Map<String, dynamic>> recommendedNextLessons;
  final double overallProgress;
  final int coursesStarted;
  final int coursesCompleted;
  final int lessonsCompleted;
  final int lessonsInProgress;
  final int lessonsRemaining;
  final int studySessions;
  final int streakDays;

  MentorContext({
    required this.userId,
    this.recentCourses = const [],
    this.recentLessons = const [],
    this.incompleteLessons = const [],
    this.completedLessons = const [],
    this.courseProgress = const {},
    this.subjectProgress = const {},
    this.quizPerformance = const {},
    this.repeatedQuestions = const {},
    this.strugglingTopics = const [],
    this.recentlyStudiedTopics = const [],
    this.recommendedNextLessons = const [],
    this.overallProgress = 0.0,
    this.coursesStarted = 0,
    this.coursesCompleted = 0,
    this.lessonsCompleted = 0,
    this.lessonsInProgress = 0,
    this.lessonsRemaining = 0,
    this.studySessions = 0,
    this.streakDays = 0,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'recentCourses': recentCourses,
        'recentLessons': recentLessons,
        'incompleteLessons': incompleteLessons,
        'completedLessons': completedLessons,
        'courseProgress': courseProgress,
        'subjectProgress': subjectProgress,
        'quizPerformance': quizPerformance,
        'repeatedQuestions': repeatedQuestions,
        'strugglingTopics': strugglingTopics.map((s) => s.toJson()).toList(),
        'recentlyStudiedTopics': recentlyStudiedTopics,
        'recommendedNextLessons': recommendedNextLessons,
        'overallProgress': overallProgress,
        'coursesStarted': coursesStarted,
        'coursesCompleted': coursesCompleted,
        'lessonsCompleted': lessonsCompleted,
        'lessonsInProgress': lessonsInProgress,
        'lessonsRemaining': lessonsRemaining,
        'studySessions': studySessions,
        'streakDays': streakDays,
      };
}

/// Learning activity item for chronological timeline rendering.
class ActivityTimelineItem {
  final String title;
  final String subtitle;
  final String actionType; // 'completed', 'started', 'quiz', 'revisit'
  final DateTime timestamp;
  final String? courseTitle;
  final String? courseId;
  final String? lessonId;

  ActivityTimelineItem({
    required this.title,
    required this.subtitle,
    required this.actionType,
    required this.timestamp,
    this.courseTitle,
    this.courseId,
    this.lessonId,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'actionType': actionType,
        'timestamp': timestamp.toIso8601String(),
        'courseTitle': courseTitle,
        'courseId': courseId,
        'lessonId': lessonId,
      };

  factory ActivityTimelineItem.fromJson(Map<String, dynamic> j) => ActivityTimelineItem(
        title: j['title'] as String? ?? '',
        subtitle: j['subtitle'] as String? ?? '',
        actionType: j['actionType'] as String? ?? 'started',
        timestamp: j['timestamp'] != null
            ? DateTime.tryParse(j['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
        courseTitle: j['courseTitle'] as String?,
        courseId: j['courseId'] as String?,
        lessonId: j['lessonId'] as String?,
      );
}

/// Consolidated student learning statistics.
class LearningStats {
  final double overallProgress;
  final int coursesStarted;
  final int coursesCompleted;
  final int lessonsCompleted;
  final int lessonsInProgress;
  final int lessonsRemaining;
  final int studySessions;
  final int streakDays;

  const LearningStats({
    this.overallProgress = 0.0,
    this.coursesStarted = 0,
    this.coursesCompleted = 0,
    this.lessonsCompleted = 0,
    this.lessonsInProgress = 0,
    this.lessonsRemaining = 0,
    this.studySessions = 0,
    this.streakDays = 0,
  });
}
