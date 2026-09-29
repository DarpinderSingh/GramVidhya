import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gramvidya/data/auth_service.dart';
import 'package:gramvidya/data/content_repository.dart';
import 'package:gramvidya/data/progress_service.dart';
import 'package:gramvidya/data/store.dart';
import 'package:gramvidya/data/user_store.dart';
import 'package:gramvidya/mentor/mentor_models.dart';
import 'package:gramvidya/mentor/mentor_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('User-Scoped Educational Platform Suite', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('user_scoped_test_');

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async {
          return tempDir.path;
        },
      );

      Hive.init(tempDir.path);
      await Hive.openBox('app');
      await Hive.openBox('content_cache');
      await Hive.openBox('recent_chapters');
      await Hive.openBox('downloads');

      await ContentRepository().init();
      await MentorService().init();
    });

    tearDown(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        try {
          await tempDir.delete(recursive: true);
        } catch (_) {}
      }
    });

    test('UserScopedStore: scopes all keys by active user and prevents cross-user leakage', () async {
      final auth = AuthService();

      // 1. Guest state
      expect(auth.isLoggedIn, false);
      expect(UserScopedStore.currentUserId, 'guest');
      expect(UserScopedStore.done('lesson-1'), false);

      await UserScopedStore.setDone('lesson-1', true);
      expect(UserScopedStore.done('lesson-1'), true);

      // 2. Register and log in User A
      final regA = await auth.register(
        name: 'Aarav Sharma',
        email: 'aarav@example.com',
        password: 'password123',
      );
      expect(regA, isNull);
      expect(auth.isLoggedIn, true);
      expect(UserScopedStore.currentUserId, 'aarav_example_com');

      // User A should NOT see guest's completed lesson
      expect(UserScopedStore.done('lesson-1'), false);

      // User A completes lesson-1 and lesson-2
      await UserScopedStore.setDone('lesson-1', true);
      await UserScopedStore.setDone('lesson-2', true);
      await UserScopedStore.setCourseProgress('basic-english', 0.5);
      await UserScopedStore.addRecentLesson(
        courseId: 'basic-english',
        courseTitle: 'Module 1: Basic English',
        lessonIndex: 0,
        lessonTitle: 'The English Alphabet',
      );

      expect(UserScopedStore.done('lesson-1'), true);
      expect(UserScopedStore.done('lesson-2'), true);
      expect(UserScopedStore.courseProgress('basic-english'), 0.5);
      expect(UserScopedStore.recentLessons.length, 1);
      expect(UserScopedStore.recentLessons.first['lessonTitle'], 'The English Alphabet');

      // 3. Register and switch to User B
      await auth.logout();
      expect(auth.isLoggedIn, false);
      expect(UserScopedStore.currentUserId, 'guest');

      final regB = await auth.register(
        name: 'Bhavna Patel',
        email: 'bhavna@example.com',
        password: 'secretpass456',
      );
      expect(regB, isNull);
      expect(auth.isLoggedIn, true);
      expect(UserScopedStore.currentUserId, 'bhavna_example_com');

      // User B should have totally clean slate: 0 progress, no lessons done
      expect(UserScopedStore.done('lesson-1'), false);
      expect(UserScopedStore.done('lesson-2'), false);
      expect(UserScopedStore.courseProgress('basic-english'), 0.0);
      expect(UserScopedStore.recentLessons.isEmpty, true);

      // User B completes only lesson-3
      await UserScopedStore.setDone('lesson-3', true);
      await UserScopedStore.setCourseProgress('basic-math', 0.25);
      expect(UserScopedStore.done('lesson-3'), true);
      expect(UserScopedStore.done('lesson-1'), false);

      // 4. Switch back to User A
      await auth.logout();
      final loginA = await auth.login(email: 'aarav@example.com', password: 'password123');
      expect(loginA, isNull);
      expect(UserScopedStore.currentUserId, 'aarav_example_com');

      // User A's data must be completely restored and untouched by User B
      expect(UserScopedStore.done('lesson-1'), true);
      expect(UserScopedStore.done('lesson-2'), true);
      expect(UserScopedStore.done('lesson-3'), false); // lesson-3 was only done by User B
      expect(UserScopedStore.courseProgress('basic-english'), 0.5);
      expect(UserScopedStore.recentLessons.length, 1);
      expect(UserScopedStore.recentLessons.first['lessonTitle'], 'The English Alphabet');
    });

    test('Store: delegates learning methods to UserScopedStore transparently', () async {
      final auth = AuthService();
      await auth.register(
        name: 'Chirag Rao',
        email: 'chirag@example.com',
        password: 'password123',
      );

      // Test Store delegation for lesson completion
      expect(Store.done('math-1'), false);
      await Store.setDone('math-1', true);
      expect(Store.done('math-1'), true);
      expect(UserScopedStore.done('math-1'), true);

      // Test Store delegation for course progress
      expect(Store.courseProgress('basic-math'), 0.0);
      await Store.setCourseProgress('basic-math', 0.75);
      expect(Store.courseProgress('basic-math'), 0.75);
      expect(UserScopedStore.courseProgress('basic-math'), 0.75);

      // Test Store delegation for recent lessons
      await Store.addRecentLesson(
        courseId: 'basic-math',
        courseTitle: 'Module 2: Basic Mathematics',
        lessonIndex: 1,
        lessonTitle: 'Addition and Subtraction',
      );
      expect(Store.recentLessons.length, 1);
      expect(Store.recentLessons.first['lessonTitle'], 'Addition and Subtraction');
    });

    test('ContentRepository: user-scoped recent chapters and continue learning isolation', () async {
      final auth = AuthService();
      final repo = ContentRepository();

      // User A logs in and accesses courses
      await auth.register(
        name: 'Devika Sen',
        email: 'devika@example.com',
        password: 'password123',
      );

      await repo.recordChapterAccess(
        courseId: 'openstax-physics-2e',
        courseName: 'College Physics 2e',
        chapterId: 'openstax-phys-ch1',
        chapterName: 'Introduction: The Nature of Science',
        progress: 0.4,
        completed: false,
        provider: 'OpenStax',
      );

      var recentsA = repo.getRecentChapters();
      expect(recentsA.length, 1);
      expect(recentsA.first.courseName, 'College Physics 2e');

      var continueA = repo.getContinueLearning();
      expect(continueA, isNotNull);
      expect(continueA!.chapterName, 'Introduction: The Nature of Science');

      // User B logs in
      await auth.logout();
      await auth.register(
        name: 'Eshwar Das',
        email: 'eshwar@example.com',
        password: 'password123',
      );

      // User B should NOT see User A's recent chapters
      var recentsB = repo.getRecentChapters();
      expect(recentsB.isEmpty, true);
      expect(repo.getContinueLearning(), isNull);

      // User B accesses Economics
      await repo.recordChapterAccess(
        courseId: 'mit-econ-14-01',
        courseName: 'Principles of Microeconomics',
        chapterId: 'mit-econ-lec1',
        chapterName: 'Supply and Demand',
        progress: 0.2,
        completed: false,
        provider: 'MIT OpenCourseWare',
      );

      recentsB = repo.getRecentChapters();
      expect(recentsB.length, 1);
      expect(recentsB.first.courseName, 'Principles of Microeconomics');

      // Switch back to User A
      await auth.logout();
      await auth.login(email: 'devika@example.com', password: 'password123');

      recentsA = repo.getRecentChapters();
      expect(recentsA.length, 1);
      expect(recentsA.first.courseName, 'College Physics 2e');
      expect(recentsA.any((r) => r.courseName.contains('Microeconomics')), false);
    });

    test('MentorService: user-scoped state, weak topic tracking, and real learning-data message', () async {
      final auth = AuthService();
      final mentor = MentorService();

      // 1. User A with weak topic
      await auth.register(
        name: 'Farhan Khan',
        email: 'farhan@example.com',
        password: 'password123',
      );

      // Initially no activity: mentor greeting reflects starting status
      final initialMsg = mentor.generateMentorMessage();
      expect(initialMsg.contains('Farhan'), true);

      // Record a weak quiz score
      await mentor.recordEvent(
        type: LearningEventType.quizResult,
        subject: 'Mathematics',
        topic: 'Fractions and Decimals',
        score: 35.0,
      );

      expect(mentor.memory.weakTopics.length, 1);
      expect(mentor.memory.weakTopics.first.topic, 'Fractions and Decimals');

      // Mentor message dynamically references the weak topic
      final weakMsg = mentor.generateMentorMessage();
      expect(weakMsg.contains('Fractions and Decimals'), true);
      expect(weakMsg.contains('challenging') || weakMsg.contains('review'), true);

      // 2. User B logs in
      await auth.logout();
      await auth.register(
        name: 'Gita Roy',
        email: 'gita@example.com',
        password: 'password123',
      );

      // User B should NOT have Farhan's weak topic
      expect(mentor.memory.weakTopics.isEmpty, true);

      // User B completes two lessons
      await mentor.recordEvent(
        type: LearningEventType.lessonCompleted,
        subject: 'English',
        topic: 'The English Alphabet',
        score: 100.0,
      );
      await mentor.recordEvent(
        type: LearningEventType.lessonCompleted,
        subject: 'English',
        topic: 'Common Greetings & Polite Expressions',
        score: 100.0,
      );

      expect(mentor.memory.completedTopics.length, 2);
      final gitaMsg = mentor.generateMentorMessage();
      expect(gitaMsg.contains('Gita'), true);
      expect(gitaMsg.contains('2 topics') || gitaMsg.contains('mastered'), true);

      // 3. User A logs back in
      await auth.logout();
      await auth.login(email: 'farhan@example.com', password: 'password123');

      expect(mentor.profile.name, 'Farhan Khan');
      expect(mentor.memory.weakTopics.length, 1);
      expect(mentor.memory.weakTopics.first.topic, 'Fractions and Decimals');
      expect(mentor.memory.completedTopics.contains('The English Alphabet'), false);
    });

    test('ProgressService: calculates real course, subject, and overall progress', () async {
      final auth = AuthService();
      final progress = ProgressService();

      await auth.register(
        name: 'Hari Om',
        email: 'hari@example.com',
        password: 'password123',
      );

      // Initially 0% progress
      expect(progress.getCourseProgress('basic-english'), 0.0);
      expect(progress.getSubjectProgress('English'), 0.0);
      expect(progress.getTotalCompletedLessons(), 0);

      // Mark first English lesson completed
      await progress.markLessonCompleted(
        courseId: 'basic-english',
        lessonId: 'eng-1',
        courseTitle: 'Module 1: Basic English',
        lessonTitle: 'The English Alphabet',
      );

      expect(progress.isLessonCompleted('eng-1'), true);
      expect(progress.isLessonCompleted('eng-2'), false);
      expect(progress.getTotalCompletedLessons(), 1);

      final englishProgress = progress.getCourseProgress('basic-english');
      expect(englishProgress, greaterThan(0.0));
      expect(englishProgress, lessThanOrEqualTo(1.0));

      final subjectProgress = progress.getSubjectProgress('English');
      expect(subjectProgress, greaterThan(0.0));

      // Mark second English lesson completed
      await progress.markLessonCompleted(
        courseId: 'basic-english',
        lessonId: 'eng-2',
        courseTitle: 'Module 1: Basic English',
        lessonTitle: 'Common Greetings & Polite Expressions',
      );
      expect(progress.getCourseProgress('basic-english'), greaterThan(englishProgress));

      // Mark lesson incomplete
      await progress.markLessonIncomplete(
        courseId: 'basic-english',
        lessonId: 'eng-2',
      );
      expect(progress.isLessonCompleted('eng-2'), false);
      expect(progress.getCourseProgress('basic-english'), closeTo(englishProgress, 0.01));
    });
  });
}
