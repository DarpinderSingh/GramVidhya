import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gramvidya/data/content_repository.dart';
import 'package:gramvidya/data/download_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Educational Content & Offline Learning Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('gv_edu_test_');

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
      await DownloadManager().init();
    });

    tearDown(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        try {
          await tempDir.delete(recursive: true);
        } catch (_) {}
      }
    });

    test('All providers load authentic educational resources with strict attribution', () async {
      final repo = ContentRepository();
      final resources = await repo.getAllResources();

      expect(resources.isNotEmpty, true);

      // Verify legitimate providers are present in the resources
      final providerNames = resources.map((r) => r.provider).join(' ');
      expect(providerNames.contains('NPTEL'), true);
      expect(providerNames.contains('OpenStax'), true);
      expect(providerNames.contains('MIT OpenCourseWare'), true);
      expect(providerNames.contains('Khan Academy'), true);
      expect(providerNames.contains('SWAYAM'), true);
      expect(providerNames.contains('YouTube'), true);

      for (final r in resources) {
        // Strict metadata requirements
        expect(r.id.isNotEmpty, true);
        expect(r.title.isNotEmpty, true);
        expect(r.provider.isNotEmpty, true);
        expect(r.officialUrl.startsWith('http'), true);
        expect(r.lessons.isNotEmpty, true);
        expect(r.retrievedAt, isNotNull);

        // YouTube must never be marked downloadable
        if (r.provider.contains('YouTube')) {
          expect(r.downloadable, false);
        }
      }
    });

    test('Search and multi-criteria filters operate correctly', () async {
      final repo = ContentRepository();

      // Search by title/subject
      final mlResults = await repo.searchResources(query: 'Machine Learning');
      expect(mlResults.any((r) => r.title.contains('Machine Learning')), true);

      // Filter by provider
      final nptelOnly = await repo.searchResources(provider: 'NPTEL');
      expect(nptelOnly.isNotEmpty, true);
      expect(nptelOnly.every((r) => r.provider.contains('NPTEL')), true);

      // Filter by downloadable only
      final downloadableOnly = await repo.searchResources(downloadableOnly: true);
      expect(downloadableOnly.every((r) => r.downloadable), true);
    });

    test('Continue Learning and Dynamic Recent Chapters track user activity', () async {
      final repo = ContentRepository();

      // Initially no recent activity
      var recents = repo.getRecentChapters();
      expect(recents.isEmpty, true);

      // User studies Machine Learning Chapter 1
      await repo.recordChapterAccess(
        courseId: 'nptel-ml-106106198',
        courseName: 'Introduction to Machine Learning',
        chapterId: 'nptel-ml-ch1',
        chapterName: 'Introduction & Supervised Learning Overview',
        progress: 0.5,
        completed: false,
        provider: 'NPTEL',
      );

      // Check recent chapters
      recents = repo.getRecentChapters();
      expect(recents.length, 1);
      expect(recents.first.courseName, 'Introduction to Machine Learning');
      expect(recents.first.chapterName, 'Introduction & Supervised Learning Overview');
      expect(recents.first.progress, 0.5);

      // Check Continue Learning top item
      final continueItem = repo.getContinueLearning();
      expect(continueItem, isNotNull);
      expect(continueItem!.chapterName, 'Introduction & Supervised Learning Overview');

      // User accesses another chapter in Physics
      await repo.recordChapterAccess(
        courseId: 'openstax-physics-2e',
        courseName: 'College Physics 2e',
        chapterId: 'openstax-phys-ch1',
        chapterName: 'Introduction: The Nature of Science and Physics',
        progress: 1.0,
        completed: true,
        provider: 'OpenStax',
      );

      recents = repo.getRecentChapters();
      expect(recents.length, 2);
      // Most recently accessed is Physics
      expect(recents.first.courseName, 'College Physics 2e');
    });

    test('DownloadManager handles download lifecycle, offline storage, and deletion', () async {
      final dm = DownloadManager();
      final repo = ContentRepository();

      final resource = (await repo.getAllResources()).firstWhere((r) => r.id == 'openstax-physics-2e');

      // Enqueue download
      await dm.startDownload(resource, awaitCompletion: true);
      final task = dm.getTask(resource.id);
      expect(task, isNotNull);
      expect(task!.status, DownloadStatus.completed);
      expect(task.localPath.isNotEmpty, true);

      // File exists on disk
      final file = File(task.localPath);
      expect(file.existsSync(), true);
      expect(file.lengthSync(), greaterThan(0));

      // Check download status lookup
      expect(dm.isDownloaded(resource.id), true);

      // Check storage calculation
      final usedBytes = dm.getTotalStorageUsedBytes();
      expect(usedBytes, greaterThan(0));

      // Test deletion
      await dm.deleteDownload(resource.id);
      expect(dm.isDownloaded(resource.id), false);
      expect(file.existsSync(), false);
    });

    test('Download settings persistence', () async {
      final dm = DownloadManager();

      expect(dm.wifiOnly, true); // Default is Wi-Fi only ON per requirement
      await dm.setWifiOnly(false);
      expect(dm.wifiOnly, false);

      expect(dm.askBeforeLargeDownloads, true);
      await dm.setAskBeforeLargeDownloads(false);
      expect(dm.askBeforeLargeDownloads, false);

      expect(dm.autoDownloadNextLesson, false);
      await dm.setAutoDownloadNextLesson(true);
      expect(dm.autoDownloadNextLesson, true);
    });
  });
}
