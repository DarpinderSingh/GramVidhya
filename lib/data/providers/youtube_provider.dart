import '../models/learning_resource.dart';
import 'content_provider.dart';

/// Provider for official YouTube Educational Channels (NPTEL-NOC, MIT OCW, Khan Academy)
/// Strict compliance with rules #9 and #17: metadata and official video links only.
/// Absolutely NO video downloading or stream ripping.
class YoutubeEduProvider implements EducationalProvider {
  @override
  String get providerId => 'youtube_edu';

  @override
  String get providerName => 'YouTube (Official Channels)';

  @override
  String get providerWebsite => 'https://www.youtube.com';

  @override
  String get defaultLicense => 'Standard YouTube License (Online Streaming Only)';

  static final List<LearningResource> _channels = [
    LearningResource(
      id: 'yt-nptel-noc',
      title: 'NPTEL Official Video Lectures',
      description:
          'Official video lecture archives from Indian Institutes of Technology (IITs) and Indian Institute of Science (IISc) across electrical, mechanical, civil, and computer engineering.',
      provider: 'NPTEL (YouTube)',
      subject: 'Engineering',
      category: 'Video Lectures',
      level: 'Undergraduate',
      language: 'English',
      officialUrl: 'https://www.youtube.com/@nptel-poc',
      type: ResourceType.video,
      downloadable: false,
      license: 'YouTube Standard License (Online Only)',
      instructorOrAuthor: 'IIT Faculty',
      institution: 'NPTEL / IITs',
      lessons: [
        ChapterLesson(
          id: 'yt-nptel-v1',
          chapterNumber: 1,
          title: 'IIT Madras: Introduction to Machine Learning Lecture 1',
          durationMinutes: 42,
          officialUrl: 'https://www.youtube.com/@nptel-poc',
          videoUrl: 'https://www.youtube.com/watch?v=1v7pxw7tW2w',
          downloadable: false,
          content: '''NPTEL Video Lecture: Introduction to Machine Learning (IIT Madras)

Official Channel: NPTEL-NOC
Speaker: Prof. Balaraman Ravindran (Dept. of Computer Science and Engineering, IIT Madras)

Key Discussion Points:
1. Historical perspective of pattern recognition and cybernetics.
2. Formulating problem spaces in terms of state vectors and loss gradients.
3. Differences between statistical inference and machine learning optimization.

Note: In accordance with YouTube terms and copyright policies, video content must be streamed through the official YouTube platform.''',
        ),
      ],
    ),
    LearningResource(
      id: 'yt-mit-ocw-channel',
      title: 'MIT OpenCourseWare Lectures',
      description:
          'Classroom recordings of renowned MIT professors delivering fundamental undergraduate lectures in physics, mathematics, computer science, and chemistry.',
      provider: 'MIT OpenCourseWare (YouTube)',
      subject: 'Multi-Disciplinary',
      category: 'Video Lectures',
      level: 'University',
      language: 'English',
      officialUrl: 'https://www.youtube.com/@mitocw',
      type: ResourceType.video,
      downloadable: false,
      license: 'CC-BY-NC-SA 4.0 via YouTube',
      instructorOrAuthor: 'MIT Faculty',
      institution: 'MIT',
      lessons: [
        ChapterLesson(
          id: 'yt-mit-v1',
          chapterNumber: 1,
          title: 'Prof. Gilbert Strang: The Geometry of Linear Equations',
          durationMinutes: 39,
          officialUrl: 'https://www.youtube.com/@mitocw',
          videoUrl: 'https://www.youtube.com/watch?v=7UJ4CFRGd-U',
          downloadable: false,
          content: '''MIT OpenCourseWare Video Lecture: Linear Algebra 18.06

Speaker: Prof. Gilbert Strang (Department of Mathematics, MIT)

Overview:
• Visualizing 2x2 and 3x3 linear systems using row and column geometries.
• The fundamental question: When does Ax = b have solutions for every b?
• Singular matrices and parallel hyperplanes.

Stream officially on the MIT OpenCourseWare YouTube channel.''',
        ),
      ],
    ),
  ];

  @override
  Future<List<LearningResource>> fetchResources({
    String? query,
    String? subject,
    String? level,
  }) async {
    return _channels.where((c) {
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        final matches = c.title.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q) ||
            c.subject.toLowerCase().contains(q);
        if (!matches) return false;
      }
      if (subject != null && subject != 'All' && c.subject.toLowerCase() != subject.toLowerCase()) {
        return false;
      }
      if (level != null && level != 'All' && c.level.toLowerCase() != level.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<LearningResource?> fetchResource(String id) async {
    try {
      return _channels.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> isAvailable() async => true;
}
