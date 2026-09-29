import '../course_provider.dart';

/// Resource types supported across educational providers.
enum ResourceType {
  course,
  video,
  lecture,
  book,
  pdf,
  article,
  quiz,
}

ResourceType parseResourceType(String typeStr) {
  switch (typeStr.toLowerCase()) {
    case 'video':
      return ResourceType.video;
    case 'lecture':
      return ResourceType.lecture;
    case 'book':
      return ResourceType.book;
    case 'pdf':
      return ResourceType.pdf;
    case 'article':
      return ResourceType.article;
    case 'quiz':
      return ResourceType.quiz;
    case 'course':
    default:
      return ResourceType.course;
  }
}

/// A chapter or lesson within a learning resource.
class ChapterLesson {
  ChapterLesson({
    required this.id,
    required this.title,
    required this.content,
    this.chapterNumber,
    this.videoUrl,
    this.pdfUrl,
    this.durationMinutes,
    this.pageCount,
    this.sourceUrl,
    this.officialUrl,
    this.downloadable = false,
    this.localFilePath,
  });

  final String id;
  final String title;
  final String content;
  final int? chapterNumber;
  final String? videoUrl;
  final String? pdfUrl;
  final int? durationMinutes;
  final int? pageCount;
  final String? sourceUrl;
  final String? officialUrl;
  final bool downloadable;
  final String? localFilePath;

  ChapterLesson copyWith({
    String? id,
    String? title,
    String? content,
    int? chapterNumber,
    String? videoUrl,
    String? pdfUrl,
    int? durationMinutes,
    int? pageCount,
    String? sourceUrl,
    String? officialUrl,
    bool? downloadable,
    String? localFilePath,
  }) {
    return ChapterLesson(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      videoUrl: videoUrl ?? this.videoUrl,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      pageCount: pageCount ?? this.pageCount,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      officialUrl: officialUrl ?? this.officialUrl,
      downloadable: downloadable ?? this.downloadable,
      localFilePath: localFilePath ?? this.localFilePath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'chapterNumber': chapterNumber,
        'videoUrl': videoUrl,
        'pdfUrl': pdfUrl,
        'durationMinutes': durationMinutes,
        'pageCount': pageCount,
        'sourceUrl': sourceUrl,
        'officialUrl': officialUrl,
        'downloadable': downloadable,
        'localFilePath': localFilePath,
      };

  factory ChapterLesson.fromJson(Map<String, dynamic> j) => ChapterLesson(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        content: j['content'] as String? ?? '',
        chapterNumber: j['chapterNumber'] as int?,
        videoUrl: j['videoUrl'] as String?,
        pdfUrl: j['pdfUrl'] as String?,
        durationMinutes: j['durationMinutes'] as int?,
        pageCount: j['pageCount'] as int?,
        sourceUrl: j['sourceUrl'] as String?,
        officialUrl: j['officialUrl'] as String?,
        downloadable: j['downloadable'] as bool? ?? false,
        localFilePath: j['localFilePath'] as String?,
      );

  Lesson toLesson() => Lesson(
        id: id,
        title: title,
        content: content,
        videoUrl: videoUrl,
        durationMinutes: durationMinutes,
        sourceUrl: sourceUrl ?? officialUrl,
      );
}

/// A unified educational resource model across SWAYAM, NPTEL, MIT OCW, OpenStax, Khan Academy, etc.
class LearningResource {
  LearningResource({
    required this.id,
    required this.title,
    required this.description,
    required this.provider,
    required this.subject,
    required this.category,
    required this.level,
    this.language = 'English',
    this.thumbnailUrl = '',
    required this.officialUrl,
    required this.type,
    this.downloadable = false,
    this.downloadUrl,
    this.fileSizeBytes,
    this.license,
    this.instructorOrAuthor,
    this.institution,
    this.lessons = const [],
    DateTime? retrievedAt,
  }) : retrievedAt = retrievedAt ?? DateTime.now();

  final String id;
  final String title;
  final String description;
  final String provider; // e.g. "NPTEL", "SWAYAM", "OpenStax", "MIT OpenCourseWare", "Khan Academy", "DIKSHA"
  final String subject;
  final String category;
  final String level; // "School", "Undergraduate", "Postgraduate", "All Levels"
  final String language;
  final String thumbnailUrl;
  final String officialUrl;
  final ResourceType type;
  final bool downloadable;
  final String? downloadUrl;
  final int? fileSizeBytes;
  final String? license; // e.g. "CC-BY 4.0", "CC-BY-NC-SA 4.0"
  final String? instructorOrAuthor;
  final String? institution;
  final List<ChapterLesson> lessons;
  final DateTime retrievedAt;

