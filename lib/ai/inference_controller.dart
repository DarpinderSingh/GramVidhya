import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:llamadart/llamadart.dart' as llama;
import 'model_manager.dart';
import 'rag.dart';

abstract class LlmBackend {
  String get name;
  Future<bool> available();
  Stream<String> generate(String system, String prompt, {String context = ''});
}

/// Dedicated Offline AI Service managing local GGUF model loading and on-device inference.
class LocalLLMService {
  static final LocalLLMService instance = LocalLLMService._();
  LocalLLMService._();

  static const _androidMethodChannel = MethodChannel('gramvidya/llama');
  static const _androidEventChannel = EventChannel('gramvidya/llama/tokens');

  llama.LlamaEngine? _engine;
  String? _loadedPath;
  bool _isLoading = false;
  bool _isLoaded = false;
  String? _lastError;

  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  String? get loadedPath => _loadedPath;

  /// Loads the GGUF model file into native inference backend memory.
  Future<bool> loadModel(String modelPath) async {
    final file = File(modelPath);
    final exists = await file.exists();
    final size = exists ? await file.length() : 0;

    if (kDebugMode) {
      print('[LOCAL_AI] Model path: $modelPath');
      print('[LOCAL_AI] Model exists: $exists');
      print('[LOCAL_AI] Model size: ${(size / (1024 * 1024)).toStringAsFixed(1)} MB');
    }

    if (!exists || size < 10000000) {
      _isLoaded = false;
      _lastError = 'Model file does not exist or is incomplete (< 10MB)';
      if (kDebugMode) {
        print('[LOCAL_AI] Model error: $_lastError');
      }
      return false;
    }

    _isLoading = true;
    _lastError = null;

    try {
      if (kDebugMode) {
        print('[LOCAL_AI] Loading model...');
      }

      // 1. If on Android, attempt Android native JNI registration if available
      if (Platform.isAndroid) {
        try {
          final isLoaded = await _androidMethodChannel.invokeMethod<bool>('isModelLoaded', {'path': modelPath}) ?? false;
          if (isLoaded) {
            _loadedPath = modelPath;
            _isLoaded = true;
            _isLoading = false;
            if (kDebugMode) {
              print('[LOCAL_AI] Model loaded successfully via Android native JNI');
            }
            return true;
          }
        } catch (_) {}
      }

      // 2. Initialize native llamadart engine
      _engine?.dispose();
      _engine = null;

      final backend = llama.LlamaBackend();
      final engine = llama.LlamaEngine(backend);
      await engine.loadModel(
        modelPath,
        modelParams: const llama.ModelParams(contextSize: 2048),
      );

      _engine = engine;
      _loadedPath = modelPath;
      _isLoaded = true;
      _isLoading = false;

      if (kDebugMode) {
        print('[LOCAL_AI] Model loaded successfully');
      }
      return true;
    } catch (e, stack) {
      _isLoaded = false;
      _isLoading = false;
      _lastError = e.toString();
      if (kDebugMode) {
        print('[LOCAL_AI] Model error: $e');
        print(stack);
      }
      return false;
    }
  }

  /// Streams token-by-token generation from the loaded local LLM.
  Stream<String> generate(String systemPrompt, String userPrompt, {String context = ''}) async* {
    if (kDebugMode) {
      print('[LOCAL_AI] Starting inference');
      print('[LOCAL_AI] User prompt: $userPrompt');
    }

    // Ensure model is loaded
    if (!_isLoaded || (_engine == null && !Platform.isAndroid)) {
      final mgrPath = ModelManager.instance.localModelPath;
      if (mgrPath != null) {
        final ok = await loadModel(mgrPath);
        if (!ok || (_engine == null && !Platform.isAndroid)) {
          throw Exception(_lastError ?? 'Offline AI model is not loaded');
        }
      } else {
        throw Exception('Offline AI model is not installed');
      }
    }

    // Format prompt using standard ChatML / Qwen format
    final buffer = StringBuffer();
    buffer.write('<|im_start|>system\n');
    buffer.write(systemPrompt);
    if (context.trim().isNotEmpty) {
      buffer.write('\n\nReference Material:\n');
      buffer.write(context.trim());
    }
    buffer.write('<|im_end|>\n<|im_start|>user\n');
    buffer.write(userPrompt.trim());
    buffer.write('<|im_end|>\n<|im_start|>assistant\n');

    final formattedPrompt = buffer.toString();
    int tokenCount = 0;

    // 1. Android EventChannel path if active
    if (Platform.isAndroid) {
      try {
        final isLoaded = await _androidMethodChannel.invokeMethod<bool>('isModelLoaded', {'path': _loadedPath}) ?? false;
        if (isLoaded) {
          final stream = _androidEventChannel.receiveBroadcastStream({
            'system': systemPrompt,
            'prompt': userPrompt,
            'modelPath': _loadedPath,
          }).cast<String>();

          await for (final token in stream) {
            tokenCount++;
            yield token;
          }

          if (kDebugMode) {
            print('[LOCAL_AI] Tokens generated: $tokenCount');
            print('[LOCAL_AI] Generation completed');
          }
          return;
        }
      } catch (_) {}
    }

    // 2. Direct llamadart engine streaming
    if (_engine == null) {
      throw Exception(_lastError ?? 'Inference engine not initialized');
    }

    try {
      final stream = _engine!.generate(
        formattedPrompt,
        params: const llama.GenerationParams(
          temp: 0.7,
          topK: 40,
          topP: 0.9,
        ),
      );

      await for (final token in stream) {
        tokenCount++;
        yield token;
      }

      if (kDebugMode) {
        print('[LOCAL_AI] Tokens generated: $tokenCount');
        print('[LOCAL_AI] Generation completed');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('[LOCAL_AI] Model error during generation: $e');
        print(stack);
      }
      rethrow;
    }
  }

