import 'package:flutter/material.dart';
import '../ai/inference_controller.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../voice/voice_service.dart';

class _Msg {
  _Msg(this.text, this.user);
  String text;
  final bool user;
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.ai});
  final InferenceController ai;
  @override
  State<ChatScreen> createState() => _ChatState();
}

class _ChatState extends State<ChatScreen> {
  final _c = TextEditingController();
  final _v = VoiceService();
  final _msgs = <_Msg>[
    _Msg("Namaste! I am your GramVidya AI Tutor. Ask me anything in your language.", false)
  ];
  bool _busy = false, _rec = false;

  final List<String> _suggestions = [
    "Explain simply",
    "Translate",
    "Summarize",
    "Quiz generation",
    "Practice questions",
    "Homework help",
  ];

  Future<void> _send([String? t]) async {
    final q = (t ?? _c.text).trim();
    if (q.isEmpty || _busy) return;
    _c.clear();
    setState(() {
      _msgs..add(_Msg(q, true))..add(_Msg('', false));
      _busy = true;
    });
    await for (final tok in widget.ai.ask(q)) {
      setState(() => _msgs.last.text += tok);
    }
    setState(() => _busy = false);
    _v.speak(_msgs.last.text, appLang.value);
  }

  Future<void> _mic() async {
    if (_rec) {
      final text = await _v.stop(appLang.value);
      setState(() => _rec = false);
      _send(text);
    } else {
      setState(() => _rec = true);
      await _v.start(appLang.value, (t) => _c.text = t);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tok = context.tokens;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: tok.accent,
              child: const Icon(Icons.smart_toy, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("GramVidya AI Tutor", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: tok.textPrimary)),
                Text("Offline AI | Multi-language RAG", style: TextStyle(fontSize: 12, color: tok.textSecondary)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _msgs.length,
              itemBuilder: (context, i) {
                final m = _msgs[i];
                return Align(
                  alignment: m.user ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: m.user ? tok.accent : tok.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(m.user ? 16 : 0),
                        bottomRight: Radius.circular(m.user ? 0 : 16),
                      ),
                      border: m.user ? null : Border.all(color: tok.border),
                    ),
                    child: Text(
                      m.text.isEmpty ? 'Typing…' : m.text,
                      style: TextStyle(
                        color: m.user ? Colors.white : tok.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_msgs.length == 1)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: _suggestions.map((s) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: Text(s, style: TextStyle(color: tok.textPrimary, fontSize: 12)),
                    backgroundColor: tok.surface,
                    side: BorderSide(color: tok.border),
                    onPressed: () => _send(s),
                  ),
                )).toList(),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tok.surface,
              border: Border(top: BorderSide(color: tok.border)),
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: _rec ? Colors.red.withValues(alpha: 0.2) : tok.chipBackground,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _mic,
                    icon: Icon(_rec ? Icons.stop : Icons.mic, color: _rec ? Colors.red : tok.accent),
                    tooltip: 'Voice Assistant Mode',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _c,
                    onSubmitted: _send,
                    style: TextStyle(color: tok.textPrimary),
                    decoration: InputDecoration(
                      hintText: "Ask in your language...",
                      hintStyle: TextStyle(color: tok.textMuted),
                      filled: true,
                      fillColor: tok.backgroundSecondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: tok.buttonPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => _send(),
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
