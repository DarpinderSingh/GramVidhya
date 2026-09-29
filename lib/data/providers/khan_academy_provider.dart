import '../models/learning_resource.dart';
import 'content_provider.dart';

/// Provider for Khan Academy (Free world-class education for anyone, anywhere)
class KhanAcademyProvider implements EducationalProvider {
  @override
  String get providerId => 'khan_academy';

  @override
  String get providerName => 'Khan Academy';

  @override
  String get providerWebsite => 'https://www.khanacademy.org';

  @override
  String get defaultLicense => 'Non-profit Educational (Online)';

  static final List<LearningResource> _resources = [
    LearningResource(
      id: 'khan-algebra-1',
      title: 'Algebra 1 Foundations',
      description:
          'Structured mastery-based curriculum covering linear equations, functions, sequences, systems of equations, inequalities, and exponents.',
      provider: 'Khan Academy',
      subject: 'Mathematics',
      category: 'Algebra',
      level: 'School',
      language: 'English',
      officialUrl: 'https://www.khanacademy.org/math/algebra',
      type: ResourceType.course,
      downloadable: false,
      license: 'Khan Academy Terms of Service (Free Online Access)',
      instructorOrAuthor: 'Sal Khan & Faculty',
      institution: 'Khan Academy',
      lessons: [
        ChapterLesson(
          id: 'khan-alg-ch1',
          chapterNumber: 1,
          title: 'Solving Linear Equations & Inequalities',
          durationMinutes: 30,
          officialUrl: 'https://www.khanacademy.org/math/algebra/x2f8bb11595b61c86:solve-equations-inequalities',
          downloadable: false,
          content: '''Khan Academy — Algebra 1: Solving Linear Equations

1. What is an Equation?
An equation is a statement asserting that two expressions are equal in value: 3x + 5 = 20.
The principle of algebraic balance states: Whatever mathematical operation you perform on one side of an equation, you must perform identically on the other side.

2. Step-by-Step Solving Protocol:
1) Eliminate parentheses using the distributive property: a(b + c) = ab + ac.
2) Combine like terms on each individual side.
3) Use addition or subtraction properties of equality to collect variable terms on one side and constant terms on the other.
4) Use multiplication or division properties of equality to isolate the variable coefficient to 1.
5) Verify by substituting the candidate solution back into the original equation.

3. Inequalities & Negative Multipliers:
When multiplying or dividing both sides of an inequality by a negative number, the inequality sign MUST be reversed:
-2x < 6 ⟹ x > -3.''',
        ),
        ChapterLesson(
          id: 'khan-alg-ch2',
          chapterNumber: 2,
          title: 'Linear Equations & Slope-Intercept Form',
          durationMinutes: 35,
          officialUrl: 'https://www.khanacademy.org/math/algebra/x2f8bb11595b61c86:linear-equations-graphs',
          downloadable: false,
          content: '''Khan Academy — Slope-Intercept Form (y = mx + b)

1. The Meaning of Slope (m):
Slope represents the rate of change of the dependent variable with respect to the independent variable:
m = (y₂ - y₁) / (x₂ - x₁) = rise / run

2. The y-Intercept (b):
The point where the line crosses the vertical y-axis, corresponding to the coordinate (0, b).

3. Standard Linear Representations:
• Slope-intercept: y = mx + b
• Point-slope: y - y₁ = m(x - x₁)
• Standard form: Ax + By = C (where A, B, C are integers, A ≥ 0)''',
        ),
      ],
    ),
    LearningResource(
      id: 'khan-cs-principles',
      title: 'Computer Science Principles',
      description:
          'Exploration of digital information representations, internet architecture, cybersecurity protocols, algorithms, programming paradigms, and global computing impacts.',
      provider: 'Khan Academy',
      subject: 'Computer Science',
      category: 'Computing',
      level: 'High School / UG',
      language: 'English',
      officialUrl: 'https://www.khanacademy.org/computing/ap-computer-science-principles',
      type: ResourceType.course,
      downloadable: false,
      license: 'Khan Academy Terms of Service (Free Online Access)',
      instructorOrAuthor: 'Khan Academy Computing Team',
      institution: 'Khan Academy',
      lessons: [
        ChapterLesson(
          id: 'khan-csp-ch1',
          chapterNumber: 1,
          title: 'Digital Information: Bits & Binary',
          durationMinutes: 30,
          officialUrl: 'https://www.khanacademy.org/computing/ap-computer-science-principles/x2d2f703b37b450a3:digital-information',
          downloadable: false,
          content: '''Computer Science Principles — Digital Information Representation

1. The Bit as the Fundamental Unit:
A bit (binary digit) is the atomic unit of digital information, holding one of two states: 0 or 1. Physical computers implement bits via voltage thresholds in microscopic silicon MOSFET transistors.

2. Positional Number Systems:
• Base 2 (Binary): Weights correspond to powers of 2 (1, 2, 4, 8, 16, 32, 64, 128...). For example, binary 1011₂ = 1·8 + 0·4 + 1·2 + 1·1 = 11₁₀.
• Base 16 (Hexadecimal): Compact shorthand for binary bytes using symbols 0-9 and A-F. One hex digit maps to 4 binary bits (a nibble).

3. Analog to Digital Conversion:
Continuous real-world signals (audio waves, light intensity) are digitized via:
• Sampling: Measuring signal amplitude at discrete temporal intervals.
• Quantization: Rounding sampled values to the nearest discrete binary quantization level.''',
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
    return _resources.where((r) {
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        final matches = r.title.toLowerCase().contains(q) ||
            r.description.toLowerCase().contains(q) ||
            r.subject.toLowerCase().contains(q);
        if (!matches) return false;
      }
      if (subject != null && subject != 'All' && r.subject.toLowerCase() != subject.toLowerCase()) {
        return false;
      }
      if (level != null && level != 'All' && r.level.toLowerCase() != level.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<LearningResource?> fetchResource(String id) async {
    try {
      return _resources.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> isAvailable() async => true;
}
