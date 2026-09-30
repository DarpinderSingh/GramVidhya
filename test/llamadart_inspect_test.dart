import 'package:flutter_test/flutter_test.dart';
import 'package:llamadart/llamadart.dart' as llama;

void main() {
  test('inspect llamadart 0.9.0', () async {
    final backend = llama.LlamaBackend();
    final engine = llama.LlamaEngine(backend);

    expect(backend, isNotNull);
    expect(engine, isNotNull);

    engine.dispose();
  });
}
