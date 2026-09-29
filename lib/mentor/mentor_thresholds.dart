/// Centralized configurable thresholds for learning evaluation and weak topic detection.
class MentorThresholds {
  /// Score below which a topic is flagged as weak (default < 50.0%)
  static const double quizWeakThreshold = 50.0;

  /// Score range [50.0, 70.0) considered "needs practice"
  static const double quizPracticeThreshold = 70.0;

  /// Score >= 70.0% considered "progressing / mastered"
  static const double quizMasteredThreshold = 70.0;

  /// Minimum number of events on a topic before declaring a weak topic
  static const int minEventsForEvaluation = 1;

  /// Number of repeated questions on the same topic to consider extra attention
  static const int repeatedQuestionThreshold = 3;

  /// Default recommended session duration in minutes
  static const int defaultSessionMinutes = 25;

  /// Categorize score into performance label
  static String categorizeScore(double score) {
    if (score < quizWeakThreshold) return 'weak';
    if (score < quizMasteredThreshold) return 'needs_practice';
    return 'progressing';
  }
}