  void dispose() {
    _engine?.dispose();
    _engine = null;
    _isLoaded = false;
    _loadedPath = null;
  }
}

/// On-Device GGUF inference backend wrapping LocalLLMService.
class OnDeviceGgufBackend implements LlmBackend {
  @override
  String get name => 'GramVidhya AI (On-Device GGUF)';

  @override
  Future<bool> available() async {
    final mgr = ModelManager.instance;
    return mgr.isReady && LocalLLMService.instance.isLoaded;
  }

  @override
  Stream<String> generate(String system, String prompt, {String context = ''}) =>
      LocalLLMService.instance.generate(system, prompt, context: context);

  void dispose() {
    LocalLLMService.instance.dispose();
  }
}

/// Desktop backend: talks to local Ollama daemon if running.
class OllamaBackend implements LlmBackend {
  OllamaBackend({String? model, this.host = 'http://127.0.0.1:11434'})
      : model = model ?? Platform.environment['GRAMVIDYA_OLLAMA_MODEL'] ?? 'qwen2.5:3b';
  final String host, model;

  @override
  String get name => 'GramVidya AI (Ollama Local)';

  @override
  Future<bool> available() async {
    try {
      final r = await http.get(Uri.parse('$host/api/tags')).timeout(const Duration(seconds: 1));
      return r.statusCode == 200 && r.body.contains(model.split(':').first);
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<String> generate(String system, String prompt, {String context = ''}) async* {
    final req = http.Request('POST', Uri.parse('$host/api/chat'))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'model': model,
        'stream': true,
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': prompt},
        ],
      });
    final res = await http.Client().send(req);
    await for (final line in res.stream.transform(utf8.decoder).transform(const LineSplitter())) {
      if (line.trim().isEmpty) continue;
      final j = jsonDecode(line);
      final c = j['message']?['content'];
      if (c is String) yield c;
      if (j['done'] == true) break;
    }
  }
}

/// Fallback backend when offline model is not installed.
class OfflineFallbackBackend implements LlmBackend {
  @override
  String get name => 'Offline AI Not Installed';

  @override
  Future<bool> available() async => true;

  @override
  Stream<String> generate(String system, String prompt, {String context = ''}) async* {
    const msg = 'The on-device offline AI model is not currently installed.\n\n'
        'Please tap "Download Offline AI" to install the ~350 MB model and ask questions completely offline with full AI generation.';
    for (final word in msg.split(' ')) {
      await Future.delayed(const Duration(milliseconds: 20));
      yield '$word ';
    }
  }
}

class InferenceController extends ChangeNotifier {
  final rag = Rag();
  final modelManager = ModelManager.instance;
  final _onDeviceGguf = OnDeviceGgufBackend();
  final _ollama = OllamaBackend();
  final _fallback = OfflineFallbackBackend();

  late LlmBackend active = _fallback;

  Future<void> init() async {
    await rag.load();
    await modelManager.init();
    modelManager.addListener(_onModelManagerChanged);
    await refresh();
  }

  void _onModelManagerChanged() {
    refresh();
  }

  Future<void> refresh() async {
    if (await _onDeviceGguf.available()) {
      active = _onDeviceGguf;
    } else if (await _ollama.available()) {
      active = _ollama;
    } else {
      active = _fallback;
    }
    notifyListeners();
  }

  bool get isModelReady => modelManager.isReady && LocalLLMService.instance.isLoaded;
  bool get isModelDownloading => modelManager.isDownloading;
  bool get isModelLoading => modelManager.isLoading || LocalLLMService.instance.isLoading;
  bool get isModelNotInstalled => modelManager.isNotInstalled;
  bool get isModelPaused => modelManager.isPaused;

  Stream<String> ask(String q) async* {
    // Only search RAG if strictly relevant (high threshold)
    final hits = rag.search(q, k: 2, minScore: 2.5);
    final ctx = hits.map((c) => c.text).join('\n');

    const sys = 'You are GramVidhya AI, an expert educational tutor. '
        'Answer the student\'s question clearly, accurately, and step-by-step in the requested language. '
        'Provide helpful explanations, key concepts, and practical examples where appropriate.';

    try {
      yield* active.generate(sys, q, context: ctx);
    } catch (e) {
      if (kDebugMode) {
        print('[LOCAL_AI] InferenceController catch: $e');
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    modelManager.removeListener(_onModelManagerChanged);
    _onDeviceGguf.dispose();
    super.dispose();
  }
}