  LearningResource copyWith({
    String? id,
    String? title,
    String? description,
    String? provider,
    String? subject,
    String? category,
    String? level,
    String? language,
    String? thumbnailUrl,
    String? officialUrl,
    ResourceType? type,
    bool? downloadable,
    String? downloadUrl,
    int? fileSizeBytes,
    String? license,
    String? instructorOrAuthor,
    String? institution,
    List<ChapterLesson>? lessons,
    DateTime? retrievedAt,
  }) {
    return LearningResource(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      provider: provider ?? this.provider,
      subject: subject ?? this.subject,
      category: category ?? this.category,
      level: level ?? this.level,
      language: language ?? this.language,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      officialUrl: officialUrl ?? this.officialUrl,
      type: type ?? this.type,
      downloadable: downloadable ?? this.downloadable,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      license: license ?? this.license,
      instructorOrAuthor: instructorOrAuthor ?? this.instructorOrAuthor,
      institution: institution ?? this.institution,
      lessons: lessons ?? this.lessons,
      retrievedAt: retrievedAt ?? this.retrievedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'provider': provider,
        'subject': subject,
        'category': category,
        'level': level,
        'language': language,
        'thumbnailUrl': thumbnailUrl,
        'officialUrl': officialUrl,
        'type': type.name,
        'downloadable': downloadable,
        'downloadUrl': downloadUrl,
        'fileSizeBytes': fileSizeBytes,
        'license': license,
        'instructorOrAuthor': instructorOrAuthor,
        'institution': institution,
        'lessons': lessons.map((l) => l.toJson()).toList(),
        'retrievedAt': retrievedAt.toIso8601String(),
      };

  factory LearningResource.fromJson(Map<String, dynamic> j) => LearningResource(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        provider: j['provider'] as String? ?? 'General',
        subject: j['subject'] as String? ?? 'General',
        category: j['category'] as String? ?? 'Educational',
        level: j['level'] as String? ?? 'All Levels',
        language: j['language'] as String? ?? 'English',
        thumbnailUrl: j['thumbnailUrl'] as String? ?? '',
        officialUrl: j['officialUrl'] as String? ?? '',
        type: parseResourceType(j['type'] as String? ?? 'course'),
        downloadable: j['downloadable'] as bool? ?? false,
        downloadUrl: j['downloadUrl'] as String?,
        fileSizeBytes: j['fileSizeBytes'] as int?,
        license: j['license'] as String?,
        instructorOrAuthor: j['instructorOrAuthor'] as String?,
        institution: j['institution'] as String?,
        lessons: (j['lessons'] as List?)
                ?.map((e) => ChapterLesson.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
        retrievedAt: j['retrievedAt'] != null
            ? DateTime.tryParse(j['retrievedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  /// Bridge to legacy Course model
  Course toCourse() => Course(
        id: id,
        title: title,
        description: description,
        icon: _providerIcon(provider, subject),
        provider: provider,
        thumbnailUrl: thumbnailUrl.isNotEmpty ? thumbnailUrl : null,
        sourceId: id,
        leafCount: lessons.length,
        lessons: lessons.map((l) => l.toLesson()).toList(),
      );

  static String _providerIcon(String provider, String subject) {
    final s = subject.toLowerCase();
    if (s.contains('math') || s.contains('calculus') || s.contains('algebra')) return 'calculate';
    if (s.contains('physics') || s.contains('science') || s.contains('biology')) return 'science';
    if (s.contains('computer') || s.contains('machine learning') || s.contains('programming')) return 'computer';
    if (s.contains('economics') || s.contains('finance') || s.contains('accounting')) return 'account_balance';
    if (s.contains('english') || s.contains('language')) return 'translate';
    return 'menu_book';
  }
}

/// Model for tracking dynamic recent chapters accessed by the user.
class RecentChapter {
  RecentChapter({
    required this.courseId,
    required this.courseName,
    required this.chapterId,
    required this.chapterName,
    required this.lastOpened,
    required this.progress,
    required this.completed,
    required this.provider,
    this.thumbnailUrl,
    this.lessonIndex = 0,
    this.totalLessons = 1,
  });

  final String courseId;
  final String courseName;
  final String chapterId;
  final String chapterName;
  final DateTime lastOpened;
  final double progress; // 0.0 to 1.0
  final bool completed;
  final String provider;
  final String? thumbnailUrl;
  final int lessonIndex;
  final int totalLessons;

  Map<String, dynamic> toJson() => {
        'courseId': courseId,
        'courseName': courseName,
        'chapterId': chapterId,
        'chapterName': chapterName,
        'lastOpened': lastOpened.toIso8601String(),
        'progress': progress,
        'completed': completed,
        'provider': provider,
        'thumbnailUrl': thumbnailUrl,
        'lessonIndex': lessonIndex,
        'totalLessons': totalLessons,
      };

  factory RecentChapter.fromJson(Map<String, dynamic> j) => RecentChapter(
        courseId: j['courseId'] as String? ?? '',
        courseName: j['courseName'] as String? ?? '',
        chapterId: j['chapterId'] as String? ?? '',
        chapterName: j['chapterName'] as String? ?? '',
        lastOpened: j['lastOpened'] != null
            ? DateTime.tryParse(j['lastOpened'] as String) ?? DateTime.now()
            : DateTime.now(),
        progress: (j['progress'] as num?)?.toDouble() ?? 0.0,
        completed: j['completed'] as bool? ?? false,
        provider: j['provider'] as String? ?? 'General',
        thumbnailUrl: j['thumbnailUrl'] as String?,
        lessonIndex: j['lessonIndex'] as int? ?? 0,
        totalLessons: j['totalLessons'] as int? ?? 1,
      );
}
