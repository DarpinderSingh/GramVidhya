import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../core/i18n.dart';
import 'rag.dart';

abstract class LlmBackend {
  String get name;
  Future<bool> available();
  Stream<String> generate(String system, String prompt, {String context = ''});
}

/// Desktop backend: talks to a local Ollama daemon. No internet needed once the model is pulled.
class OllamaBackend implements LlmBackend {
  OllamaBackend({String? model, this.host = 'http://127.0.0.1:11434'})
      : model = model ?? Platform.environment['GRAMVIDYA_OLLAMA_MODEL'] ?? 'qwen2.5:3b';
  final String host, model;
  @override
  String get name => 'GramVidya AI (Offline)';
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

  Future<void> pullModel() async {
    final req = http.Request('POST', Uri.parse('$host/api/pull'))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({'name': model});
    final res = await http.Client().send(req);
    // Wait for the download to finish
    await res.stream.drain();
  }
}

/// Android backend: llama.cpp through a platform channel (see native/android/LlamaPlugin.kt).
class NativeLlamaBackend implements LlmBackend {
  static const _m = MethodChannel('gramvidya/llama');
  static const _e = EventChannel('gramvidya/llama/tokens');
  @override
  String get name => 'llama.cpp (on-device)';
  @override
  Future<bool> available() async {
    try {
      return await _m.invokeMethod<bool>('isModelLoaded') ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<String> generate(String system, String prompt, {String context = ''}) =>
      _e.receiveBroadcastStream({'system': system, 'prompt': prompt}).cast<String>();
}

/// Offline-only fallback: answers from the best retrieved note, no LLM needed.
/// Used when no local AI model (Ollama or llama.cpp) is available.
class OfflineFallbackBackend implements LlmBackend {
  @override
  String get name => 'GramVidya (Offline Notes)';
  @override
  Future<bool> available() async => true;
  @override
  Stream<String> generate(String system, String prompt, {String context = ''}) async* {
    final text = 'I am GramVidya AI. The local AI model is not currently loaded, '
        'so I am answering from your offline notes.\n\n'
        'You asked: "$prompt"\n\n'
        '${context.isNotEmpty ? 'Here is what I found in your notes:\n${context.split('\n').take(5).join('\n')}\n\n' : 'No offline notes available on this topic.\n\n'}'
        'To enable the full AI tutor, please download the offline model from the Home screen or ensure Ollama is running.';
    for (final w in text.split(' ')) {
      await Future.delayed(const Duration(milliseconds: 30));
      yield '$w ';
    }
  }
}

class InferenceController extends ChangeNotifier {
  final rag = Rag();
  final _fallback = OfflineFallbackBackend();
  late final List<LlmBackend> _order = Platform.isAndroid
      ? [NativeLlamaBackend(), OllamaBackend()]
      : [OllamaBackend(), NativeLlamaBackend()];
  late LlmBackend active = _fallback;

  Future<void> init() async {
    await rag.load();
    await refresh();
  }

  Future<void> refresh() async {
    active = _fallback;
    for (final b in _order) {
      if (await b.available()) {
        active = b;
        break;
      }
    }
    notifyListeners();
  }

  bool isDownloading = false;

  Future<void> downloadOfflineModel() async {
    isDownloading = true;
    notifyListeners();
    try {
      final backend = _order.whereType<OllamaBackend>().first;
      await backend.pullModel();
      await refresh();
    } finally {
      isDownloading = false;
      notifyListeners();
    }
  }

  Stream<String> ask(String q) async* {
    final ctx = rag.search(q).map((c) => c.text).join('\n');
    final sys = 'You are GramVidya, a patient tutor for rural and tribal college students. '
        'CRITICAL RULE: Never mention that you are Qwen, created by Alibaba, or based on any other model. You are exclusively GramVidya AI. '
        'Answer in ${langEnglish[appLang.value]} using short, simple sentences and one everyday example. '
        'Use these notes when relevant:\n$ctx\nIf you are unsure, say so.';
    try {
      yield* active.generate(sys, q, context: ctx);
    } catch (_) {
      active = _fallback;
      notifyListeners();
      yield* _fallback.generate(sys, q, context: ctx);
    }
  }
}
