import '../models/learning_resource.dart';
import 'content_provider.dart';

/// Provider for SWAYAM (Ministry of Education, Government of India)
/// Indian national educational portal for higher secondary, undergraduate, and skill courses.
class SwayamProvider implements EducationalProvider {
  @override
  String get providerId => 'swayam';

  @override
  String get providerName => 'SWAYAM';

  @override
  String get providerWebsite => 'https://swayam.gov.in';

  @override
  String get defaultLicense => 'Government of India MOOC / Free Educational';

  static final List<LearningResource> _courses = [
    LearningResource(
      id: 'swayam-ai-for-all',
      title: 'Artificial Intelligence for All',
      description:
          'Introductory program on understanding artificial intelligence, computer vision, natural language processing, machine learning concepts, ethical considerations, and AI readiness for rural and tribal empowerment.',
      provider: 'SWAYAM',
      subject: 'Computer Science',
      category: 'Emerging Technologies',
      level: 'All Levels',
      language: 'English',
      officialUrl: 'https://swayam.gov.in/explorer',
      type: ResourceType.course,
      downloadable: true,
      downloadUrl: 'https://swayam.gov.in/assets/syllabus/ai_for_all.pdf',
      fileSizeBytes: 2900000,
      license: 'MOOC Free Access',
      instructorOrAuthor: 'National AI Portal Initiative',
      institution: 'Ministry of Education & MeitY',
      lessons: [
        ChapterLesson(
          id: 'swayam-ai-ch1',
          chapterNumber: 1,
          title: 'Understanding AI Concepts & History',
          durationMinutes: 35,
          officialUrl: 'https://swayam.gov.in/explorer',
          downloadable: true,
          content: '''Artificial Intelligence for All — Module 1 (SWAYAM)

1. The Evolution of Artificial Intelligence:
From the Dartmouth Summer Workshop in 1956 where John McCarthy coined the term "Artificial Intelligence" to rule-based expert systems and modern deep neural networks, AI has evolved through periods of rapid progress and AI winters.

2. Types of Artificial Intelligence:
• Narrow AI (Weak AI): Systems specialized in performing a single specific task with superhuman proficiency (e.g. speech recognition, chess engines, medical image segmentation). All contemporary AI is Narrow AI.
• General AI (Strong AI): Theoretical systems possessing generalized human cognitive abilities to reason, adapt, and transfer knowledge across novel problem domains.
• Superintelligence: Hypothetical intelligence surpassing the best human minds in every discipline.

3. Key Sub-fields of AI:
• Machine Learning: Statistical systems that learn representations directly from data.
• Computer Vision: Algorithms that extract semantic understanding from visual scenes and raster images.
• Natural Language Processing (NLP): Techniques enabling computational parsing, translation, and generation of human text and speech.''',
        ),
        ChapterLesson(
          id: 'swayam-ai-ch2',
          chapterNumber: 2,
          title: 'Ethical AI, Bias & Digital Citizenship',
          durationMinutes: 40,
          officialUrl: 'https://swayam.gov.in/explorer',
          downloadable: true,
          content: '''Artificial Intelligence for All — Module 2: Ethics and Society

1. Algorithmic Bias and Fairness:
AI systems mirror the biases embedded in historical training datasets. If historical loan approvals or hiring decisions contained systemic bias, uncalibrated models will institutionalize and amplify those disparities. Responsible AI requires rigorous algorithmic audits, representative sampling, and fairness metrics (demographic parity, equal opportunity).

2. Privacy & Data Governance:
Data is the fundamental feedstock of machine learning. Frameworks such as India's Digital Personal Data Protection Act (DPDPA) mandate user consent, purpose limitation, and data minimization.

3. AI for Social Good:
Applications in precision agriculture (crop disease diagnostics via smartphone cameras), telemedicine for rural healthcare, and localized multilingual education directly transform underserved communities.''',
        ),
      ],
    ),
    LearningResource(
      id: 'swayam-env-science',
      title: 'Environmental Science & Sustainable Development',
      description:
          'Comprehensive course on ecology, water resource management, biodiversity conservation, renewable energy transitions, and environmental protection legislation in India.',
      provider: 'SWAYAM',
      subject: 'Environmental Science',
      category: 'Science',
      level: 'Undergraduate',
      language: 'English',
      officialUrl: 'https://swayam.gov.in/explorer',
      type: ResourceType.course,
      downloadable: true,
      downloadUrl: 'https://swayam.gov.in/assets/syllabus/env_science.pdf',
      fileSizeBytes: 3100000,
      license: 'MOOC Free Access',
      instructorOrAuthor: 'UGC National Curriculum Committee',
      institution: 'University Grants Commission (UGC)',
      lessons: [
        ChapterLesson(
          id: 'swayam-env-ch1',
          chapterNumber: 1,
          title: 'Ecosystem Dynamics & Biodiversity Conservation',
          durationMinutes: 40,
          officialUrl: 'https://swayam.gov.in/explorer',
          downloadable: true,
          content: '''Environmental Science — Module 1: Ecosystem Dynamics (SWAYAM)

1. Structure and Function of Ecosystems:
An ecosystem comprises biotic communities (producers, consumers, decomposers) interacting with abiotic parameters (solar radiation, precipitation, soil chemistry). Energy flows unidirectionally governed by thermodynamics (10% trophic transfer efficiency), whereas nutrients cycle biogeochemically (carbon, nitrogen, phosphorus).

2. Biodiversity Hotspots:
Regions characterized by exceptional levels of plant endemism experiencing significant habitat loss. India houses four recognized hotspots:
1) The Western Ghats
2) The Eastern Himalayas
3) Indo-Burma region
4) Sundaland (including Nicobar Islands)

3. In-situ and Ex-situ Conservation:
• In-situ: Conservation of species within their natural ecosystems (National Parks, Wildlife Sanctuaries, Biosphere Reserves).
• Ex-situ: Conservation outside natural habitats (Botanical Gardens, Zoological Parks, Seed Banks, Cryogenic Gene Banks).''',
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
    return _courses.where((c) {
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        final matches = c.title.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q) ||
            c.subject.toLowerCase().contains(q) ||
            c.instructorOrAuthor?.toLowerCase().contains(q) == true;
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
      return _courses.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> isAvailable() async => true;
}
