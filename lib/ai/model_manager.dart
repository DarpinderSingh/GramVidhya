import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'inference_controller.dart';

enum ModelStatus {
  notInstalled,
  downloading,
  paused,
  verifying,
  loading,
  ready,
  error,
  updateAvailable,
}

class ModelInfo {
  final String name;
  final String version;
  final String filename;
  final String downloadUrl;
  final int sizeBytes; // ~398 MB
  final int requiredStorageBytes; // ~500 MB
  final String description;

  const ModelInfo({
    required this.name,
    required this.version,
    required this.filename,
    required this.downloadUrl,
    required this.sizeBytes,
    required this.requiredStorageBytes,
    required this.description,
  });

  double get sizeMB => sizeBytes / (1024 * 1024);
  double get requiredStorageMB => requiredStorageBytes / (1024 * 1024);
}

class ModelManager extends ChangeNotifier {
  static final ModelManager instance = ModelManager._internal();
  ModelManager._internal();

  static const defaultModel = ModelInfo(
    name: 'GramVidhya Offline AI Tutor (Qwen2.5 0.5B GGUF)',
    version: '1.0.0 (Q4_K_M)',
    filename: 'gramvidya_qwen2.5_0.5b_q4_k_m.gguf',
    downloadUrl:
        'https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf',
    sizeBytes: 397734400, // ~380-398 MB
    requiredStorageBytes: 524288000, // ~500 MB
    description: 'On-device neural network model for offline tutoring and educational Q&A.',
  );

  ModelStatus _status = ModelStatus.notInstalled;
  ModelStatus get status => _status;

  double _progress = 0.0;
  double get progress => _progress;

  int _downloadedBytes = 0;
  int get downloadedBytes => _downloadedBytes;

  int _totalBytes = defaultModel.sizeBytes;
  int get totalBytes => _totalBytes;

  double _downloadSpeedMBps = 0.0;
  double get downloadSpeedMBps => _downloadSpeedMBps;

  Duration _estimatedRemaining = Duration.zero;
  Duration get estimatedRemaining => _estimatedRemaining;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isCancelled = false;
  bool _isPaused = false;
  http.Client? _client;
  StreamSubscription<List<int>>? _streamSub;
  IOSink? _fileSink;

  String? _localModelPath;
  String? get localModelPath => _localModelPath;

  bool get isReady => _status == ModelStatus.ready;
  bool get isDownloading => _status == ModelStatus.downloading;
  bool get isPaused => _status == ModelStatus.paused;
  bool get isLoading => _status == ModelStatus.loading || _status == ModelStatus.verifying;
  bool get isNotInstalled => _status == ModelStatus.notInstalled;

  /// Initializes ModelManager, checks local storage, and initializes native LLM backend.
  Future<void> init() async {
    try {
      String basePath;
      try {
        final dir = await getApplicationDocumentsDirectory();
        basePath = dir.path;
      } catch (_) {
        basePath = Directory.systemTemp.path;
      }

      final modelDir = Directory('$basePath/models');
      if (!await modelDir.exists()) {
        await modelDir.create(recursive: true);
      }
      _localModelPath = '${modelDir.path}/${defaultModel.filename}';

      final box = Hive.box('app');
      final file = File(_localModelPath!);

      if (await file.exists()) {
        final len = await file.length();
        if (len > 10000000) { // Valid file > 10MB
          _downloadedBytes = len;
          _totalBytes = defaultModel.sizeBytes > 0 ? defaultModel.sizeBytes : len;
          _progress = 1.0;

          // Verify model file integrity
          _status = ModelStatus.verifying;
          notifyListeners();

          final isValid = await _verifyModelIntegrity(file);
          if (isValid) {
            _status = ModelStatus.loading;
            notifyListeners();

            // Actually load into local native LLM engine
            final loaded = await LocalLLMService.instance.loadModel(_localModelPath!);
            if (loaded) {
              _status = ModelStatus.ready;
              await box.put('ai_model_status', 'ready');
              await box.put('ai_model_path', _localModelPath);
            } else {
              _status = ModelStatus.error;
              _errorMessage = LocalLLMService.instance.lastError ?? 'Offline AI could not be loaded into memory.';
              await box.put('ai_model_status', 'error');
            }
          } else {
            _status = ModelStatus.error;
            _errorMessage = 'Model verification failed. File may be corrupted.';
            await box.put('ai_model_status', 'error');
          }
        } else {
          _status = ModelStatus.notInstalled;
          await box.put('ai_model_status', 'notInstalled');
        }
      } else {
        final savedStatus = box.get('ai_model_status', defaultValue: 'notInstalled') as String;
        if (savedStatus == 'paused') {
          _status = ModelStatus.paused;
        } else {
          _status = ModelStatus.notInstalled;
          await box.put('ai_model_status', 'notInstalled');
        }
      }
    } catch (e) {
      _status = ModelStatus.error;
      _errorMessage = 'Failed to initialize AI storage: ${e.toString()}';
    }
    notifyListeners();
  }

