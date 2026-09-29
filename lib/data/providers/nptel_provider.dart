import '../models/learning_resource.dart';
import 'content_provider.dart';

/// Provider for NPTEL (National Programme on Technology Enhanced Learning - IITs & IISc)
/// Legitimate Indian higher education engineering and science courses.
class NptelProvider implements EducationalProvider {
  @override
  String get providerId => 'nptel';

  @override
  String get providerName => 'NPTEL';

  @override
  String get providerWebsite => 'https://nptel.ac.in';

  @override
  String get defaultLicense => 'CC-BY-NC-SA 4.0';

  static final List<LearningResource> _courses = [
    LearningResource(
      id: 'nptel-ml-106106139',
      title: 'Introduction to Machine Learning',
      description:
          'Comprehensive foundations of machine learning covering supervised, unsupervised, and reinforcement paradigms by IIT Madras. Includes mathematical derivations, algorithms, and real-world applications.',
      provider: 'NPTEL',
      subject: 'Computer Science',
      category: 'Artificial Intelligence',
      level: 'Undergraduate',
      language: 'English',
      officialUrl: 'https://nptel.ac.in/courses/106106139',
      type: ResourceType.course,
      downloadable: true,
      downloadUrl: 'https://archive.nptel.ac.in/content/syllabus_pdf/106106139.pdf',
      fileSizeBytes: 4200000,
      license: 'CC-BY-NC-SA 4.0',
      instructorOrAuthor: 'Prof. Balaraman Ravindran',
      institution: 'IIT Madras',
      lessons: [
        ChapterLesson(
          id: 'nptel-ml-ch1',
          chapterNumber: 1,
          title: 'Introduction to Machine Learning & Paradigms',
          durationMinutes: 45,
          officialUrl: 'https://nptel.ac.in/courses/106106139',
          downloadable: true,
          content: '''Introduction to Machine Learning (IIT Madras - Prof. Balaraman Ravindran)

1. What is Machine Learning?
Machine learning is a field of computer science that gives computers the ability to learn without being explicitly programmed. Arthur Samuel defined it as a study that gives computers the ability to learn without being explicitly programmed. Tom Mitchell provides a modern engineering definition:
"A computer program is said to learn from experience E with respect to some class of tasks T and performance measure P, if its performance at tasks in T, as measured by P, improves with experience E."

2. Three Primary Learning Paradigms:
• Supervised Learning: The algorithm is provided with input features X alongside target ground-truth labels Y. The objective is to learn a mapping function f: X → Y that minimizes empirical risk. Examples include Regression (continuous target) and Classification (discrete target).
• Unsupervised Learning: The algorithm discovers latent structures, clusters, and representations from unlabeled input data X. Key techniques include K-Means clustering, Principal Component Analysis (PCA), and Gaussian Mixture Models.
• Reinforcement Learning: An autonomous agent learns optimal behavioral policies through trial-and-error interactions with a dynamic environment, receiving scalar rewards or penalties governed by Markov Decision Processes.

3. Inductive Bias & Generalization:
A core requirement for any learning algorithm is inductive bias—the set of assumptions the learner uses to predict outputs of unseen inputs. Without bias, a learner cannot generalize beyond observed training points.''',
        ),
        ChapterLesson(
          id: 'nptel-ml-ch2',
          chapterNumber: 2,
          title: 'Linear Regression & Gradient Descent',
          durationMinutes: 50,
          officialUrl: 'https://nptel.ac.in/courses/106106139',
          downloadable: true,
          content: '''Linear Regression & Optimization Formulations

1. Mathematical Formulation:
In simple linear regression, we model the relationship between a dependent variable y and independent vector x:
ŷ = θ₀ + θ₁x₁ + θ₂x₂ + ... + θₚxₚ = θᵀx

2. Cost Function (Mean Squared Error):
The objective is to find parameter vector θ that minimizes the sum of squared residuals:
J(θ) = (1 / 2m) ∑ᵢ₌₁ᵐ (h_θ(x⁽ⁱ⁾) - y⁽ⁱ⁾)²

3. Gradient Descent Optimization:
Gradient descent iteratively updates parameters in the direction opposite to the gradient of the cost function:
θⱼ := θⱼ - α ∂J(θ)/∂θⱼ
where α is the learning rate.
• Batch Gradient Descent: Computes the gradient over the entire dataset m at each iteration.
• Stochastic Gradient Descent (SGD): Updates parameters using a single random sample per iteration, enabling online learning and escaping shallow local minima.
• Mini-batch Gradient Descent: Balances computational vectorization efficiency with stochastic variance by computing gradients over batches of size 32-256.

4. Normal Equation Closed-Form Solution:
θ = (XᵀX)⁻¹ Xᵀy
Provides an analytical minimum without iterations, optimal when feature dimensionality is moderate.''',
        ),
        ChapterLesson(
          id: 'nptel-ml-ch3',
          chapterNumber: 3,
          title: 'Logistic Regression & Classification',
          durationMinutes: 48,
          officialUrl: 'https://nptel.ac.in/courses/106106139',
          downloadable: true,
          content: '''Logistic Regression & Probabilistic Classification

1. The Sigmoid Activation Function:
Logistic regression models the posterior probability P(y=1|x) using the logistic sigmoid function:
g(z) = 1 / (1 + e⁻ᶻ)
where z = θᵀx. The output is bounded between 0 and 1, representing calibrated probability.

2. Maximum Likelihood Estimation & Log-Loss:
Because squared error produces non-convex landscapes with sigmoid activations, logistic regression utilizes cross-entropy loss (Log-Loss):
J(θ) = - (1/m) ∑ᵢ [y⁽ⁱ⁾ log(h_θ(x⁽ⁱ⁾)) + (1 - y⁽ⁱ⁾) log(1 - h_θ(x⁽ⁱ⁾))]
Minimizing Log-Loss corresponds to maximizing the likelihood of observing the training data under Bernoulli distribution assumptions.

3. Decision Boundaries & Multi-Class Extensions:
A decision boundary is formed by setting h_θ(x) ≥ 0.5, corresponding to θᵀx ≥ 0.
For multi-class classification, One-vs-All (OvA) or Softmax regression (multinomial logistic regression) is employed.''',
        ),
        ChapterLesson(
          id: 'nptel-ml-ch4',
          chapterNumber: 4,
          title: 'Decision Trees & Information Gain',
          durationMinutes: 42,
          officialUrl: 'https://nptel.ac.in/courses/106106139',
          downloadable: true,
          content: '''Decision Trees & Information Theory Metrics

1. Recursive Partitioning:
A decision tree constructs non-parametric hierarchical partitions of the feature space. At each internal node, the feature and threshold that maximize impurity reduction are selected.

2. Impurity Measures:
• Shannon Entropy: H(S) = - ∑ pᵢ log₂(pᵢ)
• Information Gain: IG(S, A) = H(S) - ∑ (|Sᵥ| / |S|) H(Sᵥ)
• Gini Impurity (used in CART): Gini(S) = 1 - ∑ pᵢ²

3. Overfitting & Pruning:
Deep trees tend to overfit high-variance training noise. Regularization is achieved via:
• Pre-pruning: Limiting maximum depth, minimum samples per leaf, and maximum leaf nodes.
• Cost-complexity post-pruning: Pruning subtrees that do not yield significant validation performance improvements.''',
        ),
        ChapterLesson(
          id: 'nptel-ml-ch5',
          chapterNumber: 5,
          title: 'Neural Networks & Backpropagation',
          durationMinutes: 55,
          officialUrl: 'https://nptel.ac.in/courses/106106139',
          downloadable: true,
          content: '''Artificial Neural Networks & The Backpropagation Algorithm

1. Perceptron to Multi-Layer Perceptron (MLP):
While a single-layer perceptron can only resolve linearly separable patterns (the XOR limitation), stacking layers with non-linear activations (ReLU, Sigmoid, GELU) enables universal function approximation.

2. Forward Propagation:
z^[l] = W^[l] a^[l-1] + b^[l]
a^[l] = σ(z^[l])

3. The Chain Rule & Error Backpropagation:
Backpropagation calculates the analytical gradient of the global loss function with respect to every weight tensor in the network using the chain rule:
δ^[l] = (W^[l+1]ᵀ δ^[l+1]) ⊙ σ'(z^[l])
∂L/∂W^[l] = δ^[l] (a^[l-1])ᵀ
∂L/∂b^[l] = δ^[l]

Modern deep learning frameworks utilize reverse-mode automatic differentiation based on this exact computational graph algorithm.''',
        ),
      ],
    ),
    LearningResource(
      id: 'nptel-dsa-106102064',
      title: 'Data Structures and Algorithms',
      description:
          'Rigorous computer science curriculum by IIT Delhi covering asymptotic complexity, dynamic memory structures, search trees, balanced trees, and graph traversal algorithms.',
      provider: 'NPTEL',
      subject: 'Computer Science',
      category: 'Algorithms',
      level: 'Undergraduate',
      language: 'English',
      officialUrl: 'https://nptel.ac.in/courses/106102064',
      type: ResourceType.course,
      downloadable: true,
      downloadUrl: 'https://archive.nptel.ac.in/content/syllabus_pdf/106102064.pdf',
      fileSizeBytes: 3800000,
      license: 'CC-BY-NC-SA 4.0',
      instructorOrAuthor: 'Prof. Naveen Garg',
      institution: 'IIT Delhi',
      lessons: [
        ChapterLesson(
          id: 'nptel-dsa-ch1',
          chapterNumber: 1,
          title: 'Asymptotic Analysis & Big-O Notation',
          durationMinutes: 40,
          officialUrl: 'https://nptel.ac.in/courses/106102064',
          downloadable: true,
          content: '''Asymptotic Analysis and Algorithm Efficiency (IIT Delhi - Prof. Naveen Garg)

1. Purpose of Asymptotic Analysis:
Asymptotic notation allows computer scientists to evaluate how execution time and auxiliary space scale as input size n approaches infinity, independent of hardware architecture, compiler optimizations, or runtime environments.

2. Formal Notations:
• Big-O (O(g(n))): Tight asymptotic upper bound. f(n) = O(g(n)) iff ∃ constants c > 0 and n₀ such that 0 ≤ f(n) ≤ c·g(n) for all n ≥ n₀.
• Big-Omega (Ω(g(n))): Asymptotic lower bound. Represents minimum resource consumption.
• Big-Theta (Θ(g(n))): Asymptotically tight bound. Holds when both O(g(n)) and Ω(g(n)) are satisfied.

3. Standard Growth Rates:
O(1) < O(log n) < O(n) < O(n log n) < O(n²) < O(2ⁿ) < O(n!)''',
        ),
        ChapterLesson(
          id: 'nptel-dsa-ch2',
          chapterNumber: 2,
          title: 'Linked Lists, Stacks & Queues',
          durationMinutes: 45,
          officialUrl: 'https://nptel.ac.in/courses/106102064',
          downloadable: true,
          content: '''Linear Dynamic Data Structures

1. Singly and Doubly Linked Lists:
Unlike contiguous arrays, linked lists allocate memory dynamically on the heap. Nodes contain data elements and pointers to subsequent nodes.
• Insertion/Deletion at known position: O(1)
• Random element search: O(n)

2. Stack (LIFO - Last In First Out):
Supports push, pop, and peek operations in O(1) time. Vital for execution call stacks, recursive evaluation, syntax parsing, and backtracking.

3. Queue (FIFO - First In First Out):
Supports enqueue at rear and dequeue at front in O(1) time. Core abstraction for BFS traversal, task schedulers, and print buffers.''',
        ),
        ChapterLesson(
          id: 'nptel-dsa-ch3',
          chapterNumber: 3,
          title: 'Binary Trees & Balanced AVL Trees',
          durationMinutes: 52,
          officialUrl: 'https://nptel.ac.in/courses/106102064',
          downloadable: true,
          content: '''Hierarchical Tree Structures & Self-Balancing

1. Binary Search Tree (BST) Property:
For every node with key k, all keys in its left subtree are < k, and all keys in its right subtree are > k.
Average search, insert, and delete operations take O(log n) time, but degenerate to O(n) on skewed inputs.

2. AVL Tree Invariant:
An AVL tree maintains height balance such that for every node, |height(left) - height(right)| ≤ 1.
When an insertion violates this balance factor (-2 or +2), rotation operations (LL, RR, LR, RL) restore balance in O(1) time, ensuring guaranteed O(log n) worst-case performance.''',
        ),
      ],
    ),
    LearningResource(
      id: 'nptel-java-106105191',
      title: 'Programming in Java',
      description:
          'Hands-on object-oriented programming, inheritance, polymorphism, multithreading, and event handling by IIT Kharagpur.',
      provider: 'NPTEL',
      subject: 'Computer Science',
      category: 'Software Engineering',
      level: 'Undergraduate',
      language: 'English',
      officialUrl: 'https://nptel.ac.in/courses/106105191',
      type: ResourceType.course,
      downloadable: true,
      downloadUrl: 'https://archive.nptel.ac.in/content/syllabus_pdf/106105191.pdf',
      fileSizeBytes: 3500000,
      license: 'CC-BY-NC-SA 4.0',
      instructorOrAuthor: 'Prof. Debasis Samanta',
      institution: 'IIT Kharagpur',
      lessons: [
        ChapterLesson(
          id: 'nptel-java-ch1',
          chapterNumber: 1,
          title: 'Java Architecture & OOP Fundamentals',
          durationMinutes: 40,
          officialUrl: 'https://nptel.ac.in/courses/106105191',
          downloadable: true,
          content: '''Java Architecture & Core OOP Pillars (IIT Kharagpur)

1. The Java Platform Paradigm:
Java achieves architectural portability ("Write Once, Run Anywhere") via the Java Virtual Machine (JVM). Source code (.java) is compiled by javac into intermediate bytecode (.class), which is verified by the bytecode verifier and executed via Just-In-Time (JIT) compilation on platform-specific JVM runtimes.

2. Four Pillars of Object-Oriented Programming:
• Encapsulation: Bundling data fields with methods that manipulate them while restricting direct external access via access modifiers (private, protected, public).
• Abstraction: Exposing only high-level conceptual interfaces while encapsulating internal computational complexity.
• Inheritance: Mechanism where derived classes inherit state and behaviors from parent classes via the `extends` keyword.
• Polymorphism: Ability of objects to take multiple forms—static (method overloading) and dynamic (method overriding via virtual method tables).''',
        ),
        ChapterLesson(
          id: 'nptel-java-ch2',
          chapterNumber: 2,
          title: 'Exception Handling & Robust Systems',
          durationMinutes: 45,
          officialUrl: 'https://nptel.ac.in/courses/106105191',
          downloadable: true,
          content: '''Structured Exception Handling in Java

1. Throwable Hierarchy:
At the root is `java.lang.Throwable`, divided into:
• `Error`: Unrecoverable system-level failures (e.g. OutOfMemoryError, StackOverflowError).
• `Exception`: Recoverable application-level anomalies.
  - Checked Exceptions: Inherit from Exception; enforced at compile time (e.g. IOException, SQLException).
  - Unchecked Exceptions: Inherit from RuntimeException; logical errors (e.g. NullPointerException, ArrayIndexOutOfBoundsException).

2. Try-Catch-Finally Mechanism:
Code susceptible to runtime exceptions is placed in `try` blocks. Matching `catch` handlers execute recovery routines. The `finally` block executes unconditionally, ensuring critical resource deallocation (closing file descriptors, network sockets, database connections).''',
        ),
      ],
    ),
    LearningResource(
      id: 'nptel-dbms-106106093',
      title: 'Database Management Systems',
      description:
          'Core relational database architecture, entity-relationship modeling, relational algebra, SQL, normalization (BCNF, 3NF), and ACID transaction management by IIT Madras.',
      provider: 'NPTEL',
      subject: 'Computer Science',
      category: 'Databases',
      level: 'Undergraduate',
      language: 'English',
      officialUrl: 'https://nptel.ac.in/courses/106106093',
      type: ResourceType.course,
      downloadable: true,
      downloadUrl: 'https://archive.nptel.ac.in/content/syllabus_pdf/106106093.pdf',
      fileSizeBytes: 3950000,
      license: 'CC-BY-NC-SA 4.0',
      instructorOrAuthor: 'Prof. S. Sudarshan',
      institution: 'IIT Bombay / IIT Madras',
      lessons: [
        ChapterLesson(
          id: 'nptel-dbms-ch1',
          chapterNumber: 1,
          title: 'Relational Model & Relational Algebra',
          durationMinutes: 45,
          officialUrl: 'https://nptel.ac.in/courses/106106093',
          downloadable: true,
          content: '''Database Management Systems: Relational Algebra & Architecture
1. The Relational Model:
Relations represent mathematical subsets of Cartesian products across attribute domains. Tuples represent individual entity records, and attributes define atomic column types.

2. Fundamental Operations:
• Selection (σ): Filters tuples satisfying a propositional predicate.
• Projection (π): Extracts specified column subsets while eliminating duplicate rows.
• Cartesian Product (×): Combines all pairs of tuples between two relations.
• Natural Join (⨝): Combines relations based on equality across common attribute names.

3. Integrity Constraints:
• Entity Integrity: Primary key attributes cannot contain null values.
• Referential Integrity: Foreign key values must match an existing primary key value in the referenced relation.''',
        ),
        ChapterLesson(
          id: 'nptel-dbms-ch2',
          chapterNumber: 2,
          title: 'Functional Dependencies & Normalization (1NF to BCNF)',
          durationMinutes: 50,
          officialUrl: 'https://nptel.ac.in/courses/106106093',
          downloadable: true,
          content: '''Database Normalization Theory
1. Redundancy and Anomalies:
Unnormalized schemas suffer from insertion, deletion, and update anomalies.

2. Normal Forms:
• First Normal Form (1NF): All attribute domains contain only atomic, indivisible values.
• Second Normal Form (2NF): Relation is in 1NF and contains no partial functional dependencies (no non-prime attribute depends on a proper subset of any candidate key).
• Third Normal Form (3NF): Relation is in 2NF and contains no transitive functional dependencies (for every X → Y, either X is a superkey or Y is a prime attribute).
• Boyce-Codd Normal Form (BCNF): For every non-trivial functional dependency X → Y, X must strictly be a superkey.''',
        ),
      ],
    ),
    LearningResource(
      id: 'nptel-os-106106144',
      title: 'Operating Systems Principles',
      description:
          'Comprehensive foundations of process scheduling, virtual memory paging, concurrency primitives (semaphores, mutexes), deadlock resolution, and file system mechanics.',
      provider: 'NPTEL',
      subject: 'Computer Science',
      category: 'Systems',
      level: 'Undergraduate',
      language: 'English',
      officialUrl: 'https://nptel.ac.in/courses/106106144',
      type: ResourceType.course,
      downloadable: true,
      downloadUrl: 'https://archive.nptel.ac.in/content/syllabus_pdf/106106144.pdf',
      fileSizeBytes: 4100000,
      license: 'CC-BY-NC-SA 4.0',
      instructorOrAuthor: 'Prof. Santanu Chattopadhyay',
      institution: 'IIT Kharagpur',
      lessons: [
        ChapterLesson(
          id: 'nptel-os-ch1',
          chapterNumber: 1,
          title: 'Processes, Threads & CPU Scheduling',
          durationMinutes: 48,
          officialUrl: 'https://nptel.ac.in/courses/106106144',
          downloadable: true,
          content: '''Operating Systems: Process Management & CPU Scheduling
1. Process States & Process Control Block (PCB):
A process executes through five lifecycle states: New, Ready, Running, Waiting, and Terminated. The OS kernel tracks process context inside the PCB: Program Counter (PC), CPU registers, memory limits, and open file lists.

2. CPU Scheduling Algorithms:
• First-Come, First-Served (FCFS): Non-preemptive, suffers from the convoy effect.
• Shortest Job First (SJF / SRTF): Provably optimal average turnaround time; requires CPU burst estimation.
• Round Robin (RR): Preemptive time-sharing via fixed time quantum q. Avoids starvation.''',
        ),
        ChapterLesson(
          id: 'nptel-os-ch2',
          chapterNumber: 2,
          title: 'Virtual Memory, Paging & Page Replacement',
          durationMinutes: 52,
          officialUrl: 'https://nptel.ac.in/courses/106106144',
          downloadable: true,
          content: '''Virtual Memory Architecture & Demand Paging
1. Memory Management Unit (MMU) & Paging:
Virtual addresses are partitioned into Page Numbers (p) and Offsets (d). The MMU uses the process Page Table (accelerated by the Translation Lookaside Buffer / TLB) to translate virtual page numbers into physical Frame numbers (f).

2. Page Fault Handling:
When an invalid page entry is accessed, the hardware raises a page fault trap. The OS fetches the requested page from swap storage into an available physical frame and restarts the faulting instruction.

3. Page Replacement Strategies:
• FIFO: Simple queue; susceptible to Belady's Anomaly.
• Optimal (OPT): Replaces the page that will not be used for the longest future duration.
• Least Recently Used (LRU): Replaces the page unused for the longest past time; implemented via stack or counter architectures.''',
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
