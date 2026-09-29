import '../models/learning_resource.dart';
import 'content_provider.dart';

/// Provider for OpenStax (Rice University - Open Educational Resources)
/// Legitimate peer-reviewed open textbooks with CC-BY 4.0 license and official direct downloads.
class OpenStaxProvider implements EducationalProvider {
  @override
  String get providerId => 'openstax';

  @override
  String get providerName => 'OpenStax';

  @override
  String get providerWebsite => 'https://openstax.org';

  @override
  String get defaultLicense => 'CC-BY 4.0';

  static final List<LearningResource> _textbooks = [
    LearningResource(
      id: 'openstax-physics-2e',
      title: 'College Physics 2e',
      description:
          'Peer-reviewed introductory physics textbook covering Newtonian mechanics, thermodynamics, electromagnetism, optics, and special relativity with real-world applications and worked examples.',
      provider: 'OpenStax',
      subject: 'Physics',
      category: 'Science',
      level: 'Undergraduate',
      language: 'English',
      officialUrl: 'https://openstax.org/details/books/college-physics-2e',
      type: ResourceType.book,
      downloadable: true,
      downloadUrl: 'https://openstax.org/downloads/college-physics-2e',
      fileSizeBytes: 28500000,
      license: 'CC-BY 4.0 (Creative Commons Attribution)',
      instructorOrAuthor: 'Dr. Paul Peter Urone, Dr. Roger Hinrichs',
      institution: 'Rice University / OpenStax',
      lessons: [
        ChapterLesson(
          id: 'ostx-phys-ch1',
          chapterNumber: 1,
          title: 'The Nature of Science & Physics',
          pageCount: 32,
          officialUrl: 'https://openstax.org/books/college-physics-2e/pages/1-introduction-to-science-and-the-realm-of-physics-physical-quantities-and-units',
          downloadable: true,
          content: '''College Physics 2e — Chapter 1: The Nature of Science & Physics (OpenStax)

1. Physics: An Introduction:
Physics is the fundamental science that seeks to discern the basic laws of the universe. It describes the interactions of energy, matter, space, and time to uncover the fundamental mechanisms that underlie every phenomenon.
• Classical Physics: Formulated from Renaissance to 19th century; applies when matter moves at speeds << c, objects are large enough to be seen under a microscope, and gravitational fields are weak.
• Modern Physics: Comprises Relativity (for high-velocity and strong gravitational regimes) and Quantum Mechanics (for atomic and subatomic phenomena).

2. Physical Quantities and Units:
Physical quantities are defined by either specifying how it is measured or by stating how it is calculated from other measurements.
• Fundamental SI Units: Length (meter - m), Mass (kilogram - kg), Time (second - s), Electric Current (ampere - A), Temperature (kelvin - K), Amount of Substance (mole - mol), Luminous Intensity (candela - cd).
• Dimensional Consistency: Every equation in physics must be dimensionally homogeneous. Both sides of an equals sign must share identical dimensions.''',
        ),
        ChapterLesson(
          id: 'ostx-phys-ch2',
          chapterNumber: 2,
          title: 'Kinematics: Motion Along a Straight Line',
          pageCount: 46,
          officialUrl: 'https://openstax.org/books/college-physics-2e/pages/2-introduction-to-one-dimensional-kinematics',
          downloadable: true,
          content: '''College Physics 2e — Chapter 2: One-Dimensional Kinematics

1. Displacement vs. Distance:
• Distance is the scalar magnitude of the actual trajectory traveled by an object.
• Displacement (Δx = x_f - x_₀) is a vector quantity pointing from initial position to final position.

2. Average Velocity & Acceleration:
• Average velocity: v_avg = Δx / Δt
• Instantaneous velocity: v(t) = dx / dt
• Acceleration: a(t) = dv / dt

3. Kinematic Equations for Constant Acceleration:
When acceleration a is constant:
1) v = v₀ + at
2) x = x₀ + v₀t + ½ at²
3) v² = v₀² + 2a(x - x₀)
4) v_avg = (v₀ + v) / 2

4. Free Fall:
An object in free fall experiences constant acceleration downward due to gravity: g ≈ 9.80 m/s² near Earth's surface, neglecting atmospheric resistance.''',
        ),
        ChapterLesson(
          id: 'ostx-phys-ch3',
          chapterNumber: 3,
          title: 'Dynamics: Force and Newton\'s Laws of Motion',
          pageCount: 52,
          officialUrl: 'https://openstax.org/books/college-physics-2e/pages/4-introduction-to-dynamics-newtons-laws-of-motion',
          downloadable: true,
          content: '''College Physics 2e — Chapter 3: Dynamics & Newton's Laws

1. Concept of Force:
A force is a push or pull on an object with a specific magnitude and direction (vector). Fundamental forces include Gravitational, Electromagnetic, Weak Nuclear, and Strong Nuclear.

2. Newton's Three Laws of Motion:
• First Law (Inertia): A body remains at rest or, if in motion, remains in motion at a constant velocity unless acted upon by a net external force: ∑F = 0 ⟹ a = 0.
• Second Law (Momentum & Force): The net external force on a body is directly proportional to and in the same direction as the acceleration: ∑F = ma (or F = dp/dt).
• Third Law (Action-Reaction): Whenever one body exerts a force on a second body, the second body exerts a force equal in magnitude and opposite in direction on the first: F_AB = -F_BA.

3. Friction & Normal Force:
• Normal force N acts perpendicular to contact surfaces.
• Static friction: f_s ≤ μ_s N (prevents initiation of relative motion).
• Kinetic friction: f_k = μ_k N (opposes ongoing relative sliding).''',
        ),
      ],
    ),
    LearningResource(
      id: 'openstax-calculus-vol1',
      title: 'Calculus Volume 1',
      description:
          'Rigorous open textbook on differential and integral calculus, limits, continuity, derivative techniques, optimization, and the Fundamental Theorem of Calculus.',
      provider: 'OpenStax',
      subject: 'Mathematics',
      category: 'Higher Mathematics',
      level: 'Undergraduate',
      language: 'English',
      officialUrl: 'https://openstax.org/details/books/calculus-volume-1',
      type: ResourceType.book,
      downloadable: true,
      downloadUrl: 'https://openstax.org/downloads/calculus-volume-1',
      fileSizeBytes: 24200000,
      license: 'CC-BY 4.0 (Creative Commons Attribution)',
      instructorOrAuthor: 'Dr. Edwin Herman, Dr. Gilbert Strang',
      institution: 'Rice University / OpenStax',
      lessons: [
        ChapterLesson(
          id: 'ostx-calc-ch1',
          chapterNumber: 1,
          title: 'Limits and Continuity',
          pageCount: 58,
          officialUrl: 'https://openstax.org/books/calculus-volume-1/pages/2-introduction-to-limits',
          downloadable: true,
          content: '''Calculus Volume 1 — Chapter 1: Limits and Continuity (OpenStax)

1. The Limit of a Function:
The notation lim_{x→c} f(x) = L means that as x approaches arbitrarily close to c (with x ≠ c), f(x) approaches arbitrarily close to L.
• Formal ε-δ Definition: For every ε > 0, there exists a δ > 0 such that if 0 < |x - c| < δ, then |f(x) - L| < ε.

2. Limit Laws:
If lim_{x→c} f(x) = L and lim_{x→c} g(x) = M:
• Sum Law: lim [f(x) + g(x)] = L + M
• Product Law: lim [f(x)·g(x)] = L·M
• Quotient Law: lim [f(x)/g(x)] = L / M (provided M ≠ 0)

3. Continuity:
A function f(x) is continuous at a point x = c iff:
1) f(c) is defined
2) lim_{x→c} f(x) exists
3) lim_{x→c} f(x) = f(c)

4. Intermediate Value Theorem (IVT):
If f is continuous on [a, b] and u is any value strictly between f(a) and f(b), then there exists at least one c ∈ (a, b) such that f(c) = u.''',
        ),
        ChapterLesson(
          id: 'ostx-calc-ch2',
          chapterNumber: 2,
          title: 'Derivatives & Differentiation Rules',
          pageCount: 64,
          officialUrl: 'https://openstax.org/books/calculus-volume-1/pages/3-introduction-to-derivatives',
          downloadable: true,
          content: '''Calculus Volume 1 — Chapter 2: Derivatives

1. Definition of the Derivative:
f'(x) = lim_{h→0} [f(x + h) - f(x)] / h
Geometrically, f'(x) represents the slope of the tangent line to the curve y = f(x) at point x.

2. Essential Differentiation Rules:
• Power Rule: d/dx [xⁿ] = n xⁿ⁻¹
• Product Rule: d/dx [u·v] = u'v + uv'
• Quotient Rule: d/dx [u/v] = (u'v - uv') / v²
• Chain Rule: d/dx [f(g(x))] = f'(g(x)) · g'(x)

3. Trigonometric Derivatives:
• d/dx [sin x] = cos x
• d/dx [cos x] = -sin x
• d/dx [tan x] = sec² x''',
        ),
      ],
    ),
    LearningResource(
      id: 'openstax-microeconomics-3e',
      title: 'Principles of Microeconomics 3e',
      description:
          'Thorough economic foundations exploring consumer choice, supply and demand dynamics, elasticity, cost curves, market structures, and public policy.',
      provider: 'OpenStax',
      subject: 'Economics',
      category: 'Social Sciences',
      level: 'Undergraduate',
      language: 'English',
      officialUrl: 'https://openstax.org/details/books/principles-microeconomics-3e',
      type: ResourceType.book,
      downloadable: true,
      downloadUrl: 'https://openstax.org/downloads/principles-microeconomics-3e',
      fileSizeBytes: 19800000,
      license: 'CC-BY 4.0',
      instructorOrAuthor: 'Dr. David Shapiro, Dr. Steven A. Greenlaw',
      institution: 'OpenStax',
      lessons: [
        ChapterLesson(
          id: 'ostx-econ-ch1',
          chapterNumber: 1,
          title: 'Demand, Supply, and Equilibrium',
          pageCount: 38,
          officialUrl: 'https://openstax.org/books/principles-microeconomics-3e/pages/3-demand-and-supply',
          downloadable: true,
          content: '''Principles of Microeconomics 3e — Demand and Supply (OpenStax)

1. Law of Demand:
As the price of a good increases, the quantity demanded decreases (ceteris paribus). The demand curve slopes downward due to substitution and income effects.

2. Law of Supply:
As the price of a good increases, the quantity supplied increases. The supply curve slopes upward because higher prices incentivize increased resource allocation and production.

3. Market Equilibrium:
Equilibrium occurs at the intersection of supply and demand where Quantity Demanded equals Quantity Supplied (Q_d = Q_s). The resulting price P* clears the market without surplus or shortage.

4. Shifts vs. Movements:
• A price change causes a movement along the existing curve.
• Changes in non-price determinants (consumer income, technology, input costs, expectations) cause shifts of the entire curve.''',
        ),
      ],
    ),
    LearningResource(
      id: 'openstax-biology-2e',
      title: 'Biology 2e',
      description:
          'Peer-reviewed general biology textbook covering cell structure, metabolic pathways, molecular genetics, evolutionary mechanisms, biodiversity, and ecosystem ecology.',
      provider: 'OpenStax',
      subject: 'Biology',
      category: 'Science',
      level: 'Undergraduate',
      language: 'English',
      officialUrl: 'https://openstax.org/details/books/biology-2e',
      type: ResourceType.book,
      downloadable: true,
      downloadUrl: 'https://openstax.org/downloads/biology-2e',
      fileSizeBytes: 34200000,
      license: 'CC-BY 4.0 (Creative Commons Attribution)',
      instructorOrAuthor: 'Dr. Mary Ann Clark, Dr. Matthew Douglas',
      institution: 'OpenStax / Rice University',
      lessons: [
        ChapterLesson(
          id: 'ostx-bio-ch1',
          chapterNumber: 1,
          title: 'The Study of Life & The Scientific Method',
          pageCount: 28,
          officialUrl: 'https://openstax.org/books/biology-2e/pages/1-introduction',
          downloadable: true,
          content: '''Biology 2e — Chapter 1: The Study of Life (OpenStax)
1. Properties of Life:
All living organisms share key characteristics: order, sensitivity/response to stimuli, reproduction, adaptation, growth and development, regulation/homeostasis, and energy processing.

2. Levels of Biological Organization:
Atom → Molecule → Organelle → Cell → Tissue → Organ → Organ System → Organism → Population → Community → Ecosystem → Biosphere. The cell represents the fundamental unit of life.

3. The Scientific Method:
Science relies on empirical observation, hypothesis formulation, deductive prediction, and controlled experimentation. A hypothesis must be falsifiable to be scientifically valid.''',
        ),
        ChapterLesson(
          id: 'ostx-bio-ch2',
          chapterNumber: 2,
          title: 'Cell Structure & Membrane Transport',
          pageCount: 36,
          officialUrl: 'https://openstax.org/books/biology-2e/pages/4-introduction',
          downloadable: true,
          content: '''Cell Structure and The Fluid Mosaic Membrane Model
1. Prokaryotic vs. Eukaryotic Cells:
• Prokaryotes (Bacteria and Archaea) lack membrane-bound nuclei and compartmentalized organelles; their genetic material is localized in a nucleoid.
• Eukaryotes possess a membrane-bound nucleus and specialized organelles (mitochondria, endoplasmic reticulum, Golgi apparatus).

2. The Fluid Mosaic Model:
The plasma membrane is a phospholipid bilayer with hydrophilic heads oriented toward aqueous environments and hydrophobic fatty acid tails sequestered internally. Cholesterol modulates membrane fluidity.

3. Transport Mechanisms:
• Passive Transport: Simple diffusion, facilitated diffusion via channels/carriers, and osmosis along electrochemical gradients without ATP consumption.
• Active Transport: Primary active transport (e.g. Na+/K+ ATPase) utilizes ATP hydrolysis to pump ions against concentration gradients.''',
        ),
      ],
    ),
    LearningResource(
      id: 'openstax-python-programming',
      title: 'Introduction to Python Programming',
      description:
          'Comprehensive open textbook covering algorithmic problem solving, procedural abstractions, object-oriented software engineering, file I/O, and data processing in Python 3.',
      provider: 'OpenStax',
      subject: 'Computer Science',
      category: 'Programming',
      level: 'All Levels',
      language: 'English',
      officialUrl: 'https://openstax.org/details/books/introduction-python-programming',
      type: ResourceType.book,
      downloadable: true,
      downloadUrl: 'https://openstax.org/downloads/intro-python-programming',
      fileSizeBytes: 18400000,
      license: 'CC-BY 4.0',
      instructorOrAuthor: 'OpenStax Faculty',
      institution: 'Rice University',
      lessons: [
        ChapterLesson(
          id: 'ostx-py-ch1',
          chapterNumber: 1,
          title: 'Computational Thinking & Python Basics',
          pageCount: 30,
          officialUrl: 'https://openstax.org/books/introduction-python-programming',
          downloadable: true,
          content: '''Introduction to Python: Core Foundations
1. The Python Interpreter & Execution:
Python is a high-level, dynamically typed, interpreted language. Source code is compiled to bytecode (.pyc) and executed on the Python Virtual Machine (PVM).

2. Primitive Data Types & Variables:
• Integers (`int`), Floating-point numbers (`float`), Booleans (`bool`), and Strings (`str`).
• Variable identifiers are references to heap-allocated objects; assignment binds a name to an object.

3. Control Flow:
Conditionals (`if`, `elif`, `else`) evaluate Boolean expressions. Loops (`for`, `while`) enable bounded and unbounded iteration.''',
        ),
        ChapterLesson(
          id: 'ostx-py-ch2',
          chapterNumber: 2,
          title: 'Functions, Scoping & Data Structures',
          pageCount: 34,
          officialUrl: 'https://openstax.org/books/introduction-python-programming',
          downloadable: true,
          content: '''Functions & Built-in Compound Structures in Python
1. Functions & First-Class Citizens:
Functions are defined via the `def` keyword. In Python, functions are first-class objects that can be passed as arguments, returned from other functions, and stored in data structures.
• Scope Resolution: Follows the LEGB rule (Local, Enclosing, Global, Built-in).

2. Core Data Structures:
• Lists (`[]`): Mutable ordered sequences with amortized O(1) appending.
• Tuples (`()`): Immutable ordered sequences, hashable when containing immutable elements.
• Dictionaries (`{}`): Key-value mappings powered by hash tables with O(1) average lookup.
• Sets (`set()`): Unordered collections of unique hashable items.''',
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
    return _textbooks.where((b) {
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        final matches = b.title.toLowerCase().contains(q) ||
            b.description.toLowerCase().contains(q) ||
            b.subject.toLowerCase().contains(q) ||
            b.instructorOrAuthor?.toLowerCase().contains(q) == true;
        if (!matches) return false;
      }
      if (subject != null && subject != 'All' && b.subject.toLowerCase() != subject.toLowerCase()) {
        return false;
      }
      if (level != null && level != 'All' && b.level.toLowerCase() != level.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<LearningResource?> fetchResource(String id) async {
    try {
      return _textbooks.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> isAvailable() async => true;
}
