import '../models/learning_resource.dart';
import 'content_provider.dart';

/// Provider for MIT OpenCourseWare (Massachusetts Institute of Technology)
/// Legitimate university courses and materials published under CC-BY-NC-SA 4.0.
class MitOcwProvider implements EducationalProvider {
  @override
  String get providerId => 'mit_ocw';

  @override
  String get providerName => 'MIT OpenCourseWare';

  @override
  String get providerWebsite => 'https://ocw.mit.edu';

  @override
  String get defaultLicense => 'CC-BY-NC-SA 4.0';

  static final List<LearningResource> _courses = [
    LearningResource(
      id: 'mit-6-0001-python',
      title: '6.0001: Introduction to Computer Science in Python',
      description:
          'MIT introductory computer science course teaching computational thinking, algorithmic problem solving, Python programming, functions, recursion, and object-oriented paradigms.',
      provider: 'MIT OpenCourseWare',
      subject: 'Computer Science',
      category: 'Programming',
      level: 'Undergraduate',
      language: 'English',
      officialUrl:
          'https://ocw.mit.edu/courses/6-0001-introduction-to-computer-science-and-programming-in-python-fall-2016/',
      type: ResourceType.course,
      downloadable: true,
      downloadUrl:
          'https://ocw.mit.edu/courses/6-0001-introduction-to-computer-science-and-programming-in-python-fall-2016/resources/mit6_0001f16_lec1/',
      fileSizeBytes: 5600000,
      license: 'CC-BY-NC-SA 4.0',
      instructorOrAuthor: 'Dr. Ana Bell, Prof. Eric Grimson, Prof. John Guttag',
      institution: 'MIT',
      lessons: [
        ChapterLesson(
          id: 'mit-cs-lec1',
          chapterNumber: 1,
          title: 'What is Computation? Python Basics & Branching',
          durationMinutes: 50,
          officialUrl:
              'https://ocw.mit.edu/courses/6-0001-introduction-to-computer-science-and-programming-in-python-fall-2016/resources/lecture-1-what-is-computation/',
          downloadable: true,
          content: '''MIT 6.0001 — Lecture 1: What is Computation? (MIT OpenCourseWare)

1. Declarative vs. Imperative Knowledge:
• Declarative knowledge statements assert truth ("Square root of x is y such that y*y = x").
• Imperative knowledge prescribes a step-by-step mechanical recipe to compute the result (e.g. Heron of Alexandria's algorithm for square roots). Computer science centers on imperative algorithmic execution.

2. Fixed-Program vs. Stored-Program Computers:
Alan Turing proved that a Universal Turing Machine can simulate any computational apparatus by interpreting stored instructions. Modern von Neumann computers store both instructions and data in unified memory.

3. Python Architecture:
• Objects: Every value in Python is an object associated with a specific type (scalar: int, float, bool, NoneType; compound: str, list, dict).
• Variables & Bindings: An assignment statement (`x = 5`) binds the variable identifier to an object in memory via pointers rather than storing raw bits in place.
• Control Flow: Execution branches using boolean conditionals (`if`, `elif`, `else`) evaluated sequentially with strict indentation scoping.''',
        ),
        ChapterLesson(
          id: 'mit-cs-lec2',
          chapterNumber: 2,
          title: 'Iteration, Bisection Search & Approximations',
          durationMinutes: 48,
          officialUrl:
              'https://ocw.mit.edu/courses/6-0001-introduction-to-computer-science-and-programming-in-python-fall-2016/resources/lecture-2-branching-and-iteration/',
          downloadable: true,
          content: '''MIT 6.0001 — Lecture 2: Branching, Iteration, and Numerical Algorithms

1. While Loops & For Loops:
Loops execute a block of code repetitively. A `while` loop continues until a predicate evaluates to False. A `for` loop iterates across an iterable sequence (such as `range()`).

2. Guess-and-Check (Exhaustive Enumeration):
A fundamental algorithmic pattern: systematically step through all possible candidate solutions within a bounded search space until a solution satisfying target tolerance ε is identified.

3. Bisection Search (Binary Search over Continua):
When searching for the root of a monotonically increasing function in [low, high]:
1) Compute midpoint = (low + high) / 2
2) If |midpoint² - x| < ε, terminate with success
3) If midpoint² < x, set low = midpoint
4) Else set high = midpoint
Radically reduces computational steps: converges in O(log(range / ε)) evaluations compared to linear O(range / step).''',
        ),
        ChapterLesson(
          id: 'mit-cs-lec3',
          chapterNumber: 3,
          title: 'Functions, Scoping & Abstraction',
          durationMinutes: 52,
          officialUrl:
              'https://ocw.mit.edu/courses/6-0001-introduction-to-computer-science-and-programming-in-python-fall-2016/resources/lecture-4-functions/',
          downloadable: true,
          content: '''MIT 6.0001 — Lecture 3: Functions and Scoping

1. Decomposition and Abstraction:
• Decomposition divides complex computational tasks into self-contained modules.
• Abstraction suppresses low-level implementation details, treating functions as black-box contracts defined by docstring specifications (inputs, side effects, return values).

2. Formal Parameters vs. Actual Arguments:
When a function is called, formal parameters are bound to actual arguments inside a dedicated local frame in the execution call stack.

3. Lexical Scoping:
Variable lookups occur according to the LEGB rule (Local, Enclosing, Global, Built-in). Functions have access to global variables for reading, but creating a binding inside a function creates a local variable unless explicitly declared `global`.''',
        ),
      ],
    ),
    LearningResource(
      id: 'mit-18-06-linear-algebra',
      title: '18.06: Linear Algebra',
      description:
          'World-renowned MIT mathematics curriculum taught by Prof. Gilbert Strang. Covers vector spaces, matrix factorizations (LU, QR, SVD), projections, determinants, eigenvalues, and positive definite matrices.',
      provider: 'MIT OpenCourseWare',
      subject: 'Mathematics',
      category: 'Linear Algebra',
      level: 'Undergraduate',
      language: 'English',
      officialUrl: 'https://ocw.mit.edu/courses/18-06-linear-algebra-spring-2010/',
      type: ResourceType.course,
      downloadable: true,
      downloadUrl:
          'https://ocw.mit.edu/courses/18-06-linear-algebra-spring-2010/resources/mit18_06s10_syllabus/',
      fileSizeBytes: 6200000,
      license: 'CC-BY-NC-SA 4.0',
      instructorOrAuthor: 'Prof. Gilbert Strang',
      institution: 'MIT',
      lessons: [
        ChapterLesson(
          id: 'mit-la-lec1',
          chapterNumber: 1,
          title: 'The Geometry of Linear Equations',
          durationMinutes: 45,
          officialUrl: 'https://ocw.mit.edu/courses/18-06-linear-algebra-spring-2010/resources/lecture-1-the-geometry-of-linear-equations/',
          downloadable: true,
          content: '''MIT 18.06 — Lecture 1: The Geometry of Linear Equations (Prof. Gilbert Strang)

1. Two Views of Matrix Equations Ax = b:
Consider the linear system:
2x - y = 0
-x + 2y = 3

• Row Picture: Each equation represents a geometric hyperplane. For 2 equations in 2 unknowns, each is a line in the xy-plane; the unique intersection point (1, 2) solves the system.
• Column Picture: Ax is fundamentally a linear combination of the column vectors of matrix A:
x [ 2, -1 ]ᵀ + y [ -1, 2 ]ᵀ = [ 0, 3 ]ᵀ
This is the core perspective of modern linear algebra: Can the target vector b be formed as a linear combination of the columns of A?

2. Matrix Multiplication Perspectives:
• Entry-wise: (AB)ᵢⱼ = ∑ₖ Aᵢₖ Bₖⱼ
• Column-wise: Each column of AB is A multiplied by the corresponding column of B (linear combination of columns of A).
• Row-wise: Each row of AB is a linear combination of the rows of B.''',
        ),
        ChapterLesson(
          id: 'mit-la-lec2',
          chapterNumber: 2,
          title: 'The Four Fundamental Subspaces',
          durationMinutes: 50,
          officialUrl: 'https://ocw.mit.edu/courses/18-06-linear-algebra-spring-2010/resources/lecture-10-the-four-fundamental-subspaces/',
          downloadable: true,
          content: '''MIT 18.06 — The Four Fundamental Subspaces of Matrix A (m × n)

1. Column Space C(A):
The subspace of ℝᵐ spanned by all column vectors of A. Dimension = r (rank). Represents all vectors b for which Ax = b is solvable.

2. Nullspace N(A):
The subspace of ℝⁿ containing all solutions to Ax = 0. Dimension = n - r (number of free variables).

3. Row Space C(Aᵀ):
The subspace of ℝⁿ spanned by the rows of A (columns of Aᵀ). Dimension = r.

4. Left Nullspace N(Aᵀ):
The subspace of ℝᵐ containing all solutions to Aᵀy = 0. Dimension = m - r.

Orthogonality Theorem (Fundamental Theorem of Linear Algebra):
• The Row Space C(Aᵀ) is orthogonal to the Nullspace N(A) in ℝⁿ.
• The Column Space C(A) is orthogonal to the Left Nullspace N(Aᵀ) in ℝᵐ.''',
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
