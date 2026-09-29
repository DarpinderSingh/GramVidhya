import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gramvidya/core/i18n.dart';
import 'package:gramvidya/data/auth_service.dart';
import 'package:gramvidya/data/course_provider.dart';
import 'package:gramvidya/ai/scholarship_ai.dart';
import 'package:gramvidya/mentor/mentor_models.dart';
import 'package:gramvidya/mentor/mentor_actions.dart';
import 'package:gramvidya/mentor/mentor_prompt.dart';
import 'package:gramvidya/mentor/mentor_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GramVidya Offline Suite Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('gramvidya_test_');
      Hive.init(tempDir.path);
      await Hive.openBox('app');
    });

    tearDown(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    test('i18n translation and language switching', () async {
      expect(tr('app_title'), 'GramVidya AI');
      expect(tr('nav_home'), 'Home');
      expect(tr('nav_mentor'), 'Mentor');
      expect(tr('digital_mentor'), 'Digital Mentor');

      await setLanguage('hi');
      expect(appLang.value, 'hi');
      expect(tr('app_title'), 'ग्रामविद्या AI');
      expect(tr('digital_mentor'), 'डिजिटल मेंटर');

      await setLanguage('en');
      expect(appLang.value, 'en');
    });

    test('AuthService registration and login', () async {
      final auth = AuthService();
      expect(auth.isLoggedIn, false);

      // Validation
      final err = await auth.register(name: '', email: 'invalid', password: '123');
      expect(err, isNotNull);

      // Valid registration
      final regErr = await auth.register(
        name: 'Aarav Kumar',
        email: 'aarav@example.com',
        password: 'password123',
        educationLevel: 'UG',
      );
      expect(regErr, isNull);
      expect(auth.isLoggedIn, true);
      expect(auth.profile['name'], 'Aarav Kumar');

      // Logout
      await auth.logout();
      expect(auth.isLoggedIn, false);

      // Login
      final loginErr = await auth.login(email: 'aarav@example.com', password: 'password123');
      expect(loginErr, isNull);
      expect(auth.isLoggedIn, true);
    });

    test('ScholarshipAI offline search and QA', () async {
      final ai = ScholarshipAI();
      final chunks = await ai.answer('What documents are required for Post-Matric Scholarship for ST?').toList();
      final answer = chunks.join();
      expect(answer, isNotEmpty);
      expect(answer.toLowerCase().contains('certificate') || answer.toLowerCase().contains('document'), true);
    });

    test('CourseManager built-in educational content', () {
      final courses = CourseManager.builtInCourses;
      expect(courses.length, greaterThanOrEqualTo(2));
      expect(courses.first.lessons, isNotEmpty);
    });

    test('Digital Mentor Service: profile, events, weak topics, and daily plan', () async {
      final service = MentorService();
      await service.init();

      // Profile test
      final profile = StudentProfile(
        name: 'Rahul',
        classGrade: 'UG',
        currentSubject: 'Mathematics',
        currentTopic: 'Quadratic Equations',
      );
      await service.saveProfile(profile);
      expect(service.profile.name, 'Rahul');
      expect(service.profile.currentTopic, 'Quadratic Equations');

      // Record a weak quiz score (<50%)
      await service.recordEvent(
        type: LearningEventType.quizResult,
        subject: 'Mathematics',
        topic: 'Factorisation',
        score: 40.0,
      );

      // Verify weak topic detected deterministically
      expect(service.memory.weakTopics.length, 1);
      final weak = service.memory.weakTopics.first;
      expect(weak.topic, 'Factorisation');
      expect(weak.subject, 'Mathematics');
      expect(weak.averageScore, 40.0);

      // Verify daily plan generated with revision of weak topic
      expect(service.dailyPlan, isNotNull);
      expect(service.dailyPlan!.steps.any((s) => s.topic == 'Factorisation'), true);
      expect(service.dailyPlan!.steps.any((s) => s.actionType == 'revision'), true);

      // Record lesson completed and test progress update
      await service.recordEvent(
        type: LearningEventType.lessonCompleted,
        subject: 'English',
        topic: 'The English Alphabet',
      );
      expect(service.memory.completedTopics.contains('The English Alphabet'), true);
    });

    test('MentorAction parsing: structured JSON vs text fallback', () {
      const jsonActionText = '''
Here is your study task:
```json
{
  "action": "START_QUIZ",
  "topic": "Quadratic Equations",
  "subject": "Mathematics",
  "message": "Let's test what you've learned so far!"
}
```
''';
      final action = MentorAction.parse(jsonActionText);
      expect(action.type, MentorActionType.startQuiz);
      expect(action.topic, 'Quadratic Equations');
      expect(action.message, "Let's test what you've learned so far!");

      // Plain text fallback
      const plainText = 'Can you tell me more about what you find difficult?';
      final plainAction = MentorAction.parse(plainText);
      expect(plainAction.type, MentorActionType.noAction);
      expect(plainAction.message, plainText);
    });

    test('MentorPromptBuilder injects student context and RAG notes', () {
      final profile = StudentProfile(
        name: 'Pooja',
        classGrade: '12th',
        currentSubject: 'Physics',
        currentTopic: 'Electromagnetism',
      );
      final memory = MentorMemory(
        weakTopics: [
          WeakTopic(
            subject: 'Physics',
            topic: 'Thermodynamics',
            reason: 'Scored 45%',
            recommendedAction: 'Review First Law',
          ),
        ],
        completedTopics: ['Kinematics'],
      );

      final prompt = MentorPromptBuilder.buildSystemPrompt(
        profile: profile,
        memory: memory,
        retrievedContent: 'First law of thermodynamics: Energy is conserved.',
      );

      expect(prompt.contains('Pooja'), true);
      expect(prompt.contains('Electromagnetism'), true);
      expect(prompt.contains('Thermodynamics'), true);
      expect(prompt.contains('Energy is conserved'), true);
    });
  });
}
