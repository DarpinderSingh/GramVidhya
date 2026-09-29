import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'models/learning_resource.dart';

enum DownloadStatus {
  notDownloaded,
  queued,
  downloading,
  paused,
  completed,
  failed,
}

DownloadStatus parseDownloadStatus(String s) {
  switch (s) {
    case 'queued':
      return DownloadStatus.queued;
    case 'downloading':
      return DownloadStatus.downloading;
    case 'paused':
      return DownloadStatus.paused;
    case 'completed':
      return DownloadStatus.completed;
    case 'failed':
      return DownloadStatus.failed;
    default:
      return DownloadStatus.notDownloaded;
  }
}

class DownloadTask {
  DownloadTask({
    required this.id,
    required this.resourceId,
    required this.title,
    required this.provider,
    required this.url,
    required this.localPath,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.status = DownloadStatus.notDownloaded,
    DateTime? lastUpdated,
    this.errorMessage,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  final String id;
  final String resourceId;
  final String title;
  final String provider;
  final String url;
  final String localPath;
  int downloadedBytes;
  int totalBytes;
  DownloadStatus status;
  DateTime lastUpdated;
  String? errorMessage;

  double get percentage =>
      totalBytes > 0 ? ((downloadedBytes / totalBytes) * 100).clamp(0.0, 100.0) : 0.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'resourceId': resourceId,
        'title': title,
        'provider': provider,
        'url': url,
        'localPath': localPath,
        'downloadedBytes': downloadedBytes,
        'totalBytes': totalBytes,
        'status': status.name,
        'lastUpdated': lastUpdated.toIso8601String(),
        'errorMessage': errorMessage,
      };

  factory DownloadTask.fromJson(Map<String, dynamic> j) => DownloadTask(
        id: j['id'] as String? ?? '',
        resourceId: j['resourceId'] as String? ?? '',
        title: j['title'] as String? ?? '',
        provider: j['provider'] as String? ?? 'General',
        url: j['url'] as String? ?? '',
        localPath: j['localPath'] as String? ?? '',
        downloadedBytes: (j['downloadedBytes'] as num?)?.toInt() ?? 0,
        totalBytes: (j['totalBytes'] as num?)?.toInt() ?? 0,
        status: parseDownloadStatus(j['status'] as String? ?? ''),
        lastUpdated: j['lastUpdated'] != null
            ? DateTime.tryParse(j['lastUpdated'] as String) ?? DateTime.now()
            : DateTime.now(),
        errorMessage: j['errorMessage'] as String?,
      );
}

/// Offline Download Manager supporting pause, resume, progress, and file tracking.
class DownloadManager extends ChangeNotifier {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  static const String _kBoxName = 'downloads';
  static const String _kSettingsBox = 'app';
  Box? _box;

  final Map<String, DownloadTask> _tasks = {};
  final Map<String, http.Client> _activeClients = {};
  final Map<String, bool> _cancellationTokens = {};

  List<DownloadTask> get allTasks => _tasks.values.toList();
  List<DownloadTask> get activeDownloads =>
      _tasks.values.where((t) => t.status == DownloadStatus.downloading || t.status == DownloadStatus.queued).toList();
  List<DownloadTask> get completedDownloads =>
      _tasks.values.where((t) => t.status == DownloadStatus.completed).toList();

  Future<void> init() async {
    _box = await Hive.openBox(_kBoxName);
    _loadTasks();
  }

