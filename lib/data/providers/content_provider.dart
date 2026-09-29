import '../models/learning_resource.dart';

/// Abstract content provider interface for educational sources
/// (SWAYAM, NPTEL, MIT OpenCourseWare, OpenStax, Khan Academy, YouTube, etc.)
abstract class EducationalProvider {
  String get providerId;
  String get providerName;
  String get providerWebsite;
  String get defaultLicense;

  Future<List<LearningResource>> fetchResources({
    String? query,
    String? subject,
    String? level,
  });

  Future<LearningResource?> fetchResource(String id);

  Future<bool> isAvailable();
}
