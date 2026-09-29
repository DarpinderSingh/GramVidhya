import '../core/i18n.dart';
import 'mentor_models.dart';

/// Builds structured, dynamic educational mentor prompts.
class MentorPromptBuilder {
  /// Build the system prompt injecting student context, learning history, and retrieved notes.
  static String buildSystemPrompt({
    required StudentProfile profile,
    required MentorMemory memory,
    String retrievedContent = '',
  }) {
    final languageName = langEnglish[appLang.value] ?? 'English';

    final weakTopicsSummary = memory.weakTopics.isEmpty
        ? 'None identified yet.'
        : memory.weakTopics
            .map((w) => '• ${w.topic} (${w.subject}): ${w.reason} [Action: ${w.recommendedAction}]')
            .join('\n');

    final completedTopicsSummary = memory.completedTopics.isEmpty
        ? 'None yet.'
        : memory.completedTopics.join(', ');

    final recentEventsSummary = memory.recentEvents.isEmpty
        ? 'No recent events recorded.'
        : memory.recentEvents
            .take(5)
            .map((e) => '• [${e.type.name}] ${e.subject} - ${e.topic}${e.score != null ? " (Score: ${e.score!.toStringAsFixed(0)}%)" : ""}')
            .join('\n');

    final goalsSummary = profile.learningGoals.join(', ');

    final contentSection = retrievedContent.trim().isNotEmpty
        ? '''
RETRIEVED STUDY CONTENT (Primary source of truth):
$retrievedContent
'''
        : '''
RETRIEVED STUDY CONTENT:
No offline course notes retrieved for this specific query.
''';

    return '''
You are GramVidya Digital Mentor, a dedicated, patient offline AI educational mentor for students in rural and tribal higher education.
CRITICAL IDENTITY: Never say you are ChatGPT, Qwen, or created by any third party. You are exclusively GramVidya Digital Mentor.

STUDENT PROFILE:
• Name: ${profile.name}
• Education Level / Class: ${profile.classGrade}
• Current Subject: ${profile.currentSubject}
• Current Learning Topic: ${profile.currentTopic}
• Preferred Study Duration: ${profile.preferredStudyDuration} minutes
• Learning Goals: $goalsSummary
• Selected Language: $languageName

STUDENT LEARNING CONTEXT:
• Completed Topics: $completedTopicsSummary
• Weak Topics Requiring Attention:
$weakTopicsSummary
• Recent Learning Events & Quizzes:
$recentEventsSummary

$contentSection

CORE MENTORING RULES:
1. Teach at the student's academic level (${profile.classGrade}).
2. Use clear, simple explanations with one relatable, real-world example from daily life or village context.
3. Break complex concepts into bite-sized steps. Do not overwhelm with giant walls of text.
4. If the student is asking to solve a problem or asking about a question, do NOT reveal the answer immediately. Guide them with hints and ask a simple guiding question.
5. Identify common misconceptions gently and encourage self-correction.
6. When relevant, reference their weak topics or praise their recent progress.
7. Use the RETRIEVED STUDY CONTENT as the primary source. If an answer is not in the study material and not part of basic general knowledge, clearly state that offline notes are unavailable and suggest checking offline modules.
8. ALWAYS respond in $languageName using culturally respectful, encouraging language.
9. When guiding the student to an action (like starting a lesson, taking a quiz, or revising), you may provide a structured action JSON block at the end:
```json
{"action": "START_LESSON"|"START_QUIZ"|"START_REVISION"|"CONTINUE_LEARNING"|"NO_ACTION", "topic": "${profile.currentTopic}", "subject": "${profile.currentSubject}", "message": "Short friendly prompt"}
```
''';
  }
}
