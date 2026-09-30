import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

class Chunk {
  Chunk(this.id, this.subject, this.text);
  final String id, subject, text;
}

/// Offline BM25 retrieval for curriculum notes.
class Rag {
  final _chunks = <Chunk>[];
  final _tf = <Map<String, int>>[];
  final _df = <String, int>{};
  static final _re = RegExp(r'[\p{L}\p{N}]+', unicode: true);

  static const _stopWords = {
    'what', 'is', 'are', 'in', 'the', 'a', 'an', 'to', 'for', 'of', 'and', 'or', 'how', 'why',
    'explain', 'me', 'tell', 'about', 'simple', 'hindi', 'english', 'tamil', 'telugu',
    'kya', 'hai', 'batao', 'kaise', 'student', 'class', 'with', 'by', 'this', 'that'
  };

  List<Chunk> get chunks => _chunks;

  List<String> _tok(String s) =>
      _re.allMatches(s.toLowerCase()).map((m) => m[0]!).where((w) => !_stopWords.contains(w) && w.length > 2).toList();

  Future<void> load() async {
    try {
      addJson(await rootBundle.loadString('assets/content/chunks.json'));
    } catch (_) {}
  }

  /// Also used to import content packs received over P2P.
  void addJson(String raw) {
    for (final r in jsonDecode(raw) as List) {
      if (_chunks.any((c) => c.id == r['id'])) continue;
      final c = Chunk(r['id'], r['subject'], r['text']);
      final t = <String, int>{};
      for (final w in _tok(c.text)) {
        t[w] = (t[w] ?? 0) + 1;
      }
      for (final w in t.keys) {
        _df[w] = (_df[w] ?? 0) + 1;
      }
      _chunks.add(c);
      _tf.add(t);
    }
  }

  List<Chunk> search(String q, {int k = 2, double minScore = 2.5}) {
    final n = _chunks.length;
    final qs = _tok(q);
    if (qs.isEmpty || n == 0) return const [];

    final sc = <int, double>{};
    for (var i = 0; i < n; i++) {
      var s = 0.0;
      for (final w in qs) {
        final f = _tf[i][w];
        if (f == null) continue;
        final d = _df[w] ?? 1;
        s += log(1 + (n - d + 0.5) / (d + 0.5)) * (f * 2.2) / (f + 1.2);
      }
      if (s >= minScore) sc[i] = s;
    }

    final ids = sc.keys.toList()..sort((a, b) => sc[b]!.compareTo(sc[a]!));
    return ids.take(k).map((i) => _chunks[i]).toList();
  }
}