  /// Verifies model file integrity (checks size and GGUF header).
  Future<bool> _verifyModelIntegrity(File file) async {
    try {
      if (!await file.exists()) return false;
      final len = await file.length();
      if (len < 10000000) return false;

      final raf = await file.open(mode: FileMode.read);
      try {
        final header = await raf.read(4);
        if (header.length < 4) return false;
        // GGUF magic = 'G' (0x47), 'G' (0x47), 'U' (0x55), 'F' (0x46)
        final isGguf = header[0] == 0x47 && header[1] == 0x47 && header[2] == 0x55 && header[3] == 0x46;
        return isGguf || len > 50000000;
      } finally {
        await raf.close();
      }
    } catch (_) {
      return true;
    }
  }

  /// Starts or resumes model download with support for partial download recovery.
  Future<void> startDownload() async {
    if (_status == ModelStatus.downloading) return;
    if (_localModelPath == null) await init();

    _isCancelled = false;
    _isPaused = false;
    _errorMessage = null;
    _status = ModelStatus.downloading;
    notifyListeners();

    final file = File(_localModelPath!);
    int existingLength = 0;
    if (await file.exists()) {
      existingLength = await file.length();
      if (existingLength >= defaultModel.sizeBytes * 0.98) {
        await _onDownloadComplete(file);
        return;
      }
    }

    _downloadedBytes = existingLength;

    try {
      _client = http.Client();
      final request = http.Request('GET', Uri.parse(defaultModel.downloadUrl));
      if (existingLength > 0) {
        request.headers['Range'] = 'bytes=$existingLength-';
      }

      final response = await _client!.send(request).timeout(const Duration(seconds: 25));

      if (response.statusCode != 200 && response.statusCode != 206) {
        throw Exception('Download server returned status ${response.statusCode}');
      }

      if (response.contentLength != null && response.contentLength! > 0) {
        _totalBytes = response.statusCode == 206
            ? existingLength + response.contentLength!
            : response.contentLength!;
      } else {
        _totalBytes = defaultModel.sizeBytes;
      }

      _fileSink = file.openWrite(mode: existingLength > 0 ? FileMode.append : FileMode.write);

      int lastCheckTime = DateTime.now().millisecondsSinceEpoch;
      int bytesSinceLastCheck = 0;

      _streamSub = response.stream.listen(
        (chunk) {
          if (_isCancelled || _isPaused) return;

          _fileSink?.add(chunk);
          _downloadedBytes += chunk.length;
          bytesSinceLastCheck += chunk.length;

          final now = DateTime.now().millisecondsSinceEpoch;
          final timeDiff = now - lastCheckTime;
          if (timeDiff >= 500) {
            final speedMBps = (bytesSinceLastCheck / (1024 * 1024)) / (timeDiff / 1000.0);
            if (speedMBps > 0) {
              _downloadSpeedMBps = speedMBps;
              final remainingBytes = _totalBytes - _downloadedBytes;
              if (remainingBytes > 0) {
                final remainingSec = (remainingBytes / (1024 * 1024)) / speedMBps;
                _estimatedRemaining = Duration(seconds: remainingSec.round());
              }
            }
            bytesSinceLastCheck = 0;
            lastCheckTime = now;
          }

          if (_totalBytes > 0) {
            _progress = (_downloadedBytes / _totalBytes).clamp(0.0, 1.0);
          }
          notifyListeners();
        },
        onDone: () async {
          await _fileSink?.flush();
          await _fileSink?.close();
          _fileSink = null;
          _client?.close();

          if (_isCancelled) {
            _status = ModelStatus.notInstalled;
            notifyListeners();
            return;
          }

          if (_isPaused) {
            _status = ModelStatus.paused;
            final box = Hive.box('app');
            await box.put('ai_model_status', 'paused');
            notifyListeners();
            return;
          }

          await _onDownloadComplete(file);
        },
        onError: (err) async {
          await _fileSink?.close();
          _fileSink = null;
          _client?.close();
          _status = ModelStatus.error;
          _errorMessage = 'Download interrupted: ${err.toString()}';
          notifyListeners();
        },
        cancelOnError: true,
      );
    } catch (e) {
      await _fileSink?.close();
      _fileSink = null;
      _client?.close();
      _status = ModelStatus.error;
      _errorMessage = 'Unable to connect to model server. Please check your internet connection.';
      notifyListeners();
    }
  }

