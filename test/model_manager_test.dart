import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gramvidya/ai/model_manager.dart';
import 'package:gramvidya/ai/inference_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('gramvidya_test_');
    Hive.init(tempDir.path);
    await Hive.openBox('app');
  });

  group('ModelManager & AI Inference Architecture Tests', () {
    test('Initial ModelManager state defaults to notInstalled when no model file exists', () async {
      final mgr = ModelManager.instance;
      await mgr.init();

      expect(mgr.status, equals(ModelStatus.notInstalled));
      expect(mgr.isReady, isFalse);
      expect(mgr.isDownloading, isFalse);
      expect(mgr.progress, equals(0.0));
      expect(mgr.downloadedBytes, equals(0));
    });

    test('InferenceController falls back gracefully when model is not installed', () async {
      final ai = InferenceController();
      await ai.init();

      expect(ai.isModelReady, isFalse);
      expect(ai.active.name, contains('Not Installed'));

      final stream = ai.ask('What is photosynthesis?');
      final output = (await stream.toList()).join();

      expect(output.isNotEmpty, isTrue);
      expect(output, contains('installed'));
    });

    test('ModelManager handles deletion cleanly without touching app storage', () async {
      final mgr = ModelManager.instance;
      await mgr.deleteModel();

      expect(mgr.status, equals(ModelStatus.notInstalled));
      expect(mgr.progress, equals(0.0));
      expect(mgr.downloadedBytes, equals(0));
    });

    test('ModelManager pause and cancel state transitions', () {
      final mgr = ModelManager.instance;
      mgr.pauseDownload();
      // If not downloading, pause is no-op
      expect(mgr.status, equals(ModelStatus.notInstalled));

      mgr.cancelDownload();
      expect(mgr.status, equals(ModelStatus.notInstalled));
    });
  });
}