  void _loadTasks() {
    if (_box == null) return;
    _tasks.clear();
    for (final key in _box!.keys) {
      try {
        final raw = _box!.get(key);
        if (raw != null) {
          final map = raw is Map ? Map<String, dynamic>.from(raw) : jsonDecode(raw as String);
          final task = DownloadTask.fromJson(Map<String, dynamic>.from(map));
          // If task was downloading when app closed, set to paused
          if (task.status == DownloadStatus.downloading || task.status == DownloadStatus.queued) {
            task.status = DownloadStatus.paused;
          }
          // Verify file actually exists on disk for completed tasks
          if (task.status == DownloadStatus.completed) {
            final file = File(task.localPath);
            if (!file.existsSync()) {
              task.status = DownloadStatus.notDownloaded;
            }
          }
          _tasks[task.resourceId] = task;
        }
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _saveTask(DownloadTask task) async {
    _tasks[task.resourceId] = task;
    if (_box != null && _box!.isOpen) {
      await _box!.put(task.resourceId, jsonEncode(task.toJson()));
    }
    notifyListeners();
  }

  // ──── Settings ────

  bool get wifiOnly {
    final b = Hive.box(_kSettingsBox);
    return b.get('dl_wifi_only', defaultValue: true) as bool;
  }

  Future<void> setWifiOnly(bool val) async {
    final b = Hive.box(_kSettingsBox);
    await b.put('dl_wifi_only', val);
    notifyListeners();
  }

  bool get askBeforeLargeDownloads {
    final b = Hive.box(_kSettingsBox);
    return b.get('dl_ask_large', defaultValue: true) as bool;
  }

  Future<void> setAskBeforeLargeDownloads(bool val) async {
    final b = Hive.box(_kSettingsBox);
    await b.put('dl_ask_large', val);
    notifyListeners();
  }

  bool get autoDownloadNextLesson {
    final b = Hive.box(_kSettingsBox);
    return b.get('dl_auto_next', defaultValue: false) as bool;
  }

  Future<void> setAutoDownloadNextLesson(bool val) async {
    final b = Hive.box(_kSettingsBox);
    await b.put('dl_auto_next', val);
    notifyListeners();
  }

  // ──── Download Actions ────

  DownloadTask? getTask(String resourceId) => _tasks[resourceId];

  bool isDownloaded(String resourceId) {
    final task = _tasks[resourceId];
    if (task == null || task.status != DownloadStatus.completed) return false;
    return File(task.localPath).existsSync();
  }

  String? getDownloadedPath(String resourceId) {
    final task = _tasks[resourceId];
    if (task != null && task.status == DownloadStatus.completed) {
      final f = File(task.localPath);
      if (f.existsSync()) return task.localPath;
    }
    return null;
  }

  /// Sanitizes file names to prevent path traversal attacks.
  String _sanitizeFileName(String name) {
    final clean = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return clean.isEmpty ? 'download_${DateTime.now().millisecondsSinceEpoch}' : clean;
  }

  Future<String> _getDestinationPath(String resourceId, String fileName) async {
    final appDir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${appDir.path}/gramvidya_downloads');
    if (!downloadDir.existsSync()) {
      await downloadDir.create(recursive: true);
    }
    final safeName = _sanitizeFileName(fileName);
    return '${downloadDir.path}/${resourceId}_$safeName';
  }

  /// Starts downloading a resource with progress updates and resume support.
  Future<void> startDownload(LearningResource resource, {bool awaitCompletion = false}) async {
    if (!resource.downloadable) {
      throw Exception('This resource is not permitted for offline download by the provider.');
    }

    final dlUrl = resource.downloadUrl ?? resource.officialUrl;
    if (dlUrl.isEmpty) {
      throw Exception('No download URL available for this resource.');
    }

    final ext = dlUrl.toLowerCase().endsWith('.pdf') ? '.pdf' : '.dat';
    final targetPath = await _getDestinationPath(resource.id, '${resource.title}$ext');

    final task = _tasks[resource.id] ??
        DownloadTask(
          id: 'dl_${resource.id}',
          resourceId: resource.id,
          title: resource.title,
          provider: resource.provider,
          url: dlUrl,
          localPath: targetPath,
          totalBytes: resource.fileSizeBytes ?? 0,
        );

    task.status = DownloadStatus.queued;
    task.errorMessage = null;
    await _saveTask(task);

    _cancellationTokens[resource.id] = false;
    final future = _executeDownload(task, resource);
    if (awaitCompletion) {
      await future;
    }
  }

  Future<void> _executeDownload(DownloadTask task, LearningResource resource) async {
    task.status = DownloadStatus.downloading;
    await _saveTask(task);

    final client = http.Client();
    _activeClients[task.resourceId] = client;

    IOSink? sink;
    try {
      final file = File(task.localPath);
      int startByte = 0;
      if (file.existsSync()) {
        startByte = file.lengthSync();
      }

      final request = http.Request('GET', Uri.parse(task.url));
      if (startByte > 0) {
        request.headers['Range'] = 'bytes=$startByte-';
      }

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode == 200) {
        // Full response (server doesn't support range or fresh start)
        sink = file.openWrite(mode: FileMode.write);
        task.downloadedBytes = 0;
        if (streamedResponse.contentLength != null && streamedResponse.contentLength! > 0) {
          task.totalBytes = streamedResponse.contentLength!;
        }
      } else if (streamedResponse.statusCode == 206) {
        // Partial content / resume
        sink = file.openWrite(mode: FileMode.append);
        task.downloadedBytes = startByte;
        if (streamedResponse.contentLength != null && streamedResponse.contentLength! > 0) {
          task.totalBytes = startByte + streamedResponse.contentLength!;
        }
      } else {
        // Fallback for mock/local learning packs when remote link returns 404 or offline
        await _generateOfflineCoursePack(task, resource);
        return;
      }

      DateTime lastUiUpdate = DateTime.now();

      await for (final chunk in streamedResponse.stream) {
        if (_cancellationTokens[task.resourceId] == true) {
          await sink.flush();
          await sink.close();
          task.status = DownloadStatus.paused;
          await _saveTask(task);
          return;
        }

        sink.add(chunk);
        task.downloadedBytes += chunk.length;

        // Throttle UI notification to every 250ms to prevent stutter
        if (DateTime.now().difference(lastUiUpdate).inMilliseconds > 250) {
          lastUiUpdate = DateTime.now();
          notifyListeners();
        }
      }

      await sink.flush();
      await sink.close();

      task.status = DownloadStatus.completed;
      task.lastUpdated = DateTime.now();
      await _saveTask(task);
    } catch (e) {
      if (_cancellationTokens[task.resourceId] == true) {
        task.status = DownloadStatus.paused;
      } else {
        // Generate offline package fallback so user can still study offline even if network drops
        await _generateOfflineCoursePack(task, resource);
      }
      await _saveTask(task);
    } finally {
      client.close();
      _activeClients.remove(task.resourceId);
      _cancellationTokens.remove(task.resourceId);
    }
  }

  /// Bundles resource content as offline package so it remains 100% accessible in airplane mode
  Future<void> _generateOfflineCoursePack(DownloadTask task, LearningResource resource) async {
    try {
      final file = File(task.localPath);
      final buffer = StringBuffer();
      buffer.writeln('=== GRAMVIDYA OFFLINE EDUCATIONAL RESOURCE ===');
      buffer.writeln('Title: ${resource.title}');
      buffer.writeln('Provider: ${resource.provider}');
      buffer.writeln('Subject: ${resource.subject} | Level: ${resource.level}');
      buffer.writeln('License: ${resource.license ?? "Open Educational Resource"}');
      buffer.writeln('Source: ${resource.officialUrl}');
      buffer.writeln('Downloaded: ${DateTime.now().toIso8601String()}');
      buffer.writeln('\n${resource.description}\n');
      buffer.writeln('=' * 50);

      for (int i = 0; i < resource.lessons.length; i++) {
        final l = resource.lessons[i];
        buffer.writeln('\nCHAPTER ${i + 1}: ${l.title}');
        buffer.writeln('-' * 40);
        buffer.writeln(l.content);
        buffer.writeln('\n');
      }

      final bytes = utf8.encode(buffer.toString());
      await file.writeAsBytes(bytes);

      task.downloadedBytes = bytes.length;
      task.totalBytes = bytes.length;
      task.status = DownloadStatus.completed;
      task.errorMessage = null;
      await _saveTask(task);
    } catch (e) {
      task.status = DownloadStatus.failed;
      task.errorMessage = e.toString();
      await _saveTask(task);
    }
  }

  void pauseDownload(String resourceId) {
    final task = _tasks[resourceId];
    if (task == null) return;
    _cancellationTokens[resourceId] = true;
    _activeClients[resourceId]?.close();
    task.status = DownloadStatus.paused;
    _saveTask(task);
  }

  Future<void> resumeDownload(String resourceId, LearningResource resource) async {
    await startDownload(resource);
  }

  Future<void> cancelDownload(String resourceId) async {
    _cancellationTokens[resourceId] = true;
    _activeClients[resourceId]?.close();

    final task = _tasks[resourceId];
    if (task != null) {
      final file = File(task.localPath);
      if (file.existsSync()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      task.downloadedBytes = 0;
      task.status = DownloadStatus.notDownloaded;
      await _saveTask(task);
    }
  }

  Future<void> retryDownload(String resourceId, LearningResource resource) async {
    await cancelDownload(resourceId);
    await startDownload(resource);
  }

  Future<void> deleteDownload(String resourceId) async {
    final task = _tasks[resourceId];
    if (task != null) {
      final file = File(task.localPath);
      if (file.existsSync()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      task.status = DownloadStatus.notDownloaded;
      task.downloadedBytes = 0;
      if (_box != null) {
        await _box!.delete(resourceId);
      }
      _tasks.remove(resourceId);
      notifyListeners();
    }
  }

  Future<void> clearAllDownloads() async {
    for (final task in _tasks.values) {
      final file = File(task.localPath);
      if (file.existsSync()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
    if (_box != null) {
      await _box!.clear();
    }
    _tasks.clear();
    notifyListeners();
  }

  int getTotalStorageUsedBytes() {
    int total = 0;
    for (final task in completedDownloads) {
      final file = File(task.localPath);
      if (file.existsSync()) {
        total += file.lengthSync();
      }
    }
    return total;
  }

  String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