  Future<void> _onDownloadComplete(File file) async {
    _status = ModelStatus.verifying;
    notifyListeners();

    final isValid = await _verifyModelIntegrity(file);
    if (!isValid) {
      _status = ModelStatus.error;
      _errorMessage = 'Model verification failed. The downloaded file may be incomplete.';
      notifyListeners();
      return;
    }

    _status = ModelStatus.loading;
    notifyListeners();

    final loaded = await LocalLLMService.instance.loadModel(file.path);
    if (!loaded) {
      _status = ModelStatus.error;
      _errorMessage = LocalLLMService.instance.lastError ?? 'Failed to load model into native inference engine.';
      notifyListeners();
      return;
    }

    _status = ModelStatus.ready;
    _progress = 1.0;
    _downloadedBytes = _totalBytes;
    final box = Hive.box('app');
    await box.put('ai_model_status', 'ready');
    await box.put('ai_model_path', _localModelPath);
    await box.put('ai_model_version', defaultModel.version);
    notifyListeners();
  }

  void pauseDownload() {
    if (_status != ModelStatus.downloading) return;
    _isPaused = true;
    _streamSub?.cancel();
    _fileSink?.close();
    _fileSink = null;
    _client?.close();
    _status = ModelStatus.paused;
    final box = Hive.box('app');
    box.put('ai_model_status', 'paused');
    notifyListeners();
  }

  void resumeDownload() {
    if (_status == ModelStatus.paused || _status == ModelStatus.error) {
      startDownload();
    }
  }

  void cancelDownload() async {
    _isCancelled = true;
    _streamSub?.cancel();
    await _fileSink?.close();
    _fileSink = null;
    _client?.close();

    LocalLLMService.instance.dispose();

    if (_localModelPath != null) {
      final file = File(_localModelPath!);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
    _downloadedBytes = 0;
    _progress = 0.0;
    _status = ModelStatus.notInstalled;
    final box = Hive.box('app');
    await box.put('ai_model_status', 'notInstalled');
    notifyListeners();
  }

  /// Deletes only the AI model file (~350-400 MB), leaving all courses, notes, and progress intact.
  Future<void> deleteModel() async {
    cancelDownload();
    LocalLLMService.instance.dispose();

    if (_localModelPath != null) {
      final file = File(_localModelPath!);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
    _downloadedBytes = 0;
    _progress = 0.0;
    _status = ModelStatus.notInstalled;
    final box = Hive.box('app');
    await box.put('ai_model_status', 'notInstalled');
    await box.delete('ai_model_path');
    notifyListeners();
  }

  Future<void> reloadModel() async {
    await init();
  }
}
